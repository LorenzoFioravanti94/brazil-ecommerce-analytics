from dagster import define_asset_job, AssetSelection, RunConfig, job
from dagster_dbt import build_dbt_asset_selection

from .assets import warehouse_assets, DbtConfig
from .ops import check_source_freshness
from .resources import dbt_resource

# Standard Job — triggered by GitHub Actions after merge on main.
# Full project incremental build.
standard_job = define_asset_job(
    name="standard_job",
    selection=AssetSelection.all(),
)

# Full Refresh Job — weekly schedule.
# Rebuilds *only the incremental models* from scratch to clear accumulated
# drift (late-arriving rows, back-filled corrections, changed is_incremental()
# logic). A `--full-refresh` over the whole project would be wasteful: views and
# tables are already rebuilt from scratch on every standard run, so the flag is
# a no-op for them and only changes behaviour for incremental models.
#
# The selection uses dbt's native `config.materialized:incremental` selector
# rather than a tag or a hardcoded model list: dbt already knows which models
# are incremental from their config, so this is self-maintaining — a new
# incremental model is picked up automatically with no tag to forget.
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
