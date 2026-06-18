from dagster import ScheduleDefinition
from .jobs import full_refresh_job, source_freshness_job

# Every Sunday at 4:00 AM
freshness_schedule = ScheduleDefinition(
    job=source_freshness_job,
    cron_schedule="0 4 * * 0",
)

# Every Sunday at 6:00 AM
full_refresh_schedule = ScheduleDefinition(
    job=full_refresh_job,
    cron_schedule="0 6 * * 0",
)
