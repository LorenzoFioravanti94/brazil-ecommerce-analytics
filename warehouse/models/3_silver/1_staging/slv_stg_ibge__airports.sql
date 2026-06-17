WITH airports AS (
    SELECT
        UF,
        "Passengers rate"
    FROM {{ ref('brz_ibge__airports') }}
),
final AS (
    SELECT
        UPPER(TRIM(UF)) AS state_id,
        "Passengers rate" AS passengers_rate
    FROM airports
)
SELECT *
FROM final
