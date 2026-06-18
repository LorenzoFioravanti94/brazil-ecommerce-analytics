WITH states AS (
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
-- Retain only geographic fields; socioeconomic indicators (population, GDP, gdp_world_share) live in dim_socio_economics.
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
    FROM states
)
SELECT *
FROM final
