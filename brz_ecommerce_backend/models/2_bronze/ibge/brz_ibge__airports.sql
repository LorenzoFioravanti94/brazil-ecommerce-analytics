SELECT UF,
       "Passengers rate"
FROM {{ source('ibge', 'airports') }}