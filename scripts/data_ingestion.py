# scripts/load_raw.py
import duckdb
import os

DB_PATH    = "data/duckdb/prod.duckdb"
OLIST_PATH = os.path.join("data", "raw", "olist")
IBGE_PATH  = os.path.join("data", "raw", "ibge")

con = duckdb.connect(DB_PATH)

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

for table_name, filename in olist_tables.items():
    filepath = os.path.join(OLIST_PATH, filename)
    con.execute(f"""
        CREATE OR REPLACE TABLE raw_olist.{table_name} AS
        SELECT * FROM read_csv_auto('{filepath}')
    """)
    print(f"✔ Loaded: raw_olist.{table_name}")

# --- IBGE tables ---
ibge_tables = {
    "airports": "airports.csv",
    "hdi":      "hdi.csv",
    "icu_beds": "icu-beds.csv",  # we use the UNDERSCORE beacause '-' is not a valid SQL table name
    "states":   "states.csv",
}

for table_name, filename in ibge_tables.items():
    filepath = os.path.join(IBGE_PATH, filename)
    con.execute(f"""
        CREATE OR REPLACE TABLE raw_ibge.{table_name} AS
        SELECT * FROM read_csv_auto('{filepath}')
    """)
    print(f"✔ Loaded: raw_ibge.{table_name}")

con.close()
print("\n✅ All raw tables loaded successfully.")