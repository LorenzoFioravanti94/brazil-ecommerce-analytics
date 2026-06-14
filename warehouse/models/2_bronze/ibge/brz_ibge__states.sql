WITH source AS (
    SELECT *
    FROM {{ source('ibge', 'states') }}
),
final AS (
    SELECT
        UF,
        State,
        Capital,
        Region,
        Area,
        Population,
        "Demographic Density",
        "Cities count",
        GDP,
        "GDP rate",
        Poverty,
        Latitude,
        Longitude
    FROM source
)
SELECT *
FROM final
