#!/bin/sh

set -eu

CONTAINER_NAME=purpleair-matterbridge
IMAGE_REPOSITORY=carlkidcrypto/purpleair-matterbridge-images
IMAGE_TAG=
FDR=0
LOGGER_MODE=
MDNS_INTERFACE=
SETTINGS_FILE=

resolve_newest_docker_hub_tag() {
    case "$IMAGE_REPOSITORY" in
        */*/*)
            printf '%s\n' "Cannot discover tags automatically for registry repository '$IMAGE_REPOSITORY'; pass --image-tag." >&2
            exit 64
            ;;
    esac

    python3 - "$IMAGE_REPOSITORY" <<'PY'
import json
import re
import sys
from urllib.parse import quote
from urllib.request import Request, urlopen

repository = sys.argv[1]
url = (
    "https://hub.docker.com/v2/repositories/"
    f"{quote(repository, safe='/')}/tags?page_size=100&ordering=last_updated"
)
request = Request(url, headers={"Accept": "application/json", "User-Agent": "purpleair-matterbridge"})

try:
    with urlopen(request, timeout=15) as response:
        payload = json.load(response)
except Exception as error:
    raise SystemExit(f"Could not query Docker Hub tags for {repository}: {error}")

immutable_tag = re.compile(r"^\d+\.\d+\.\d+-[0-9a-f]+-\d+-\d+$")
tags = [tag for tag in payload.get("results", []) if immutable_tag.fullmatch(tag.get("name", ""))]
if not tags:
    raise SystemExit(f"No published immutable image tags found for {repository}")

tags.sort(key=lambda tag: tag.get("last_updated", ""), reverse=True)
print(tags[0]["name"])
PY
}

usage() {
    printf '%s\n' "Usage: ./update_pa_matterbridge.sh --local|--remote --settings-file PATH_TO_PURPLEAIR_SETTINGS_JSON [--image-tag TAG] [--mdns-interface INTERFACE] [--image-repository DOCKER_HUB_REPOSITORY] [--fdr]" >&2
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
        --local)
            [ -z "$LOGGER_MODE" ] || { printf '%s\n' "Choose only one of --local or --remote." >&2; usage; exit 1; }
            LOGGER_MODE=local
            shift
            ;;
        --remote)
            [ -z "$LOGGER_MODE" ] || { printf '%s\n' "Choose only one of --local or --remote." >&2; usage; exit 1; }
            LOGGER_MODE=remote
            shift
            ;;
        --mdns-interface)
            [ "$#" -ge 2 ] || { usage; exit 1; }
            MDNS_INTERFACE=$2
            shift 2
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

if [ "$#" -ne 0 ] || [ -z "$SETTINGS_FILE" ] || [ -z "$LOGGER_MODE" ]; then
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

if [ -z "$IMAGE_TAG" ]; then
    printf '%s\n' "Discovering the newest published Docker Hub image tag for $IMAGE_REPOSITORY..."
    IMAGE_TAG=$(resolve_newest_docker_hub_tag)
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
        --entrypoint /opt/matterbridge/bin/matterbridge \
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
    --env "PURPLEAIR_LOGGER_MODE=$LOGGER_MODE" \
    --env "MDNS_INTERFACE=$MDNS_INTERFACE" \
    "$IMAGE"

printf '%s\n' "purpleair-matterbridge is running from $IMAGE."
docker ps --filter "name=^/${CONTAINER_NAME}$"
printf '%s\n' "Recent Matterbridge logs (pairing QR/manual code is shown here on first startup):"
docker logs --tail 200 "$CONTAINER_NAME"