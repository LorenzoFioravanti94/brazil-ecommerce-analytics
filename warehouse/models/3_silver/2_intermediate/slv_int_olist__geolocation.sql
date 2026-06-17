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
-- 1. Text standardization consistent with Seed 1
geolocation_no_accents AS (
    SELECT
        zip_code_prefix,
        latitude,
        longitude,
        state_id,
        -- Apply the exact transformation used to build the first seed
        REGEXP_REPLACE(STRIP_ACCENTS(city_raw), '[^A-Z0-9 ]', '', 'g') AS city_no_accents
    FROM geolocation
),
-- 2. Apply Seed 1: fix grammatical typos
apply_seed_typos AS (
    SELECT
        g.zip_code_prefix,
        g.latitude,
        g.longitude,
        g.state_id,
        -- If the seed has a typo fix, use it; otherwise keep the normalized string
        COALESCE(t.fixed_city, g.city_no_accents) AS city_corrected
    FROM geolocation_no_accents g
    LEFT JOIN typo_cure t
        ON g.city_no_accents = t.original_city
),
-- 3. Apply Seed 2: resolve ZIP code conflicts (absolute rules)
apply_seed_zip_rules AS (
    SELECT
        t.zip_code_prefix,
        t.latitude,
        t.longitude,
        t.state_id,
        -- If the ZIP code is problematic, the seed unconditionally overrides the city
        COALESCE(z.city_associated, t.city_corrected) AS city_associated
    FROM apply_seed_typos t
    LEFT JOIN zip_code_fix z
        ON t.zip_code_prefix = z.zip_code_prefix
),
-- 4. Apply Seed 3: map districts to official IBGE municipalities
apply_seed_municipality AS (
    SELECT
        z.zip_code_prefix,
        z.latitude,
        z.longitude,
        z.state_id,
        -- If the locality is a district, map it to the official IBGE municipality
        COALESCE(m.municipality, z.city_associated) AS city_final
    FROM apply_seed_zip_rules z
    LEFT JOIN municipality_map m
        ON z.city_associated = m.locality
),
-- 5. Final aggregated output (makes zip_code_prefix the primary key)
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
    FROM apply_seed_municipality
    GROUP BY zip_code_prefix
)
SELECT *
FROM final
