{{ config(materialized='ephemeral') }}

WITH customers AS (
    SELECT customer_id,
           customer_unique_id,
           customer_zip_code_prefix,
           customer_city,
           customer_state
    FROM {{ ref('brz_olist__customers') }} 
)
SELECT trim(customer_id) AS customer_basket_id,
       trim(customer_unique_id) AS customer_id,
       trim(customer_zip_code_prefix) AS zip_code_prefix,
       upper(trim(customer_city)) AS city,
       upper(trim(customer_state)) AS state_id
FROM customers