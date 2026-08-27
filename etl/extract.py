import pandas as pd
from sqlalchemy import text

# How many days before the watermark to re-pull, so a row that arrives
# late on the same calendar day as the watermark isn't permanently
# missed. Safe to widen this window because staging dedup (see
# stg_sales.sql / stg_marketing.sql) already protects against
# re-processing rows we've already loaded.
DEFAULT_LOOKBACK_DAYS = 3


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
    lookback_days=DEFAULT_LOOKBACK_DAYS,
):

    # Watermarked on a business date (order_date / date), not a
    # created_at/updated_at timestamp — a strict ">" against that value
    # would permanently skip any row that arrives late but still carries
    # a date at or before the watermark. Re-pulling a short window and
    # using ">=" catches those, and dedup downstream makes the overlap
    # safe (see audit P1.3).
    effective_watermark = pd.to_datetime(watermark_value) - pd.Timedelta(
        days=lookback_days
    )

    query = text(f"""
        SELECT *
        FROM {table}
        WHERE {watermark_column} >= :watermark
        """)

    return pd.read_sql(
        query,
        engine,
        params={"watermark": effective_watermark},
    )
