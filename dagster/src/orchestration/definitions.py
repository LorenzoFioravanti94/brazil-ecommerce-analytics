from dagster import Definitions

from .defs.assets import warehouse_assets
from .defs.resources import dbt_resource
from .defs.jobs import (
    standard_job,
    full_refresh_job,
    source_freshness_job,
    # time_sensitive_job,     # deferred — see Phase I
    # fresher_rebuild_job,    # deferred — see Phase I
)
from .defs.schedules import (
    full_refresh_schedule,
    freshness_schedule,
    # time_sensitive_schedule,    # deferred — see Phase I
)
# from .defs.sensors import source_freshness_sensor    # deferred — see Phase I

defs = Definitions(
    assets=[warehouse_assets],
    jobs=[
        standard_job,
        full_refresh_job,
        source_freshness_job,
        # time_sensitive_job,     # deferred — see Phase I
        # fresher_rebuild_job,    # deferred — see Phase I
    ],
    schedules=[
        full_refresh_schedule,
        freshness_schedule,
        # time_sensitive_schedule,    # deferred — see Phase I
    ],
    # sensors=[source_freshness_sensor],    # deferred — see Phase I
    resources={
        "dbt": dbt_resource,
    },
)
