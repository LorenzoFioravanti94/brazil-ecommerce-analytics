# dagster

Dagster orchestration for the `warehouse` dbt project. Every dbt model, test, seed, and snapshot becomes a Dagster asset. Dagster powers the **CD** side of the pipeline only — after each merge to `main`, GitHub Actions triggers the `standard_job`. CI is handled entirely by GitHub Actions; see [`../.github/CICD.md`](../.github/CICD.md).

---

## What Is Orchestrated

The `@dbt_assets` decorator in `src/orchestration/defs/assets.py` generates one Dagster asset per dbt node by reading the compiled `manifest.json`. The manifest is (re)generated at code-location load time via `prepare_if_dev()`, so the asset graph in the UI always reflects the current warehouse state.

Materializing the warehouse assets runs `dbt build` followed by `dbt docs generate`, so the dbt documentation site is refreshed after every run. Dagster always runs against the `prod` target, so the published docs reflect production state.

### Asset checks

dbt tests become Dagster **asset checks** rather than blocking build steps. Pass/fail is surfaced per asset in the UI instead of being buried in `dbt build` logs. This applies to both model tests and source tests (unique, not null, relationships).

### Asset groups

Assets are grouped by medallion layer, reusing the dbt `+tags` already defined in `dbt_project.yml`:

| Group | Members |
|---|---|
| `bronze` | All `brz_*` models |
| `silver` | All `slv_stg_*` and `slv_int_*` models |
| `gold` | All `dim_*` and `fct_*` models |
| `consumption` | `churn_customer_orders` |
| `seeds` | All seed assets |
| `snapshots` | `orders_snapshot` |

A model added to a layer in `dbt_project.yml` is grouped automatically — no extra Dagster config is needed.

---

## Jobs

| Job | Trigger | Behaviour |
|---|---|---|
| `standard_job` | GitHub Actions (post-merge on `main`) | Full `dbt build` of all warehouse assets |
| `full_refresh_job` | Sunday 06:00 UTC (scheduled) + manual | Rebuilds only incremental models with `--full-refresh` |
| `source_freshness_job` | Sunday 04:00 UTC (scheduled) + manual | Runs `dbt source freshness` — non-blocking (failures are logged as warnings, not errors) |

The automatic trigger of `standard_job` after each merge to `main` is the foundation of the project's continuous delivery: a single merge rebuilds production end to end, with no manual step.

### CD trigger (GitHub Actions → Dagster)

After a merge to `main`, GitHub Actions reloads this code location and launches `standard_job` over GraphQL. The instance is reached through the URL set in the `DAGSTER_URL` secret.

The full CI/CD subsystem — the `persistent_state/manifest.json` loop and how this trigger fits in — is documented in [`../.github/CICD.md`](../.github/CICD.md).

---

## Sensors

**`run_failure_sensor_logger`** — enabled by default (`default_status=RUNNING`). Fires on any run failure in this code location and writes a structured error log with the job name, run ID, and failure message. No manual toggle in the UI is needed.

---

## Getting Started

### Prerequisites

- Python 3.10+
- An empty `dagster.yaml` in `DAGSTER_HOME` (default `~/.dagster`). Create it once:

```bash
mkdir -p "$HOME/.dagster" && touch "$HOME/.dagster/dagster.yaml"
```

Do not keep a `dagster.yaml` inside this `dagster/` project folder — Dagster will warn that the local file is ignored when `DAGSTER_HOME` points elsewhere.

### Installing dependencies

This project shares the repository's virtual environment (`myvenv`), created in the
[root README](../README.md#quickstart) from `requirements.txt` — which already pins the
Dagster runtime. With that environment active, install the local `orchestration` package
in editable mode so `dg` can load the code location. From the `dagster/` directory:

```bash
source ../myvenv/bin/activate    # the repo's shared venv
pip install -e ".[dev]"          # adds the orchestration package + the `dg` CLI
```

### Running locally

Starting the Dagster UI (`dg dev`) and exposing the webserver to GitHub Actions with ngrok are part of the standard local-development workflow, documented in [Local Development Setup](../CONTRIBUTING.md#local-development-setup) (terminals 2 and 3).

---

## Learn More

- [Dagster Documentation](https://docs.dagster.io/)
- [dagster-dbt integration](https://docs.dagster.io/integrations/libraries/dbt/)
- [Dagster University](https://courses.dagster.io/)
