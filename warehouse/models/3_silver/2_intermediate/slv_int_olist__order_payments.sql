WITH order_payments AS (
    SELECT
        order_id,
        sequence_number,
        type,
        instalments_count,
        value
    FROM {{ ref('slv_stg_olist__order_payments') }}
),
final AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['order_id', 'sequence_number']) }} AS order_payment_id,
        order_id,
        sequence_number,
        type,
        instalments_count,
        value
    FROM order_payments
)
SELECT *
FROM final
