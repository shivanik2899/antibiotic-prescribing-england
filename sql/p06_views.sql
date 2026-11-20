DROP VIEW IF EXISTS v_practice_rank, v_icb_summary, v_monthly_national;

CREATE VIEW v_monthly_national AS
SELECT year_month,
       SUM(items) AS abx_items,
       SUM(CASE WHEN substr(bnf_code,1,9) = '0501013K0'
                  OR substr(bnf_code,1,7) IN ('0501021','0501120')
                THEN items ELSE 0 END) AS broad_items
FROM epd_antibiotics
WHERE substr(bnf_code,1,6) NOT IN ('050109','050110')
GROUP BY year_month;

CREATE VIEW v_icb_summary AS
SELECT i.icb_name,
       COUNT(*)                                       AS practices,
       SUM(p.abx_items)                               AS abx_items,
       1000.0 * SUM(p.abx_items) / SUM(p.list_size)   AS abx_per_1000,
       100.0  * SUM(p.broad_items) / SUM(p.abx_items) AS broad_pct,
       RANK() OVER (ORDER BY SUM(p.abx_items) * 1.0 / SUM(p.list_size) DESC) AS rank_by_rate
FROM practice_year p JOIN practice_icb i USING (practice_code)
GROUP BY i.icb_name;

CREATE VIEW v_practice_rank AS
SELECT p.*, i.icb_name,
       PERCENT_RANK() OVER (PARTITION BY i.icb_name ORDER BY p.abx_per_1000) AS pct_rank_in_icb
FROM practice_year p JOIN practice_icb i USING (practice_code);
