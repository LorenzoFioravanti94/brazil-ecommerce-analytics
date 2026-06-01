WITH intensive_care_unit_beds AS (
    SELECT
        state_id,
        icu_beds,
        public_beds,
        private_beds,
        public_beds_per_10k_citizens,
        private_beds_per_10k_citizens
    FROM {{ ref('slv_stg_ibge__intensive_care_unit_beds') }}
),
remove_redundancy AS (
    SELECT
        state_id,
        public_beds,
        private_beds
    FROM intensive_care_unit_beds
)
SELECT *
FROM remove_redundancy