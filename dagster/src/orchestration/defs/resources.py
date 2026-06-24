from pathlib import Path

from dagster_dbt import DbtCliResource, DbtProject

# Repo-root dbt project, resolved relative to this file (cwd-independent).
DBT_PROJECT_DIR = Path(__file__).parents[4] / "warehouse"
# The profiles.yml committed in the project — the same one local dbt and CI use.
DBT_PROFILES_DIR = DBT_PROJECT_DIR

# DbtProject centralizes project + manifest handling. prepare_if_dev() regenerates
# the manifest from disk on every (re)load under `dg dev`, so a renamed model never
# leaves a stale manifest. The post-merge CD reloads this location before standard_job.
dbt_project = DbtProject(
    project_dir=DBT_PROJECT_DIR,
    profiles_dir=DBT_PROFILES_DIR,
    target="prod",
)
dbt_project.prepare_if_dev()

dbt_resource = DbtCliResource(project_dir=dbt_project)
