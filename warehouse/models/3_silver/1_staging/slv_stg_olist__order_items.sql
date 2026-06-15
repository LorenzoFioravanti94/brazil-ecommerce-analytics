WITH order_items AS (
    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    FROM {{ ref('brz_olist__order_items') }}
),
final AS (
    SELECT
        TRIM(order_id) AS order_id,
        CAST(order_item_id AS INTEGER) AS item_sequence_number,
        TRIM(product_id) AS product_id,
        TRIM(seller_id) AS seller_id,
        CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_date,
        price,
        freight_value
    FROM order_items
)
SELECT *
FROM final
