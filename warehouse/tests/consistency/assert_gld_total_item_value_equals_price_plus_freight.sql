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