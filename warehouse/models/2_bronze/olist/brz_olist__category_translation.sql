WITH source AS (
    SELECT *
    FROM {{ source('olist', 'category_translation') }}
),
final AS (
    SELECT
        product_category_name,
        product_category_name_english
    FROM source
)
SELECT *
FROM final
