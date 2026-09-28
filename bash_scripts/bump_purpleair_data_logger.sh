#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: bash_scripts/bump_purpleair_data_logger.sh LOGGER_VERSION

Update purpleair-data-logger version in docker/requirements.txt and synchronize
documentation references across README.md and TROUBLESHOOTING-WINDOWS-WSL.md.

The script does not commit, tag, push, or open a pull request.
Review the resulting git diff and submit changes via a pull request.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "$#" -eq 0 ]]; then
  usage
  exit 0
fi

if [[ "$#" -ne 1 ]]; then
  usage >&2
  exit 2
fi

RAW_VERSION="$1"
# Strip leading 'v' if present (e.g. from GitHub release tag v1.6.0a0)
LOGGER_VERSION="${RAW_VERSION#v}"

if [[ ! "$LOGGER_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-]?[0-9A-Za-z.-]+)?$ ]]; then
  printf 'Error: LOGGER_VERSION must be a valid version format (e.g. 1.6.0, 1.6.0a0, 1.6.0-alpha.0), got: %s\n' "$RAW_VERSION" >&2
  exit 2
fi

cd "$ROOT_DIR"

command -v node >/dev/null 2>&1 || { printf 'Error: node is required.\n' >&2; exit 1; }

printf 'Updating purpleair-data-logger version to %s...\n' "$LOGGER_VERSION"

LOGGER_VERSION="$LOGGER_VERSION" node <<'NODE'
const fs = require('node:fs');
const path = require('node:path');

const version = process.env.LOGGER_VERSION;

// 1. Update docker/requirements.txt
const reqPath = path.join('docker', 'requirements.txt');
const reqOriginal = fs.readFileSync(reqPath, 'utf8');
const reqUpdated = reqOriginal.replace(
  /^purpleair-data-logger==.+$/m,
  `purpleair-data-logger==${version}`
);
if (reqUpdated === reqOriginal && !reqOriginal.includes(`purpleair-data-logger==${version}`)) {
  throw new Error(`Could not find expected purpleair-data-logger entry in ${reqPath}`);
}
fs.writeFileSync(reqPath, reqUpdated.trimEnd() + '\n');
console.log(`Updated ${reqPath}`);

// 2. Update README.md
const readmePath = 'README.md';
let readme = fs.readFileSync(readmePath, 'utf8');
readme = readme.replace(
  /purpleair-matterbridge:logger-[^\s\\`]+/g,
  `purpleair-matterbridge:logger-${version}`
);
readme = readme.replace(
  /(```text\n)[^\n]+(\n```\n\n### Published image tags)/,
  `$1${version}$2`
);
fs.writeFileSync(readmePath, readme);
console.log(`Updated ${readmePath}`);

// 3. Update TROUBLESHOOTING-WINDOWS-WSL.md
const wslPath = 'TROUBLESHOOTING-WINDOWS-WSL.md';
let wsl = fs.readFileSync(wslPath, 'utf8');
wsl = wsl.replace(
  /purpleair-matterbridge:logger-[^\s\\`]+/g,
  `purpleair-matterbridge:logger-${version}`
);
wsl = wsl.replace(
  /The version check should print `[^`]+`\./,
  `The version check should print \`${version}\`.`
);
fs.writeFileSync(wslPath, wsl);
console.log(`Updated ${wslPath}`);
NODE

if command -v npm >/dev/null 2>&1; then
  printf 'Checking formatting...\n'
  npm run format:check || {
    printf 'Formatting files...\n'
    npm run format
    npm run format:check
  }
fi

printf '\nSuccessfully bumped purpleair-data-logger to %s.\n' "$LOGGER_VERSION"
printf 'Review git diff and submit changes via a pull request.\n'
