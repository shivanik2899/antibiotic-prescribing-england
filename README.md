# Antibiotic Prescribing in English General Practice
### August 2025 – July 2026

## Project Overview

This project examines antibiotic prescribing patterns across English general practices between August 2025 and July 2026.

Using SQL, DuckDB, PostgreSQL and R, the analysis investigates variation in total antibiotic prescribing, broad-spectrum antibiotic use, socioeconomic deprivation and geographical differences across Integrated Care Boards (ICBs).

The primary analysis includes 6,121 GP practices across England.

## Research Questions

1. How much do GP practices differ in antibiotic prescribing per 1,000 registered patients?
2. What proportion of antibiotic items are broad-spectrum antibiotics, including co-amoxiclav, cephalosporins and quinolones?
3. How are total antibiotic prescribing and broad-spectrum prescribing associated with practice-level deprivation?
4. How does prescribing vary across ICBs and over time?

## Data Sources

- **NHS Business Services Authority (NHSBSA):** English Prescribing Dataset, August 2025 to July 2026, including prescribing information and SNOMED codes.
- **NHS England:** Patients Registered at a GP Practice, October 2025, including registered list sizes, patient distribution by LSOA and practice-to-ICB mapping.
- **Ministry of Housing, Communities and Local Government (MHCLG):** English Indices of Deprivation 2025, using deprivation scores for 2021 Lower-layer Super Output Areas (LSOAs).

Data licensing and attribution: Public sector information is licensed under the Open Government Licence v3.0 where applicable. NHSBSA copyright and attribution should follow the exact wording provided with the source dataset.

## Study Population

The primary analysis included 6,121 English GP practices.

Practice eligibility criteria:
- At least 1,000 registered patients.
- At least 10 months of prescribing data.
- Available practice-level IMD score.

Practice-level deprivation was calculated using the patient-weighted mean of LSOA deprivation scores.

## Methodology

### Data processing

- Data extraction and preparation using SQL.
- DuckDB used for initial data loading and processing.
- PostgreSQL used for relational data management and analysis.
- R used for statistical analysis and visualisation.

### Antibiotic classification

The analysis focused on BNF section 0501 antibacterials, excluding 050109 and 050110.

Broad-spectrum antibiotics included:
- Co-amoxiclav: 0501013K0.
- Cephalosporins: 0501021*.
- Quinolones: 0501120*.

### Statistical analysis

- Antibiotic prescribing rates were calculated as items per 1,000 registered patients.
- Broad-spectrum prescribing was calculated as the proportion of antibiotic items classified as broad-spectrum.
- Descriptive comparisons were conducted across IMD quintiles and ICBs.
- Negative binomial regression was used to model total antibiotic item counts, with the logarithm of registered list size included as an offset.
- Quasibinomial regression was used to examine broad-spectrum prescribing share.
- Models were reported unadjusted and adjusted for ICB using categorical fixed effects.

### Sensitivity analysis

A sensitivity analysis excluded GP practices with practice codes beginning with Y.

- Primary analysis: 6,121 practices.
- Sensitivity analysis: 5,876 practices.

The results were broadly consistent between the two analyses.

## Key Findings

1. **Monthly prescribing patterns:** Total antibiotic prescribing peaked in December 2025, at approximately 3.05 million items, before declining towards May 2026. Broad-spectrum share followed a different monthly pattern, declining towards December before increasing again.

2. **Practice-level variation:** Substantial variation was observed between GP practices and across ICBs. Total prescribing rates did not demonstrate a clear unadjusted deprivation gradient.

3. **Total antibiotic prescribing:** After adjustment for ICB, the most deprived quintile had a lower estimated prescribing rate than the least deprived quintile (RR 0.939, 95% CI 0.916–0.963).

4. **Broad-spectrum prescribing:** Broad-spectrum prescribing odds decreased progressively across increasing deprivation quintiles. The ICB-adjusted odds ratio for the most deprived quintile was 0.806 (95% CI 0.787–0.826), compared with the least deprived quintile.

5. **Sensitivity analysis:** Excluding Y-coded practices did not materially change the main findings. The adjusted Q5 rate ratio was 0.952 and the adjusted broad-spectrum odds ratio was 0.809.

## Model Diagnostics

The Poisson model showed substantial overdispersion (dispersion = 421.81), supporting the use of negative binomial regression. The negative binomial model dispersion was 1.02.

The quasibinomial model showed substantial extra-binomial variation (dispersion = 29.05; 22.00 after ICB adjustment), accounted for through the quasibinomial variance specification.

## Validation

National monthly prescribing volume and broad-spectrum share were compared with OpenPrescribing.

Data-matching checks:
- Prescribing items not matched to a registered practice: 10.03%
- Registered patients matched to an IMD score: 99.80%

## Limitations

- The analysis is ecological and uses practice-level rather than individual patient-level data.
- Models were not adjusted for practice population age structure.
- Registered list size may not perfectly represent the population actually served.
- ICB fixed effects account for average differences between ICBs but do not automatically account for all residual within-ICB correlation.
- Prescribing items do not represent individual patients, clinical indications or treatment episodes.
- Dental and Pharmacy First prescribing are not included in the source data.
- The monthly analysis covers one year and cannot establish a recurring seasonal pattern.
- Findings represent associations rather than causal effects.

## Repository Structure

- `sql/`: SQL data extraction and processing scripts.
- `r/`: R statistical analysis scripts.
- `outputs/`: Primary analysis figures and summary tables.
- `outputs_sensitivity_no_Y/`: Sensitivity analysis outputs.

## Reproducibility

The project uses the following processing stages:

1. Run SQL scripts `d01` to `d04` in DuckDB.
2. Load the exported data into PostgreSQL using `p02_load.sql`.
3. Prepare practice reference data using `p03_practice_ref.sql`.
4. Generate the practice-level analytical dataset using `p04_practice_year.sql`.
5. Run data quality checks using `p05_checks.sql`.
6. Create analytical views using `p06_views.sql`.
7. Run `r/01_analysis.R` in R.

Reproduction requires access to the original source datasets and appropriate database configuration. Raw source data and credentials are not included in this repository.

## Tools and Technologies

SQL | PostgreSQL | DuckDB | R | dplyr | ggplot2 | MASS | Epidemiology | Statistical Modelling | Data Visualisation