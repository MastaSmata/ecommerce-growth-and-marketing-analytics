import pandas as pd


def normalize_dataframe(df, schema):

    for column, dtype in schema.items():

        if column not in df.columns:
            continue

        try:

            if dtype == "DATE":
                df[column] = pd.to_datetime(
                    df[column],
                    errors="coerce",
                )

            elif dtype == "INT":
                df[column] = pd.to_numeric(
                    df[column],
                    errors="coerce",
                ).astype("Int64")

            elif "DECIMAL" in dtype:
                df[column] = pd.to_numeric(
                    df[column],
                    errors="coerce",
                )

            elif "VARCHAR" in dtype:
                df[column] = df[column].astype(str)

        except Exception as e:
            print(f"Failed to normalize {column}: {e}")

    return df
