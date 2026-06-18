-- This test validates that total_payment_value is mathematically consistent with:
--     credit_card_value + boleto_value + voucher_value + debit_card_value
--
-- A tolerance of 0.01 is applied to account for floating-point rounding.
-- The test fails when the absolute difference exceeds 0.01.
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
  AND ABS(total_payment_value - credit_card_value - boleto_value - voucher_value - debit_card_value) > 0.01