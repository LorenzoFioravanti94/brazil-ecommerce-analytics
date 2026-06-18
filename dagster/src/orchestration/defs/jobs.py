from dagster import define_asset_job, RunConfig, job
from dagster_dbt import build_dbt_asset_selection

from .assets import warehouse_assets, DbtConfig
from .ops import check_source_freshness
from .resources import dbt_resource

# Standard Job — triggered by GitHub Actions after merge on main.
# Full project build. We use build_dbt_asset_selection (not AssetSelection.all())
# because only the former includes the dbt source tests surfaced as asset checks.
standard_job = define_asset_job(
    name="standard_job",
    selection=build_dbt_asset_selection([warehouse_assets]),
)

# Rebuilds only the incremental models from scratch. To target just those models
# we use dbt's `config.materialized:incremental` selector.
full_refresh_job = define_asset_job(
    name="full_refresh_job",
    selection=build_dbt_asset_selection(
        [warehouse_assets],
        dbt_select="config.materialized:incremental",
    ),
    config=RunConfig(
        ops={
            "warehouse_assets": DbtConfig(full_refresh=True)
        }
    )
)


# Source Freshness Job — runs the non-blocking freshness check op.
@job(resource_defs={"dbt": dbt_resource})
def source_freshness_job():
    check_source_freshness()
