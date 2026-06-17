{#
    Override dbt's default schema-name generation.

    dbt DEFAULT: concatenates <target.schema>_<custom_schema>  ->  e.g. "main_bronze".
    The "main" prefix (DuckDB's default schema) is noise: it carries no meaning.

    The default prefix exists as a SAFETY mechanism for multi-developer setups that
    share the SAME database (so dev_bronze and prod_bronze do not collide).
    It is not needed here: environment isolation happens at the DuckDB FILE level
    (dev -> /tmp/dev.duckdb, prod -> prod.duckdb), so the prefix is redundant and
    the override is safe.

    BEHAVIOR:
      - if the model/seed defines a custom +schema  -> use THAT one as-is
        (bronze, silver_staging, silver_intermediate, gold, seeds)
      - if it does not                              -> use target.schema (fallback)
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
