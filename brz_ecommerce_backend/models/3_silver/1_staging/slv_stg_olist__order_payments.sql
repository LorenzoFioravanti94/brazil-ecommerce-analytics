WITH order_payments AS (
    SELECT order_id,
           payment_sequential,
           payment_type,
           payment_installments,
           payment_value
    FROM {{ ref('brz_olist__order_payments') }}
)
SELECT trim(order_id) AS order_id,
       cast(payment_sequential AS INTEGER) AS sequential_order_id,
       lower(trim(payment_type)) AS type,
       cast(payment_installments AS INTEGER) AS installments,
       payment_value AS value
FROM order_payments