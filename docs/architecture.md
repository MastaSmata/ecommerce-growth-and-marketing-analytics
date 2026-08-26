# ETL Application Architecture

This document describes the ETL application in the etl folder and explains how each file contributes to the end-to-end data pipeline. The current implementation moves data from an operational PostgreSQL source into Google BigQuery raw tables, applies light normalization, and supports incremental loading through a watermark mechanism.

## 1. High-level purpose

The ETL app is responsible for:

- Connecting to the source PostgreSQL database.
- Extracting data from several source tables.
- Transforming the data into a shape compatible with BigQuery raw tables.
- Loading the data into BigQuery.
- Tracking incremental load progress through a watermark table.

The pipeline is designed around a simple orchestration pattern:

1. Read dataset configuration.
2. Extract data from the source system.
3. Normalize and type-cast the data.
4. Load it into BigQuery.
5. Update the watermark for incremental datasets.

---

## 2. Execution flow

The main execution path starts in [etl/main.py](../etl/main.py). That file loops through the dataset definitions from [etl/config/datasets.py](../etl/config/datasets.py), decides whether each dataset should be loaded fully or incrementally, and then calls the extraction, normalization, and loading steps in order.

The general flow is:

- For a full load, read all rows from the source table.
- For an incremental load, read only rows newer than the last recorded watermark.
- Normalize the dataframe using the appropriate schema.
- Load the dataframe into a BigQuery raw table.
- Update the watermark table for incremental datasets after a successful load.

This makes the ETL process very linear and easy to follow, but it also means each step relies on the previous modules being configured correctly.

---

## 3. File-by-file breakdown

### [etl/main.py](../etl/main.py)

This is the orchestration entry point for the ETL pipeline.

Its responsibilities are:

- Importing the database engines, extraction functions, loading function, watermark helpers, and transformation utilities.
- Clearing the ETL log file at startup so each run begins with a fresh log.
- Iterating through every dataset in the configuration dictionary.
- Deciding whether to perform a full or incremental extract.
- Calling the normalization step and the loading step.
- Updating the watermark for incremental loads after the batch is loaded.

The code is intentionally simple: for each dataset, it performs one extraction, one normalize step, one load step, and optionally one watermark update.

Key behavior:

- Full loads call extract_full().
- Incremental loads call get_watermark() to find the previous high-water mark, then extract_incremental().
- After loading, the code calculates the maximum watermark value from the newly loaded batch and stores it.

### [etl/extract.py](../etl/extract.py)

This file contains the data extraction logic.

It has two functions:

- extract_full(engine, table): reads the full contents of a source table using pandas.read_sql.
- extract_incremental(engine, table, watermark_column, watermark_value): builds a SQL query that selects rows where the watermark column is greater than the last known watermark value.

The extraction layer is intentionally thin. It does not implement complex filtering, joins, or business logic; it simply retrieves the required rows from the source database.

Connection to the rest of the system:

- It receives the source engine from [etl/db_engines.py](../etl/db_engines.py).
- It is called by [etl/main.py](../etl/main.py) for each dataset.

### [etl/load.py](../etl/load.py)

This file contains the load logic into BigQuery.

Its responsibilities are:

- Checking whether the dataframe is empty before attempting to load anything.
- Standardizing column names so they are compatible with SQL-style naming conventions.
- Sending the dataframe to BigQuery using the Google BigQuery Python client.

The function normalize_columns() prepares the dataframe by:

- trimming whitespace from column names,
- converting them to lowercase,
- replacing spaces and hyphens with underscores.

The function load() then uses the BigQuery client to append rows into a target table in the configured dataset. It uses the write_disposition WRITE_APPEND, meaning each run appends new records rather than replacing the table contents.

Connection to the rest of the system:

- It receives the dataframe produced by the normalization step.
- It uses the BigQuery client created in [etl/db_engines.py](../etl/db_engines.py).
- It is invoked by [etl/main.py](../etl/main.py) after transformation.

### [etl/transform/normalize.py](../etl/transform/normalize.py)

This module applies a lightweight type-normalization step to the extracted dataframe.

It uses the dataset schema definitions from [etl/transform/schemas.py](../etl/transform/schemas.py) and adjusts the incoming columns based on their expected data types.

The normalization rules are:

- DATE columns are parsed as pandas datetime values.
- INT columns are coerced to numeric values and cast to pandas nullable integer type.
- DECIMAL columns are converted to numeric values.
- VARCHAR columns are cast to strings.

The function catches errors during conversion and prints a message instead of failing the whole run. This means the pipeline is tolerant of a few bad values, but it does not provide a deep validation framework.

Connection to the rest of the system:

- It is called from [etl/main.py](../etl/main.py).
- It relies on the schema mapping in [etl/transform/schemas.py](../etl/transform/schemas.py).

### [etl/transform/schemas.py](../etl/transform/schemas.py)

This file defines the target schema for each dataset.

It maps dataset names such as customers, sales, products, campaigns, marketing, and channels to dictionaries of columns and expected types.

These definitions are used to guide the normalization step so that the data lands in BigQuery in a consistent and predictable shape.

The schema file is a central contract between:

- the source extraction step,
- the transformation step,
- and the final BigQuery load step.

### [etl/transform/__init__.py](../etl/transform/__init__.py)

This file simply re-exports the transformation helpers so they can be imported cleanly from the rest of the ETL application.

It makes the package easier to import by exposing:

- normalize_dataframe
- SCHEMAS

### [etl/db_engines.py](../etl/db_engines.py)

This file handles the configuration and creation of the two external database connections used by the ETL app.

It performs three important tasks:

- Reads required environment variables from the local environment.
- Creates a PostgreSQL SQLAlchemy engine for the source database.
- Creates a Google BigQuery client for the destination warehouse.

It exports:

- source_engine: the SQLAlchemy engine used to read from PostgreSQL.
- dest_engine: the BigQuery client used to write to BigQuery.
- big_db: the fully qualified BigQuery project.dataset identifier.

This module is foundational because the rest of the ETL code depends on these connection objects being initialized correctly.

### [etl/logger.py](../etl/logger.py)

This file defines the logging configuration for the ETL application.

It creates a logger named logs/etl and attaches two handlers:

- a file handler that writes logs to etl.log,
- a console handler that prints logs to the terminal.

The logger level is set to INFO, so the pipeline emits operational messages about the extraction, normalization, and loading steps.

Connection to the rest of the system:

- [etl/main.py](../etl/main.py) and [etl/load.py](../etl/load.py) use the logger to provide run-time visibility.

### [etl/watermark.py](../etl/watermark.py)

This module implements the incremental-load tracking mechanism.

It is responsible for:

- reading the last loaded watermark value from BigQuery,
- writing a new watermark value after a successful load.

The watermark is stored in a BigQuery table named etl_watermark. The module uses the table_name and last_loaded_date fields to record which source table was processed and when.

The default watermark is set to 2023-01-01 00:00:00, which means that the first incremental run will typically pull data from that date forward.

Connection to the rest of the system:

- [etl/main.py](../etl/main.py) calls get_watermark() before extracting incremental data.
- [etl/main.py](../etl/main.py) calls update_watermark() after loading a batch.

### [etl/create_watermark.py](../etl/create_watermark.py)

This file is a setup helper for the watermark system.

It creates the BigQuery table used by [etl/watermark.py](../etl/watermark.py) if it does not already exist. The table schema contains:

- table_name
- last_loaded_date
- loaded_at

The script is intended to be run once during setup or when the watermark table needs to be recreated.

It also contains commented-out examples for truncating tables, which suggests that the file may have been used during development and testing.

### [etl/config/datasets.py](../etl/config/datasets.py)

This file contains the dataset registry for the ETL pipeline.

Each dataset entry specifies:

- the source table name in PostgreSQL,
- the target raw table name in BigQuery,
- the load strategy (full or incremental),
- the watermark column for incremental loads,
- the schema key used for normalization.

The current configuration includes six datasets:

- customers -> raw_customers
- sales -> raw_sales
- products -> raw_products
- campaigns -> raw_campaigns
- channels -> raw_channels
- marketing -> raw_marketing

This file is the central place where new datasets can be added to the pipeline.

---

## 4. Raw table SQL definitions

The SQL files under [etl/sql/raw_tables](../etl/sql/raw_tables) define the destination table structures for the raw layer in BigQuery.

These files are:

- [etl/sql/raw_tables/raw_customers.sql](../etl/sql/raw_tables/raw_customers.sql)
- [etl/sql/raw_tables/raw_sales.sql](../etl/sql/raw_tables/raw_sales.sql)
- [etl/sql/raw_tables/raw_products.sql](../etl/sql/raw_tables/raw_products.sql)
- [etl/sql/raw_tables/raw_marketing.sql](../etl/sql/raw_tables/raw_marketing.sql)
- [etl/sql/raw_tables/raw_campaigns.sql](../etl/sql/raw_tables/raw_campaigns.sql)
- [etl/sql/raw_tables/raw_channels.sql](../etl/sql/raw_tables/raw_channels.sql)

They define the raw tables with primary keys and column definitions that reflect the expected structure of the incoming data. These SQL files are not invoked by the Python orchestrator directly, but they serve as the schema blueprints for the warehouse layer and are important for understanding what the ETL app is loading into BigQuery.

---

## 5. How the modules connect

The ETL app is built around a simple dependency chain:

1. [etl/db_engines.py](../etl/db_engines.py) establishes the source and destination connections.
2. [etl/config/datasets.py](../etl/config/datasets.py) provides the dataset definitions.
3. [etl/main.py](../etl/main.py) reads those definitions and orchestrates the run.
4. [etl/extract.py](../etl/extract.py) pulls data from PostgreSQL.
5. [etl/transform/normalize.py](../etl/transform/normalize.py) and [etl/transform/schemas.py](../etl/transform/schemas.py) shape the data.
6. [etl/load.py](../etl/load.py) pushes the data into BigQuery.
7. [etl/watermark.py](../etl/watermark.py) tracks the latest processed timestamp for incremental loads.
8. [etl/logger.py](../etl/logger.py) records operational messages for observability.

In other words, the pipeline is a straightforward sequence of configuration, extraction, normalization, loading, and incremental tracking.

---

## 6. Operational notes

A few implementation details are worth noting:

- The pipeline currently uses append-only loading into BigQuery. It does not perform upserts or deletes.
- Incremental loading is based on a single watermark column per dataset.
- The transformation layer is lightweight and focuses mostly on data type coercion rather than full data quality enforcement.
- The ETL process assumes that the target raw tables already exist or that the SQL definitions have been applied beforehand.

This architecture is appropriate for a small-to-medium data pipeline where clarity and maintainability matter more than advanced orchestration or complex transformations.
