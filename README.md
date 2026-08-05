# purpleair-matterbridge

Matterbridge plugin that exposes PurpleAir Matter JSON as bridged Matter air
quality sensors.

## Requirements

- Node.js 20.19, 22.13, 24, or 26
- Matterbridge 3.10.0 or newer
- A running PurpleAir Matter feed, normally
	`http://127.0.0.1:9855/matter/sensors`
- IPv6 and mDNS connectivity for Matter commissioning

## Install From npm

Install the package into the Matterbridge home directory:

```bash
npm install --prefix "$HOME/.matterbridge" purpleair-matterbridge
```

Register it with Matterbridge:

```bash
"$HOME/.local/bin/matterbridge" \
	--add "$HOME/.matterbridge/node_modules/purpleair-matterbridge"
```

Registration persists. Start the bridge with:

```bash
"$HOME/.local/bin/matterbridge" --bridge \
	--productName "Purple Air Matterbridge" \
	--novirtual \
	--nosudo
```

## Local Development
## Docker

The combined Matterbridge and `purpleair_data_logger` container files are in
[docker](docker). The image uses Ubuntu 26.04, Node.js 26, and host networking
so Matter mDNS and UDP traffic can reach the local network. Build and start it
from this directory:

```bash
export LOGGER_ARGS='-paa_read_key YOUR_READ_KEY -paa_multiple_sensor_request_json_file /config/sensors.json --matter-only'
docker compose -f docker/docker-compose.yml up --build -d
```

For local-network sensors, use the logger's local configuration instead:

```bash
export LOGGER_ARGS='-paa_local_sensor_request_json_file /config/sensors.json --matter-only'
```

Add a read-only bind mount such as
`./sensors.json:/config/sensors.json:ro` to the volumes in

```bash
npm install --global --prefix "$HOME/.local" matterbridge@3.10.3
the LAN.

The image intentionally uses host networking. Matter commissioning requires
mDNS and UDP 5540; use a separate network only if it preserves IPv6 and
multicast behavior.
npm install
npm_config_prefix="$HOME/.local" npm run dev:link
npm run typecheck
npm test
npm run build
```

`npm run dev:link` links the locally installed Matterbridge package without
adding Matterbridge or Matter.js to this package's dependencies. This preserves
the single Matter.js instance required by Matterbridge.

For a local plugin registration, run Matterbridge from the repository parent:

```bash
"$HOME/.local/bin/matterbridge" --add ./purpleair-matterbridge
```

## Configuration

The example configuration is in
[purpleair-matterbridge.config.json](purpleair-matterbridge.config.json), with
its schema in
[purpleair-matterbridge.schema.json](purpleair-matterbridge.schema.json).
The default feed URL is `http://127.0.0.1:9855/matter/sensors`.

Each accepted sensor receives a stable Matter identity of
`purpleair-<sensor_index>`. MAC-based display names use the final three MAC
octets, for example `purple-air-84-a1-4b`.

## Docker

The combined Matterbridge and `purpleair_data_logger` container files are in
[docker](docker). The image uses Ubuntu 26.04, Node.js 26, and host networking
so Matter mDNS and UDP traffic can reach the local network. Build and start it
from this directory:

```bash
export LOGGER_ARGS='-paa_read_key YOUR_READ_KEY -paa_multiple_sensor_request_json_file /config/sensors.json --matter-only'
docker compose -f docker/docker-compose.yml up --build -d
```

For local-network sensors, use the logger's local configuration instead:

```bash
export LOGGER_ARGS='-paa_local_sensor_request_json_file /config/sensors.json --matter-only'
```

Add a read-only bind mount such as
`./sensors.json:/config/sensors.json:ro` to the volumes in
`docker/docker-compose.yml`. Matterbridge state is persisted in the
`matterbridge-data` volume. The logger serves its private feed on
`127.0.0.1:9855`, and Matterbridge consumes that feed without exposing it on
the LAN.

The image intentionally uses host networking. Matter commissioning requires
mDNS and UDP 5540; use a separate network only if it preserves IPv6 and
multicast behavior.

## Documentation

The Sphinx source and build system are in
[sphinx_docs_build](sphinx_docs_build). Build the strict HTML documentation
locally from WSL or Linux with:

```bash
cd sphinx_docs_build
python3 -m pip install -r requirements.txt
make clean
make html SPHINXOPTS="-W"
```

The output is written to `docs/html/` and is ignored by Git. The
`Sphinx Docs Build` workflow builds and deploys the site to GitHub Pages for
pushes to `main` and manual workflow runs.

## Testing And Publishing

`npm publish` runs the `prepublishOnly` verification hook, which cleans and
rebuilds `dist`, typechecks the project, and runs the test suite. The package is
configured for public npm access. Before publishing from a clean checkout,
install and link Matterbridge as shown in the local-development commands, then
run `npm publish`.

See [Requirements.rst](Requirements.rst) for normative behavior,
[PLATFORMS-TESTED.md](PLATFORMS-TESTED.md) for controller results, and
[TROUBLESHOOTING-WINDOWS-WSL.md](TROUBLESHOOTING-WINDOWS-WSL.md) for Windows/WSL
commissioning and logging procedures.
