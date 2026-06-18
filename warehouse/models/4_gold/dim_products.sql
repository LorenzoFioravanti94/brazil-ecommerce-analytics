WITH products AS (
    SELECT
        product_id,
        local_category_name,
        name_lenght,
        description_lenght,
        photos_qty,
        weight_g,
        length_cm,
        height_cm,
        width_cm
    FROM {{ ref('slv_stg_olist__products') }}
),
product_category AS (
    SELECT
        local_name,
        english_name,
        business_area
    FROM {{ ref('slv_int_olist__product_category') }}
),
-- Replace the local category name with its English equivalent and attach the business area.
final AS (
    SELECT
        p.product_id,
        pc.english_name AS category_name,
        pc.business_area,
        -- quality indicators
        p.name_lenght,
        p.description_lenght,
        p.photos_qty,
        -- physical attributes
        p.weight_g,
        p.length_cm,
        p.height_cm,
        p.width_cm
    FROM products AS p
    LEFT JOIN product_category AS pc
        ON p.local_category_name = pc.local_name
)
SELECT *
FROM final
