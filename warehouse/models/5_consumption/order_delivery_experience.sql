-- Feature/target source for the downstream delivery-experience ML project.
--   * grain: one row per delivered order (delivered_customer_date is non-null)
--   * target: days_to_deliver (regression); delivery_delay_days exposes lateness
--   * every non-target column is knowable at purchase time, so the feature set has no leakage
{{ config(materialized='table') }}

WITH orders AS (
    SELECT
        order_id,
        customer_id,
        order_date_id,
        estimated_delivery_date,
        delivered_customer_date,
        days_to_deliver,
        delivery_delay_days,
        instalments_count,
        total_payment_value,
        credit_card_value,
        boleto_value,
        voucher_value,
        debit_card_value
    FROM {{ ref('fct_orders') }}
),
order_items AS (
    SELECT
        order_id,
        product_id,
        seller_id,
        price,
        freight_value
    FROM {{ ref('fct_order_items') }}
),
products AS (
    SELECT
        product_id,
        category_name,
        business_area,
        photos_qty,
        weight_g,
        length_cm,
        height_cm,
        width_cm
    FROM {{ ref('dim_products') }}
),
sellers AS (
    SELECT
        seller_id,
        state_id,
        latitude,
        longitude
    FROM {{ ref('dim_sellers') }}
),
customers AS (
    SELECT
        customer_id,
        city,
        state_id,
        latitude,
        longitude
    FROM {{ ref('dim_customers') }}
),
states AS (
    SELECT
        state_id,
        region
    FROM {{ ref('dim_states') }}
),
socio_economics AS (
    SELECT
        state_id,
        population,
        gdp,
        education_index,
        wealth_index,
        health_index,
        poverty_index,
        airports_passengers_rate,
        public_icu_beds,
        private_icu_beds
    FROM {{ ref('dim_socio_economics') }}
),
dates AS (
    SELECT
        date_id,
        month,
        quarter,
        day_of_week,
        is_weekend,
        is_holiday_brazil
    FROM {{ ref('dim_date') }}
),
-- Only delivered orders have a realised delivery time; this filter sets the grain.
delivered_orders AS (
    SELECT
        order_id,
        customer_id,
        order_date_id           AS order_purchase_date,
        estimated_delivery_date,
        days_to_deliver,
        delivery_delay_days,
        instalments_count,
        total_payment_value,
        credit_card_value,
        boleto_value,
        voucher_value,
        debit_card_value
    FROM orders
    WHERE delivered_customer_date IS NOT NULL
),
order_customer_geo AS (
    SELECT
        o.order_id,
        c.state_id              AS customer_state_id,
        st.region               AS customer_region,
        c.city                  AS customer_city,
        c.latitude              AS customer_lat,
        c.longitude             AS customer_long
    FROM delivered_orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN states st
        ON c.state_id = st.state_id
),
-- The customer coordinate is carried in here so the per-item distance can be
-- evaluated leg by leg; the INNER JOIN also prunes items of non-delivered orders.
order_items_enriched AS (
    SELECT
        oi.order_id,
        oi.seller_id,
        oi.price,
        oi.freight_value,
        oi.price + oi.freight_value             AS item_value,
        p.category_name,
        p.business_area,
        p.photos_qty,
        p.weight_g,
        p.length_cm * p.height_cm * p.width_cm  AS volume_cm3,
        s.state_id                              AS seller_state_id,
        -- Haversine great-circle distance (km, R = 6371) between the customer and
        -- the item's seller. Null when either zip code is not geolocated; the null
        -- is kept rather than imputed, since a fabricated distance would bias the
        -- regression target.
        CASE
            WHEN cg.customer_lat IS NULL OR s.latitude IS NULL THEN NULL
            ELSE 2 * 6371 * ASIN(SQRT(
                POWER(SIN(RADIANS(s.latitude - cg.customer_lat) / 2), 2)
                + COS(RADIANS(cg.customer_lat)) * COS(RADIANS(s.latitude))
                * POWER(SIN(RADIANS(s.longitude - cg.customer_long) / 2), 2)
            ))
        END                                     AS item_distance_km
    FROM order_items oi
    LEFT JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN sellers s
        ON oi.seller_id = s.seller_id
    INNER JOIN order_customer_geo cg
        ON oi.order_id = cg.order_id
),
order_item_aggregates AS (
    SELECT
        order_id,
        COUNT(*)                    AS n_items,
        COUNT(DISTINCT seller_id)   AS n_sellers,
        SUM(freight_value)          AS total_freight,
        SUM(price)                  AS total_price,
        SUM(weight_g)               AS total_weight_g,
        SUM(volume_cm3)             AS total_volume_cm3,
        AVG(photos_qty)             AS avg_photos_qty,
        -- A multi-seller order is only complete once the farthest parcel arrives,
        -- so MAX gates the delivery; AVG summarizes the overall shipping spread.
        MAX(item_distance_km)       AS max_distance_km,
        AVG(item_distance_km)       AS avg_distance_km
    FROM order_items_enriched
    GROUP BY order_id
),
-- Dominant category/business area = the group with the highest summed item value;
-- category_name breaks ties so the pick is deterministic.
category_value_ranked AS (
    SELECT
        order_id,
        category_name,
        business_area,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY SUM(item_value) DESC, category_name
        ) AS rn
    FROM order_items_enriched
    GROUP BY order_id, category_name, business_area
),
main_category AS (
    SELECT
        order_id,
        category_name   AS main_category_name,
        business_area
    FROM category_value_ranked
    WHERE rn = 1
),
-- Principal seller = the seller contributing the highest summed item value.
seller_value_ranked AS (
    SELECT
        order_id,
        seller_id,
        seller_state_id,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY SUM(item_value) DESC, seller_id
        ) AS rn
    FROM order_items_enriched
    GROUP BY order_id, seller_id, seller_state_id
),
main_seller AS (
    SELECT
        order_id,
        seller_state_id
    FROM seller_value_ranked
    WHERE rn = 1
),
final AS (
    SELECT
        -- PK
        o.order_id,
        -- regression target and delivery outcome
        CAST(o.days_to_deliver AS INTEGER)                              AS days_to_deliver,
        CAST(o.delivery_delay_days AS INTEGER)                          AS delivery_delay_days,
        -- purchase-time features (no leakage)
        o.order_purchase_date,
        CAST({{ dbt.datediff('o.order_purchase_date', 'o.estimated_delivery_date', 'day') }} AS INTEGER) AS estimated_delivery_days,
        -- total_payment_value is null for the rare order with no recorded payment;
        -- main_payment_type is then null too, never a defaulted guess.
        CAST(o.total_payment_value AS DOUBLE)                           AS total_payment_value,
        CAST(o.instalments_count AS INTEGER)                            AS instalments_count,
        CAST(
            CASE
                WHEN o.total_payment_value IS NULL THEN NULL
                WHEN COALESCE(o.credit_card_value, 0) >= COALESCE(o.boleto_value, 0)
                 AND COALESCE(o.credit_card_value, 0) >= COALESCE(o.voucher_value, 0)
                 AND COALESCE(o.credit_card_value, 0) >= COALESCE(o.debit_card_value, 0) THEN 'credit_card'
                WHEN COALESCE(o.boleto_value, 0) >= COALESCE(o.voucher_value, 0)
                 AND COALESCE(o.boleto_value, 0) >= COALESCE(o.debit_card_value, 0) THEN 'boleto'
                WHEN COALESCE(o.voucher_value, 0) >= COALESCE(o.debit_card_value, 0) THEN 'voucher'
                ELSE 'debit_card'
            END
        AS VARCHAR)                                                     AS main_payment_type,
        -- calendar features of the purchase date
        CAST(d.month AS INTEGER)                                        AS month,
        CAST(d.quarter AS INTEGER)                                      AS quarter,
        CAST(d.day_of_week AS INTEGER)                                  AS day_of_week,
        d.is_weekend,
        d.is_holiday_brazil,
        -- item aggregates
        CAST(ia.n_items AS INTEGER)                                     AS n_items,
        CAST(ia.n_sellers AS INTEGER)                                   AS n_sellers,
        CAST(ia.total_freight AS DOUBLE)                               AS total_freight,
        CAST(ia.total_price AS DOUBLE)                                 AS total_price,
        CAST(ia.total_weight_g AS BIGINT)                              AS total_weight_g,
        CAST(ia.total_volume_cm3 AS BIGINT)                            AS total_volume_cm3,
        mc.main_category_name,
        mc.business_area,
        CAST(ia.avg_photos_qty AS DOUBLE)                             AS avg_photos_qty,
        CAST(ia.max_distance_km AS DOUBLE)                            AS max_distance_km,
        CAST(ia.avg_distance_km AS DOUBLE)                            AS avg_distance_km,
        -- customer geography
        cg.customer_state_id,
        cg.customer_region,
        cg.customer_city,
        CAST(cg.customer_lat AS DOUBLE)                               AS customer_lat,
        CAST(cg.customer_long AS DOUBLE)                              AS customer_long,
        -- principal-seller geography
        ms.seller_state_id,
        ss.region                                                      AS seller_region,
        -- socioeconomic context of the customer's state
        CAST(se.population AS BIGINT)                                  AS population,
        CAST(se.gdp AS DOUBLE)                                        AS gdp,
        CAST(se.education_index AS DOUBLE)                            AS education_index,
        CAST(se.wealth_index AS DOUBLE)                              AS wealth_index,
        CAST(se.health_index AS DOUBLE)                             AS health_index,
        CAST(se.poverty_index AS DOUBLE)                            AS poverty_index,
        CAST(se.airports_passengers_rate AS DOUBLE)                 AS airports_passengers_rate,
        CAST(se.public_icu_beds AS INTEGER)                         AS public_icu_beds,
        CAST(se.private_icu_beds AS INTEGER)                        AS private_icu_beds
    FROM delivered_orders o
    LEFT JOIN order_customer_geo cg
        ON o.order_id = cg.order_id
    LEFT JOIN order_item_aggregates ia
        ON o.order_id = ia.order_id
    LEFT JOIN main_category mc
        ON o.order_id = mc.order_id
    LEFT JOIN main_seller ms
        ON o.order_id = ms.order_id
    LEFT JOIN states ss
        ON ms.seller_state_id = ss.state_id
    LEFT JOIN dates d
        ON o.order_purchase_date = d.date_id
    LEFT JOIN socio_economics se
        ON cg.customer_state_id = se.state_id
)
SELECT *
FROM final
