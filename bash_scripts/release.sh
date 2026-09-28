#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: bash_scripts/release.sh VERSION [LOGGER_VERSION]

Update npm, config, and Sphinx version metadata, optionally bump purpleair-data-logger,
regenerate package-lock.json, and run formatting, linting, typechecking, tests,
and the production build.

The script does not commit, tag, push, publish, or update the changelog.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "$#" -eq 0 ]]; then
  usage
  exit 0
fi

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
  usage >&2
  exit 2
fi

VERSION="$1"
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
  printf 'Error: VERSION must be a valid semantic version, got: %s\n' "$VERSION" >&2
  exit 2
fi

LOGGER_VERSION="${2:-}"

cd "$ROOT_DIR"

command -v npm >/dev/null 2>&1 || { printf 'Error: npm is required.\n' >&2; exit 1; }
command -v node >/dev/null 2>&1 || { printf 'Error: node is required.\n' >&2; exit 1; }

if [[ -n "$LOGGER_VERSION" ]]; then
  printf 'Bumping purpleair-data-logger to %s...\n' "$LOGGER_VERSION"
  bash "$ROOT_DIR/bash_scripts/bump_purpleair_data_logger.sh" "$LOGGER_VERSION"
fi

printf 'Updating package version to %s...\n' "$VERSION"
npm version "$VERSION" --no-git-tag-version --allow-same-version --ignore-scripts

VERSION="$VERSION" node <<'NODE'
const fs = require('node:fs');

const version = process.env.VERSION;
const files = ['sphinx_docs_build/source/conf.py'];

for (const file of files) {
  const path = file;
  const original = fs.readFileSync(path, 'utf8');
  const newline = original.includes('\r\n') ? '\r\n' : '\n';
  const normalized = original.replace(/\r\n/g, '\n');
  let updated;

  updated = normalized.replace(
    /^release = "[^"]+"$/m,
    `release = "${version}"`,
  );

  if (updated === normalized) {
    throw new Error(`Could not find the expected version entry in ${path}`);
  }

  fs.writeFileSync(path, updated.replace(/\n/g, newline));
}

const configPath = 'purpleair-matterbridge.config.json';
if (fs.existsSync(configPath)) {
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  config.version = version;
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
}
NODE

printf 'Running formatting...\n'
npm run format
printf 'Checking formatting...\n'
npm run format:check
printf 'Running linter...\n'
npm run lint
printf 'Running typecheck...\n'
npm run typecheck
printf 'Running tests...\n'
npm test
printf 'Building package...\n'
npm run build

printf '\nRelease preparation complete for %s.\n' "$VERSION"
printf 'Review git diff, update the changelog, then commit/tag/publish separately.\n'
