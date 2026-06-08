import os
from pathlib import Path

import duckdb

# ---------------------------------------------------------------------------
# DB path selection — driven by the DBT_TARGET env var.
# Locally DBT_TARGET is unset -> defaults to "dev"; CI sets DBT_TARGET=test.
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).parent.parent  # scripts/ -> repo root
TARGET = os.environ.get("DBT_TARGET", "dev")

DB_PATHS = {
    "prod": REPO_ROOT / "data/duckdb/prod.duckdb",
    "test": Path("/tmp/test.duckdb"),
    "dev":  Path("/tmp/dev.duckdb"),
}

if TARGET not in DB_PATHS:
    raise ValueError(f"Unknown DBT_TARGET: '{TARGET}'. Must be one of: {list(DB_PATHS)}")

DB_PATH = DB_PATHS[TARGET]
OLIST_PATH = REPO_ROOT / "data/raw/olist"
IBGE_PATH = REPO_ROOT / "data/raw/ibge"

# Raw source CSVs grouped by destination schema (logical table name -> filename).
OLIST_TABLES = {
    "orders":               "olist_orders_dataset.csv",
    "order_items":          "olist_order_items_dataset.csv",
    "order_payments":       "olist_order_payments_dataset.csv",
    "order_reviews":        "olist_order_reviews_dataset.csv",
    "customers":            "olist_customers_dataset.csv",
    "sellers":              "olist_sellers_dataset.csv",
    "products":             "olist_products_dataset.csv",
    "geolocation":          "olist_geolocation_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

IBGE_TABLES = {
    "airports": "airports.csv",
    "hdi":      "hdi.csv",
    "icu_beds": "icu-beds.csv",
    "states":   "states.csv",
}


def load_csvs(con, schema: str, base_path: Path, tables: dict[str, str]) -> None:
    """Load each CSV into `schema` as a CREATE OR REPLACE TABLE (idempotent)."""
    con.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
    for table_name, filename in tables.items():
        filepath = base_path / filename
        if not filepath.exists():
            raise FileNotFoundError(f"Missing file: {filepath}")
        con.execute(
            f"CREATE OR REPLACE TABLE {schema}.{table_name} AS "
            f"SELECT * FROM read_csv_auto('{filepath}')"
        )
        print(f"  loaded {schema}.{table_name}")


def main() -> None:
    print(f"[ingestion] target={TARGET}  db={DB_PATH}")
    con = duckdb.connect(str(DB_PATH))
    try:
        print("\n=== OLIST INGESTION ===")
        load_csvs(con, "raw_olist", OLIST_PATH, OLIST_TABLES)
        print("\n=== IBGE INGESTION ===")
        load_csvs(con, "raw_ibge", IBGE_PATH, IBGE_TABLES)
    finally:
        con.close()
    print("\nAll raw tables loaded successfully.")


if __name__ == "__main__":
    main()
