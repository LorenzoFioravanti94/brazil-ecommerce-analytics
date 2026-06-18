from dagster import AssetExecutionContext, Config
from dagster_dbt import DbtCliResource, dbt_assets

from .resources import dbt_project
from .translator import dbt_translator


class DbtConfig(Config):
    # When True, the dbt build runs with --full-refresh, rebuilding incremental models from scratch.
    full_refresh: bool = False


# @dbt_assets generates one Dagster asset per dbt model in the manifest. The three
# arguments set where that manifest comes from and how each node maps to an asset:
#   - manifest: taken from the shared DbtProject, so it always reflects the manifest
#     prepare_if_dev() (re)generates at code-location load time.
#   - project: the project directory itself, needed so the translator's code
#     references can link each asset back to its .sql file.
#   - dagster_dbt_translator: our custom translator — turns dbt tests into asset
#     checks and groups assets by medallion layer (see defs/translator.py).
@dbt_assets(
    manifest=dbt_project.manifest_path,
    project=dbt_project,
    dagster_dbt_translator=dbt_translator,
)
def warehouse_assets(context: AssetExecutionContext, dbt: DbtCliResource, config: DbtConfig):
    dbt_args = ["build"]
    if config.full_refresh:
        dbt_args += ["--full-refresh"]
    yield from dbt.cli(dbt_args, context=context).stream()
    yield from dbt.cli(["docs", "generate"], context=context).stream()
