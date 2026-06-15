WITH orders AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    FROM {{ ref('brz_olist__orders') }}
),
orders_cleaned AS (
    SELECT
        TRIM(order_id) AS order_id,
        TRIM(customer_id) AS customer_basket_id,
        CASE
            WHEN order_status == 'canceled' THEN 'cancelled'
            ELSE order_status
        END AS status,
        CAST(order_purchase_timestamp AS TIMESTAMP) AS purchase_timestamp,
        CAST(order_approved_at AS TIMESTAMP) AS approved_at,
        CAST(order_delivered_carrier_date AS TIMESTAMP) AS delivered_carrier_date,
        CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_customer_date,
        CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_delivery_date
    FROM orders
),
final AS (
    SELECT
        order_id,
        customer_basket_id,
        UPPER(TRIM(status)) AS status,
        purchase_timestamp,
        approved_at,
        delivered_carrier_date,
        delivered_customer_date,
        estimated_delivery_date
    FROM orders_cleaned
)
SELECT *
FROM final
