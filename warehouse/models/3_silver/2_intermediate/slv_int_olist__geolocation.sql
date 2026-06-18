WITH geolocation AS (
    SELECT
        zip_code_prefix,
        latitude,
        longitude,
        city AS city_raw,
        state_id
    FROM {{ ref('slv_stg_olist__geolocation') }}
),
typo_cure AS (
    SELECT *
    FROM {{ ref('typo_cure') }}
),
zip_code_fix AS (
    SELECT *
    FROM {{ ref('zip_code_fix') }}
),
municipality_map AS (
    SELECT *
    FROM {{ ref('municipality_map') }}
),
-- Text standardization consistent with typo_cure seed
geolocation_normalized_city AS (
    SELECT
        zip_code_prefix,
        latitude,
        longitude,
        state_id,
        -- Standardize city names by removing accents and special characters
        REGEXP_REPLACE(STRIP_ACCENTS(city_raw), '[^A-Z0-9 ]', '', 'g') AS city_no_accents
    FROM geolocation
),
-- Fix grammatical typos: apply typo_cure seed
geolocation_typos_fixed AS (
    SELECT
        g.zip_code_prefix,
        g.latitude,
        g.longitude,
        g.state_id,
        -- If the seed has a typo fix, use it; otherwise keep the normalized string
        COALESCE(t.fixed_city, g.city_no_accents) AS city_corrected
    FROM geolocation_normalized_city g
    LEFT JOIN typo_cure t
        ON g.city_no_accents = t.original_city
),
-- Resolve ZIP code conflicts: apply zip_code_fix seed
geolocation_zip_fixed AS (
    SELECT
        t.zip_code_prefix,
        t.latitude,
        t.longitude,
        t.state_id,
        -- If the ZIP code is problematic, the seed unconditionally overrides the city
        COALESCE(z.city_associated, t.city_corrected) AS city_associated
    FROM geolocation_typos_fixed t
    LEFT JOIN zip_code_fix z
        ON t.zip_code_prefix = z.zip_code_prefix
),
-- Map districts to official IBGE municipalities: apply municipality_map seed
geolocation_district_fixed AS (
    SELECT
        z.zip_code_prefix,
        z.latitude,
        z.longitude,
        z.state_id,
        -- If the locality is a district, map it to the official IBGE municipality
        COALESCE(m.municipality, z.city_associated) AS city_final
    FROM geolocation_zip_fixed z
    LEFT JOIN municipality_map m
        ON z.city_associated = m.locality
),
-- Aggregate to one row per zip_code_prefix: average coordinates, pick canonical city
final AS (
    SELECT
        zip_code_prefix,
        -- Compute the geometric centroid of the coordinates for each ZIP code
        AVG(latitude) AS latitude_mean,
        AVG(longitude) AS longitude_mean,
        -- Take the now-normalized, consistent city name for the same ZIP code
        MAX(city_final) AS city,
        -- Each ZIP code prefix belongs to a single state; MAX just satisfies GROUP BY
        MAX(state_id) AS state_id
    FROM geolocation_district_fixed
    GROUP BY zip_code_prefix
)
SELECT *
FROM final
