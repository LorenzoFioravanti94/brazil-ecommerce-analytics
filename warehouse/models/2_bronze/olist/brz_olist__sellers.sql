WITH source AS (
    SELECT *
    FROM {{ source('olist', 'sellers') }}
),
final AS (
    SELECT
        seller_id,
        seller_zip_code_prefix,
        seller_city,
        seller_state
    FROM source
)
SELECT *
FROM final
