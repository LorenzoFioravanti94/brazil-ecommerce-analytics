SELECT product_category_name,
       product_category_name_english
FROM {{ source('olist', 'category_translation') }}
