-- `always_build` tag — Slim CI requirement:
-- dim_date is a standalone date dimension (no upstream project models), so
-- `state:modified+` never selects it. The fact tables' relationship tests
-- reference it, and Slim CI builds only the selected subgraph in a fresh DB.
-- This tag forces dim_date to always be built, so those tests do not fail on a
-- missing table. Consumed by the Slim CI selector in .github/workflows/ci.yml.
{{
    config(
        tags=['always_build']
    )
}}

WITH source AS (
    {{ dbt_date.get_date_dimension('2016-09-01', '2020-05-01') }}
),
dates AS (
    SELECT
        date_day            AS date_id,
        year_number         AS year,
        quarter_of_year     AS quarter,
        month_of_year       AS month,
        month_name,
        iso_week_of_year        AS week,
        day_of_month,
        day_of_week_iso AS day_of_week,
        day_of_week_name,
        CASE 
            WHEN day_of_week_iso IN (6, 7) THEN TRUE 
            ELSE FALSE 
        END AS is_weekend
    FROM source
),
add_holidays AS (
    SELECT
        date_id,
        year,
        quarter,
        month,
        month_name,
        week,
        day_of_month,
        day_of_week,
        day_of_week_name,
        is_weekend,
        CASE 
            WHEN h.holiday_date IS NOT NULL THEN TRUE
            ELSE FALSE 
        END AS is_holiday_brazil
    FROM dates d
    LEFT JOIN {{ ref('brazil_holidays') }} h
        ON d.date_id = h.holiday_date
)
SELECT *
FROM add_holidays