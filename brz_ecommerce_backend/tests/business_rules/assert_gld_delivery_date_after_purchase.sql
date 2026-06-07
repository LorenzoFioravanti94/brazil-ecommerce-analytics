-- If delivered, the delivery date must be after the purchase date
WITH orders_dates_data AS (
    SELECT
        order_id,
        order_date_id,
        delivered_customer_date
    FROM {{ ref('fct_orders') }}
)
SELECT order_id
FROM orders_dates_data
WHERE delivered_customer_date IS NOT NULL AND delivered_customer_date < order_date_id