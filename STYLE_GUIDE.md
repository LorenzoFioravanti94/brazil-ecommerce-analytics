# Style Guide

This guide defines the conventions used across all SQL models, YAML files, and comments in this repository. Consistent conventions make the codebase predictable and easy to navigate regardless of who is reading it.

---

## SQL

### Keywords

All SQL keywords are uppercase.

```sql
SELECT
    order_id,
    TRIM(customer_id)         AS customer_basket_id,
    CAST(created_at AS DATE)  AS purchase_date
FROM orders
WHERE status IS NOT NULL
```

### Indentation and alignment

- 4-space indentation throughout
- One column per line
- `AS` aliases are right-aligned with spaces to form a visual column

### Joins

Join keyword and `ON` condition are on separate lines; the condition is indented 4 spaces under `ON`:

```sql
INNER JOIN customers c
    ON o.customer_basket_id = c.customer_basket_id
```

---

## dbt Model Structure

Every model follows a three-section CTE pattern in this order:

1. **Import CTEs** — expose upstream models with no transformation
2. **Logical CTEs** — one transformation step per CTE
3. **`final` CTE + `SELECT * FROM final`** — determines the model's output columns

```sql
WITH orders AS (
    SELECT * FROM {{ ref('brz_olist__orders') }}
),
orders_cleaned AS (
    SELECT
        TRIM(order_id)                               AS order_id,
        CAST(order_purchase_timestamp AS TIMESTAMP)  AS purchase_timestamp
    FROM orders
),
final AS (
    SELECT
        order_id,
        UPPER(purchase_timestamp::VARCHAR)  AS purchase_timestamp
    FROM orders_cleaned
)
SELECT *
FROM final
```

**Rules:**
- Import CTEs contain only a `SELECT *` (or a column list for pruning) — no logic
- Each logical CTE does exactly one thing
- `final` is always the last named CTE
- The model ends with `SELECT * FROM final` — no column selection in the outer query

---

## CTE Naming

CTEs are named for what the data **is** at that stage, not what you are doing to it.

| Prefer (state-based) | Avoid (procedural) |
|---|---|
| `orders` | `get_orders` |
| `orders_cleaned` | `apply_cleaning` |
| `customers_with_ids` | `join_customer_ids` |
| `final` | `result` / `output` |

---

## File Naming Conventions

### dbt models

Model filenames follow the pattern `{layer_prefix}[_{sublayer_prefix}]_{source}__{entity}.sql`. The sublayer prefix is optional and exists only in the Silver layer. The double underscore separates the data source from the entity name (dbt convention).

| Layer | Prefix | Sublayer prefix | Example |
|---|---|---|---|
| Bronze | `brz_` | — | `brz_olist__orders.sql` |
| Silver — Staging | `slv_` | `stg_` | `slv_stg_olist__orders.sql` |
| Silver — Intermediate | `slv_` | `int_` | `slv_int_olist__orders.sql` |
| Gold — Dimension | `dim_` | — | `dim_customers.sql` |
| Gold — Fact | `fct_` | — | `fct_order_items.sql` |
| Consumption | *(no prefix)* | — | `churn_customer_orders.sql` |

Models are also organized in layer-named subdirectories that mirror the prefix structure (e.g. `models/2_bronze/`, `models/3_silver/1_staging/`).

### Seeds and snapshots

Seeds and snapshots are named for what they represent, with no layer prefix. Examples: `brazil_holidays.csv`, `orders_snapshot`.

### Tests

| Type | Prefix | Location | Example |
|---|---|---|---|
| Custom generic test | `test_` | `tests/generic/` | `test_ratio_consistency.sql` |
| Singular test — consistency | `assert_` | `tests/consistency/` | `assert_gld_payment_breakdown_matches_total.sql` |
| Singular test — business rule | `assert_` | `tests/business_rules/` | `assert_gld_delivery_date_after_purchase.sql` |

Singular tests are grouped into subdirectories by logical category, not by layer.

---

## YAML Conventions

Add a blank line immediately after every top-level key (`models:`, `seeds:`, `snapshots:`, `exposures:`):

```yaml
models:

  - name: dim_date
    description: Date dimension with calendar attributes and Brazilian holiday flags.
    columns:
      - name: date_id
        description: Calendar date in YYYY-MM-DD format.
        data_tests:
          - not_null
          - unique
```

Column descriptions are factual and concise. They answer *what this column contains*, not how it was derived.

---

## Python

### File structure

Every Python file follows this order: module docstring or opening comment → imports → module-level constants → classes and helper functions → `main()` → `if __name__ == "__main__": main()` guard.

### Dict literal alignment

When a dict has keys of uneven length, values are right-aligned with spaces to form a visual column:

```python
OLIST_TABLES = {
    "orders":               "olist_orders_dataset.csv",
    "order_items":          "olist_order_items_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}
```

### Docstrings

One line describing what the function does. If a non-obvious constraint or return value needs explaining, add a second paragraph separated by a blank line. No `Args:` / `Returns:` sections — types are already in the annotations.

```python
def graphql(query: str, variables: dict | None = None) -> dict:
    """POST a GraphQL document and return its `data` payload, or exit on error."""
    ...

def discover_target() -> tuple[str, str]:
    """Find the code-location and repository names that own JOB.

    Returns (location_name, repository_name) so the caller never has to hardcode
    names that shift with the Dagster project layout.
    """
    ...
```

### Error handling

Fatal errors in scripts use `sys.exit(f"...")` — no exception propagation. Input validation at the top of a script uses `raise ValueError(...)`. Cleanup is guaranteed with `try/finally`.

Non-blocking errors in Dagster assets and ops are caught and logged with `context.log.warning(...)` — they must not raise and fail the run.

### Logging

Scripts use `print()`. Dagster assets and ops use `context.log` — never `print()` inside a Dagster execution context.

### Comments

Same rule as SQL: explain WHY, never WHAT. See the [Comments](#comments) section below.

---

## Comments

**Write a comment only to explain WHY — never to restate WHAT the code does.**

Named identifiers (CTEs, columns, models) already describe what the code does. A comment that restates visible code adds noise without adding meaning.

```sql
-- Good: captures a constraint that cannot be inferred from the code
-- strategy: check (not timestamp) — no single reliable updated_at column in the source

-- Bad: describes what the code already says
-- Filter for new records
WHERE shipping_date_id >= (SELECT MAX(shipping_date_id) FROM {{ this }})
```

**Placement:**
- Comments go **above** the code they explain — never trailing on the same line
- Single-line `--` comments only; no block comment syntax

**Avoid:**
- Historical narration ("Previously this used view X…")
- References to tickets, PR numbers, or task names (they rot as the codebase evolves)
- Comments that describe the purpose of the current task ("Added for issue #123")
