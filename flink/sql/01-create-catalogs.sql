-- ================================================================
-- 01: Create Iceberg Catalog & Databases (via Nessie + GCS)
-- ================================================================
-- Run this first in Flink SQL CLI:
--   docker exec -it flink-jobmanager ./bin/sql-client.sh

-- Create Iceberg catalog backed by Nessie + GCS
CREATE CATALOG iceberg_lakehouse WITH (
    'type'          = 'iceberg',
    'catalog-impl'  = 'org.apache.iceberg.nessie.NessieCatalog',
    'uri'           = 'http://nessie:19120/api/v1',
    'ref'           = 'main',
    'warehouse'     = 'gs://${GCS_BUCKET}/warehouse',
    'io-impl'       = 'org.apache.iceberg.gcp.gcs.GCSFileIO'
);

USE CATALOG iceberg_lakehouse;

-- Create Medallion databases
CREATE DATABASE IF NOT EXISTS bronze;
CREATE DATABASE IF NOT EXISTS silver;
CREATE DATABASE IF NOT EXISTS gold;
