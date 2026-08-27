from sqlalchemy import text
from db_engines import dest_engine, big_db


from google.cloud import bigquery


def truncate_table(engine, table_name):
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {table_name}"))


def create_watermark_table(client):

    table_id = f"{big_db}.etl_watermark"

    schema = [
        bigquery.SchemaField("table_name", "STRING", mode="REQUIRED"),
        bigquery.SchemaField("last_loaded_date", "TIMESTAMP", mode="REQUIRED"),
        bigquery.SchemaField("loaded_at", "TIMESTAMP", mode="REQUIRED"),
    ]

    table = bigquery.Table(table_id, schema=schema)

    client.create_table(table, exists_ok=True)

    print("Watermark table created.")


create_watermark_table(dest_engine)

"""truncate_table(dest_engine, "etl_watermark")
truncate_table(dest_engine, "raw_sales")
truncate_table(dest_engine, "raw_customers")
truncate_table(dest_engine, "raw_inventory")"""

