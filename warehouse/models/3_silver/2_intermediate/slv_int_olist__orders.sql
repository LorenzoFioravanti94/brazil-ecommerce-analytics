-- Objective: Update the orders model to replace the old record-level PK with the new unique customer identifier, ensuring that all order records are correctly linked to their respective customers using the new FK.
-- CTE 1: Source the staging orders data
WITH orders AS (
    SELECT *
    FROM {{ ref('slv_stg_olist__orders') }}
),
-- CTE 2: Source the staging customers data to get the mapping between records and IDs
customers AS (
    SELECT
        customer_basket_id,
        customer_id
    FROM {{ ref('slv_stg_olist__customers') }}
),
-- CTE 3: Replace the old record-level PK with the new unique customer identifier
final AS (
    SELECT
        o.order_id,
        -- Replacing customer_record_id with the definitive customer_id Foreign Key (FK)
        c.customer_id,
        -- Include all other original order attributes here
        o.status,
        o.purchase_timestamp,
        o.approved_at,
        o.delivered_carrier_date,
        o.delivered_customer_date,
        o.estimated_delivery_date
    FROM orders o
    -- Join on the record level to correctly map which customer generated each specific order
    INNER JOIN customers c
        ON o.customer_basket_id = c.customer_basket_id
)
SELECT *
FROM final
