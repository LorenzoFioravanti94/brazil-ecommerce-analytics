WITH states AS (
    SELECT
        UF,
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
    FROM {{ ref('brz_ibge__states') }}
),
states_enhanced AS (
	SELECT
    	upper(trim(UF)) AS state_id,
    	upper(trim(State)) AS state_name,
    	upper(trim(Capital)) AS capital,
    	CASE
	    	WHEN Region == 'Northeast' THEN 'North-east'
	    	WHEN Region == 'Southeast' THEN 'South-east'
	    	ELSE Region
    	END AS Region,
    	Area AS area_km2,
    	Population AS population,
    	"Demographic Density" AS demographic_density_per_km2,
    	"Cities count" AS cities_number,
    	GDP AS gdp,
    	"GDP rate" AS gdp_world_share,
    	Poverty AS poverty_index,
    	Latitude AS latitude,
    	Longitude AS longitude
	FROM states
)
SELECT
	state_id,
	state_name,
	capital,
	lower(trim(Region)) AS region,
	area_km2,
	population,
	demographic_density_per_km2,
	cities_number,
	gdp,
	gdp_world_share,
	poverty_index,
	latitude,
	longitude
FROM states_enhanced