WITH staging_order_items AS (
    SELECT order_id,
           item_sequence_number,
           product_id,
           seller_id,
           shipping_limit_date,
           price,
           freight_value
    FROM {{ ref('slv_stg_olist__order_items') }}
),
surrogate_key AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['order_id', 'item_sequence_number']) }} AS order_item_id,
        order_id,
        item_sequence_number,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value
    FROM staging_order_items
)
SELECT *
FROM surrogate_key