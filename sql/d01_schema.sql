CREATE TABLE IF NOT EXISTS epd_antibiotics (
    source_file   VARCHAR,
    year_month    INTEGER,
    practice_code VARCHAR,
    bnf_code      VARCHAR,
    chemical_name VARCHAR,
    items         BIGINT
);
