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
## Docker
The combined Matterbridge and `purpleair_data_logger` container files are in
[docker](docker). The image uses Ubuntu 26.04, Node.js 26, and host networking
so Matter mDNS and UDP traffic can reach the local network. Build and start it
from this directory:

```bash
./docker/spinup.sh --local --settings-file /absolute/path/to/sensors.json
```

The script requires exactly one logger mode. Use `--local` when the settings
file contains local sensor network addresses, and use `--remote` when it
contains PurpleAir API credentials. The settings file is mounted read-only at
`/config/purpleair-settings.json`.

```bash
./docker/spinup.sh --local --settings-file ./sensors.json
```

If the host has Docker bridge or virtual Ethernet interfaces, identify the
real LAN interface with `ip -brief address` and pass it explicitly:

```bash
./docker/spinup.sh --local \
	--mdns-interface eth0 \
	--settings-file /absolute/path/to/sensors.json
```

The interface name is host-specific; common names include `eth0`, `enp3s0`,
and `wlan0`. Do not select `docker0`, `br-*`, or `veth*` for Matter mDNS.

It builds the image, removes orphaned Compose containers, and prints the
resulting container status. It can be run from any directory inside the
repository.

To update an existing installation from a published image without building
locally, use `docker/update_pa_matterbridge.sh`. It defaults to the Docker Hub
repository `carlkidcrypto/purpleair-matterbridge-images` and the currently
newest published immutable image tag:

```bash
./docker/update_pa_matterbridge.sh \
	--local \
	--settings-file /absolute/path/to/sensors.json
```

When `--image-tag` is omitted, the script queries Docker Hub and selects the
newest generated immutable tag. Pass `--image-tag TAG` for a specific image.
The automatic lookup applies to Docker Hub repositories; pass an explicit tag
when using another registry. The script pulls the selected image, stops and removes the existing
`purpleair-matterbridge` container, then starts it with host networking,
persistent named volumes, and the settings file mounted read-only.
The Matterbridge home, including its commissioning identity, is stored in the
`matterbridge-data` volume. Replacing the container or pulling a new immutable
image does not reset pairing state.

### Watch the updated container

The update script uses the stable container name
`purpleair-matterbridge`. Check its status and follow its live logs with:

```bash
docker ps --filter 'name=^/purpleair-matterbridge$'
docker logs --tail 200 -f purpleair-matterbridge
```

Press `Ctrl+C` to stop following the logs; it does not stop the container. To
inspect the selected image, network mode, mounts, and environment:

```bash
docker inspect purpleair-matterbridge
docker inspect --format '{{.Config.Image}} {{.HostConfig.NetworkMode}}' purpleair-matterbridge
```

For a shorter live window, use `--since`, for example:

```bash
docker logs --since 10m -f purpleair-matterbridge
```

Use `docker start purpleair-matterbridge` or
`docker restart purpleair-matterbridge` after a manual stop. Normal restarts
preserve the named Matterbridge and logger volumes.
For example, to use a specific immutable Docker Hub image tag:

```bash
./docker/update_pa_matterbridge.sh \
	--image-repository 'carlkidcrypto/purpleair-matterbridge-images' \
	--local \
	--image-tag '0.1.0-35eb4068220a-123456789-1' \
	--settings-file /absolute/path/to/sensors.json
```

### Matter pairing and factory reset

On the first startup, Matterbridge prints its pairing QR code and numerical
pairing code to the container log. Follow the live output with:

```bash
docker logs --tail 200 -f purpleair-matterbridge
```

Commission the bridge with either code. The commissioning identity remains in
the `matterbridge-data` volume across restarts, image pulls, and container
replacement. Do not remove that volume unless you intentionally want to lose
the pairing state.

To deliberately erase all Matterbridge commissioning and registered-plugin
state, pass `--fdr` for one startup operation. The script stops the existing
container, runs Matterbridge's supported `--factoryreset` command against the
persistent volume, and starts a clean instance that prints new pairing codes:

```bash
./docker/spinup.sh --local --fdr --settings-file /absolute/path/to/sensors.json

./docker/update_pa_matterbridge.sh \
	--local \
	--fdr \
	--settings-file /absolute/path/to/sensors.json
```

Factory reset is destructive and invalidates all existing controller pairings.
Normal startup and image updates leave the commissioning state untouched.

Use `--local` for a settings file containing a local sensor address, or
`--remote` for a settings file containing PurpleAir API credentials:

```bash
./docker/spinup.sh --remote --settings-file /absolute/path/to/remote-sensors.json
```

The logger mode is passed into the container as `PURPLEAIR_LOGGER_MODE`; the
entrypoint maps it to the corresponding PurpleAir logger option. Do not set
`LOGGER_ARGS` manually. The combined image starts the logger first, registers
the plugin once, and then starts the long-running Matterbridge process.

The image intentionally uses Node.js 26 because that is the configured image
runtime and it is supported by this project. Matterbridge may log an advisory
message recommending Node.js 24 LTS; that message does not indicate a startup
failure.

The `matterbridge-data` volume stores Matterbridge commissioning and runtime
state. The `logger-data` volume stores logger data. Both volumes survive normal
restarts, image updates, and container replacement.

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

### Verify the image from WSL

The container build uses Ubuntu 26.04, Node.js 26, the latest npm and npx
available for that Node release, Matterbridge 3.10.3, and the published
`purpleair-data-logger` 1.5.0a2 package on Python 3.14. When Docker Desktop's
Linux engine is unavailable, use the Docker Engine installed inside WSL:

```bash
cd /home/carlkidcrypto/Github/purpleair-matterbridge

docker build \
	--progress=plain \
	--build-arg LOGGER_VERSION=1.5.0a2 \
	--build-arg MATTERBRIDGE_VERSION=3.10.3 \
	-f docker/Dockerfile \
	-t purpleair-matterbridge:logger-1.5.0a2 .
```

The build output should show the Matterbridge TypeScript build completing and
the logger package being installed. Verify the generated image and the
published logger module with:

```bash
docker image inspect purpleair-matterbridge:logger-1.5.0a2

docker run --rm \
	--entrypoint /opt/logger-venv/bin/python \
	purpleair-matterbridge:logger-1.5.0a2 \
	-c 'import importlib.metadata as m; print(m.version("purpleair-data-logger"))'
```

The final command should print:

```text
1.5.0a2
```

### Published image tags

The Docker publishing workflow targets
`carlkidcrypto/purpleair-matterbridge-images` on Docker Hub and the matching
repository on GHCR. Each build publishes one immutable tag to both registries.
The immutable tag contains the package version, commit, GitHub run ID, and run
attempt, for example:

```text
0.1.0-35eb4068220a-123456789-1
```

The update script discovers the newest Docker Hub tag automatically when no
tag is supplied. Use the complete generated tag explicitly when
reproducibility is required.

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
pushes to `main` and manual workflow runs. When a GitHub release is published,
the workflow also builds that release tag and prepares a versioned
`docs/html_<tag>/` snapshot plus a landing-page link in an automated pull
request. Those versioned directories are intentionally tracked so released
documentation remains locked as the project changes.

## Testing And Publishing

The package is configured for public npm access. From a clean checkout, install
the locked dependencies and run the release checks:

```bash
npm ci
npm run typecheck
npm test
npm run build
npm run lint
npm run format:check
npm pack --dry-run
npm publish --dry-run
```

Before the first publication, authenticate and verify the npm account:

```bash
npm login
npm whoami
```

For a new release, update both package metadata files with npm and push the
generated commit and tag:

```bash
npm version patch
# or: npm version minor
# or: npm version major
git push origin main --follow-tags
```

Then publish the public package. The `prepublishOnly` hook automatically cleans
and rebuilds `dist`, typechecks, and runs the tests before npm uploads anything:

```bash
npm publish --access public
npm view purpleair-matterbridge version
```

The `Publish npm Package` workflow also publishes automatically when a
semantic-version tag is pushed. Configure npm trusted publishing for
`.github/workflows/publish_npm.yml` first, then use `npm version` and push the
generated tag. The workflow runs the release checks, publishes with npm
provenance, and does not require an `NPM_TOKEN` secret.

Published npm versions are immutable. Never reuse a version that has already
been published. The complete maintainer runbook, including prereleases,
registry verification, package inspection, release ordering, and troubleshooting
is in [npm-publishing.rst](sphinx_docs_build/source/npm-publishing.rst).

See [Requirements.rst](Requirements.rst) for normative behavior,
[PLATFORMS-TESTED.md](PLATFORMS-TESTED.md) for controller results and the
Google Home measurement limitation, and
[TROUBLESHOOTING-LINUX.md](TROUBLESHOOTING-LINUX.md) for native Linux
firewall, IPv6, mDNS, and commissioning procedures. See
[TROUBLESHOOTING-WINDOWS-WSL.md](TROUBLESHOOTING-WINDOWS-WSL.md) for Windows/WSL
commissioning and logging procedures.
