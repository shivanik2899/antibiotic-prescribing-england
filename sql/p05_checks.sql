\echo '--- Check 1: rows and items per month'
SELECT year_month, COUNT(*) AS rows_loaded, SUM(items) AS items
FROM epd_antibiotics GROUP BY year_month ORDER BY year_month;

\echo '--- Check 2: duplicates (must be 0)'
SELECT COUNT(*) AS duplicate_keys FROM (
    SELECT practice_code, year_month, bnf_code, chemical_name
    FROM epd_antibiotics
    GROUP BY practice_code, year_month, bnf_code, chemical_name
    HAVING COUNT(*) > 1) AS d;

\echo '--- Check 3: share of items from codes that are not GP practices in the registration data'
SELECT ROUND(100.0 * SUM(CASE WHEN r.practice_code IS NULL THEN e.items ELSE 0 END) / SUM(e.items), 2)
       AS pct_items_not_matched_to_a_practice
FROM epd_antibiotics e LEFT JOIN practice_ref r USING (practice_code);

\echo '--- Check 4: share of registered patients with an IMD score'
SELECT ROUND(100.0 * SUM(patients_with_imd) / SUM(list_size), 2) AS pct_patients_with_imd FROM practice_ref;

\echo '--- Check 5: BNF sections and example drugs'
SELECT substr(bnf_code,1,6) AS bnf_section, MIN(chemical_name) AS example_drug, SUM(items) AS items
FROM epd_antibiotics GROUP BY 1 ORDER BY 1;

\echo '--- Check 6: national broad-spectrum share by month'
SELECT year_month,
       SUM(items) AS abx_items,
       ROUND(100.0 * SUM(CASE WHEN substr(bnf_code,1,9) = '0501013K0'
                                OR substr(bnf_code,1,7) IN ('0501021','0501120')
                              THEN items ELSE 0 END) / SUM(items), 2) AS broad_pct
FROM epd_antibiotics
WHERE substr(bnf_code,1,6) NOT IN ('050109','050110')
GROUP BY year_month ORDER BY year_month;

\echo '--- Check 7: practices lost at each stage'
SELECT
  (SELECT COUNT(DISTINCT practice_code) FROM epd_antibiotics) AS practices_in_prescribing,
  (SELECT COUNT(*) FROM practice_ref)                         AS practices_in_registration,
  (SELECT COUNT(*) FROM practice_year)                        AS practices_in_final_table;

\echo '--- Check 8: quintile sanity'
SELECT imd_quintile, COUNT(*) AS practices, ROUND(AVG(imd_score_w)::numeric, 1) AS mean_imd
FROM practice_year GROUP BY imd_quintile ORDER BY imd_quintile;

\echo '--- Check 9: tie-out with DuckDB'
SELECT COUNT(*) AS epd_rows, SUM(items) AS epd_items FROM epd_antibiotics;
SELECT COUNT(*) AS gp_lsoa_rows, SUM(patients) AS gp_lsoa_patients FROM gp_lsoa;
