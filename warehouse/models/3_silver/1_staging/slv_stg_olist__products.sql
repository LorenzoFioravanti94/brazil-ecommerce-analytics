WITH products AS (
    SELECT
        product_id,
        product_category_name,
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    FROM {{ ref('brz_olist__products') }}
),
final AS (
    SELECT
        TRIM(product_id) AS product_id,
        LOWER(TRIM(product_category_name)) AS local_category_name,
        CAST(product_name_lenght AS INTEGER) AS name_length,
        CAST(product_description_lenght AS INTEGER) AS description_length,
        CAST(product_photos_qty AS INTEGER) AS photos_qty,
        product_weight_g AS weight_g,
        product_length_cm AS length_cm,
        product_height_cm AS height_cm,
        product_width_cm AS width_cm
    FROM products
)
SELECT *
FROM final
