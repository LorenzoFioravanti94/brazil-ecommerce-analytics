from dagster import op, OpExecutionContext
from dagster_dbt import DbtCliResource

@op
def check_source_freshness(context: OpExecutionContext, dbt: DbtCliResource):
    """
    Non-blocking: lancia dbt source freshness e logga il risultato.
    Non fa fallire la pipeline anche se le sorgenti risultano stale.
    """
    try:
        result = dbt.cli(["source", "freshness"], context=context)
        for event in result.stream():
            yield event
    except Exception as e:
        context.log.warning(f"Source freshness check failed (non-blocking): {e}")