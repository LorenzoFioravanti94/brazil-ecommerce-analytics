from dagster import AssetExecutionContext, Config
from dagster_dbt import DbtCliResource, dbt_assets

from .resources import dbt_project


class DbtConfig(Config):
    full_refresh: bool = False  # default: incremental run


# Manifest path comes from the shared DbtProject, so it always reflects the
# manifest prepare_if_dev() (re)generates at code-location load time.
@dbt_assets(manifest=dbt_project.manifest_path)
def warehouse_assets(context: AssetExecutionContext, dbt: DbtCliResource, config: DbtConfig):
    dbt_args = ["build"]
    if config.full_refresh:
        dbt_args += ["--full-refresh"]
    yield from dbt.cli(dbt_args, context=context).stream()
    yield from dbt.cli(["docs", "generate"], context=context).stream()
