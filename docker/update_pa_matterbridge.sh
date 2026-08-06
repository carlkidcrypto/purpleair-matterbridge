#!/bin/sh

set -eu

CONTAINER_NAME=purpleair-matterbridge
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-ghcr.io/carlkidcrypto/purpleair-matterbridge}

if [ "$#" -ne 1 ] || [ -z "${IMAGE_TAG:-}" ]; then
    printf '%s\n' "Usage: FDR=1 IMAGE_TAG=VERSION-SHA-RUN-ATTEMPT ./docker/update_pa_matterbridge.sh PATH_TO_PURPLEAIR_SETTINGS_JSON" >&2
    printf '%s\n' "Optional: IMAGE_REPOSITORY=carlkidcrypto/purpleair-matterbridge-images" >&2
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

IMAGE="$IMAGE_REPOSITORY:$IMAGE_TAG"

printf '%s\n' "Pulling $IMAGE"
docker pull "$IMAGE"

docker rm --force "$CONTAINER_NAME" 2>/dev/null || true

if [ "${FDR:-0}" = "1" ]; then
    printf '%s\n' "FDR=1: factory-resetting the persistent Matterbridge data volume." >&2
    docker run --rm \
        --network host \
        --volume matterbridge-data:/data \
        --volume logger-data:/data/logger \
        --entrypoint /opt/matterbridge/node_modules/.bin/matterbridge \
        "$IMAGE" \
        --factoryreset
fi

docker run --detach \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    --network host \
    --volume matterbridge-data:/data \
    --volume logger-data:/data/logger \
    --volume "$SETTINGS_FILE:/config/purpleair-settings.json:ro" \
    "$IMAGE"

printf '%s\n' "purpleair-matterbridge is running from $IMAGE."
docker ps --filter "name=^/${CONTAINER_NAME}$"