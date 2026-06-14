{{ config(materialized='ephemeral') }}

WITH geolocation AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM {{ ref('brz_olist__geolocation') }}
),
final AS (
    SELECT
        TRIM(geolocation_zip_code_prefix) AS zip_code_prefix,
        geolocation_lat AS latitude,
        geolocation_lng AS longitude,
        UPPER(TRIM(geolocation_city)) AS city,
        UPPER(TRIM(geolocation_state)) AS state_id
    FROM geolocation
)
SELECT *
FROM final
