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

```bash
npm install --global --prefix "$HOME/.local" matterbridge@3.10.3
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
