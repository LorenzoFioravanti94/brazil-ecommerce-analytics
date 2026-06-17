WITH category_translation AS (
    SELECT
        product_category_name,
        product_category_name_english
    FROM {{ ref('brz_olist__category_translation') }}
),
final AS (
    SELECT
        LOWER(TRIM(product_category_name)) AS local_name,
        LOWER(TRIM(product_category_name_english)) AS english_name
    FROM category_translation
)
SELECT *
FROM final
