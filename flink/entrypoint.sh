#!/bin/bash
set -e

# ----------------------------------------------------------------
# Write GCS credentials JSON to a temp file
# ----------------------------------------------------------------
if [ -n "$GCS_CREDENTIALS_JSON" ]; then
    echo "$GCS_CREDENTIALS_JSON" > /tmp/gcs-key.json
    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcs-key.json
    echo "[entrypoint] GCS credentials written to /tmp/gcs-key.json"
else
    echo "[entrypoint] WARNING: GCS_CREDENTIALS_JSON is not set!"
fi

# ----------------------------------------------------------------
# Copy custom JARs to Flink lib
# ----------------------------------------------------------------
if [ -d /opt/flink/lib/custom ] && [ "$(ls -A /opt/flink/lib/custom/*.jar 2>/dev/null)" ]; then
    cp /opt/flink/lib/custom/*.jar /opt/flink/lib/
    echo "[entrypoint] Copied custom JARs to /opt/flink/lib/"
    ls -la /opt/flink/lib/custom/*.jar
fi

# ----------------------------------------------------------------
# Substitute env vars in SQL templates (copy to /tmp so host is untouched)
# ----------------------------------------------------------------
if [ -d /opt/flink/sql ]; then
    mkdir -p /tmp/sql
    for f in /opt/flink/sql/*.sql; do
        [ -f "$f" ] && envsubst < "$f" > "/tmp/sql/$(basename "$f")"
    done
    echo "[entrypoint] Substituted env vars in SQL files → /tmp/sql/"
fi

# ----------------------------------------------------------------
# Start Flink (jobmanager or taskmanager)
# ----------------------------------------------------------------
exec /docker-entrypoint.sh "$@"
