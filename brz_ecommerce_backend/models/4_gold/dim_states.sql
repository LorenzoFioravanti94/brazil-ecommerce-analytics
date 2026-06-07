WITH states_intermediate AS (
    SELECT
        state_id,
        state_name,
        capital,
        region,
        area_km2,
        population,
        cities_number,
        gdp,
        gdp_world_share,
        poverty_index,
        latitude,
        longitude
    FROM {{ ref('slv_int_ibge__states') }}
),
final AS (
    SELECT
        state_id,
        state_name,
        capital,
        region,
        area_km2,
        cities_number,
        latitude,
        longitude
    FROM states_intermediate
)
SELECT *
FROM final