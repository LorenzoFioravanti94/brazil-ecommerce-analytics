-- Replaces the old FK customer_basket_id with the new FK customer_id,
-- linking each order to the new customer PK from slv_int_olist__customers.
WITH orders AS (
    SELECT *
    FROM {{ ref('slv_stg_olist__orders') }}
),
-- Source customers to map basket_id to customer_id
customers AS (
    SELECT
        customer_basket_id,
        customer_id
    FROM {{ ref('slv_stg_olist__customers') }}
),
final AS (
    SELECT
        o.order_id,
        -- FK to customers
        c.customer_id,
        o.status,
        o.purchase_timestamp,
        o.approved_at,
        o.delivered_carrier_date,
        o.delivered_customer_date,
        o.estimated_delivery_date
    FROM orders o
    INNER JOIN customers c
        ON o.customer_basket_id = c.customer_basket_id
)
SELECT *
FROM final
