-- The HDI source (IBGE) contains multiple reference years (1991, 2000, 2010, 2017),
-- while the Olist orders dataset is concentrated in 2016–2018.
-- In the Gold layer, we therefore retain only the 2017 HDI snapshot to ensure temporal alignment
-- with the orders, effectively reducing dim_hdi to a single row per state (state_id as natural PK).

WITH hdi_intermediate AS (
    SELECT *
    FROM {{ ref('slv_int_ibge__human_development_index') }}
),
filter_year AS (
    SELECT                  
        state_id,           -- dropped the artificial PK
        education_index,
        wealth_index,
        health_index        -- also dropped the year column as it's no longer needed after filtering for 2017
    FROM hdi_intermediate
    WHERE year = 2017
)
SELECT *
FROM filter_year