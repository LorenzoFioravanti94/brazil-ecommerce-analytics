from dagster import define_asset_job, AssetSelection, RunConfig, job
from .assets import warehouse_assets, DbtConfig
from .ops import check_source_freshness
from .resources import dbt_resource

# build_dbt_asset_selection is only used by the deferred jobs below.
# from dagster_dbt import build_dbt_asset_selection

# Standard Job — triggered by GitHub Actions after merge on main.
# Full project incremental build.
standard_job = define_asset_job(
    name="standard_job",
    selection=AssetSelection.all(),
)

# Full Refresh Job — weekly schedule.
# Rebuilds incremental models from scratch.
full_refresh_job = define_asset_job(
    name="full_refresh_job",
    selection=AssetSelection.all(),
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


# ── Future work (deferred — see Phase I) ────────────────────────────────────
# Time Sensitive Job — hourly; builds only a subset of the DAG.
# time_sensitive_job = define_asset_job(
#     name="time_sensitive_job",
#     selection=build_dbt_asset_selection(
#         [warehouse_assets],
#         dbt_select="state:new+",
#     ),
# )
#
# Fresher Rebuild Job — triggered by the source freshness sensor; builds only
# models whose sources became fresher.
# fresher_rebuild_job = define_asset_job(
#     name="fresher_rebuild_job",
#     selection=build_dbt_asset_selection(
#         [warehouse_assets],
#         dbt_select="source_status:fresher+",
#     ),
# )
