"""Future work (deferred — see Phase I): source-freshness sensor.

DuckDB has no native data-arrival notification (unlike Snowflake, S3, etc.), so
this sensor would poll the raw source files and trigger a rebuild whenever any
of them changes. Kept commented until the time-sensitive jobs are introduced.
"""
# from dagster import sensor, RunRequest, SensorEvaluationContext
# from pathlib import Path
# import os
# from .jobs import fresher_rebuild_job
#
# SOURCE_DIR = Path("data/raw")
#
# @sensor(job=fresher_rebuild_job, minimum_interval_seconds=86400)  # poll every 24h
# def source_freshness_sensor(context: SensorEvaluationContext):
#     last_mtime = float(context.cursor) if context.cursor else 0.0
#     latest_mtime = max(
#         os.path.getmtime(os.path.join(root, f))
#         for root, _, files in os.walk(SOURCE_DIR)
#         for f in files
#         if f.endswith(".csv")
#     )
#     if latest_mtime > last_mtime:
#         context.update_cursor(str(latest_mtime))
#         yield RunRequest(run_key=str(latest_mtime))
