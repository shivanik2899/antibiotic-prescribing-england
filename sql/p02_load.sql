TRUNCATE epd_antibiotics, gp_lsoa, imd, practice_icb;

\copy epd_antibiotics FROM 'export/epd_antibiotics.csv' WITH (FORMAT csv, HEADER true)
\copy gp_lsoa FROM 'export/gp_lsoa.csv' WITH (FORMAT csv, HEADER true)
\copy imd FROM 'export/imd.csv' WITH (FORMAT csv, HEADER true)
\copy practice_icb FROM 'export/practice_icb.csv' WITH (FORMAT csv, HEADER true)

CREATE INDEX IF NOT EXISTS idx_epd_practice ON epd_antibiotics (practice_code);
CREATE INDEX IF NOT EXISTS idx_epd_month    ON epd_antibiotics (year_month);
CREATE INDEX IF NOT EXISTS idx_epd_bnf      ON epd_antibiotics (bnf_code text_pattern_ops);
CREATE INDEX IF NOT EXISTS idx_gp_lsoa_prac ON gp_lsoa (practice_code);
CREATE INDEX IF NOT EXISTS idx_gp_lsoa_lsoa ON gp_lsoa (lsoa_code);
ANALYZE;
