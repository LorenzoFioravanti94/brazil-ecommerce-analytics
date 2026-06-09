WITH sellers_staging AS (
    SELECT
        seller_id,
        zip_code_prefix,
        city AS city_raw,
        state_id
    FROM {{ ref('slv_stg_olist__sellers') }}
),
-- 1. Standardizzazione del testo coerente con il Seed 1
sellers_city_no_accents AS (
    SELECT
        seller_id,
        zip_code_prefix,
        -- Applichiamo la trasformazione esatta usata per il primo seed
        REGEXP_REPLACE(STRIP_ACCENTS(city_raw), '[^A-Z0-9 ]', '', 'g') AS city_no_accents,
        state_id
    FROM sellers_staging
),
-- 2. Applicazione del Seed 1: Correzione dei Typo Grammaticali
apply_seed_typos AS (
    SELECT
        s.seller_id,
        s.zip_code_prefix,
        -- Se c'è un typo nel seed usa quello corretto, altrimenti tieni la stringa normalizzata
        COALESCE(t.fixed_city, s.city_no_accents) AS city_corrected,
        s.state_id
    FROM sellers_city_no_accents s
    LEFT JOIN {{ ref('typo_cure') }} t 
        ON s.city_no_accents = t.original_city
),
-- 3. Applicazione del Seed 2: Correzione dei Conflitti dei CAP (Regole Assolute)
apply_seed_zip_rules AS (
    SELECT
        t.seller_id,
        t.zip_code_prefix,
        -- Se il CAP è problematico, il seed sovrascrive in modo assoluto la città
        COALESCE(z.city_associated, t.city_corrected) AS city_associated,
        t.state_id
    FROM apply_seed_typos t
    LEFT JOIN {{ ref('zip_code_fix') }} z 
        ON t.zip_code_prefix = z.zip_code_prefix
),
-- 4. Applicazione del Seed 3: Mappatura Distretti -> Comuni IBGE
apply_seed_municipality AS (
    SELECT
        z.seller_id,
        z.zip_code_prefix,
        -- Se la località è un distretto, mappa sul comune ufficiale IBGE
        COALESCE(m.municipality, z.city_associated) AS city,
        z.state_id
    FROM apply_seed_zip_rules z
    LEFT JOIN {{ ref('municipality_map') }} m 
        ON z.city_associated = m.locality
)
SELECT *
FROM apply_seed_municipality