import warnings

from dagster import BetaWarning, Definitions

# enable_code_references=True in the translator uses two Dagster classes still
# in beta, which emit a BetaWarning at startup. The feature adds a clickable
# link on each asset in the Dagster UI that opens the model's .sql file
# directly. Dagster is version-pinned, so the API cannot change without an
# explicit upgrade — so, silencing the warnings is safe.
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
