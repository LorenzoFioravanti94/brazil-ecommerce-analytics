-- This test validates that total_item_value is mathematically consistent with:
--     price + freight_value
--
-- A tolerance of 0.01 is applied to account for floating-point rounding.
-- The test fails when the absolute difference exceeds 0.01.
WITH values_data AS (
    SELECT
        order_item_id,
        total_item_value,
        price,
        freight_value
    FROM {{ ref('fct_order_items') }}
)
SELECT order_item_id
FROM values_data
WHERE ABS(total_item_value - (price + freight_value)) > 0.01