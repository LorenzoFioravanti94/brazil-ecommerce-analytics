{{ config(materialized='ephemeral') }}

WITH geolocation AS (
    SELECT geolocation_zip_code_prefix,
           geolocation_lat,
           geolocation_lng,
           geolocation_city,
           geolocation_state
    FROM {{ ref('brz_olist__geolocation') }}
)
SELECT trim(geolocation_zip_code_prefix) AS zip_code_prefix,
       geolocation_lat AS latitude,
       geolocation_lng AS longitude,
       upper(trim(geolocation_city)) AS city,
       upper(trim(geolocation_state)) AS state_id
FROM geolocation