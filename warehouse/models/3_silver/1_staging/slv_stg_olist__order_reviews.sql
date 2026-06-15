WITH order_reviews AS (
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    FROM {{ ref('brz_olist__order_reviews') }}
),
final AS (
    SELECT
        TRIM(review_id) AS review_id,
        TRIM(order_id) AS order_id,
        CAST(review_score AS INTEGER) AS score,
        LOWER(TRIM(review_comment_title)) AS comment_title,
        LOWER(TRIM(review_comment_message)) AS comment_text,
        CAST(review_creation_date AS DATE) AS creation_date,
        CAST(review_answer_timestamp AS TIMESTAMP) AS answer_timestamp
    FROM order_reviews
)
SELECT *
FROM final
