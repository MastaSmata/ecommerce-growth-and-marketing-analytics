from datetime import datetime
from google.cloud import bigquery
from db_engines import big_db
import pandas as pd
from db_engines import dest_engine

WATERMARK_TABLE = "etl_watermark"

DEFAULT_WATERMARK = "2023-01-01 00:00:00"  # or your existing default


def get_watermark(table_name, engine):
    """
    Retrieves the last loaded watermark for a table from BigQuery.

    Args:
        table_name (str): Source table name.
        bq_client (bigquery.Client): BigQuery client.
        project (str): BigQuery project ID.
        dataset (str): BigQuery dataset.

    Returns:
        datetime | str: Watermark value or DEFAULT_WATERMARK.
    """

    query = f"""
    SELECT MAX(last_loaded_date) AS last_loaded_date
    FROM `{big_db}.{WATERMARK_TABLE}`
    WHERE table_name = @table_name
    """

    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter(
                "table_name",
                "STRING",
                table_name,
            )
        ]
    )

    results = engine.query(
        query,
        job_config=job_config,
    ).result()

    row = next(results, None)

    if row.last_loaded_date is None:         # type: ignore
        return DEFAULT_WATERMARK
    else:
        return row["last_loaded_date"]   #type: ignore



def update_watermark(table_name, watermark_value, engine):
    """
    Inserts the watermark for a table in BigQuery.

    In case of a real project, it is better to replace the existing 
    "last loaded date" of a table, rather than creating new rows
    """

    if watermark_value is None:
        return

    df = pd.DataFrame({
        "table_name": [table_name],
        "last_loaded_date": [watermark_value],
        "loaded_at": [datetime.now()]
    })

    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_APPEND"
    )

    engine.load_table_from_dataframe(
        df,
        f"{big_db}.etl_watermark",
        job_config=job_config,
    ).result()
