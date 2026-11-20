DROP TABLE IF EXISTS practice_year CASCADE;

CREATE TABLE practice_year AS
WITH abx AS (
    SELECT
        practice_code,
        COUNT(DISTINCT year_month) AS months_present,
        SUM(items) AS abx_items,
        SUM(CASE WHEN substr(bnf_code,1,9) = '0501013K0'
                   OR substr(bnf_code,1,7) IN ('0501021','0501120')
                 THEN items ELSE 0 END) AS broad_items
    FROM epd_antibiotics
    WHERE year_month BETWEEN 202508 AND 202607
      AND substr(bnf_code,1,6) NOT IN ('050109','050110')
    GROUP BY practice_code
)
SELECT
    a.practice_code,
    a.months_present,
    a.abx_items,
    a.broad_items,
    r.list_size,
    r.imd_score_w,
    1000.0 * a.abx_items / r.list_size             AS abx_per_1000,
    100.0  * a.broad_items / NULLIF(a.abx_items,0) AS broad_pct,
    NTILE(5) OVER (ORDER BY r.imd_score_w)         AS imd_quintile
FROM abx a
JOIN practice_ref r USING (practice_code)
WHERE r.list_size >= 1000
  AND a.months_present >= 10
  AND r.imd_score_w IS NOT NULL;

ALTER TABLE practice_year ADD PRIMARY KEY (practice_code);
