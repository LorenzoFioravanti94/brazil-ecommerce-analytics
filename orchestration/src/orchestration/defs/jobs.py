from dagster import define_asset_job, AssetSelection, RunConfig
from dagster_dbt import build_dbt_asset_selection
from .assets import brz_ecommerce_assets, DbtConfig

# Standard Job — triggered by GitHub Actions after merge on main
# full project incremental build
standard_job = define_asset_job(
    name="standard_job",
    selection=AssetSelection.all(),
)

# Full Refresh Job — weekly schedule
# rebuilds incremental models from scratch
full_refresh_job = define_asset_job(
    name="full_refresh_job",
    selection=AssetSelection.all(),
    config=RunConfig(
        ops={
            "brz_ecommerce_assets": DbtConfig(full_refresh=True)  # <project_name>_assets
        }
    )
)

# Time Sensitive Job — hourly schedule
# builds only a specific subset of the DAG
# timeout: 3550 seconds (just under one hour) — prevents overlap with the next run
time_sensitive_job = define_asset_job(
    name="time_sensitive_job",
    selection=build_dbt_asset_selection(
        [brz_ecommerce_assets],
        dbt_select="+fct_orders+"    # <model_name>
        # +fct_<model_name>+ selects all upstream models (to ensure inputs are fresh)
        # and all downstream models (to propagate the update)
    ),
    config={
        "execution": {
            "config": {
                "timeout_seconds": 3550
            }
        }
    }
)

# Fresher Rebuild Job — triggered by source freshness sensor
# builds only models with fresh sources
fresher_rebuild_job = define_asset_job(
    name="fresher_rebuild_job",
    selection=build_dbt_asset_selection(
        [brz_ecommerce_assets],
        dbt_select="source_status:fresher+"
    )
)