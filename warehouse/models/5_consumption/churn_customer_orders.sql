-- Consumer-facing model for the downstream customer-churn ML project.
-- Emits the transaction-grain contract that project expects:
--   customer_id, accounting_date, order_status, order_value
--
-- Grain: one row per order. The two source rules the ML relies on are already
-- guaranteed upstream by fct_orders, so nothing extra is done here:
--   * one order = one transaction  -> order_id is unique in fct_orders
--   * one order = exactly one date -> order_date_id is a single purchase date
-- customer_id is already the unique customer (customer_unique_id), so churn/RFM
-- is computed per person. All statuses are kept (CANCELLED included) so the ML
-- can derive the cancellation_rate; it filters to valid statuses for RFM itself.
--
-- NOTE: no purchased/cancelled pair de-duplication is applied (unlike the old
-- enterprise extraction, which removed reversal rows). In Olist an order_id is
-- unique and carries a single status with a non-negative value, so that anomaly
-- cannot occur; matching distinct orders by equal value would delete real data.

WITH fct_orders AS (
    SELECT
        customer_id,
        order_date_id,
        status,
        total_payment_value
    FROM {{ ref('fct_orders') }}
),
final AS (
    SELECT
        customer_id,
        order_date_id          AS accounting_date,
        status                 AS order_status,
        total_payment_value    AS order_value
    FROM fct_orders
)
SELECT *
FROM final
