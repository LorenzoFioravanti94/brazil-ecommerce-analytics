-- The HDI source (IBGE) contains multiple reference years (1991, 2000, 2010, 2017),
-- while the Olist orders dataset is concentrated in 2016–2018.
-- In the Gold layer, we therefore retain only the 2017 HDI snapshot to ensure temporal alignment
-- with the orders, effectively reducing dim_hdi to a single row per state (state_id as natural PK).

WITH human_development_index AS (
    SELECT *
    FROM {{ ref('slv_int_ibge__human_development_index') }}
),
intensive_care_unit_beds AS (
    SELECT *
    FROM {{ ref('slv_int_ibge__intensive_care_unit_beds') }}
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
hdi_filter_year AS (
    SELECT
        state_id,           -- dropped the artificial PK
        education_index,
        wealth_index,
        health_index        -- also dropped the year column as it's no longer needed after filtering for 2017
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
