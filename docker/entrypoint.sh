#!/bin/sh
set -eu

if [ -z "${LOGGER_ARGS:-}" ]; then
    echo "LOGGER_ARGS must contain the PurpleAir Matter logger arguments" >&2
    exit 64
fi

set -- ${LOGGER_ARGS}
python3 -m purpleair_data_logger.PurpleAirMatterDataLogger \
    --http-host 127.0.0.1 \
    --http-port 9855 \
    "$@" &
logger_pid=$!

cleanup() {
    kill "$logger_pid" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

printf '%s\n' "Matterbridge pairing information follows below. On first startup, scan the QR code or enter the numerical pairing code shown in these logs." >&2

/opt/matterbridge/node_modules/.bin/matterbridge \
    --docker \
    --add /opt/plugin \
    --bridge \
    --productName "Purple Air Matterbridge" \
    --novirtual \
    --nosudo