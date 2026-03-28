# Stock Lakehouse — Open-Source ETL

Open-source Lakehouse ETL stack untuk memproses stock market data dari Kafka.

## Architecture

```
yfinance WebSocket → Kafka (stock-stream) → Flink → Iceberg (GCS) → Trino
                                                                    ↕
                                                              OpenMetadata
```

**Medallion Architecture**: Bronze (raw) → Silver (clean) → Gold (OHLCV 1-min)

## Stack

| Component | Tool | Port |
|-----------|------|------|
| Stream Processing | Apache Flink 1.20 | `8081` (Web UI) |
| Table Format | Apache Iceberg | — |
| Iceberg Catalog | Nessie | `19120` |
| Storage | GCS | — |
| Query Engine | Trino | `8085` |
| Data Catalog | OpenMetadata | `8585` |

## Prerequisites

- Docker & Docker Compose
- Running Kafka cluster (3-broker KRaft) — lokal (compose terpisah) atau remote
- GCS bucket + Service Account JSON key (Storage Object Admin)

## Quick Start

### 1. Download Flink JARs (sekali saja)

```bash
chmod +x flink/download-jars.sh
./flink/download-jars.sh
```

### 2. Setup environment

```bash
cp .env.lakehouse.example .env.lakehouse
# Edit .env.lakehouse:
#   - Paste GCS_CREDENTIALS_JSON (full JSON, single line)
#   - Set GCS_BUCKET
#   - Kafka remote: set KAFKA_BOOTSTRAP_SERVERS, KAFKA_SECURITY_PROTOCOL,
#     KAFKA_SASL_USERNAME, KAFKA_SASL_PASSWORD
#   - Kafka lokal: default sudah benar (PLAINTEXT, no auth)
```

### 3. Start lakehouse stack

```bash
# Kafka REMOTE (default)
docker compose -f docker-compose.lakehouse.yml --env-file .env.lakehouse up -d

# Kafka LOKAL (compose terpisah, 1 VM)
docker compose \
  -f docker-compose.lakehouse.yml \
  -f docker-compose.network.yml \
  --env-file .env.lakehouse up -d
```

### 4. Verify services

```bash
docker compose -f docker-compose.lakehouse.yml ps

# Nessie API
curl http://localhost:19120/api/v2/trees

# Flink Web UI
open http://localhost:8081

# Trino
open http://localhost:8085

# OpenMetadata
open http://localhost:8585    # admin / admin
```

### 5. Run Flink SQL jobs

```bash
# Open Flink SQL CLI
docker exec -it flink-jobmanager ./bin/sql-client.sh

# Di dalam SQL CLI, jalankan berurutan:
#   1. source /opt/flink/sql/01-create-catalogs.sql
#   2. source /opt/flink/sql/02-bronze-ingest.sql   (streaming job)
#   3. source /opt/flink/sql/04-gold-ohlcv.sql       (streaming job)
#
# Silver (batch dedup) bisa dijalankan periodik:
#   4. source /opt/flink/sql/03-silver-clean.sql
```

### 6. Query data via Trino

```bash
docker exec -it trino trino

# Di dalam Trino CLI:
SHOW CATALOGS;
SHOW SCHEMAS FROM iceberg;
SELECT * FROM iceberg.bronze.stock_ticks LIMIT 10;
SELECT * FROM iceberg.gold.stock_ohlcv_1m LIMIT 10;
```

## Resource Usage (dengan limits)

| Service | RAM | CPU |
|---------|-----|-----|
| Nessie | 256 MB | 0.15 |
| Flink JobManager | 768 MB | 0.25 |
| Flink TaskManager | 1.5 GB | 0.40 |
| Trino | 1 GB | 0.30 |
| OpenMetadata | 1 GB | 0.25 |
| MySQL (OM) | 256 MB | 0.15 |
| Elasticsearch (OM) | 768 MB | 0.25 |
| OM Ingestion | 384 MB | 0.15 |
| **Total** | **~5.9 GB** | **~1.9** |

> **Note**: Jika Kafka berjalan di compose terpisah di VM yang sama, tambahkan
> `-f docker-compose.network.yml` saat start. Jika Kafka remote, cukup pakai compose utama saja.

## File Structure

```
stock-lakehouse/
├── docker-compose.lakehouse.yml
├── docker-compose.network.yml    # Optional: join Kafka network lokal
├── .env.lakehouse.example
├── flink/
│   ├── entrypoint.sh           # GCS credentials + SQL envsubst
│   ├── download-jars.sh        # Download Flink dependencies
│   ├── lib/                    # JARs (gitignored)
│   └── sql/
│       ├── 01-create-catalogs.sql
│       ├── 02-bronze-ingest.sql
│       ├── 03-silver-clean.sql
│       └── 04-gold-ohlcv.sql
├── trino/
│   ├── entrypoint.sh           # GCS credentials handler
│   └── catalog/
│       └── iceberg.properties
└── openmetadata/
```

## Stopping

```bash
# Kafka remote
docker compose -f docker-compose.lakehouse.yml --env-file .env.lakehouse down

# Kafka lokal (sama seperti saat start)
docker compose \
  -f docker-compose.lakehouse.yml \
  -f docker-compose.network.yml \
  --env-file .env.lakehouse down

# Remove volumes too (tambah -v):
docker compose -f docker-compose.lakehouse.yml --env-file .env.lakehouse down -v
```
