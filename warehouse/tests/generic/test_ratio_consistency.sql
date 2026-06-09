-- This generic test validates that a pre-computed ratio column (`given_ratio`) 
-- is mathematically consistent with its raw components:
--     (numerator / denominator) * scale
--
-- It dynamically supports both single-table verification and cross-table lookups 
-- via optional conditional JOIN operations.
--
-- A configurable tolerance threshold (default: 0.05) accounts for:
-- - numerical rounding differences
-- - source dataset precision constraints
-- - minor temporal discrepancies between joined datasets
--
-- The test fails and returns rows where the absolute difference exceeds the tolerance.
{% test test_ratio_consistency(model, numerator, denominator, given_ratio, scale=1, tolerance=0.05, join_to=none, join_on=none) %}

WITH source_data AS (
    SELECT
        main_table.{{ given_ratio }} AS ratio,
        {% if join_to %}
            CAST(ext_table.{{ denominator }} AS double) AS den,
        {% else %}
            CAST(main_table.{{ denominator }} AS double) AS den,
        {% endif %}
        CAST(main_table.{{ numerator }} AS double) AS num
    FROM {{ model }} AS main_table
    
    -- Inject only if join parameters are provided
    {% if join_to and join_on %}
    INNER JOIN {{ ref(join_to) }} AS ext_table
        ON main_table.{{ join_on }} = ext_table.{{ join_on }}
    {% endif %}
),
ratio_recalculation AS (
    SELECT
        ratio,
        (num / NULLIF(den, 0)) * {{ scale }} AS recomputed_ratio
    FROM source_data
)
SELECT *
FROM ratio_recalculation
WHERE ABS(ratio - recomputed_ratio) > {{ tolerance }}

{% endtest %}
