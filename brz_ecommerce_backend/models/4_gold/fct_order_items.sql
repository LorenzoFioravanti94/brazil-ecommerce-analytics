WITH order_items AS (
    SELECT
        order_item_id,
        order_id,
        item_sequence_number,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    FROM {{ ref('slv_int_olist__order_items') }}
),
final AS (
    SELECT
        -- PK
        order_item_id,
        -- FKs
        order_id,
        product_id,
        seller_id,
        CAST(shipping_limit_date AS DATE)    AS shipping_date_id,
        -- degenerate dimension
        item_sequence_number,
        -- measures
        price,
        freight_value,
        price + freight_value                AS total_item_value
    FROM order_items
)
SELECT *
FROM final