# Release Tools

Standardized automation and validation utilities for managing releases, version bumps, dependency synchronization, and documentation checks across `purpleair-matterbridge`.

## Overview

The `release_tools/` directory provides release utilities for `purpleair-matterbridge` following the unified `carlkidcrypto` ecosystem standard.

## Available Tools

### `bump_version.sh` (or `release.sh`)

Atomically bumps version strings across npm package metadata, lockfiles, plugin configuration, and Sphinx documentation. Optionally bumps `purpleair-data-logger` dependency.

- **Aliases**: `release_tools/release.sh` is a symlink to `bump_version.sh`.
- **Validation**: Supports Semantic Versioning (e.g. `1.1.0-alpha.3`, `1.1.0`).
- **Auto-detection**: Automatically extracts current version from `package.json` if omitted.
- **Safety checks**:
  - Updates `package.json`, `package-lock.json`, `purpleair-matterbridge.config.json`, and `sphinx_docs_build/source/conf.py`.
  - Optionally bumps `purpleair-data-logger` references across `docker/requirements.txt`, `README.md`, and `TROUBLESHOOTING-WINDOWS-WSL.md`.

### `bump_purpleair_data_logger.sh`

Dedicated script for synchronizing the `purpleair-data-logger` dependency version across Docker configuration and documentation without changing the Matterbridge plugin package version.

### Command-Line Usage

```bash
# Preview changes without modifying files
./release_tools/bump_version.sh --dry-run 1.1.0-alpha.3

# Bump version and automatically verify formatting, linting, typechecking, tests, build, and docs (-W)
./release_tools/bump_version.sh --verify 1.1.0-alpha.3

# Bump both plugin version and purpleair-data-logger dependency version
./release_tools/bump_version.sh --verify 1.1.0-alpha.3 1.6.0

# Bump only purpleair-data-logger dependency
./release_tools/bump_purpleair_data_logger.sh 1.6.0
```

### Options

| Flag | Long Option | Description |
| :--- | :--- | :--- |
| `-n` | `--dry-run` | Shows files that would be modified without writing changes. |
| `-v` | `--verify` | Runs `format:check`, `lint`, `typecheck`, `test`, `build`, and Sphinx doc build with `-W`. |
| `-l` | `--logger-version` | Bumps purpleair-data-logger dependency version as part of the release. |
| `-h` | `--help` | Displays help message and examples. |

---

## Managed File Touchpoints

When running `bump_version.sh` in `purpleair-matterbridge`, the following files are synchronized:

1. `package.json` &mdash; npm plugin package version
2. `package-lock.json` &mdash; npm dependency lockfile
3. `purpleair-matterbridge.config.json` &mdash; Matterbridge plugin configuration manifest
4. `sphinx_docs_build/source/conf.py` &mdash; Sphinx documentation release variable (`release = "<VER>"`)

If a logger version is specified:
5. `docker/requirements.txt` &mdash; Docker PurpleAir data logger pip requirement pin
6. `README.md` &mdash; Documentation image tags
7. `TROUBLESHOOTING-WINDOWS-WSL.md` &mdash; WSL troubleshooting guide image tag references

---

## Standard Release Checklist

1. **Create a release branch or worktree**:
   ```bash
   git checkout -b chore/bump-v1.1.0-alpha.3
   ```
2. **Execute version bump with verification**:
   ```bash
   ./release_tools/bump_version.sh --verify 1.1.0-alpha.3
   ```
3. **Inspect the git status and diff**:
   ```bash
   git diff
   ```
4. **Commit and push**:
   ```bash
   git commit -am "chore: bump version to 1.1.0-alpha.3"
   git push -u origin chore/bump-v1.1.0-alpha.3
   ```
5. **Open Pull Request**:
   - Open a PR targeting `main`.
   - Wait for maintainer review and merge.
