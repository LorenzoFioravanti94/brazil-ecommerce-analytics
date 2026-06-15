{{ config(materialized='ephemeral') }}

WITH customers AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    FROM {{ ref('brz_olist__customers') }}
),
final AS (
    SELECT
        TRIM(customer_id) AS customer_basket_id,
        TRIM(customer_unique_id) AS customer_id,
        TRIM(customer_zip_code_prefix) AS zip_code_prefix,
        UPPER(TRIM(customer_city)) AS city,
        UPPER(TRIM(customer_state)) AS state_id
    FROM customers
)
SELECT *
FROM final
