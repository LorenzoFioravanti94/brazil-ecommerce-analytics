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
),
-- 1. Standardizzazione del testo coerente con il Seed 1
states_capital_state_name_no_accents AS (
    SELECT
        state_id,
        REGEXP_REPLACE(STRIP_ACCENTS(state_name), '[^A-Z0-9 ]', '', 'g') AS state_name,
        REGEXP_REPLACE(STRIP_ACCENTS(capital), '[^A-Z0-9 ]', '', 'g') AS capital, -- no need to apply seeds beacuse they are capitals
        region,
        area_km2,
        population,
        cities_number,
        gdp,
        gdp_world_share,
        poverty_index,
        latitude,
        longitude
    FROM remove_redundancy
)
SELECT *
FROM states_capital_state_name_no_accents