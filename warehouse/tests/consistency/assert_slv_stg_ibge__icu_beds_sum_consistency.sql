-- This test validates that the metric `icu_beds` is mathematically consistent with:
--     public_beds + private_beds
--
--
-- The test fails when this sum is not equal to the `icu_beds` metric.
WITH icu_beds_data AS (
    SELECT
        state_id,
        icu_beds,
        public_beds,
        private_beds      
    FROM {{ ref('slv_stg_ibge__intensive_care_unit_beds') }}
)
SELECT
    state_id,
    icu_beds AS beds_sum,
    (public_beds + private_beds) AS recomputed_beds_sum
FROM icu_beds_data
WHERE recomputed_beds_sum != beds_sum