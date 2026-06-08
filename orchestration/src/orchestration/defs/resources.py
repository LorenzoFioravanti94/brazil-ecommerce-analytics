from pathlib import Path

from dagster_dbt import DbtCliResource, DbtProject

# Repo-root dbt project, resolved relative to this file so it works regardless
# of the cwd Dagster is launched from.
DBT_PROJECT_DIR = Path(__file__).parents[4] / "brz_ecommerce_backend"
DBT_PROFILES_DIR = Path.home() / ".dbt"

# DbtProject centralizes project + manifest handling. prepare_if_dev()
# regenerates the manifest from the project on disk whenever the code location
# is (re)loaded under `dagster dev`, so a model rename on main no longer leaves
# Dagster with a stale in-memory manifest (KeyError mapping events to assets).
# The post-merge CD reloads this location before running standard_job.
dbt_project = DbtProject(
    project_dir=DBT_PROJECT_DIR,
    profiles_dir=DBT_PROFILES_DIR,
    target="prod",
)
dbt_project.prepare_if_dev()

dbt_resource = DbtCliResource(project_dir=dbt_project)
