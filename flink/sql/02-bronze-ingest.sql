-- ================================================================
-- 02: Bronze — Raw Ingest (Kafka → Iceberg)
-- ================================================================
-- Kafka source → iceberg_lakehouse.bronze.stock_ticks
-- Run via:  docker exec flink-jobmanager ./bin/sql-client.sh -f /tmp/sql/02-bronze-ingest.sql

USE CATALOG iceberg_lakehouse;
USE bronze;

-- Kafka source table
CREATE TEMPORARY TABLE kafka_stock_stream (
    `id`         STRING,
    `price`      DOUBLE,
    `volume`     BIGINT,
    `timestamp`  BIGINT,        -- epoch seconds from yfinance
    `exchange`   STRING,
    `event_time` AS TO_TIMESTAMP_LTZ(`timestamp`, 0),
    WATERMARK FOR `event_time` AS `event_time` - INTERVAL '10' SECOND
) WITH (
    'connector'                      = 'kafka',
    'topic'                          = '${KAFKA_TOPIC}',
    'properties.bootstrap.servers'   = '${KAFKA_BOOTSTRAP_SERVERS}',
    'properties.security.protocol'   = '${KAFKA_SECURITY_PROTOCOL}',
    'properties.sasl.mechanism'      = '${KAFKA_SASL_MECHANISM}',
    'properties.sasl.jaas.config'    = '${KAFKA_SASL_JAAS_CONFIG}',
    'properties.group.id'            = 'flink-bronze-ingest',
    'format'                         = 'json',
    'json.ignore-parse-errors'       = 'true',
    'scan.startup.mode'              = 'earliest-offset'
);

-- Bronze Iceberg sink table
CREATE TABLE IF NOT EXISTS stock_ticks (
    `id`           STRING,
    `price`        DOUBLE,
    `volume`       BIGINT,
    `raw_timestamp` BIGINT,
    `exchange`     STRING,
    `event_time`   TIMESTAMP_LTZ(3),
    `ingested_at`  TIMESTAMP_LTZ(3)
) WITH (
    'format-version' = '2',
    'write.upsert.enabled' = 'false'
);

-- Insert: append raw events
INSERT INTO stock_ticks
SELECT
    `id`,
    `price`,
    `volume`,
    `timestamp`  AS `raw_timestamp`,
    `exchange`,
    `event_time`,
    CURRENT_TIMESTAMP AS `ingested_at`
FROM kafka_stock_stream;
