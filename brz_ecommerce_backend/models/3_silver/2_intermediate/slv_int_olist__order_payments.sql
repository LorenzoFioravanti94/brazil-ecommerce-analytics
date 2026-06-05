WITH staging_order_payments AS (
    SELECT order_id,
           sequence_number,
           type,
           installments_count,
           value
    FROM {{ ref('slv_stg_olist__order_payments') }}
),
surrogate_key AS (
    SELECT 
           {{ dbt_utils.generate_surrogate_key(['order_id', 'sequence_number']) }} AS order_payment_id,
           order_id,
           sequence_number,
           type,
           installments_count,
           value
    FROM staging_order_payments
)
SELECT *
FROM surrogate_key