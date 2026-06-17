WITH sellers AS (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM {{ ref('brz_olist__sellers') }}
),
final AS (
    SELECT
        TRIM(seller_id) AS seller_id,
        seller_zip_code_prefix AS zip_code_prefix,
        UPPER(TRIM(seller_city)) AS city,
        UPPER(TRIM(seller_state)) AS state_id
    FROM sellers
)
SELECT *
FROM final
