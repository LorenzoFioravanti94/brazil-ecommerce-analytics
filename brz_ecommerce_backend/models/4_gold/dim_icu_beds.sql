WITH icu_beds_intermediate AS (
    SELECT *
    FROM {{ ref('slv_int_ibge__intensive_care_unit_beds') }}
)
SELECT *
FROM icu_beds_intermediate