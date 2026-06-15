WITH source AS (
    SELECT *
    FROM {{ source('ibge', 'airports') }}
),
final AS (
    SELECT
        UF,
        "Passengers rate"
    FROM source
)
SELECT *
FROM final
