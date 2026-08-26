import pandas as pd

from logger import logger
from config.datasets import DATASETS
from watermark import get_watermark
from db_engines import (
    source_engine,
    dest_engine,
)

from extract import (
    extract_full,
    extract_incremental,
)

from load import load

from watermark import (
    get_watermark,
    update_watermark,
)

from config.datasets import DATASETS

from transform import (
    normalize_dataframe,
    SCHEMAS,
)

from extract import (
    extract_full,
    extract_incremental,
)

from load import load

# CLear the logger file and start afresh
from pathlib import Path

log_file = Path("etl/etl.log")

# Clear the file contents
log_file.write_text("")


for name, config in DATASETS.items():

    if config["load_type"] == "full":
        df = extract_full(source_engine, config["source"])
        wm_value = None
        logger.info(f"{df} successfully loaded")

    else:
        wm_value = get_watermark(config["target"], dest_engine)

        logger.info(f"extracting data from {config['source']} since {wm_value}")

        df = extract_incremental(
            source_engine,
            config["source"],
            config["watermark_column"],
            wm_value,
        )
    logger.info(f"normalizing...")
    df = normalize_dataframe(df, SCHEMAS[config["schema"]])

    logger.info("loading...")
    load(df, config["target"], dest_engine, config["load_type"])

    # recompute watermark from loaded batch
    if config["load_type"] == "incremental" and not df.empty:

        logger.info("watermarking..")

        new_wm = df[config["watermark_column"]].max()
        update_watermark(config["target"], new_wm, dest_engine)

        logger.info(f"watermark updated for {config['target']} with {new_wm}")
