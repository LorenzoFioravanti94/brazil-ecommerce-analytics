-- Outrigger dimension: joins to dim_states, not directly to a fact table.
-- Socioeconomic data exists at the state level; the navigation path from facts is
-- fct_orders → dim_customers → dim_states → dim_socio_economics.
-- Combines HDI indicators, ICU bed counts, airport throughput, and non-geographic state attributes
-- (population, GDP, gdp_world_share) into a single socioeconomic dimension; one row per state.
WITH human_development_index AS (
    SELECT *
    FROM {{ ref('slv_int_ibge__hdi') }}
),
intensive_care_unit_beds AS (
    SELECT *
    FROM {{ ref('slv_int_ibge__icu_beds') }}
),
states AS (
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
airports AS (
    SELECT
        state_id,
        passengers_rate
    FROM {{ ref('slv_stg_ibge__airports') }}
),
-- The HDI source spans multiple reference years; only 2017 is kept to align with the Olist order period (2016–2018).
hdi_filter_year AS (
    SELECT
        -- Dropped the artificial PK from the intermediate layer
        state_id,
        education_index,
        wealth_index,
        health_index
        -- Year column dropped: not needed after filtering for 2017
    FROM human_development_index
    WHERE year = 2017
),
final AS (
    SELECT
        s.state_id,
        s.population,
        s.gdp,
        s.gdp_world_share,
        h.education_index,
        h.wealth_index,
        h.health_index,
        s.poverty_index,
        a.passengers_rate AS airports_passengers_rate,
        i.public_beds AS public_icu_beds,
        i.private_beds AS private_icu_beds
    FROM states s
    LEFT JOIN hdi_filter_year h ON s.state_id = h.state_id
    LEFT JOIN intensive_care_unit_beds i ON s.state_id = i.state_id
    LEFT JOIN airports a ON s.state_id = a.state_id
)
SELECT *
FROM final
