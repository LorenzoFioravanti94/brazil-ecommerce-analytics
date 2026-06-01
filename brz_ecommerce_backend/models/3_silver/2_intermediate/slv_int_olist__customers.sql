-- Objective: define a new PK for the customers table by selecting the most recent geographic information for each customer, while also preserving the total number of orders as a key metric for downstream models.
-- CTE 1: Combine customer details with order timestamps to establish chronological order
WITH staging_customers AS (
    SELECT
        customer_basket_id,
        customer_id,
        zip_code_prefix,
        city AS city_raw,
        state_id
    FROM {{ ref('slv_stg_olist__customers') }}
),
customers_city_no_accents AS (
    SELECT
        customer_basket_id,
        customer_id,
        zip_code_prefix,
        -- Standardize city names by removing accents and special characters
        REGEXP_REPLACE(STRIP_ACCENTS(city_raw), '[^A-Z0-9 ]', '', 'g') AS city_no_accents,
        state_id
    FROM staging_customers
),
-- 2. Applicazione del Seed 1: Correzione dei Typo Grammaticali
apply_seed_typos AS (
    SELECT
        c.customer_basket_id,
        c.customer_id,
        c.zip_code_prefix,
        -- Se c'è un typo nel seed usa quello corretto, altrimenti tieni la stringa normalizzata
        COALESCE(t.fixed_city, c.city_no_accents) AS city_corrected,
        c.state_id
    FROM customers_city_no_accents c
    LEFT JOIN {{ ref('typo_cure') }} t 
        ON c.city_no_accents = t.original_city
),
-- 3. Applicazione del Seed 2: Correzione dei Conflitti dei CAP (Regole Assolute)
apply_seed_zip_rules AS (
    SELECT
        t.customer_basket_id,
        t.customer_id,
        t.zip_code_prefix,
        -- Se il CAP è problematico, il seed sovrascrive in modo assoluto la città
        COALESCE(z.city_associated, t.city_corrected) AS city_associated,
        t.state_id
    FROM apply_seed_typos t
    LEFT JOIN {{ ref('zip_code_fix') }} z 
        ON t.zip_code_prefix = z.zip_code_prefix
),
-- 4. Applicazione del Seed 3: Mappatura Distretti -> Comuni IBGE
apply_seed_municipality AS (
    SELECT
        z.customer_basket_id,
        z.customer_id,
        z.zip_code_prefix,
        -- Se la località è un distretto, mappa sul comune ufficiale IBGE
        COALESCE(m.municipality, z.city_associated) AS city,
        z.state_id
    FROM apply_seed_zip_rules z
    LEFT JOIN {{ ref('municipality_map') }} m 
        ON z.city_associated = m.locality
),
staging_orders AS (
    SELECT *
    FROM {{ ref('slv_stg_olist__orders') }}
),
customer_orders_joined AS (
    SELECT
        c.customer_id,
        c.customer_basket_id,
        c.zip_code_prefix,
        c.city,
        c.state_id,
        o.purchase_timestamp
    FROM apply_seed_municipality c
    INNER JOIN staging_orders o 
        ON c.customer_basket_id = o.customer_basket_id
),
-- CTE 2: Calculate total orders per customer and rank their records from newest to oldest
customer_records_ranked AS (
    SELECT
        customer_id,
        zip_code_prefix,
        city,
        state_id,
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
        state_id,
        total_orders
    FROM customer_records_ranked
    -- Filter out older records, resolving data ambiguity for multi-order customers
    WHERE order_recency_rank = 1
)
SELECT *
FROM final