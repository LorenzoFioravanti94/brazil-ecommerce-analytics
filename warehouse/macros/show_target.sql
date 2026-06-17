{#
    Developer utility -- do NOT use in models / ref.

    Prints the attributes of the active target (the current connection) to the
    console. This is a standalone macro: it produces no relation and returns
    nothing; it only lets the developer inspect the target.

    Usage:  dbt run-operation show_target
#}

{% macro show_target() %}

    {% do log("", info=true) %}
    {% do log("Active dbt target -----------------------------", info=true) %}
    {% do log("  name     : " ~ target.name,     info=true) %}
    {% do log("  database : " ~ target.database,  info=true) %}
    {% do log("  schema   : " ~ target.schema,    info=true) %}
    {% do log("  type     : " ~ target.type,      info=true) %}
    {% do log("  threads  : " ~ target.threads,   info=true) %}
    {% do log("-----------------------------------------------", info=true) %}

{% endmacro %}
