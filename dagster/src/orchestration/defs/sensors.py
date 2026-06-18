"""Logs an error whenever a Dagster run in this code location fails.

Enabled automatically at code-location load time (default_status=RUNNING),
so no manual toggle in the UI is needed.
"""

from dagster import (
    DefaultSensorStatus,
    RunFailureSensorContext,
    run_failure_sensor,
)


@run_failure_sensor(default_status=DefaultSensorStatus.RUNNING)
def run_failure_sensor_logger(context: RunFailureSensorContext):
    run = context.dagster_run
    context.log.error(
        f"Run failed — job '{run.job_name}' (run_id {run.run_id}): "
        f"{context.failure_event.message}"
    )
