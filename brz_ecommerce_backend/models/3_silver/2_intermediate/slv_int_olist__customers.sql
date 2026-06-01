-- Objective: define a new PK for the customers table by selecting the most recent geographic information for each customer, while also preserving the total number of orders as a key metric for downstream models.
-- CTE 1: Combine customer details with order timestamps to establish chronological order
WITH customer_orders_joined AS (
    SELECT
        c.customer_id,
        c.customer_basket_id,
        c.zip_code_prefix,
        c.city,
        c.state,
        o.purchase_timestamp
    FROM {{ ref('slv_stg_olist__customers') }} c
    INNER JOIN {{ ref('slv_stg_olist__orders') }} o 
        ON c.customer_basket_id = o.customer_basket_id
),
-- CTE 2: Calculate total orders per customer and rank their records from newest to oldest
customer_records_ranked AS (
    SELECT
        customer_id,
        zip_code_prefix,
        city,
        state,
        -- Generate a sequence number where 1 is always the latest order
        ROW_NUMBER() OVER (
            PARTITION BY customer_id 
            ORDER BY purchase_timestamp DESC
        ) AS order_recency_rank,
        -- Count total records/orders per customer to preserve this metric for downstream models
        COUNT(customer_basket_id) OVER (
            PARTITION BY customer_id
        ) AS total_orders
    FROM customer_orders_joined
),
-- Final Selection: Deduplicate by picking only the latest geographic data for each customer
final AS (
    SELECT
        customer_id, -- This now safely acts as the new Primary Key (PK)
        zip_code_prefix,
        city,
        state AS state_id,
        total_orders
    FROM customer_records_ranked
    -- Filter out older records, resolving data ambiguity for multi-order customers
    WHERE order_recency_rank = 1
)
SELECT *
FROM final