WITH product_category AS (
	SELECT 
		local_name,
		english_name
	FROM {{ ref('slv_stg_olist__product_category') }}
),
seed AS (
    SELECT 
	    s.raw_category AS local_name, 
	    pc.english_name,
	    s.business_area
FROM {{ ref('category_map') }} AS s
LEFT JOIN product_category AS pc
	ON s.raw_category = pc.local_name
ORDER BY s.business_area, s.raw_category
),
final AS (
    SELECT 
        local_name,
        CASE
            WHEN local_name = 'pc_gamer' THEN 'pc_gamer'
            WHEN local_name = 'portateis_cozinha_e_preparadores_de_alimentos' THEN 'small_kitchen_appliances_and_food_processors'
            ELSE english_name
        END AS english_name,
        business_area
    FROM seed
)
SELECT *
FROM final