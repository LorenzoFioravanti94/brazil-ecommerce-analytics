WITH sellers AS (
    SELECT
        seller_id,
        zip_code_prefix,
        city AS city,
        state_id
    FROM {{ ref('slv_int_olist__sellers') }}
),
geolocation AS (
    SELECT
        zip_code_prefix,
        city AS city,
        state_id,
        latitude_mean AS latitude,
        longitude_mean AS longitude
    FROM {{ ref('slv_int_olist__geolocation') }}
),
final AS (
    SELECT
        s.seller_id,
        s.zip_code_prefix,
        s.city,
        s.state_id,
        g.latitude,
        g.longitude
    FROM sellers s
    LEFT JOIN geolocation g
        ON s.zip_code_prefix = g.zip_code_prefix
)
SELECT *
FROM final
