WITH geolocation_raw AS (
    SELECT
        zip_code_prefix,
        latitude,
        longitude,
        city AS city_raw,
        state_id
    FROM {{ ref('slv_stg_olist__geolocation') }}
),

-- 1. Standardizzazione del testo coerente con il Seed 1
geolocation_no_accents AS (
    SELECT
        zip_code_prefix,
        latitude,
        longitude,
        state_id,
        -- Applichiamo la trasformazione esatta usata per il primo seed
        REGEXP_REPLACE(STRIP_ACCENTS(city_raw), '[^A-Z0-9 ]', '', 'g') AS city_no_accents
    FROM geolocation_raw
),

-- 2. Applicazione del Seed 1: Correzione dei Typo Grammaticali
apply_seed_typos AS (
    SELECT
        g.zip_code_prefix,
        g.latitude,
        g.longitude,
        g.state_id,
        -- Se c'è un typo nel seed usa quello corretto, altrimenti tieni la stringa normalizzata
        COALESCE(t.fixed_city, g.city_no_accents) AS city_corrected
    FROM geolocation_no_accents g
    LEFT JOIN {{ ref('typo_cure') }} t 
        ON g.city_no_accents = t.original_city
),

-- 3. Applicazione del Seed 2: Correzione dei Conflitti dei CAP (Regole Assolute)
apply_seed_zip_rules AS (
    SELECT
        t.zip_code_prefix,
        t.latitude,
        t.longitude,
        t.state_id,
        -- Se il CAP è problematico, il seed sovrascrive in modo assoluto la città
        COALESCE(z.city_associated, t.city_corrected) AS city_associated
    FROM apply_seed_typos t
    LEFT JOIN {{ ref('zip_code_fix') }} z 
        ON t.zip_code_prefix = z.zip_code_prefix
),

-- 4. Applicazione del Seed 3: Mappatura Distretti -> Comuni IBGE
apply_seed_municipality AS (
    SELECT
        z.zip_code_prefix,
        z.latitude,
        z.longitude,
        z.state_id,
        -- Se la località è un distretto, mappa sul comune ufficiale IBGE
        COALESCE(m.municipality, z.city_associated) AS city_final
    FROM apply_seed_zip_rules z
    LEFT JOIN {{ ref('municipality_map') }} m 
        ON z.city_associated = m.locality
)
-- 5. Output Finale Aggregato (Rende zip_code_prefix Chiave Primaria)
SELECT 
    zip_code_prefix,
    -- Calcolo del baricentro geometrico delle coordinate per ogni CAP
    AVG(latitude) AS latitude_mean,
    AVG(longitude) AS longitude_mean,
    -- Prendiamo il nome della città ormai normalizzato e coerente per lo stesso CAP
    MAX(city_final) AS city, 
    -- Ogni prefisso CAP appartiene a un solo Stato, MAX soddisfa la sintassi del GROUP BY
    MAX(state_id) AS state_id
FROM apply_seed_municipality
GROUP BY zip_code_prefix



