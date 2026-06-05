WITH staging_order_reviews AS (
    SELECT review_id,
           order_id,
           score,
           comment_title,
           comment_text,
           creation_date,
           answer_timestamp
    FROM {{ ref('slv_stg_olist__order_reviews') }}
),
-- Step 1: Eliminiamo i duplicati speculari identici
specular_duplicates AS (
    SELECT DISTINCT
           review_id AS review_group_id,
           order_id,
           score,
           comment_title,
           comment_text,
           creation_date,
           answer_timestamp,
    FROM staging_order_reviews
),
surrogate_key AS (
    SELECT 
           {{ dbt_utils.generate_surrogate_key(['review_group_id', 'order_id']) }} AS order_review_id,
           review_group_id,
           order_id,
           score,
           comment_title,
           comment_text,
           creation_date,
           answer_timestamp
    FROM specular_duplicates
)
SELECT *
FROM surrogate_key