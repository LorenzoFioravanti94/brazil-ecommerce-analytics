WITH order_payments AS (
    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    FROM {{ ref('brz_olist__order_payments') }}
),
final AS (
    SELECT
        TRIM(order_id) AS order_id,
        CAST(payment_sequential AS INTEGER) AS sequence_number,
        LOWER(TRIM(payment_type)) AS type,
        CAST(payment_installments AS INTEGER) AS installments_count,
        payment_value AS value
    FROM order_payments
)
SELECT *
FROM final
