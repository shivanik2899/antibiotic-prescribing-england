# ==============================================================================
# Antibiotic Prescribing in English General Practice
# Analysis period: August 2025 – July 2026
#
# Purpose:
# This script analyses practice-level antibiotic prescribing data in England.
# It produces descriptive summaries, regression models, diagnostic checks
# and visualisations to examine variation in prescribing across deprivation
# quintiles and Integrated Care Boards (ICBs).
#
# Data inputs:
# The script retrieves prepared analytical datasets from a local PostgreSQL
# database:
#   - v_practice_rank: practice-level prescribing and deprivation data
#   - v_monthly_national: monthly national prescribing totals
#   - v_icb_summary: prescribing summaries by ICB
#
# Analysis:
#   1. Descriptive summaries by deprivation quintile
#   2. Negative binomial regression for antibiotic prescribing rates
#   3. Quasibinomial regression for broad-spectrum prescribing share
#   4. Model diagnostics and sensitivity analysis
#   5. Figures and CSV outputs
#
# Before running:
#   1. Set the working directory to the project folder.
#   2. Set the PostgreSQL password in the R Console:
#      Sys.setenv(PGPASSWORD = 'your-password')
#
# Sensitivity analysis:
# Set exclude_y to TRUE to exclude practices whose codes start with Y.
# Outputs are saved to outputs_sensitivity_no_Y/ rather than outputs/.
#
# ============================================================================== 

library(DBI)
library(RPostgres)
library(dplyr)
library(ggplot2)

# Set to TRUE to repeat the whole analysis without practice codes that start with Y.
# Results then go to the folder outputs_sensitivity_no_Y instead of outputs.
exclude_y <- FALSE
out_dir <- if (exclude_y) 'outputs_sensitivity_no_Y' else 'outputs'
out <- function(file) file.path(out_dir, file)

if (!dir.exists('sql')) stop('Set the working directory to the project folder first.')
if (Sys.getenv('PGPASSWORD') == '') stop('Type Sys.setenv(PGPASSWORD = ...) in the Console first.')
dir.create(out_dir, showWarnings = FALSE)

# 1. Read the data from PostgreSQL --------------------------------------------
con <- dbConnect(Postgres(), dbname = 'antibiotic', host = 'localhost', port = 5432,
                 user = 'postgres', password = Sys.getenv('PGPASSWORD'), bigint = 'numeric')
py  <- dbGetQuery(con, 'SELECT * FROM v_practice_rank')
mon <- dbGetQuery(con, 'SELECT * FROM v_monthly_national ORDER BY year_month')
icb <- dbGetQuery(con, 'SELECT * FROM v_icb_summary')
dbDisconnect(con)

if (exclude_y) {
  py <- py[!startsWith(py$practice_code, 'Y'), ]
  icb <- py |>
    group_by(icb_name) |>
    summarise(practices = n(),
              abx_per_1000 = sum(abx_items) / sum(list_size) * 1000,
              .groups = 'drop')
  cat('Sensitivity analysis: codes starting with Y excluded\n')
}

py$imd_quintile <- factor(py$imd_quintile, levels = 1:5,
                          labels = c('Q1 least deprived', 'Q2', 'Q3', 'Q4', 'Q5 most deprived'))
py$icb_name <- factor(py$icb_name)
cat('Practices analysed:', nrow(py), '\n')

# 2. Summary by deprivation group ---------------------------------------------
# mean_items_per_1000 = average of the practice rates (each practice counts once)
# weighted_rate_per_1000 = all items / all registered patients (big practices count more)
by_q <- py |>
  group_by(imd_quintile) |>
  summarise(practices = n(),
            patients = sum(list_size),
            mean_imd = mean(imd_score_w),
            mean_items_per_1000 = mean(abx_per_1000),
            weighted_rate_per_1000 = sum(abx_items) / sum(list_size) * 1000,
            median_broad_pct = median(broad_pct),
            weighted_broad_pct = sum(broad_items) / sum(abx_items) * 100,
            .groups = 'drop')
print(as.data.frame(by_q))
write.csv(by_q, out('summary_by_quintile.csv'), row.names = FALSE)

# 3. Models -------------------------------------------------------------------
# Model 1: antibiotic items per registered patient (negative binomial, log list size offset)
m_rate     <- MASS::glm.nb(abx_items ~ imd_quintile + offset(log(list_size)), data = py)
m_rate_adj <- MASS::glm.nb(abx_items ~ imd_quintile + icb_name + offset(log(list_size)), data = py)

# Model 2: share of items that are broad-spectrum (quasibinomial)
m_broad     <- glm(cbind(broad_items, abx_items - broad_items) ~ imd_quintile,
                   family = quasibinomial, data = py)
m_broad_adj <- glm(cbind(broad_items, abx_items - broad_items) ~ imd_quintile + icb_name,
                   family = quasibinomial, data = py)

# Ratios with 95% confidence intervals for the deprivation terms only
get_ratios <- function(model, measure, adjustment) {
  est <- coef(model)
  ci  <- confint.default(model)
  p   <- summary(model)$coefficients[, 4]
  keep <- grepl('imd_quintile', names(est))
  data.frame(measure = measure, adjustment = adjustment,
             group = sub('imd_quintile', '', names(est)[keep]),
             ratio = exp(est[keep]), conf.low = exp(ci[keep, 1]), conf.high = exp(ci[keep, 2]),
             p.value = p[keep], row.names = NULL)
}
results <- rbind(
  get_ratios(m_rate,      'Rate ratio (items per patient)',  'Unadjusted'),
  get_ratios(m_rate_adj,  'Rate ratio (items per patient)',  'Adjusted for ICB'),
  get_ratios(m_broad,     'Odds ratio (broad-spectrum share)', 'Unadjusted'),
  get_ratios(m_broad_adj, 'Odds ratio (broad-spectrum share)', 'Adjusted for ICB'))
print(results, digits = 3)
write.csv(results, out('model_results.csv'), row.names = FALSE)

# 4. Do the models fit the data? ----------------------------------------------
# A dispersion value near 1 means the model's assumed spread matches the data.
m_pois <- glm(abx_items ~ imd_quintile + offset(log(list_size)), family = poisson, data = py)
checks <- data.frame(
  check = c('Poisson dispersion (items)', 'Negative binomial dispersion (items)',
            'Negative binomial theta', 'Quasibinomial dispersion (broad share)',
            'Quasibinomial dispersion, ICB-adjusted'),
  value = c(sum(residuals(m_pois, 'pearson')^2) / df.residual(m_pois),
            sum(residuals(m_rate, 'pearson')^2) / df.residual(m_rate),
            m_rate$theta,
            summary(m_broad)$dispersion,
            summary(m_broad_adj)$dispersion))
print(checks, digits = 3)
write.csv(checks, out('model_checks.csv'), row.names = FALSE)
# Reading: Poisson dispersion far above 1 means the counts vary more than Poisson allows,
# which is why the negative binomial is used. A quasibinomial dispersion above 1 means
# a plain binomial would understate uncertainty, which is why the quasi version is used.

# 5. Figures ------------------------------------------------------------------
mon$month <- as.Date(paste0(mon$year_month, '01'), format = '%Y%m%d')
mon$broad_pct <- 100 * mon$broad_items / mon$abx_items

p1 <- ggplot(mon, aes(month, abx_items)) + geom_line() + geom_point() +
  labs(x = NULL, y = 'Antibiotic items', title = 'Antibiotic items prescribed in English general practice')
ggsave(out('fig1_monthly_items.png'), p1, width = 8, height = 4.5, dpi = 300)

p1b <- ggplot(mon, aes(month, broad_pct)) + geom_line() + geom_point() +
  labs(x = NULL, y = 'Broad-spectrum share of items (%)')
ggsave(out('fig1b_monthly_broad_share.png'), p1b, width = 8, height = 4.5, dpi = 300)

p2 <- ggplot(py, aes(imd_quintile, abx_per_1000)) + geom_boxplot(outlier.alpha = 0.3) +
  coord_cartesian(ylim = c(0, 1000)) +
  labs(x = NULL, y = 'Items per 1,000 registered patients',
       caption = 'The y-axis stops at 1,000; a small number of practices are higher')
ggsave(out('fig2_rate_by_quintile.png'), p2, width = 8, height = 4.5, dpi = 300)

p0 <- sum(py$broad_items) / sum(py$abx_items) * 100
p3 <- ggplot(py, aes(abx_items, broad_pct)) +
  geom_point(alpha = 0.3, size = 1) +
  geom_hline(yintercept = p0, linetype = 'dashed') +
  scale_x_log10() +
  labs(x = 'Antibiotic items per practice (log scale)', y = 'Broad-spectrum share (%)',
       caption = 'Dashed line: national share')
ggsave(out('fig3_practice_variation.png'), p3, width = 8, height = 5, dpi = 300)

p4 <- ggplot(icb, aes(abx_per_1000, reorder(icb_name, abx_per_1000))) + geom_point() +
  labs(x = 'Items per 1,000 registered patients', y = NULL)
ggsave(out('fig4_icb.png'), p4, width = 8, height = 9, dpi = 300)

plot_ratios <- function(measure_name, xlab, file) {
  d <- results[results$measure == measure_name, ]
  d$group <- factor(d$group, levels = rev(unique(d$group)))
  p <- ggplot(d, aes(ratio, group, colour = adjustment)) +
    geom_vline(xintercept = 1, linetype = 'dashed') +
    geom_pointrange(aes(xmin = conf.low, xmax = conf.high), position = position_dodge(width = 0.5)) +
    labs(x = xlab, y = 'Compared with Q1 least deprived', colour = NULL)
  ggsave(file, p, width = 8, height = 4.5, dpi = 300)
}
plot_ratios('Rate ratio (items per patient)', 'Rate ratio (95% CI)', out('fig5_rate_ratios.png'))
plot_ratios('Odds ratio (broad-spectrum share)', 'Odds ratio (95% CI)', out('fig6_odds_ratios.png'))

cat('Done. Results and figures are in the', out_dir, 'folder.\n')
