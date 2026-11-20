COPY (SELECT year_month, practice_code, bnf_code, chemical_name, items FROM epd_antibiotics)
    TO 'export/epd_antibiotics.csv' (HEADER, DELIMITER ',');
COPY gp_lsoa      TO 'export/gp_lsoa.csv'      (HEADER, DELIMITER ',');
COPY imd          TO 'export/imd.csv'          (HEADER, DELIMITER ',');
COPY practice_icb TO 'export/practice_icb.csv' (HEADER, DELIMITER ',');
