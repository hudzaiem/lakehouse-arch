#!/bin/bash
set -e

# ================================================================
# Download required Flink JARs for Kafka + Iceberg + GCS
# ================================================================
# Run this ONCE before starting Flink:
#   chmod +x flink/download-jars.sh && ./flink/download-jars.sh

FLINK_VERSION="1.20.0"
FLINK_SHORT="1.20"          # Maven artifact suffix (tanpa patch)
KAFKA_CONNECTOR_VERSION="3.4.0"
ICEBERG_VERSION="1.7.1"
SCALA_VERSION="2.12"

LIB_DIR="$(dirname "$0")/lib"
mkdir -p "$LIB_DIR"

echo "Downloading Flink JARs to $LIB_DIR ..."

# 1. Kafka SQL Connector
echo "[1/4] flink-sql-connector-kafka..."
curl -fSL -o "$LIB_DIR/flink-sql-connector-kafka-${KAFKA_CONNECTOR_VERSION}-${FLINK_SHORT}.jar" \
  "https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/${KAFKA_CONNECTOR_VERSION}-${FLINK_SHORT}/flink-sql-connector-kafka-${KAFKA_CONNECTOR_VERSION}-${FLINK_SHORT}.jar"

# 2. Iceberg Flink Runtime
echo "[2/4] iceberg-flink-runtime..."
curl -fSL -o "$LIB_DIR/iceberg-flink-runtime-${FLINK_SHORT}-${ICEBERG_VERSION}.jar" \
  "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-flink-runtime-${FLINK_SHORT}/${ICEBERG_VERSION}/iceberg-flink-runtime-${FLINK_SHORT}-${ICEBERG_VERSION}.jar"

# 3. Flink S3 Hadoop Filesystem (for GCS via S3-compat API)
echo "[3/4] flink-s3-fs-hadoop..."
curl -fSL -o "$LIB_DIR/flink-s3-fs-hadoop-${FLINK_VERSION}.jar" \
  "https://repo1.maven.org/maven2/org/apache/flink/flink-s3-fs-hadoop/${FLINK_VERSION}/flink-s3-fs-hadoop-${FLINK_VERSION}.jar"

# 4. GCS Hadoop Connector (native GCS support)
echo "[4/4] gcs-connector-hadoop..."
curl -fSL -o "$LIB_DIR/gcs-connector-hadoop3-latest.jar" \
  "https://storage.googleapis.com/hadoop-lib/gcs/gcs-connector-hadoop3-latest.jar"

echo ""
echo "✅ All JARs downloaded to $LIB_DIR:"
ls -lh "$LIB_DIR"/*.jar
