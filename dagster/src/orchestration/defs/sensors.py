"""Run-failure sensor — lightweight observability.

A previous design polled the raw CSV files' mtimes to trigger rebuilds. That
was dropped in Phase I: the sources here are a static Kaggle/IBGE dump, so a
data-arrival sensor would only ever be theatre. What *is* always useful, even
on static data, is being told when a run fails.

This sensor is deliberately minimal: it logs failures rather than paging an
external service, so it adds real observability without pulling Slack/email
infrastructure into a portfolio project. Swapping the log for a notification
is a one-line change if this ever runs against live data.
"""

from dagster import (
    DefaultSensorStatus,
    RunFailureSensorContext,
    run_failure_sensor,
)


# monitor_all_code_locations defaults to this location's runs; default_status
# RUNNING means the sensor is live as soon as the code location loads, with no
# manual toggle in the UI.
@run_failure_sensor(default_status=DefaultSensorStatus.RUNNING)
def run_failure_sensor_logger(context: RunFailureSensorContext):
    run = context.dagster_run
    context.log.error(
        f"Run failed — job '{run.job_name}' (run_id {run.run_id}): "
        f"{context.failure_event.message}"
    )
