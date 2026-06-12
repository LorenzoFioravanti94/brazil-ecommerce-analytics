{{ config(
    materialized='incremental',
    unique_key='order_id'
) }}

WITH orders AS (
    SELECT
        order_id,
        customer_id,
        status,
        purchase_timestamp,
        approved_at,
        delivered_carrier_date,
        delivered_customer_date,
        estimated_delivery_date,
    FROM {{ ref('slv_int_olist__orders') }}
),
payments AS (
    SELECT
        order_payment_id,
        order_id,
        sequence_number,
        type,
        installments_count,
        value
    FROM {{ ref('slv_int_olist__order_payments') }}
),
payments_aggregated AS (
    SELECT
        order_id,
        SUM(value)                                                    AS total_payment_value,
        MAX(installments_count)                                       AS installments_count,
        -- one summed column per payment type (credit_card_value, boleto_value, ...)
        {{ dbt_utils.pivot(
            column='type',
            values=['credit_card', 'boleto', 'voucher', 'debit_card'],
            agg='sum',
            then_value='value',
            suffix='_value',
            quote_identifiers=false
        ) }}
    FROM payments
    WHERE type <> 'not_defined'
    GROUP BY order_id
),
reviews_deduplicated AS (
    SELECT
        order_id,
        score,
        creation_date,
        answer_timestamp,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY creation_date DESC) AS rn -- Assuming we want the most recent review per order
    FROM {{ ref('slv_int_olist__order_reviews') }}
),
final AS (
    SELECT
        -- PK
        o.order_id,
        -- FKs
        o.customer_id,
        CAST(o.purchase_timestamp AS DATE)                       AS order_date_id,
        -- order attributes
        o.status,
        -- timestamps
        o.approved_at,
        o.delivered_carrier_date,
        o.delivered_customer_date,
        o.estimated_delivery_date,
        -- derived delivery metrics (using dbt's datediff macro for consistency across databases)
        {{ dbt.datediff("o.purchase_timestamp", "o.delivered_customer_date", "day") }} AS days_to_deliver,
        {{ dbt.datediff("o.estimated_delivery_date", "o.delivered_customer_date", "day") }} AS delivery_delay_days, --negative when delivered before estimated date
        -- payment aggregates
        pa.installments_count,
        pa.credit_card_value,
        pa.boleto_value,
        pa.voucher_value,
        pa.debit_card_value,
        pa.total_payment_value,
        -- review outcome
        r.score                                                 AS review_score,
        r.creation_date                                         AS review_creation_date,
        r.answer_timestamp                                      AS review_answer_timestamp
    FROM orders o
    LEFT JOIN payments_aggregated pa
        ON o.order_id = pa.order_id
    LEFT JOIN reviews_deduplicated r
        ON o.order_id = r.order_id AND r.rn = 1 -- Keep only the most recent review per order
)
SELECT *
FROM final
{% if is_incremental() %}
  -- Process only new or recently updated records using a 3-day lookback window
  WHERE approved_at >= (
      SELECT {{ dbt.dateadd(datepart='day', interval=-3, from_date_or_timestamp='MAX(approved_at)') }} 
      FROM {{ this }}
  )
{% endif %}
