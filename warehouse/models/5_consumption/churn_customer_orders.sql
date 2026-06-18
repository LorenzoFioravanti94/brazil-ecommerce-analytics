-- Transaction-grain contract for the downstream customer-churn ML project.
--   * grain: one row per order (order_id is PK)
--   * all statuses kept, CANCELLED included
--   * customer_id is the unique customer identifier (repeats across orders)

{{ config(materialized='table') }}

WITH fct_orders AS (
    SELECT
        order_id,
        customer_id,
        order_date_id,
        status,
        total_payment_value
    FROM {{ ref('fct_orders') }}
),
final AS (
    SELECT
        order_id,
        customer_id,
        order_date_id          AS accounting_date,
        status                 AS order_status,
        total_payment_value    AS order_value
    FROM fct_orders
)
SELECT *
FROM final
