{#
    Override del comportamento di default di dbt per la generazione dei nomi di schema.

    DEFAULT dbt: concatena <target.schema>_<custom_schema>  ->  es. "main_bronze".
    Il prefisso "main" (schema di default di DuckDB) e' rumore: non porta significato.

    Il prefisso di default esiste come SAFETY per ambienti multi-developer che
    condividono lo STESSO database (cosi' dev_bronze e prod_bronze non collidono).
    Qui non serve: l'isolamento tra ambienti e' a livello di FILE DuckDB
    (dev -> /tmp/dev.duckdb, prod -> prod.duckdb), quindi il prefisso e' ridondante
    e l'override e' sicuro.

    COMPORTAMENTO:
      - se il modello/seed definisce un +schema custom  -> usa QUELLO, cosi' com'e'
        (bronze, silver_staging, silver_intermediate, gold, seeds)
      - se non lo definisce                              -> usa target.schema (fallback)
#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
