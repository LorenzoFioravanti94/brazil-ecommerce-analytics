WITH order_reviews AS (
    SELECT review_id,
           order_id,
           review_score,
           review_comment_title,
           review_comment_message,
           review_creation_date,
           review_answer_timestamp
    FROM {{ ref('brz_olist__order_reviews') }}
)
SELECT trim(review_id) AS review_id,
       trim(order_id) AS order_id,
       cast(review_score AS INTEGER) AS score,
       lower(trim(review_comment_title)) AS comment_title,
       lower(trim(review_comment_message)) AS comment_text,
       cast(review_creation_date AS DATE) AS creation_date,
       cast(review_answer_timestamp AS TIMESTAMP) AS answer_timestamp
FROM order_reviews