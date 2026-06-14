WITH source AS (
    SELECT *
    FROM {{ source('ibge', 'icu_beds') }}
),
final AS (
    SELECT
        UF,
        "ICU beds",
        "Public beds",
        "Private beds",
        "Public beds per citizen",
        "Private beds per citizen"
    FROM source
)
SELECT *
FROM final
