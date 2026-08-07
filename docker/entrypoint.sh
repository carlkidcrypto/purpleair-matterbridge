#!/bin/sh
set -eu

if [ ! -f "${PURPLEAIR_SETTINGS_FILE:-}" ]; then
    echo "PurpleAir settings file is missing: ${PURPLEAIR_SETTINGS_FILE:-}" >&2
    exit 64
fi

logger_mode=${PURPLEAIR_LOGGER_MODE:-}
if [ -z "$logger_mode" ]; then
    logger_mode=$(python3 - "$PURPLEAIR_SETTINGS_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as settings_file:
    settings = json.load(settings_file)

keys = set()
values = [settings]
while values:
    value = values.pop()
    if isinstance(value, dict):
        keys.update(value)
        values.extend(value.values())
    elif isinstance(value, list):
        values.extend(value)

if "your_ipv4_address" in keys:
    print("local")
elif {"your_api_read_key", "your_api_write_key"} & keys:
    print("remote")
else:
    raise SystemExit("cannot detect local or API PurpleAir settings")
PY
    ) || {
        echo "Could not detect PurpleAir logger mode from $PURPLEAIR_SETTINGS_FILE. Set --local or --remote." >&2
        exit 64
    }
fi

case "$logger_mode" in
    local) logger_option=-paa_local_sensor_request_json_file ;;
    remote) logger_option=-paa_multiple_sensor_request_json_file ;;
    *) echo "PURPLEAIR_LOGGER_MODE must be local or remote" >&2; exit 64 ;;
esac

python3 -m purpleair_data_logger.PurpleAirMatterDataLogger \
    --http-host 127.0.0.1 \
    --http-port 9855 \
    "$logger_option" "$PURPLEAIR_SETTINGS_FILE" \
    --matter-only &
logger_pid=$!

cleanup() {
    kill "$logger_pid" 2>/dev/null || true
}
trap cleanup INT TERM EXIT

process_running() {
    [ -d "/proc/$1" ] || return 1
    [ "$(sed -n 's/^State:[[:space:]]*\([A-Z]\).*/\1/p' "/proc/$1/status")" != Z ]
}

printf '%s\n' "Matterbridge pairing information follows below. On first startup, scan the QR code or enter the numerical pairing code shown in these logs." >&2

matterbridge \
    --docker \
    --add /opt/plugin \
    --nosudo

matterbridge \
    --docker \
    --bridge \
    --productName "Purple Air Matterbridge" \
    --novirtual \
    --nosudo &
matterbridge_pid=$!

while process_running "$logger_pid" && process_running "$matterbridge_pid"; do
    sleep 1
done

if ! process_running "$logger_pid"; then
    echo "PurpleAir logger exited; stopping Matterbridge." >&2
    kill "$matterbridge_pid" 2>/dev/null || true
    wait "$matterbridge_pid" 2>/dev/null || true
    exit 1
fi

wait "$matterbridge_pid"