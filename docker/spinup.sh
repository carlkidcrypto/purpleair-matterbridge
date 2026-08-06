#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_DIR=$(dirname -- "$SCRIPT_DIR")
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

if [ "$#" -ne 1 ]; then
    printf '%s\n' "Usage: ./docker/spinup.sh PATH_TO_PURPLEAIR_SETTINGS_JSON" >&2
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

export PURPLEAIR_SETTINGS_FILE="$SETTINGS_FILE"

cd "$REPO_DIR"
docker compose -f "$COMPOSE_FILE" up --build -d --remove-orphans

printf '%s\n' "purpleair-matterbridge is running."
docker compose -f "$COMPOSE_FILE" ps