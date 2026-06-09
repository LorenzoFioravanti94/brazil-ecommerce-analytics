WITH human_development_index AS (
    SELECT
        state_id,
        hdi_2017,
        hdi_education_2017,
        hdi_wealth_2017,
        hdi_health_2017,
        hdi_2010,
        hdi_education_2010,
        hdi_wealth_2010,
        hdi_health_2010,
        hdi_2000,
        hdi_education_2000,
        hdi_wealth_2000,
        hdi_health_2000,
        hdi_1991,
        hdi_education_1991,
        hdi_wealth_1991,
        hdi_health_1991
    FROM {{ ref('slv_stg_ibge__human_development_index') }}
),
hdi_2017 AS (
    SELECT
        state_id,
        hdi_2017 AS hdi,
        hdi_education_2017 AS education_index,
        hdi_wealth_2017 AS wealth_index,
        hdi_health_2017 AS health_index,
        2017 AS year
    FROM human_development_index
),
hdi_2010 AS (
    SELECT
        state_id,
        hdi_2010 AS hdi,
        hdi_education_2010 AS education_index,
        hdi_wealth_2010 AS wealth_index,
        hdi_health_2010 AS health_index,
        2010 AS year
    FROM human_development_index
),
hdi_2000 AS (
    SELECT
        state_id,
        hdi_2000 AS hdi,
        hdi_education_2000 AS education_index,
        hdi_wealth_2000 AS wealth_index,
        hdi_health_2000 AS health_index,
        2000 AS year
    FROM human_development_index
),
hdi_1991 AS (
    SELECT
        state_id,
        hdi_1991 AS hdi,
        hdi_education_1991 AS education_index,
        hdi_wealth_1991 AS wealth_index,
        hdi_health_1991 AS health_index,
        1991 AS year
    FROM human_development_index
),
hdi_union AS (
    SELECT *
    FROM hdi_2017

    UNION ALL

    SELECT *
    FROM hdi_2010

    UNION ALL

    SELECT *
    FROM hdi_2000

    UNION ALL

    SELECT *
    FROM hdi_1991
),
remove_redundancy AS (
    SELECT
        state_id,
        education_index,
        wealth_index,
        health_index,
        year,
    FROM hdi_union
),
surrogate_key AS(
        SELECT
            {{ dbt_utils.generate_surrogate_key(['state_id', 'year']) }} AS hdi_id,
            state_id,
            education_index,
            wealth_index,
            health_index,
            year
        FROM remove_redundancy
)
SELECT *
FROM surrogate_key