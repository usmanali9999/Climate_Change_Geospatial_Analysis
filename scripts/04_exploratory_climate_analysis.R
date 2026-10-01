# ============================================================
# SkilledScore — Data Visualization Internship
# Supervisor: Dr. Zeeshan Usmani
# Intern: Usman Ali
#
# Task 2: Climate Change Impact Geospatial Analysis
# Script 04: Exploratory Climate Analysis
# ============================================================

# Purpose:
# Explore historical climate patterns from 2000–2025,
# quantify global and regional trends, examine relationships
# among climate indicators, and generate analytical evidence
# for subsequent predictive and geospatial modeling.

# ============================================================
# 1. Load Libraries and Historical Climate Data
# ============================================================

library(tidyverse)  # Data analysis, aggregation, and visualization
library(scales)     # Professional axis and number formatting

# Load cleaned historical country-year dataset
climate_data <- read_csv(
  "data/processed/climate_historical_clean.csv",
  show_col_types = FALSE
)

# Confirm analytical dataset
cat("Records loaded:", nrow(climate_data), "\n")
cat("Countries/entities:", n_distinct(climate_data$iso3_code), "\n")
cat("Historical period:",
    min(climate_data$year), "-",
    max(climate_data$year), "\n")

# ============================================================
# 2. Calculate Annual Global Climate Trends
# ============================================================

global_annual_trends <- climate_data |>
  group_by(year) |>
  summarise(
    avg_temperature_c = mean(average_temperature_c),
    avg_precipitation_mm = mean(precipitation_mm),
    avg_co2_emissions_mt = mean(co2_emissions_mt),
    avg_sea_level_rise_mm = mean(sea_level_rise_mm),
    .groups = "drop"
  )

# Inspect beginning and end of historical trend
cat("Annual observations:", nrow(global_annual_trends), "\n")
print(head(global_annual_trends, 3))
print(tail(global_annual_trends, 3))


# ============================================================
# 3. Quantify Historical Climate Changes
# ============================================================

historical_change <- global_annual_trends |>
  summarise(
    temperature_change_c =
      last(avg_temperature_c) - first(avg_temperature_c),
    
    precipitation_change_mm =
      last(avg_precipitation_mm) - first(avg_precipitation_mm),
    
    co2_change_mt =
      last(avg_co2_emissions_mt) - first(avg_co2_emissions_mt),
    
    sea_level_change_mm =
      last(avg_sea_level_rise_mm) - first(avg_sea_level_rise_mm)
  )

print(historical_change)


# ============================================================
# 4. Calculate Regional Climate Trends
# ============================================================

regional_climate_summary <- climate_data |>
  group_by(continent) |>
  summarise(
    avg_temperature_c = mean(average_temperature_c),
    avg_precipitation_mm = mean(precipitation_mm),
    avg_co2_emissions_mt = mean(co2_emissions_mt),
    avg_sea_level_rise_mm = mean(sea_level_rise_mm),
    .groups = "drop"
  ) |>
  arrange(desc(avg_temperature_c))

print(regional_climate_summary)


# ============================================================
# 5. Calculate Country-Level Temperature Change
# ============================================================

country_temperature_change <- climate_data |>
  filter(year %in% c(2000, 2025)) |>
  select(country, iso3_code, year, average_temperature_c) |>
  pivot_wider(
    names_from = year,
    values_from = average_temperature_c,
    names_prefix = "temp_"
  ) |>
  mutate(
    temperature_change_c = temp_2025 - temp_2000
  ) |>
  arrange(desc(temperature_change_c))

cat("Countries/entities analyzed:",
    nrow(country_temperature_change), "\n")

print(head(country_temperature_change, 10))

# ============================================================
# 6. Calculate Country-Level Sea-Level Change
# ============================================================

country_sea_level_change <- climate_data |>
  filter(year %in% c(2000, 2025)) |>
  select(country, iso3_code, year, sea_level_rise_mm) |>
  pivot_wider(
    names_from = year,
    values_from = sea_level_rise_mm,
    names_prefix = "sea_level_"
  ) |>
  mutate(
    sea_level_change_mm = sea_level_2025 - sea_level_2000
  ) |>
  arrange(desc(sea_level_change_mm))

cat("Countries/entities analyzed:",
    nrow(country_sea_level_change), "\n")

print(head(country_sea_level_change, 10))

# ============================================================
# 7. Analyze CO2–Climate Relationships
# ============================================================

climate_correlations <- climate_data |>
  summarise(
    co2_temperature_correlation =
      cor(co2_emissions_mt, average_temperature_c),
    
    co2_precipitation_correlation =
      cor(co2_emissions_mt, precipitation_mm),
    
    co2_sea_level_correlation =
      cor(co2_emissions_mt, sea_level_rise_mm)
  )

print(climate_correlations)

# ============================================================
# 8. Calculate Country-Level Precipitation Change
# ============================================================

country_precipitation_change <- climate_data |>
  filter(year %in% c(2000, 2025)) |>
  select(country, iso3_code, year, precipitation_mm) |>
  pivot_wider(
    names_from = year,
    values_from = precipitation_mm,
    names_prefix = "precip_"
  ) |>
  mutate(
    precipitation_change_mm = precip_2025 - precip_2000
  ) |>
  arrange(desc(abs(precipitation_change_mm)))

cat("Countries/entities analyzed:",
    nrow(country_precipitation_change), "\n")

print(head(country_precipitation_change, 10))

# ============================================================
# 9. Create Country-Level Climate Change Summary
# ============================================================

country_change_summary <- country_temperature_change |>
  select(country, iso3_code, temperature_change_c) |>
  left_join(
    country_precipitation_change |>
      select(iso3_code, precipitation_change_mm),
    by = "iso3_code"
  ) |>
  left_join(
    country_sea_level_change |>
      select(iso3_code, sea_level_change_mm),
    by = "iso3_code"
  )

cat("Country change records:",
    nrow(country_change_summary), "\n")

cat("Missing values:",
    sum(is.na(country_change_summary)), "\n")

print(head(country_change_summary))

# ============================================================
# 10. Export Exploratory Analysis Tables
# ============================================================

write_csv(
  global_annual_trends,
  "outputs/tables/global_annual_climate_trends_2000_2025.csv"
)

write_csv(
  regional_climate_summary,
  "outputs/tables/regional_climate_summary_2000_2025.csv"
)

write_csv(
  country_change_summary,
  "outputs/tables/country_climate_change_2000_2025.csv"
)

cat("EDA analytical tables exported successfully.\n")
cat("Country change records:", nrow(country_change_summary), "\n")


# ============================================================
# 11. Final Exploratory Analysis Audit
# ============================================================

stopifnot(
  nrow(global_annual_trends) == 26,
  nrow(regional_climate_summary) == 6,
  nrow(country_temperature_change) == 233,
  nrow(country_precipitation_change) == 233,
  nrow(country_sea_level_change) == 233,
  nrow(country_change_summary) == 233,
  sum(is.na(country_change_summary)) == 0
)

cat("SCRIPT 04 AUDIT PASSED\n")
cat("Historical climate EDA completed successfully.\n")






























