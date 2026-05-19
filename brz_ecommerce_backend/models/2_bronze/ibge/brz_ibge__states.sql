SELECT UF,
       State,
       Capital,
       Region,
       Area,
       Population,
       "Demographic Density",
       "Cities count",
       GDP,
       "GDP rate",
       Poverty,
       Latitude,
       Longitude
FROM {{ source('ibge', 'states') }}