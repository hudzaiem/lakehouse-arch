#!/bin/bash
set -e

# ----------------------------------------------------------------
# Write GCS credentials JSON to a temp file
# ----------------------------------------------------------------
if [ -n "$GCS_CREDENTIALS_JSON" ]; then
    mkdir -p /tmp/gcs
    echo "$GCS_CREDENTIALS_JSON" > /tmp/gcs/gcs-key.json
    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcs/gcs-key.json
    echo "[entrypoint] GCS credentials written to /tmp/gcs/gcs-key.json"
else
    echo "[entrypoint] WARNING: GCS_CREDENTIALS_JSON is not set!"
fi

# ----------------------------------------------------------------
# Start Trino
# ----------------------------------------------------------------
exec /usr/lib/trino/bin/run-trino "$@"
