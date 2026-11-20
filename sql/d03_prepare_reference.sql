CREATE OR REPLACE TABLE gp_lsoa AS
SELECT
    PRACTICE_CODE                       AS practice_code,
    LSOA_CODE                           AS lsoa_code,
    CAST(NUMBER_OF_PATIENTS AS INTEGER) AS patients
FROM read_csv('data_raw/gp_reg/gp_lsoa.csv', all_varchar = true, quote = '"', escape = '"')
WHERE SEX = 'ALL';

CREATE OR REPLACE TABLE imd AS
SELECT
    "LSOA code (2021)"                                           AS lsoa_code,
    CAST("Index of Multiple Deprivation (IMD) Score" AS DOUBLE)  AS imd_score
FROM read_csv('data_raw/imd/imd.csv', all_varchar = true, quote = '"', escape = '"');

CREATE OR REPLACE TABLE practice_icb AS
SELECT
    PRACTICE_CODE AS practice_code,
    ICB_CODE      AS icb_code,
    ICB_NAME      AS icb_name
FROM read_csv('data_raw/gp_reg/practice_map.csv', all_varchar = true, quote = '"', escape = '"');
