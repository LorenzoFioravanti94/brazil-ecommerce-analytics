-- This test validates that the metric `hdi` is mathematically consistent with:
--     (hdi_education + hdi_wealth + hdi_health) / 3
--
-- A tolerance threshold of 0.05 is allowed to account for:
-- - rounding differences
-- - dataset precision
--
-- The test fails when the absolute difference exceeds 0.05.
{% test test_mean_consistency(model, hdi, hdi_education, hdi_wealth, hdi_health, tolerance=0.05) %}

WITH mean_comparison AS (
    SELECT
        {{ hdi }} AS mean,
        ({{ hdi_education }} + {{ hdi_wealth }} + {{ hdi_health }}) / 3 AS recomputed_mean
    FROM {{ model }}
)
SELECT *
FROM mean_comparison
WHERE abs(mean - recomputed_mean) > {{ tolerance }}

{% endtest %}
