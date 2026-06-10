"""Custom Dagster <-> dbt translator.

Centralizes two Phase I enrichments that both hang off the dbt metadata:

1. Data quality as first-class Dagster objects — dbt tests are surfaced as
   Dagster *asset checks* (and source tests too), so test pass/fail shows up
   on each asset in the UI instead of being buried in `dbt build` logs.
2. Medallion layers as Dagster *asset groups* — every model already carries a
   `bronze`/`silver`/`gold` tag (set once per layer in dbt_project.yml), so we
   reuse that single source of truth to group the asset graph by layer. No new
   tag to maintain: add a model to a layer in dbt and it groups automatically.
"""

from dagster_dbt import DagsterDbtTranslator, DagsterDbtTranslatorSettings

# Layer tags defined in warehouse/dbt_project.yml (`+tags: ["bronze"|...]`).
# Ordered most-upstream -> most-downstream; the first match wins, which is the
# correct layer because a model lives in exactly one layer.
_LAYER_TAGS = ("bronze", "silver", "gold")


class WarehouseDbtTranslator(DagsterDbtTranslator):
    """Groups assets by medallion layer, reusing the existing dbt layer tags."""

    def get_group_name(self, dbt_resource_props):
        # dbt_resource_props is the manifest node dict; `tags` aggregates the
        # folder-level `+tags` from dbt_project.yml plus any model-level tags.
        tags = dbt_resource_props.get("tags", [])
        for layer in _LAYER_TAGS:
            if layer in tags:
                return layer
        # Seeds carry no layer tag but are reference/lookup data — give them
        # their own group so nothing lands in the catch-all "default" group.
        if dbt_resource_props.get("resource_type") == "seed":
            return "seeds"
        # Anything else (e.g. sources) falls back to dagster-dbt's default.
        return super().get_group_name(dbt_resource_props)


# Single shared translator instance used by @dbt_assets.
# Settings are spelled out explicitly (several already default to True) so the
# data-quality intent is visible in code rather than relying on silent defaults:
#   - enable_asset_checks: model dbt tests -> asset checks (default True).
#   - enable_source_tests_as_checks: also surface the source-level tests
#     (unique/not_null on raw columns) as checks — our freshness/quality story
#     starts at the sources, so we want them visible too (default False).
#   - enable_code_references: attach a link from each asset back to its .sql
#     file, so the dbt model is one click away in the Dagster UI (default False).
# Model/column descriptions from dbt are surfaced as asset metadata by default,
# so no extra wiring is needed for that part of the "metadata" enrichment.
dbt_translator = WarehouseDbtTranslator(
    settings=DagsterDbtTranslatorSettings(
        enable_asset_checks=True,
        enable_source_tests_as_checks=True,
        enable_code_references=True,
    )
)
