import os
from pathlib import Path
import duckdb

# ---------------------------------------------------------------------------
# DB path selection — driven by DBT_TARGET env var
# Locally DBT_TARGET is not set → defaults to "dev"
# In CI the workflow sets DBT_TARGET=test
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).parent.parent  # scripts/ → repo root
TARGET = os.environ.get("DBT_TARGET", "dev")

DB_PATHS = {
    "prod": REPO_ROOT / "data/duckdb/prod.duckdb",
    "test": Path("/tmp/test.duckdb"),
    "dev":  Path("/tmp/dev.duckdb"),
}

if TARGET not in DB_PATHS:
    raise ValueError(f"Unknown DBT_TARGET: '{TARGET}'. Must be one of: {list(DB_PATHS)}")

DB_PATH   = DB_PATHS[TARGET]
OLIST_PATH = REPO_ROOT / "data/raw/olist"
IBGE_PATH  = REPO_ROOT / "data/raw/ibge"

print(f"[ingestion] target={TARGET}  db={DB_PATH}")

con = duckdb.connect(str(DB_PATH))
con.execute("CREATE SCHEMA IF NOT EXISTS raw_olist")
con.execute("CREATE SCHEMA IF NOT EXISTS raw_ibge")

# ---------------------------------------------------------------------------
# Olist tables
# ---------------------------------------------------------------------------
olist_tables = {
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

print("\n=== OLIST INGESTION ===")
for table_name, filename in olist_tables.items():
    filepath = OLIST_PATH / filename
    if not filepath.exists():
        raise FileNotFoundError(f"Missing file: {filepath}")
    con.execute(f"""
        CREATE OR REPLACE TABLE raw_olist.{table_name} AS
        SELECT * FROM read_csv_auto('{filepath}')
    """)
    print(f"  ✔ raw_olist.{table_name}")

# ---------------------------------------------------------------------------
# IBGE tables
# ---------------------------------------------------------------------------
ibge_tables = {
    "airports": "airports.csv",
    "hdi":      "hdi.csv",
    "icu_beds": "icu-beds.csv",
    "states":   "states.csv",
}

print("\n=== IBGE INGESTION ===")
for table_name, filename in ibge_tables.items():
    filepath = IBGE_PATH / filename
    if not filepath.exists():
        raise FileNotFoundError(f"Missing file: {filepath}")
    con.execute(f"""
        CREATE OR REPLACE TABLE raw_ibge.{table_name} AS
        SELECT * FROM read_csv_auto('{filepath}')
    """)
    print(f"  ✔ raw_ibge.{table_name}")

con.close()
print("\n✅ All raw tables loaded successfully.")