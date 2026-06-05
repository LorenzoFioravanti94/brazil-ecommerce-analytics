{{ config(materialized='ephemeral') }}

WITH airports AS (
    SELECT
        UF,
        "Passengers rate"
    FROM {{ ref('brz_ibge__airports') }}
)
SELECT
    upper(trim(UF)) AS state_id,
    "Passengers rate" AS passengers_rate
FROM airports