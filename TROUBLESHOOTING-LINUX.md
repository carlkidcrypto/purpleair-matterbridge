# Linux troubleshooting

This guide covers Matter commissioning when the combined PurpleAir
Matterbridge container runs on a native Linux host and the Matter controller,
such as an Android phone or Home Assistant, is on the same local network.

## Confirm the container network

The Compose service uses Docker host networking:

```yaml
network_mode: host
```

On native Linux, this gives Matterbridge the host's IPv4 and IPv6 interfaces
and allows it to bind directly to the host's UDP ports. No `ports:` mapping is
needed. Confirm the running container uses host networking:

```bash
docker inspect --format '{{.HostConfig.NetworkMode}}' purpleair-matterbridge
```

The result must be:

```text
host
```

Start the container with the physical LAN interface, not a Docker interface:

```bash
ip -brief address

./docker/spinup.sh \
  --local \
  --mdns-interface wlp2s0 \
  --settings-file /absolute/path/to/paa_local_config.json
```

Replace `wlp2s0` with the interface carrying the host's LAN address. Do not
use `docker0`, `br-*`, or `veth*`.

## Watch and inspect the container

The update script creates the container with the stable name
`purpleair-matterbridge`. Check that it is running and follow the current
Matterbridge/logger output:

```bash
docker ps --filter 'name=^/purpleair-matterbridge$'
docker logs --tail 200 -f purpleair-matterbridge
```

Press `Ctrl+C` to leave the log view without stopping the container. Inspect
the image and host-network configuration with:

```bash
docker inspect --format '{{.Config.Image}} {{.HostConfig.NetworkMode}}' purpleair-matterbridge
```

The output should show the selected immutable image tag and `host`. Use
`docker logs --since 10m -f purpleair-matterbridge` to watch only recent
output. The update script preserves the `matterbridge-data` and `logger-data`
volumes when it replaces the container.

## Automate image updates with cron

The update script can run unattended from the system root crontab. Edit it
with:

```bash
sudo crontab -e
```

Add a nightly entry such as:

```cron
0 0 * * * /home/carlkidcrypto/Documents/repos/purpleair-matterbridge/docker/update_pa_matterbridge.sh --local --settings-file /home/carlkidcrypto/Documents/paa_local_config.json --mdns-interface wlp2s0 >> /var/log/purpleair-matterbridge-update.log 2>&1
```

This runs at midnight according to the Linux system timezone. The updater
queries Docker Hub for the newest published immutable image tag, pulls it,
replaces the `purpleair-matterbridge` container, and starts it with the
persistent Matterbridge and logger volumes. The commissioning identity is
therefore preserved during normal automated updates.

Use absolute paths in cron entries. Do not use `~`, since cron does not load
your interactive shell environment. Replace `wlp2s0` and the settings path
with values appropriate for the host. The script's Docker Hub lookup requires
network access and Python 3; failures are written to the update log.

View the update history with:

```bash
sudo tail -f /var/log/purpleair-matterbridge-update.log
```

The running container's application logs remain separate:

```bash
docker logs --tail 200 -f purpleair-matterbridge
```

Do not put `--fdr` in a recurring cron entry. Factory reset is destructive,
removes commissioning state, and requires deliberate one-time use.

## Allow Matter through UFW

A default UFW policy that denies incoming traffic blocks the Matter session.
Check the firewall:

```bash
sudo ufw status verbose
```

If UFW is active, allow mDNS discovery and Matter commissioning on the LAN
interface:

```bash
sudo ufw allow in on wlp2s0 proto udp to any port 5353 comment 'Matter mDNS'
sudo ufw allow in on wlp2s0 proto udp to any port 5540 comment 'Matter commissioning'
```

Replace `wlp2s0` with the actual LAN interface. Confirm IPv6 support is
enabled in UFW:

```bash
grep '^IPV6=' /etc/default/ufw
```

The result should be:

```text
IPV6=yes
```

Reload UFW after changing its configuration:

```bash
sudo ufw reload
```

The rules need to cover both IPv4 and IPv6. `ufw status verbose` should show
both the normal and `(v6)` versions of the rules.

## Confirm Matterbridge listeners

Run this while the container is running:

```bash
ss -H -lunp | grep -E ':(5353|5540)'
```

Matterbridge should expose UDP 5540 on IPv4 and IPv6, usually shown as:

```text
0.0.0.0:5540
[::]:5540
```

UDP 5353 may have multiple listeners because Linux hosts often run an mDNS
service such as Avahi in addition to Matterbridge. That is not automatically a
problem. The important requirements are that the selected LAN interface has
mDNS multicast membership and that Matterbridge has IPv4 and IPv6 reachability.

Check the interface addresses and multicast routes:

```bash
ip -brief address show dev wlp2s0
ip -6 route
ip maddr show dev wlp2s0
```

The interface should have an IPv6 link-local address, and multicast membership
should include IPv4 `224.0.0.251` and IPv6 `ff02::fb`.

## Observe a commissioning attempt

Capture traffic while starting pairing from the controller:

```bash
sudo tcpdump -ni wlp2s0 'udp port 5353 or udp port 5540'
```

Healthy discovery resembles:

```text
192.168.212.x.5353 > 224.0.0.251.5353
fe80::....5353 > ff02::fb.5353
```

The controller should appear as a source of mDNS traffic. During the actual
Matter connection, UDP traffic to the host on port 5540 should also appear.

Interpret the capture as follows:

- No packets: the phone and host are not on the same reachable LAN, or the
  access point has client isolation/VLAN isolation enabled.
- mDNS packets but no UDP 5540 traffic: discovery works, but the controller's
  Matter session is blocked by UFW, another host firewall, or IPv6 routing.
- UDP 5540 traffic in both directions but pairing still fails: inspect the
  Matterbridge logs for commissioning or CASE/PASE errors.

## Pair with a fresh code

After an intentional factory reset, use the new manual pairing code or QR code
printed by the current container startup. Do not reuse a code from an earlier
startup. Follow the startup logs with:

```bash
docker logs --tail 200 -f purpleair-matterbridge
```

The expected output includes:

```text
Matterbridge is uncommissioned
QR Code URL:
Manual pairing code
```

Keep the Android phone on the same Wi-Fi network, with Bluetooth enabled, and
avoid guest Wi-Fi networks or access points with wireless client isolation.

## Evidence from a working Ubuntu host

A working native Linux setup may show all of the following:

- UFW is active with IPv6 enabled.
- UFW allows UDP 5353 and 5540 on the physical Wi-Fi interface.
- `ss` shows `0.0.0.0:5540` and `[::]:5540`.
- `tcpdump` sees IPv4 mDNS to `224.0.0.251` and IPv6 mDNS to `ff02::fb`.
- The Android controller appears in the mDNS capture.
- Matterbridge logs `Using mdnsinterface wlp2s0` and publishes
  `_matterc._udp.local`.

These observations confirm that Docker host networking, IPv6, mDNS, and the
local firewall are functioning. A failure after this point should be diagnosed
from the Matterbridge commissioning logs or the controller application rather
than from the PurpleAir logger.
