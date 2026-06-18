"""Custom Dagster <-> dbt translator.

dagster-dbt turns every dbt node into a Dagster asset; a translator is the hook
that customizes how that mapping happens. This one adds two things:

1. dbt tests become Dagster *asset checks* (source tests included), so a test's
   pass/fail shows up on its asset in the UI instead of being buried in the
   `dbt build` logs.
2. Assets are grouped by medallion layer, reusing the bronze/silver/gold/
   consumption tag each model already has in dbt_project.yml. Add a model to a
   layer in dbt and it is grouped automatically — no extra tag to maintain.
"""

from dagster_dbt import DagsterDbtTranslator, DagsterDbtTranslatorSettings

# The medallion layers, in upstream -> downstream order. Each model is tagged with
# exactly one (set per folder in dbt_project.yml), so the first match is its layer.
_LAYER_TAGS = ("bronze", "silver", "gold", "consumption")


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
        # Snapshots carry no layer tag either — they capture SCD2 history of a
        # source, so give them their own group rather than the "default" one.
        if dbt_resource_props.get("resource_type") == "snapshot":
            return "snapshots"
        # Anything else (e.g. sources) falls back to dagster-dbt's default.
        return super().get_group_name(dbt_resource_props)


# The single translator instance used by @dbt_assets. Every setting is listed
# explicitly, including those already enabled by default, to document each choice:
#   - enable_asset_checks: turn dbt tests on models into asset checks.
#   - enable_source_tests_as_checks: also show source tests (unique/not_null on
#     raw columns) as checks, since our data-quality story starts at the sources.
#   - enable_code_references: add a link from each asset to its .sql file, so the
#     model is one click away in the Dagster UI.
# dbt model and column descriptions already show up as asset metadata by default.
dbt_translator = WarehouseDbtTranslator(
    settings=DagsterDbtTranslatorSettings(
        enable_asset_checks=True,
        enable_source_tests_as_checks=True,
        enable_code_references=True,
    )
)
