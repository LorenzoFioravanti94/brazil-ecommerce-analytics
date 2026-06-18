-- This test validates that delivered orders have a delivery date strictly after the purchase date.
--
-- The test fails when delivered_customer_date < order_date_id.
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