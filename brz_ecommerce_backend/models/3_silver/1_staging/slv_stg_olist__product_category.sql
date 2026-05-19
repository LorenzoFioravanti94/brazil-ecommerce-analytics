WITH category_translation AS (
    SELECT
        product_category_name,
        product_category_name_english
    FROM {{ ref('brz_olist__category_translation') }}
)
SELECT
    lower(trim(product_category_name)) AS local_name,
    lower(trim(product_category_name_english)) AS english_name
FROM category_translation