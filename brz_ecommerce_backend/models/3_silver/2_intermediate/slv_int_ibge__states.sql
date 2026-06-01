WITH states AS (
    SELECT
        state_id,
        state_name,
        capital,
        region,
        area_km2,
        population,
        demographic_density_per_km2,
        cities_number,
        gdp,
        gdp_world_share,
        poverty_index,
        latitude,
        longitude
    FROM {{ ref('slv_stg_ibge__states') }}
),
remove_redundancy AS (
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
    FROM states
)
SELECT *
FROM remove_redundancy