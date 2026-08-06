#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(dirname -- "$SCRIPT_DIR")
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

if [ "$#" -ne 1 ]; then
    printf '%s\n' "Usage: FDR=1 ./docker/spinup.sh PATH_TO_PURPLEAIR_SETTINGS_JSON" >&2
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
    printf '%s\n' "FDR=1: factory-resetting the persistent Matterbridge data volume." >&2
    docker compose -f "$COMPOSE_FILE" stop purpleair-matterbridge 2>/dev/null || true
    docker compose -f "$COMPOSE_FILE" build
    docker compose -f "$COMPOSE_FILE" run --rm --no-deps \
        --entrypoint /opt/matterbridge/node_modules/.bin/matterbridge \
        purpleair-matterbridge --factoryreset
fi

docker compose -f "$COMPOSE_FILE" up --build -d --remove-orphans

printf '%s\n' "purpleair-matterbridge is running."
docker compose -f "$COMPOSE_FILE" ps