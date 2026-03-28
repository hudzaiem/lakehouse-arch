-- ================================================================
-- 03: Silver — Clean & Dedup (Bronze → Silver)
-- ================================================================
-- Deduplicate by (id, raw_timestamp), type-safe
-- Jalankan sebagai batch job setelah Bronze sudah ada data

USE CATALOG iceberg_lakehouse;
USE silver;

-- Silver table
CREATE TABLE IF NOT EXISTS stock_ticks_clean (
    `ticker`        STRING,
    `price`         DOUBLE,
    `volume`        BIGINT,
    `event_time`    TIMESTAMP_LTZ(3),
    `exchange`      STRING,
    `processed_at`  TIMESTAMP_LTZ(3)
) WITH (
    'format-version' = '2',
    'write.upsert.enabled' = 'false'
);

-- Insert: deduplicated from bronze
INSERT INTO stock_ticks_clean
SELECT
    `id`           AS `ticker`,
    `price`,
    `volume`,
    `event_time`,
    `exchange`,
    CURRENT_TIMESTAMP AS `processed_at`
FROM (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY `id`, `raw_timestamp`
            ORDER BY `ingested_at` DESC
        ) AS rn
    FROM iceberg_lakehouse.bronze.stock_ticks
) WHERE rn = 1;
