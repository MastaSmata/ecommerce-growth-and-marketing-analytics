import logging

logger = logging.getLogger("etl.log")
logger.setLevel(logging.INFO)

formatter = logging.Formatter("%(asctime)s | %(levelname)s | %(name)s | %(message)s")

# FILE HANDLER (detailed logs)
file_handler = logging.FileHandler("etl.log")
file_handler.setLevel(logging.INFO)
file_handler.setFormatter(formatter)

# CONSOLE HANDLER
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
console_handler.setFormatter(formatter)

logger.addHandler(file_handler)
logger.addHandler(console_handler)
