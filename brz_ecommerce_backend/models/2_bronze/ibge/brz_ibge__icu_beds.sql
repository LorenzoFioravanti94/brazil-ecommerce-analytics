SELECT UF,
       "ICU beds",
       "Public beds",
       "Private beds",
       "Public beds per citizen",
       "Private beds per citizen"
FROM {{ source('ibge', 'icu_beds') }}