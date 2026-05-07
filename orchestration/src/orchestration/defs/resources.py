from dagster_dbt import DbtCliResource
from pathlib import Path

DBT_PROJECT_DIR = (
    Path(__file__).parent.parent.parent.parent.parent / "brz_ecommerce_backend"
)

DBT_PROFILES_DIR = Path.home() / ".dbt"

dbt_resource = DbtCliResource(
    project_dir=str(DBT_PROJECT_DIR),
    profiles_dir=str(DBT_PROFILES_DIR),
    target="prod"
)