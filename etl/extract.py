import pandas as pd
from sqlalchemy import text


def extract_full(engine, table):

    return pd.read_sql(
        f"SELECT * FROM {table}",
        engine,
    )


def extract_incremental(
    engine,
    table,
    watermark_column,
    watermark_value,
):

    query = text(f"""
        SELECT *
        FROM {table}
        WHERE {watermark_column} > :watermark
        """)

    return pd.read_sql(
        query,
        engine,
        params={"watermark": watermark_value},
    )
