# dbt_project_evaluator — Project Audit

This document records a one-off best-practice audit of the `warehouse` dbt
project, run with the official [`dbt-labs/dbt_project_evaluator`](https://hub.getdbt.com/dbt-labs/dbt_project_evaluator/latest/)
package, and the decisions taken on each finding.

## Why this exists (audit-and-strip)

`dbt_project_evaluator` is an opinionated auditing package: it adds ~30 models
and a set of tests that flag deviations from dbt's recommended conventions. It is
an **audit tool, not a runtime dependency** — leaving it installed would inflate
the committed `manifest.json` used by Slim CI and add noise to the DAG and docs.

The strategy was therefore **audit-and-strip**:

1. Install the package on a dedicated branch and run it **only on target `dev`**.
2. Triage every finding into: *real best-practice gap* (fix), *deliberate design
   choice* (document as an exception), or *derived/noise* (acknowledge).
3. Apply only the real fixes.
4. **Remove the package** once the audit is done.
5. Keep this report as the durable record of what was run and why.

The point of a portfolio audit is not a perfect score — it is demonstrating that
findings were handled with judgement, distinguishing genuine improvements from an
opinionated tool disagreeing with an intentional design.

## How it was run

```bash
# packages.yml (temporary):
#   - package: dbt-labs/dbt_project_evaluator
#     version: 1.3.1
dbt deps
dbt build --select package:dbt_project_evaluator --target dev
```

- Package version: **1.3.1** (requires dbt `>=1.10.6, <3.0.0`; project runs dbt 1.11).
- Run on the `dev` DuckDB only; the committed `persistent_state/manifest.json`
  was never touched.

## Findings summary

The initial run produced **7 findings** (all `warn`). After applying the fixes
below, **5 remain — every one a documented, deliberate design choice.**

| Finding | Initial | Final | Disposition |
|---|---:|---:|---|
| `model_naming_conventions` | 38 | 38 | **Exception** — intentional Medallion naming |
| `source_directories` | 13 | 13 | **Exception** — sources centralized by layer |
| `sources_without_freshness` | 11 | 11 | **Exception** — static dataset, no load-time column |
| `exposure_parents_materializations` | 1 | 0 | **Fixed** — exposure parent materialized as a table |
| `exposures_dependent_on_private_models` | 1 | 0 | **Fixed** — exposed model set to `access: public` |
| `missing_primary_key_tests` | 27 | 14 | **Partially fixed** — staging + consumption tested; bronze + raw-grain staging are exceptions |
| `valid_test_coverage` | 1 | 1 | **Derived** — see note below |

## Fixes applied

### 1. Primary-key tests on the staging layer

Added a tested primary key to every `slv_stg_*` model that has one:

- Single-column PK (`unique` + `not_null`): `orders`, `products`, `sellers`,
  `customers` (`customer_basket_id`), `product_category` (`local_name`), and the
  four IBGE models (`state_id`).
- Composite PK (`dbt_utils.unique_combination_of_columns` + `not_null` on each
  key column): `order_items` (`order_id, item_sequence_number`), `order_payments`
  (`order_id, sequence_number`), `order_reviews` (`review_id, order_id`).

Every key was verified for uniqueness against the real data before adding the test.

### 2. `churn_customer_orders` hardened into a data product

This model is the consumer-facing feature source behind the `customer_churn_model`
exposure. It was hardened so the exposed contract is solid:

- **Exposes `order_id`** (its true grain) and tests it `unique` + `not_null` —
  previously the model emitted no unique key, so the grain was untestable.
- **Materialized as a `table`** (not a view) so the downstream ML consumer reads a
  stable, fast relation.
- **`access: public`** — it is an intentionally exposed contract.
- **Enforced contract** (`contract: {enforced: true}` with `data_type` on every
  column) so column names and types are guaranteed to the consumer.

Together these cleared the two exposure findings, the PK finding for this model,
and the `public_models_without_contract` finding that surfaced once the model was
made public.

## Exceptions (deliberate design, not fixed)

- **`model_naming_conventions` (38).** The project uses a deliberate Medallion +
  dbt naming convention (`brz_`, `slv_stg_`, `slv_int_`, `dim_`, `fct_`). The
  evaluator's defaults expect `stg_`/`int_`/`rpt_` prefixes and classify every
  model as `other`. The naming is intentional and internally consistent.

- **`source_directories` (13).** Sources are declared centrally under
  `models/1_sources/` as part of the layered folder structure. The evaluator
  expects them under `models/staging/<source>/`. This is a deliberate structural
  choice.

- **`sources_without_freshness` (11).** The Olist/IBGE data is a static Kaggle
  dump with no row-level load-time column, so source freshness is semantically
  meaningless here. (See `snapshots/_snapshots.yml` for the related SCD2 note.)

- **`missing_primary_key_tests` — remaining 14.**
  - **Bronze (13 models):** the raw 1:1 ingestion layer is intentionally left
    untested for primary keys; uniqueness is validated from staging onward.
  - **`slv_stg_olist__geolocation` (1):** raw geolocation holds many coordinate
    rows per `zip_code_prefix`, so there is no primary key at this grain. The grain
    is finalized in `slv_int_olist__geolocation` (one row per `zip_code_prefix`),
    where the primary key is tested.

- **`valid_test_coverage` (1, derived).** Coverage sits below the evaluator's
  default 100% target. The untested models are exactly the documented exceptions
  above (bronze + raw-grain geolocation staging), so this finding is a consequence
  of those deliberate choices rather than an independent gap.

## Reproducing the audit

The package was removed after the audit. To re-run it, temporarily add it back to
`packages.yml`:

```yaml
  - package: dbt-labs/dbt_project_evaluator
    version: 1.3.1
```

then `dbt deps` and `dbt build --select package:dbt_project_evaluator --target dev`,
and remove it again once done.
