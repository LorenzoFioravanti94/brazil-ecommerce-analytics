from dagster import ScheduleDefinition
from .jobs import full_refresh_job, time_sensitive_job

# standard_job has no schedule — it is triggered by GitHub Actions via cd.yml

# Every Sunday at 6:00 PM
full_refresh_schedule = ScheduleDefinition(
    job=full_refresh_job,
    cron_schedule="0 6 * * 0",
)

# Every hour
time_sensitive_schedule = ScheduleDefinition(
    job=time_sensitive_job,
    cron_schedule="0 * * * *",
)