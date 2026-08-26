import pandas as pd
from google.cloud import bigquery
from logger import logger
from db_engines import big_db


def normalize_columns(df):
    """
    Standardizes column names to ensure compatibility with SQL databases.
    """

    # Remove extra spaces, convert to lowercase, and replace
    # spaces/hyphens with underscores for SQL-safe naming
    df.columns = (
        df.columns.str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
        .str.replace("-", "_", regex=False)
    )

    return df


# Maps each dataset's load_type to the correct BigQuery write behavior.
# "full" re-extracts the entire source table every run, so it must REPLACE
# the destination table rather than append to it — otherwise every row
# duplicates on every run (see audit P1.1).
WRITE_DISPOSITIONS = {
    "full": "WRITE_TRUNCATE",
    "incremental": "WRITE_APPEND",
}


def load(df, table_name, engine, load_type="incremental"):
    if df.empty:
        return

    if load_type not in WRITE_DISPOSITIONS:
        raise ValueError(
            f"Unknown load_type {load_type!r} for {table_name} — "
            f"expected one of {list(WRITE_DISPOSITIONS)}"
        )

    df = normalize_columns(df)

    # Stamp ingestion time so staging models can deduplicate deterministically
    # (see audit P1.2) — without this there's no way to tell which of two
    # duplicate rows is the one that should survive.
    df["_ingested_at"] = pd.Timestamp.now(tz="UTC")

    table_id = f"{big_db}.{table_name}"

    job_config = bigquery.LoadJobConfig(write_disposition=WRITE_DISPOSITIONS[load_type])

    engine.load_table_from_dataframe(
        df,
        table_id,
        job_config=job_config,
    ).result()

    logger.info(
        f"Loaded {len(df)} rows into {table_name} "
        f"(write_disposition={WRITE_DISPOSITIONS[load_type]})"
    )
