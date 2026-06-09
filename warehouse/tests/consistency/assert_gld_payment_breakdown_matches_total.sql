-- The sum of payment methods must be equal to the total payment value

WITH payment_data AS (
    SELECT
        order_id,
        total_payment_value,
        credit_card_value,
        boleto_value,
        voucher_value,
        debit_card_value
    FROM {{ ref('fct_orders') }}
)
SELECT order_id
FROM payment_data
WHERE total_payment_value IS NOT NULL
  AND ABS(total_payment_value - credit_card_value - boleto_value - voucher_value - debit_card_value) > 0.01   -- tolerance for floating point