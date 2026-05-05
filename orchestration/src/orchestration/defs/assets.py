from dagster import AssetExecutionContext, Config
from dagster_dbt import DbtCliResource, dbt_assets
from pathlib import Path

DBT_PROJECT_DIR = (
    Path(__file__).parent.parent.parent.parent.parent / "brz_ecommerce_backend"  # <project_name>
)

class DbtConfig(Config):
    full_refresh: bool = False    # default: incremental run

@dbt_assets(manifest=DBT_PROJECT_DIR / "target" / "manifest.json")
def brz_ecommerce_assets(context: AssetExecutionContext, dbt: DbtCliResource, config: DbtConfig):  # <project_name>_assets
    dbt_args = ["build"]
    if config.full_refresh:
        dbt_args += ["--full-refresh"]
    yield from dbt.cli(dbt_args, context=context).stream()
    yield from dbt.cli(["docs", "generate"], context=context).stream()