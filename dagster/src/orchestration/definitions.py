import warnings

from dagster import BetaWarning, Definitions

# dagster-dbt builds `LocalFileCodeReference` / `CodeReferencesMetadataValue`
# (both beta in dagster-dbt 0.29.2) when `enable_code_references=True` on our
# translator. We deliberately use that feature (one-click asset -> .sql in the
# UI) and dagster is version-pinned, so the beta API will not shift underneath
# us. Silence just those two beta notices instead of dropping the feature.
warnings.filterwarnings(
    "ignore",
    category=BetaWarning,
    message=r"Class `(LocalFileCodeReference|CodeReferencesMetadataValue)`",
)

from .defs.assets import warehouse_assets
from .defs.resources import dbt_resource
from .defs.jobs import (
    standard_job,
    full_refresh_job,
    source_freshness_job,
)
from .defs.schedules import (
    full_refresh_schedule,
    freshness_schedule,
)
from .defs.sensors import run_failure_sensor_logger

defs = Definitions(
    assets=[warehouse_assets],
    jobs=[
        standard_job,
        full_refresh_job,
        source_freshness_job,
    ],
    schedules=[
        full_refresh_schedule,
        freshness_schedule,
    ],
    sensors=[run_failure_sensor_logger],
    resources={
        "dbt": dbt_resource,
    },
)
