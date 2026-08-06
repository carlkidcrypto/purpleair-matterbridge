#!/bin/sh

set -eu

CONTAINER_NAME=purpleair-matterbridge
IMAGE_REPOSITORY=ghcr.io/carlkidcrypto/purpleair-matterbridge
IMAGE_TAG=
FDR=0
SETTINGS_FILE=

usage() {
    printf '%s\n' "Usage: ./update_pa_matterbridge.sh --image-tag VERSION-SHA-RUN-ATTEMPT --settings-file PATH_TO_PURPLEAIR_SETTINGS_JSON [--image-repository REPOSITORY] [--fdr]" >&2
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --image-tag)
            [ "$#" -ge 2 ] || { usage; exit 1; }
            IMAGE_TAG=$2
            shift 2
            ;;
        --image-repository)
            [ "$#" -ge 2 ] || { usage; exit 1; }
            IMAGE_REPOSITORY=$2
            shift 2
            ;;
        --fdr)
            FDR=1
            shift
            ;;
        --settings-file)
            [ "$#" -ge 2 ] || { usage; exit 1; }
            SETTINGS_FILE=$2
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

if [ "$#" -ne 0 ] || [ -z "$IMAGE_TAG" ] || [ -z "$SETTINGS_FILE" ]; then
    usage
    exit 1
fi

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

if [ "$FDR" = "1" ]; then
    printf '%s\n' "--fdr: factory-resetting the persistent Matterbridge data volume." >&2
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
printf '%s\n' "Recent Matterbridge logs (pairing QR/manual code is shown here on first startup):"
docker logs --tail 200 "$CONTAINER_NAME"