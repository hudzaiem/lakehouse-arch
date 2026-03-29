-- ================================================================
-- 04: Gold — 1-Minute OHLCV Candles (Stream → Gold)
-- ================================================================
-- Real-time TUMBLE window aggregation langsung dari Kafka
-- Run via:  docker exec flink-jobmanager ./bin/sql-client.sh -f /tmp/sql/04-gold-ohlcv.sql

USE CATALOG iceberg_lakehouse;
USE gold;

-- Gold table
CREATE TABLE IF NOT EXISTS stock_ohlcv_1m (
    `ticker`        STRING,
    `window_start`  TIMESTAMP(3),
    `window_end`    TIMESTAMP(3),
    `open`          DOUBLE,
    `high`          DOUBLE,
    `low`           DOUBLE,
    `close`         DOUBLE,
    `volume`        BIGINT,
    `tick_count`    BIGINT
) WITH (
    'format-version' = '2',
    'write.upsert.enabled' = 'false'
);

-- Kafka source (same as bronze, redeclare karena TEMPORARY)
CREATE TEMPORARY TABLE kafka_stock_stream_gold (
    `id`         STRING,
    `price`      DOUBLE,
    `volume`     BIGINT,
    `timestamp`  BIGINT,
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
    'properties.group.id'            = 'flink-gold-ohlcv',
    'format'                         = 'json',
    'json.ignore-parse-errors'       = 'true',
    'scan.startup.mode'              = 'earliest-offset'
);

-- Insert: 1-minute OHLCV windowed aggregation
INSERT INTO stock_ohlcv_1m
SELECT
    `id`                                       AS `ticker`,
    window_start,
    window_end,
    FIRST_VALUE(`price`)                       AS `open`,
    MAX(`price`)                               AS `high`,
    MIN(`price`)                               AS `low`,
    LAST_VALUE(`price`)                        AS `close`,
    SUM(`volume`)                              AS `volume`,
    COUNT(*)                                   AS `tick_count`
FROM TABLE(
    TUMBLE(TABLE kafka_stock_stream_gold, DESCRIPTOR(`event_time`), INTERVAL '1' MINUTE)
)
GROUP BY `id`, window_start, window_end;
