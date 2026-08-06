#!/bin/sh

set -eu

CONTAINER_NAME=purpleair-matterbridge
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:-ghcr.io/carlkidcrypto/purpleair-matterbridge}

if [ "$#" -ne 1 ] || [ -z "${IMAGE_TAG:-}" ]; then
    printf '%s\n' "Usage: IMAGE_TAG=VERSION-SHA-RUN-ATTEMPT ./docker/update_pa_matterbridge.sh PATH_TO_PURPLEAIR_SETTINGS_JSON" >&2
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

IMAGE="$IMAGE_REPOSITORY:$IMAGE_TAG"

printf '%s\n' "Pulling $IMAGE"
docker pull "$IMAGE"

docker rm --force "$CONTAINER_NAME" 2>/dev/null || true

docker run --detach \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    --network host \
    --volume matterbridge-data:/data/matterbridge \
    --volume logger-data:/data/logger \
    --volume "$SETTINGS_FILE:/config/purpleair-settings.json:ro" \
    "$IMAGE"

printf '%s\n' "purpleair-matterbridge is running from $IMAGE."
docker ps --filter "name=^/${CONTAINER_NAME}$"