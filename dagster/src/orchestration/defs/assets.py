from dagster import AssetExecutionContext, Config
from dagster_dbt import DbtCliResource, dbt_assets

from .resources import dbt_project
from .translator import dbt_translator


class DbtConfig(Config):
    full_refresh: bool = False  # default: incremental run


# Manifest path comes from the shared DbtProject, so it always reflects the
# manifest prepare_if_dev() (re)generates at code-location load time.
# `project=dbt_project` is also passed (not just the manifest path) because the
# translator's enable_code_references needs the project dir to resolve each
# asset back to its .sql file.
# The custom translator turns dbt tests into asset checks and groups the assets
# by medallion layer — see defs/translator.py for the rationale.
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
