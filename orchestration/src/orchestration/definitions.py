from dagster import Definitions

from .defs.assets import brz_ecommerce_assets
from .defs.jobs import (
    standard_job,
    full_refresh_job,
    time_sensitive_job,
    fresher_rebuild_job,
)
from .defs.schedules import (
    full_refresh_schedule,
    time_sensitive_schedule,
)
from .defs.sensors import source_freshness_sensor
from .defs.resources import dbt_resource

defs = Definitions(
    assets=[brz_ecommerce_assets],
    jobs=[
        standard_job,
        full_refresh_job,
        time_sensitive_job,
        fresher_rebuild_job,
    ],
    schedules=[
        full_refresh_schedule,
        time_sensitive_schedule,
    ],
    sensors=[source_freshness_sensor],
    resources={
        "dbt": dbt_resource,
    },
)