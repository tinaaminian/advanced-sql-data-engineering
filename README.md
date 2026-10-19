
# Advanced SQL for Data Engineering

This repository contains SQL exercises and practical data engineering scenarios I've worked on using PostgreSQL.

I created this project to improve my SQL skills beyond basic queries, focusing on data cleaning, incremental loading, change detection, and data warehouse modeling.

The exercises use an e-commerce dataset containing customers, products and orders.

## Tech Stack

- PostgreSQL 18
- Docker & Docker Compose
- DBeaver
- SQL

## Topics Covered

| File | Description |
|------|-------------|
| `01_advanced_joins.sql` | Advanced joins, anti-joins, EXISTS, and aggregations |
| `02_window_functions.sql` | Ranking, window functions, and analytical queries |
| `03_deduplication_data_quality.sql` | Duplicate detection and data validation |
| `04_incremental_loading.sql` | Watermarks, incremental filtering, and lookback windows |
| `05_change_detection.sql` | Identifying new, changed, and unchanged records |
| `06_dimensional_modeling.sql` | Fact and dimension tables, SCD Type 1 and Type 2 |




### Data Cleaning and Deduplication

Used `ROW_NUMBER()` and CTEs to identify duplicate records, select the latest version of each record, and validate data before loading it into warehouse tables.

### Incremental Loading

Worked with timestamp-based watermarks to identify records updated since the previous load.

I also explored lookback windows for late-arriving records and the importance of idempotency when reprocessing data.

### Change Detection

Compared staging records against warehouse records using `IS DISTINCT FROM` and hash-based comparisons to identify inserts, updates, and unchanged records.

### Slowly Changing Dimensions (SCD Type 2)

Implemented customer history tracking using:

- `effective_from` and `effective_to` to define validity periods
- `is_current` to identify active records
- Change detection to avoid unnecessary historical versions
- Transactions and temporary tables to coordinate updates and inserts

### Dimensional Modeling

Practiced designing fact and dimension tables, defining table grain, using surrogate keys, and joining facts to the appropriate historical dimension records.

## Running Locally

Start PostgreSQL using Docker Compose:

```bash
docker compose up -d
```

Connect to the database using DBeaver or another PostgreSQL client.

Run the scripts in the `setup/` directory to initialize the database, then explore the SQL files in `queries/`.

To stop the container:

```bash
docker compose down
```

