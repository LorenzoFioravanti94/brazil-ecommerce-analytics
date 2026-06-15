WITH source AS (
    SELECT *
    FROM {{ source('olist', 'order_payments') }}
),
final AS (
    SELECT
        order_id,
        payment_sequential,
        payment_type,
        payment_installments,
        payment_value
    FROM source
)
SELECT *
FROM final
