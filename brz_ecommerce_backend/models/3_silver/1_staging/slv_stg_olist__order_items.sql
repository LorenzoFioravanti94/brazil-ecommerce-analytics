WITH order_items AS (
    SELECT order_id,
           order_item_id,
           product_id,
           seller_id,
           shipping_limit_date,
           price,
           freight_value
    FROM {{ ref('brz_olist__order_items') }}
)
SELECT trim(order_id) AS order_id,
       cast(order_item_id AS INTEGER) AS order_item_id,
       trim(product_id) AS product_id,
       trim(seller_id) AS seller_id,
       cast(shipping_limit_date AS TIMESTAMP) AS shipping_limit_date,
       price,
       freight_value
FROM order_items