from dagster import op, OpExecutionContext
from dagster_dbt import DbtCliResource


@op
def check_source_freshness(context: OpExecutionContext, dbt: DbtCliResource):
    """Run dbt source freshness and log the result without blocking.

    Non-blocking by design: a stale source must not fail the pipeline, so any
    error raised by the dbt CLI is caught and logged as a warning.
    """
    try:
        result = dbt.cli(["source", "freshness"], context=context)
        for event in result.stream():
            yield event
    except Exception as e:
        context.log.warning(f"Source freshness check failed (non-blocking): {e}")
