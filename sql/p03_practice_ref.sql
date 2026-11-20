DROP TABLE IF EXISTS practice_ref CASCADE;

CREATE TABLE practice_ref AS
SELECT
    g.practice_code,
    SUM(g.patients)                                               AS list_size,
    SUM(CASE WHEN i.imd_score IS NOT NULL THEN g.patients END)    AS patients_with_imd,
    SUM(g.patients * i.imd_score)
      / NULLIF(SUM(CASE WHEN i.imd_score IS NOT NULL THEN g.patients END), 0) AS imd_score_w
FROM gp_lsoa g
LEFT JOIN imd i USING (lsoa_code)
GROUP BY g.practice_code;

ALTER TABLE practice_ref ADD PRIMARY KEY (practice_code);
