-- always_build tag: dim_date has no upstream project models, so state:modified+ never selects it in Slim CI.
-- This tag forces it to always be built so FK relationship tests referencing dim_date do not fail.
{{
    config(
        tags=['always_build']
    )
}}

-- Range set to span the full Olist dataset window, with a small buffer on each end.
WITH source AS (
    {{ dbt_date.get_date_dimension('2016-09-01', '2020-05-01') }}
),
brazil_holidays AS (
    SELECT *
    FROM {{ ref('brazil_holidays') }}
),
dates AS (
    SELECT
        date_day            AS date_id,
        year_number         AS year,
        quarter_of_year     AS quarter,
        month_of_year       AS month,
        month_name,
        iso_week_of_year    AS week,
        day_of_month,
        day_of_week_iso     AS day_of_week,
        day_of_week_name,
        CASE
            WHEN day_of_week_iso IN (6, 7) THEN TRUE
            ELSE FALSE
        END AS is_weekend
    FROM source
),
-- Add a boolean column flagging whether each date is a public holiday in Brazil.
final AS (
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
    LEFT JOIN brazil_holidays h
        ON d.date_id = h.holiday_date
)
SELECT *
FROM final
