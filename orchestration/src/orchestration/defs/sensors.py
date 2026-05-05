# orchestration/src/orchestration/defs/sensors.py
from dagster import sensor, RunRequest, SensorEvaluationContext
from pathlib import Path
import os
from .jobs import fresher_rebuild_job

# NOTE: unlike cloud databases (Snowflake, S3, etc.), DuckDB has no native
# notification system for incoming data. The sensor below polls the source
# CSV files periodically and triggers a fresher rebuild when it detects
# that any file has been modified.

SOURCE_DIR = Path("data/raw")  # <source_data_path>

@sensor(job=fresher_rebuild_job, minimum_interval_seconds=86400)  # polls every 24 hours
def source_freshness_sensor(context: SensorEvaluationContext):
    last_mtime = float(context.cursor) if context.cursor else 0.0

    latest_mtime = max(
        os.path.getmtime(os.path.join(root, f))
        for root, _, files in os.walk(SOURCE_DIR)
        for f in files
        if f.endswith(".csv")
    )

    if latest_mtime > last_mtime:
        context.update_cursor(str(latest_mtime))
        yield RunRequest(run_key=str(latest_mtime))