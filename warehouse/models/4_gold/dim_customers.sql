WITH customers AS (
    SELECT
        customer_id,
        zip_code_prefix,
        city,
        state_id,
        total_orders
    FROM {{ ref('slv_int_olist__customers') }}
),
geolocation AS (
    SELECT
        zip_code_prefix,
        latitude_mean,
        longitude_mean,
        city,
        state_id
    FROM {{ ref('slv_int_olist__geolocation') }}
),
final AS (
    SELECT
        c.customer_id,
        c.zip_code_prefix,
        c.city,
        c.state_id,
        g.latitude_mean AS latitude,
        g.longitude_mean AS longitude,
        c.total_orders
    FROM customers c
    LEFT JOIN geolocation g
        ON c.zip_code_prefix = g.zip_code_prefix
)
SELECT *
FROM final
