WITH sellers AS (
    SELECT seller_id,
           seller_zip_code_prefix,
           seller_city,
           seller_state
    FROM {{ ref('brz_olist__sellers') }}
)
SELECT trim(seller_id) AS seller_id,
       seller_zip_code_prefix AS zip_code_prefix,
       upper(trim(seller_city)) AS city,
       upper(trim(seller_state)) AS state
FROM sellers