# scripts/load_raw.py
import duckdb
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]

DB_PATH    = BASE_DIR / "data/duckdb/prod.duckdb"
OLIST_PATH = BASE_DIR / "data/raw/olist"
IBGE_PATH  = BASE_DIR / "data/raw/ibge"

print("\n=== DEBUG PATHS ===")
print("BASE_DIR:", BASE_DIR)
print("DB_PATH:", DB_PATH)
print("OLIST_PATH:", OLIST_PATH)
print("IBGE_PATH:", IBGE_PATH)

print("\n=== FILE EXISTENCE CHECK (OLIST) ===")
for f in os.listdir(OLIST_PATH):
    print(" -", f)

print("\n=== FILE EXISTENCE CHECK (IBGE) ===")
for f in os.listdir(IBGE_PATH):
    print(" -", f)

con = duckdb.connect(str(DB_PATH))

con.execute("CREATE SCHEMA IF NOT EXISTS raw_olist")
con.execute("CREATE SCHEMA IF NOT EXISTS raw_ibge")

# --- Olist tables ---
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

    print(f"\nTABLE: {table_name}")
    print("FILEPATH:", filepath)
    print("EXISTS:", filepath.exists())

    if not filepath.exists():
        raise FileNotFoundError(f"Missing file: {filepath}")

    sql = f"""
        CREATE OR REPLACE TABLE raw_olist.{table_name} AS
        SELECT * FROM read_csv_auto('{str(filepath)}')
    """

    print("SQL:", sql)

    con.execute(sql)
    print(f"✔ Loaded: raw_olist.{table_name}")

# --- IBGE tables ---
ibge_tables = {
    "airports": "airports.csv",
    "hdi":      "hdi.csv",
    "icu_beds": "icu-beds.csv",
    "states":   "states.csv",
}

print("\n=== IBGE INGESTION ===")

for table_name, filename in ibge_tables.items():
    filepath = IBGE_PATH / filename

    print(f"\nTABLE: {table_name}")
    print("FILEPATH:", filepath)
    print("EXISTS:", filepath.exists())

    if not filepath.exists():
        raise FileNotFoundError(f"Missing file: {filepath}")

    sql = f"""
        CREATE OR REPLACE TABLE raw_ibge.{table_name} AS
        SELECT * FROM read_csv_auto('{str(filepath)}')
    """

    print("SQL:", sql)

    con.execute(sql)
    print(f"✔ Loaded: raw_ibge.{table_name}")

con.close()
print("\n✅ All raw tables loaded successfully.")