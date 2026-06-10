from dagster import Definitions

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
