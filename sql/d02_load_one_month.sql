DELETE FROM epd_antibiotics WHERE source_file = getvariable('f');

INSERT INTO epd_antibiotics
SELECT
    getvariable('f')                                  AS source_file,
    CAST(REPLACE(YEAR_MONTH, '-', '') AS INTEGER)     AS year_month,
    PRACTICE_CODE                                     AS practice_code,
    substr(BNF_PRESENTATION_CODE, 1, 15)              AS bnf_code,
    BNF_CHEMICAL_SUBSTANCE                            AS chemical_name,
    SUM(CAST(ITEMS AS BIGINT))                        AS items
FROM read_csv(getvariable('f'), all_varchar = true, quote = '"', escape = '"')
WHERE BNF_PRESENTATION_CODE LIKE '0501%'
GROUP BY ALL;
