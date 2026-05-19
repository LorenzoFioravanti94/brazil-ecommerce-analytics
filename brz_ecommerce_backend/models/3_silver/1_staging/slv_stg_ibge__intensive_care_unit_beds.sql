WITH icu_beds AS (
    SELECT
        UF,
        "ICU beds",
        "Public beds",
        "Private beds",
        "Public beds per citizen",
        "Private beds per citizen"
    FROM {{ ref('brz_ibge__icu_beds') }}
)
SELECT
    upper(trim(UF)) AS state_id,
    "ICU beds" AS icu_beds,
    "Public beds" AS public_beds,
    "Private beds" AS private_beds,
    "Public beds per citizen" AS public_beds_per_citizen,
    "Private beds per citizen" AS private_beds_per_citizen
FROM icu_beds