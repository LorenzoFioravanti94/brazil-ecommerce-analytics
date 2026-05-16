from dagster import define_asset_job, AssetSelection, RunConfig
from dagster_dbt import build_dbt_asset_selection
from .assets import brz_ecommerce_assets, brz_ecommerce_freshness_assets, DbtConfig

# Standard Job — triggered by GitHub Actions after merge on main
# full project incremental build
standard_job = define_asset_job(
    name="standard_job",
    selection=AssetSelection.assets("brz_ecommerce_assets"),
)

# Full Refresh Job — weekly schedule
# rebuilds incremental models from scratch
full_refresh_job = define_asset_job(
    name="full_refresh_job",
    selection=AssetSelection.assets("brz_ecommerce_assets"),
    config=RunConfig(
        ops={
            "brz_ecommerce_assets": DbtConfig(full_refresh=True)  # <project_name>_assets
        }
    )
)

# Time Sensitive Job — hourly schedule
# builds only a specific subset of the DAG
time_sensitive_job = define_asset_job(
    name="time_sensitive_job",
    selection=build_dbt_asset_selection(
        [brz_ecommerce_assets],
        dbt_select="+fct_orders+"    # <model_name>
    ),
)

"""
# Fresher Rebuild Job — triggered by source freshness sensor
# builds only models with fresh sources
fresher_rebuild_job = define_asset_job(
    name="fresher_rebuild_job",
    selection=build_dbt_asset_selection(
        [brz_ecommerce_assets],
        dbt_select="source_status:fresher+"
    )
)
"""

# Source Freshness Job
source_freshness_job = define_asset_job(
    name="source_freshness_job",
    selection=AssetSelection.assets("brz_ecommerce_freshness_assets"),
)