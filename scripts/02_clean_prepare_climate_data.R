# ============================================================
# SkilledScore — Data Visualization Internship
# Supervisor: Dr. Zeeshan Usmani
# Intern: Usman Ali
#
# Task 2: Climate Change Impact Geospatial Analysis
# Script 02: Climate Data Cleaning and Preparation
# ============================================================

# Purpose:
# Load, inspect, clean, aggregate, and prepare the synthetic
# historical climate dataset for analysis, predictive modeling,
# and integration with global geographic boundaries.

# ============================================================
# 1. Load Required Library and Historical Dataset
# ============================================================

library(tidyverse)                       # Data cleaning, transformation, validation, and analysis

# Load the historical synthetic climate dataset created in Script 01
climate_raw <- read_csv(
  "data/raw/synthetic_climate_historical_2000_2025.csv",
  show_col_types = FALSE
)

# Confirm successful import
cat("Rows loaded:", nrow(climate_raw), "\n")
cat("Columns loaded:", ncol(climate_raw), "\n")

glimpse(climate_raw)

# ============================================================
# 2. Inspect Data Quality
# ============================================================

# Check missing values in every column
colSums(is.na(climate_raw))

# Check duplicate country-year records
climate_raw |>
  count(iso3_code, year) |>
  filter(n > 1)

# Inspect numerical distributions and ranges
climate_raw |>
  select(
    year,
    average_temperature_c,
    precipitation_mm,
    co2_emissions_mt,
    sea_level_rise_mm
  ) |>
  summary()

# ============================================================
# 3. Apply Data Cleaning Rules
# ============================================================

climate_clean <- climate_raw |>
  distinct(iso3_code, year, .keep_all = TRUE) |>
  filter(
    !is.na(country),
    !is.na(iso3_code),
    between(year, 2000, 2025)
  ) |>
  mutate(
    country = str_squish(country),
    iso3_code = str_to_upper(str_squish(iso3_code)),
    continent = str_squish(continent),
    region = str_squish(region)
  ) |>
  arrange(country, year)

# Verify cleaning did not unintentionally remove valid records
cat("Rows before cleaning:", nrow(climate_raw), "\n")
cat("Rows after cleaning:", nrow(climate_clean), "\n")


# ============================================================
# 4. Validate Climate Indicator Ranges
# ============================================================

range_validation <- climate_clean |>
  summarise(
    invalid_temperature = sum(
      average_temperature_c < -60 | average_temperature_c > 60
    ),
    invalid_precipitation = sum(precipitation_mm < 0),
    invalid_co2 = sum(co2_emissions_mt < 0),
    invalid_sea_level = sum(sea_level_rise_mm < 0)
  )

range_validation

# ============================================================
# 5. Flag and Document Potential Outliers
# ============================================================

# Function to flag values outside the standard 1.5 × IQR range
flag_iqr_outlier <- function(x) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr_value <- IQR(x, na.rm = TRUE)
  
  x < (q1 - 1.5 * iqr_value) |
    x > (q3 + 1.5 * iqr_value)
}

climate_clean <- climate_clean |>
  mutate(
    temperature_outlier = flag_iqr_outlier(average_temperature_c),
    precipitation_outlier = flag_iqr_outlier(precipitation_mm),
    co2_outlier = flag_iqr_outlier(co2_emissions_mt),
    sea_level_outlier = flag_iqr_outlier(sea_level_rise_mm)
  )

# Review number of flagged observations
climate_clean |>
  summarise(
    temperature_flags = sum(temperature_outlier),
    precipitation_flags = sum(precipitation_outlier),
    co2_flags = sum(co2_outlier),
    sea_level_flags = sum(sea_level_outlier)
  )

# ============================================================
# 6. Create Country-Level Climate Summary
# ============================================================

country_climate_summary <- climate_clean |>
  group_by(country, iso3_code, continent, region) |>
  summarise(
    avg_temperature_c = mean(average_temperature_c),
    avg_precipitation_mm = mean(precipitation_mm),
    avg_co2_emissions_mt = mean(co2_emissions_mt),
    avg_sea_level_rise_mm = mean(sea_level_rise_mm),
    .groups = "drop"
  )

# Validate country-level aggregation
cat("Countries/geographic entities summarized:",
    nrow(country_climate_summary), "\n")

head(country_climate_summary)

# ============================================================
# 7. Export Cleaned and Aggregated Climate Data
# ============================================================

# Save cleaned country-year dataset
write_csv(
  climate_clean,
  "data/processed/climate_historical_clean.csv"
)

# Save country-level aggregated dataset
write_csv(
  country_climate_summary,
  "data/processed/country_climate_summary_2000_2025.csv"
)

cat("Processed datasets exported successfully.\n")
cat("Clean dataset rows:", nrow(climate_clean), "\n")
cat("Country summary rows:", nrow(country_climate_summary), "\n")

# ============================================================
# 8. Final Cleaning and Preparation Audit
# ============================================================

stopifnot(
  nrow(climate_clean) == 6058,
  nrow(country_climate_summary) == 233,
  sum(is.na(climate_clean)) == 0,
  n_distinct(climate_clean$iso3_code) == 233,
  min(climate_clean$year) == 2000,
  max(climate_clean$year) == 2025
)

cat("SCRIPT 02 AUDIT PASSED\n")
cat("Climate data is ready for geographic integration and analysis.\n")




















