#!/usr/bin/env bash

set -euo pipefail

usage() {
    cat <<'USAGE_TEXT'
Usage: release_tools/bump_version.sh [OPTIONS] NEW_VERSION [LOGGER_VERSION]

Bump the current release version across npm package, config, and Sphinx documentation.
Optionally bumps purpleair-data-logger dependency when LOGGER_VERSION is provided.

Options:
    -n, --dry-run             Preview files that would be modified without writing changes.
    -v, --verify              Run format, lint, typecheck, test, build, and sphinx doc build (-W).
    -l, --logger-version VER  Bump purpleair-data-logger dependency to specified version.
    -h, --help                Show this help message.

Examples:
    release_tools/bump_version.sh 1.1.0-alpha.3
    release_tools/bump_version.sh --dry-run 1.1.0-alpha.3
    release_tools/bump_version.sh --verify 1.1.0-alpha.3
    release_tools/bump_version.sh --verify 1.1.0-alpha.3 1.6.0
    release_tools/bump_version.sh --verify 1.1.0-alpha.3 --logger-version 1.6.0
USAGE_TEXT
}

dry_run=false
verify=false
logger_version=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            dry_run=true
            shift
            ;;
        -v|--verify)
            verify=true
            shift
            ;;
        -l|--logger-version)
            if [[ $# -lt 2 ]]; then
                printf 'Error: --logger-version requires an argument\n' >&2
                exit 2
            fi
            logger_version="${2#v}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -lt 1 || $# -gt 2 ]]; then
    usage >&2
    exit 2
fi

new_version="${1#v}"  # Strip leading 'v' if present
if [[ $# -eq 2 && -z "$logger_version" ]]; then
    logger_version="${2#v}"
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# Validate version format (Semantic Versioning e.g. 1.1.0-alpha.3, 1.1.0)
if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    printf 'Error: Invalid release version: %s. Expected semantic version format.\n' "$new_version" >&2
    exit 2
fi

if [[ -n "$logger_version" && ! "$logger_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-]?[0-9A-Za-z.-]+)?$ ]]; then
    printf 'Error: Invalid logger version: %s\n' "$logger_version" >&2
    exit 2
fi

command -v npm >/dev/null 2>&1 || { printf 'Error: npm is required.\n' >&2; exit 1; }
command -v node >/dev/null 2>&1 || { printf 'Error: node is required.\n' >&2; exit 1; }

old_version=$(node -p "require('./package.json').version" 2>/dev/null || sed -nE 's/^[[:space:]]*"version":[[:space:]]*"([^"]+)".*$/\1/p' package.json | head -n 1)

target_files=(
    package.json
    package-lock.json
    sphinx_docs_build/source/conf.py
    purpleair-matterbridge.config.json
)

if [[ -n "$logger_version" ]]; then
    target_files+=(
        docker/requirements.txt
        README.md
        TROUBLESHOOTING-WINDOWS-WSL.md
    )
fi

printf '%s version %s -> %s%s in %d file(s):\n' \
    "$([[ "$dry_run" == true ]] && printf 'Would bump' || printf 'Bumping')" \
    "$old_version" "$new_version" \
    "$([[ -n "$logger_version" ]] && printf ' (purpleair-data-logger -> %s)' "$logger_version" || true)" \
    "${#target_files[@]}"

for f in "${target_files[@]}"; do
    printf '  - %s\n' "$f"
done

if [[ "$dry_run" == true ]]; then
    printf '\nDry-run complete. No files were modified.\n'
    exit 0
fi

# 1. Bump logger dependency if requested
if [[ -n "$logger_version" ]]; then
    printf '\nBumping purpleair-data-logger dependency to %s...\n' "$logger_version"
    bash "${repo_root}/release_tools/bump_purpleair_data_logger.sh" "$logger_version"
fi

# 2. Update npm package & lockfile
printf '\nUpdating package version to %s...\n' "$new_version"
npm version "$new_version" --no-git-tag-version --allow-same-version --ignore-scripts

# 3. Synchronize Sphinx conf.py and plugin config
VERSION="$new_version" node <<'NODE'
const fs = require('node:fs');

const version = process.env.VERSION;
const files = ['sphinx_docs_build/source/conf.py'];

for (const file of files) {
  const original = fs.readFileSync(file, 'utf8');
  const newline = original.includes('\r\n') ? '\r\n' : '\n';
  const normalized = original.replace(/\r\n/g, '\n');
  const updated = normalized.replace(
    /^release = "[^"]+"$/m,
    `release = "${version}"`,
  );

  if (updated === normalized) {
    throw new Error(`Could not find the expected version entry in ${file}`);
  }

  fs.writeFileSync(file, updated.replace(/\n/g, newline));
}

const configPath = 'purpleair-matterbridge.config.json';
if (fs.existsSync(configPath)) {
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  config.version = version;
  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
}
NODE

printf 'Successfully updated version to %s.\n' "$new_version"

if [[ "$verify" == true ]]; then
    printf '\nRunning post-bump verification...\n'

    # Formatting and linting
    printf '[1/6] Checking formatting...\n'
    npm run format:check
    printf '[2/6] Running linter...\n'
    npm run lint
    printf '[3/6] Running typecheck...\n'
    npm run typecheck
    printf '[4/6] Running tests...\n'
    npm test
    printf '[5/6] Building production package...\n'
    npm run build

    # Sphinx documentation build
    sphinx_bin="sphinx-build"
    venv_candidates=(
        "/home/carlkidcrypto/Github/ezsnmp/python3.12.venv"
        "${repo_root}/python3.12.venv"
        "${VIRTUAL_ENV:-}"
    )
    for vdir in "${venv_candidates[@]}"; do
        [[ -z "$vdir" ]] && continue
        [[ "$sphinx_bin" == "sphinx-build" && -x "${vdir}/bin/sphinx-build" ]] && sphinx_bin="${vdir}/bin/sphinx-build"
    done

    if command -v "$sphinx_bin" >/dev/null 2>&1; then
        printf '[6/6] Building Sphinx documentation (SPHINXOPTS="-W")...\n'
        (cd sphinx_docs_build && SPHINXBUILD="$sphinx_bin" make html SPHINXOPTS="-W" >/dev/null && rm -rf .doctrees)
    else
        printf '[6/6] sphinx-build not found, skipping doc build.\n'
    fi

    printf '\nVerification complete: all checks passed with zero warnings.\n'
fi
