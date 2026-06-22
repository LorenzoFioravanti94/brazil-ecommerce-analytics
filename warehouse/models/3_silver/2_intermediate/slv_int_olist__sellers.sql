WITH sellers AS (
    SELECT
        seller_id,
        zip_code_prefix,
        city AS city_raw,
        state_id
    FROM {{ ref('slv_stg_olist__sellers') }}
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
sellers_normalized_city AS (
    SELECT
        seller_id,
        zip_code_prefix,
        -- Standardize city names by removing accents and special characters
        REGEXP_REPLACE(STRIP_ACCENTS(city_raw), '[^A-Z0-9 ]', '', 'g') AS city_no_accents,
        state_id
    FROM sellers
),
-- Fix grammatical typos: apply typo_cure seed
sellers_typos_fixed AS (
    SELECT
        s.seller_id,
        s.zip_code_prefix,
        -- If the seed has a typo fix, use it; otherwise keep the normalized string
        COALESCE(t.fixed_city, s.city_no_accents) AS city_corrected,
        s.state_id
    FROM sellers_normalized_city s
    LEFT JOIN typo_cure t
        ON s.city_no_accents = t.original_city
),
-- Resolve ZIP code conflicts: apply zip_code_fix seed
sellers_zip_fixed AS (
    SELECT
        t.seller_id,
        t.zip_code_prefix,
        -- If the ZIP code is problematic, the seed unconditionally overrides the city
        COALESCE(z.associated_city, t.city_corrected) AS associated_city,
        t.state_id
    FROM sellers_typos_fixed t
    LEFT JOIN zip_code_fix z
        ON t.zip_code_prefix = z.zip_code_prefix
),
-- Map districts to official IBGE municipalities: apply municipality_map seed
final AS (
    SELECT
        z.seller_id,
        z.zip_code_prefix,
        -- If the locality is a district, map it to the official IBGE municipality
        COALESCE(m.municipality, z.associated_city) AS city,
        z.state_id
    FROM sellers_zip_fixed z
    LEFT JOIN municipality_map m
        ON z.associated_city = m.locality
)
SELECT *
FROM final
