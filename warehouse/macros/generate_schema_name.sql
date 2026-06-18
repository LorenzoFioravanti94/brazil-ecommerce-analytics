{#
    Override dbt's default schema-name generation to use custom_schema as-is (no target prefix).
    Safe because environment isolation happens at the DuckDB file level, not at the schema level.
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
