#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(dirname -- "$SCRIPT_DIR")
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
FDR=0

usage() {
    printf '%s\n' "Usage: ./spinup.sh [--fdr 0|1] PATH_TO_PURPLEAIR_SETTINGS_JSON" >&2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --fdr)
            [ "$#" -ge 2 ] || { usage; exit 1; }
            FDR=$2
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            printf '%s\n' "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

SETTINGS_FILE=$1
case "$SETTINGS_FILE" in
    /*) ;;
    *) SETTINGS_FILE=$(pwd)/$SETTINGS_FILE ;;
esac

if [ ! -f "$SETTINGS_FILE" ]; then
    printf '%s\n' "PurpleAir settings file does not exist: $SETTINGS_FILE" >&2
    exit 1
fi

case "${FDR:-0}" in
    0|1) ;;
    *) printf '%s\n' "FDR must be 0 or 1" >&2; exit 1 ;;
esac

export PURPLEAIR_SETTINGS_FILE="$SETTINGS_FILE"

cd "$REPO_DIR"
if [ "${FDR:-0}" = "1" ]; then
    printf '%s\n' "--fdr 1: factory-resetting the persistent Matterbridge data volume." >&2
    docker compose -f "$COMPOSE_FILE" stop purpleair-matterbridge 2>/dev/null || true
    docker compose -f "$COMPOSE_FILE" build
    docker compose -f "$COMPOSE_FILE" run --rm --no-deps \
        --entrypoint /opt/matterbridge/node_modules/.bin/matterbridge \
        purpleair-matterbridge --factoryreset
fi

docker compose -f "$COMPOSE_FILE" up --build -d --remove-orphans

printf '%s\n' "purpleair-matterbridge is running."
docker compose -f "$COMPOSE_FILE" ps
printf '%s\n' "Recent Matterbridge logs (pairing QR/manual code is shown here on first startup):"
docker compose -f "$COMPOSE_FILE" logs --no-color --tail 200 purpleair-matterbridge