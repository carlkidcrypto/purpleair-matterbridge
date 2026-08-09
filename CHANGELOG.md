# Changelog

All notable changes to `purpleair-matterbridge` are documented here.

## [1.0.1] - 2026-08-09

### Fixed

- Corrected npm release workflow handling for GitHub release events.
- Restored the Matterbridge development dependency needed by npm release checks.
- Corrected versioned Sphinx documentation publishing for release tags.

## [1.0.0] - 2026-08-09

### Added

- Combined Docker image running the PurpleAir data logger and Matterbridge.
- Explicit `--local` and `--remote` PurpleAir logger modes.
- Persistent Matterbridge and logger Docker volumes.
- Automatic Docker Hub discovery of the newest immutable image tag.
- Optional `--mdns-interface` selection for hosts with Docker bridge and virtual
  Ethernet interfaces.
- Native Linux, WSL, firewall, IPv6, mDNS, commissioning, and cron
  troubleshooting documentation.
- Matter air-quality endpoints with temperature, humidity, pressure, air
  quality, PM1, PM2.5, PM10, and optional TVOC measurements.
- Documented controller compatibility and cross-controller sharing workflows.

### Release Notes

- Matterbridge is published as a separate runtime and is not an npm package
  dependency of this plugin.
- Normal container replacement preserves commissioning state through the
  `matterbridge-data` volume.
- `--fdr` remains an explicit destructive factory-reset operation.
