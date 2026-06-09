WITH hdi AS (
    SELECT
        UF,
        "HDI 2017",
        "HDI Education 2017",
        "HDI Wealth 2017",
        "HDI Health 2017",
        "HDI 2010",
        "HDI Education 2010",
        "HDI Wealth 2010",
        "HDI Health 2010",
        "HDI 2000",
        "HDI Education 2000",
        "HDI Wealth 2000",
        "HDI Health 2000",
        "HDI 1991",
        "HDI Education 1991",
        "HDI Wealth 1991",
        "HDI Health 1991"
    FROM {{ ref('brz_ibge__hdi') }}
)
SELECT
    upper(trim(UF)) AS state_id,
    "HDI 2017" AS hdi_2017,
    "HDI Education 2017" AS hdi_education_2017,
    "HDI Wealth 2017" AS hdi_wealth_2017,
    "HDI Health 2017" AS hdi_health_2017,
    "HDI 2010" AS hdi_2010,
    "HDI Education 2010" AS hdi_education_2010,
    "HDI Wealth 2010" AS hdi_wealth_2010,
    "HDI Health 2010" AS hdi_health_2010,
    "HDI 2000" AS hdi_2000,
    "HDI Education 2000" AS hdi_education_2000,
    "HDI Wealth 2000" AS hdi_wealth_2000,
    "HDI Health 2000" AS hdi_health_2000,
    "HDI 1991" AS hdi_1991,
    "HDI Education 1991" AS hdi_education_1991,
    "HDI Wealth 1991" AS hdi_wealth_1991,
    "HDI Health 1991" AS hdi_health_1991
FROM hdi