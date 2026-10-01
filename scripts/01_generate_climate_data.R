# ============================================================
# SkilledScore — Data Visualization Internship
# Supervisor: Dr. Zeeshan Usmani
# Intern: Usman Ali
#
# Task 2: Climate Change Impact Geospatial Analysis
# Script 01: Synthetic Climate Data Generation
# ============================================================

# Purpose:
# Generate reproducible country-level synthetic climate data
# for historical/mock observations (2000–2025) and establish
# the foundation for later projections (2026–2050).

# ============================================================
# 1. Load Required Libraries
# ============================================================

library(tidyverse)      # Data manipulation, cleaning, analysis, and visualization
library(sf)             # Spatial/geographic data handling and geospatial analysis
library(rnaturalearth)  # Provides global country boundaries and world map data

# ============================================================
# 2. Configure Reproducibility and Analysis Periods
# ============================================================

# Ensure reproducible synthetic data
set.seed(2026)

# Analysis periods
historical_years <- 2000:2025
projection_years <- 2026:2050

# ============================================================
# 3. Define Core Climate Indicators
# ============================================================

# Core climate indicators
climate_indicators <- c(
  "average_temperature_c",
  "precipitation_mm",
  "co2_emissions_mt",
  "sea_level_rise_mm"
)

# Confirm project configuration
cat("Historical period:", min(historical_years), "-", max(historical_years), "\n")
cat("Projection period:", min(projection_years), "-", max(projection_years), "\n")
cat("Number of climate indicators:", length(climate_indicators), "\n")



# ============================================================
# 4. Build Global Country Foundation
# ============================================================

# Load global country boundaries at medium map resolution
world_countries <- ne_countries(
  scale = "medium",
  returnclass = "sf"
)

# Keep valid sovereign-country identifiers required for analysis
country_reference <- world_countries |>
  st_drop_geometry() |>
  transmute(
    country = admin,
    iso3_code = adm0_a3,
    continent = continent,
    region = region_un
  ) |>
  filter(
    !is.na(iso3_code),
    iso3_code != "-99"
  ) |>
  distinct(iso3_code, .keep_all = TRUE) |>
  arrange(country)

# Validate country coverage
cat("Countries included:", nrow(country_reference), "\n")

head(country_reference, 10)

# ============================================================
# 5. Define Analytical Country Universe
# ============================================================

# Exclude non-country geographic areas from country-level analysis
analysis_countries <- country_reference |>
  filter(
    !continent %in% c("Antarctica", "Seven seas (open ocean)")
  )

# Validate geographic coverage
cat("Geographic entities retained:", nrow(analysis_countries), "\n")
cat("Continents represented:", n_distinct(analysis_countries$continent), "\n")

table(analysis_countries$continent)

# ============================================================
# 6. Create Country-Year Historical Framework
# ============================================================

# Create one record for every geographic entity and year (2000–2025)
historical_climate <- analysis_countries |>
  tidyr::crossing(year = historical_years) |>
  arrange(iso3_code, year)

# Validate expected dataset dimensions
expected_rows <- nrow(analysis_countries) * length(historical_years)

cat("Historical records created:", nrow(historical_climate), "\n")
cat("Expected records:", expected_rows, "\n")
cat("Years covered:", min(historical_climate$year), "-",
    max(historical_climate$year), "\n")

# ============================================================
# 7. Generate Country Climate Baselines
# ============================================================

# Create reproducible country-specific baseline climate characteristics
country_baselines <- analysis_countries |>
  mutate(
    baseline_temperature_c = case_when(
      continent == "Africa" ~ rnorm(n(), 24, 4),
      continent == "Asia" ~ rnorm(n(), 18, 7),
      continent == "Europe" ~ rnorm(n(), 10, 4),
      continent == "North America" ~ rnorm(n(), 16, 7),
      continent == "South America" ~ rnorm(n(), 21, 5),
      continent == "Oceania" ~ rnorm(n(), 22, 4)
    ),
    baseline_precipitation_mm = pmax(rnorm(n(), 1100, 450), 150),
    baseline_co2_emissions_mt = pmax(rlnorm(n(), log(20), 1.5), 0.1),
    baseline_sea_level_rise_mm = runif(n(), 0, 8)
  )

# Validate generated baselines
summary(
  country_baselines |>
    select(starts_with("baseline_"))
)

# ============================================================
# 8. Generate Historical Climate Observations (2000–2025)
# ============================================================

historical_climate <- historical_climate |>
  left_join(
    country_baselines |>
      select(
        iso3_code,
        starts_with("baseline_")
      ),
    by = "iso3_code"
  ) |>
  mutate(
    years_since_2000 = year - 2000,
    
    average_temperature_c =
      baseline_temperature_c +
      (0.035 * years_since_2000) +
      rnorm(n(), 0, 0.35),
    
    precipitation_mm = pmax(
      baseline_precipitation_mm +
        (1.5 * years_since_2000) +
        rnorm(n(), 0, 90),
      0
    ),
    
    co2_emissions_mt = pmax(
      baseline_co2_emissions_mt *
        (1 + 0.012 * years_since_2000) +
        rnorm(n(), 0, 3),
      0
    ),
    
    sea_level_rise_mm = pmax(
      baseline_sea_level_rise_mm +
        (3.2 * years_since_2000) +
        rnorm(n(), 0, 2),
      0
    )
  )

# Inspect generated historical indicators
summary(
  historical_climate |>
    select(
      average_temperature_c,
      precipitation_mm,
      co2_emissions_mt,
      sea_level_rise_mm
    )
)

# ============================================================
# 9. Validate Historical Data Quality
# ============================================================

# Check missing values in key analytical fields
historical_climate |>
  summarise(
    missing_temperature = sum(is.na(average_temperature_c)),
    missing_precipitation = sum(is.na(precipitation_mm)),
    missing_co2 = sum(is.na(co2_emissions_mt)),
    missing_sea_level = sum(is.na(sea_level_rise_mm))
  )

# Check duplicate country-year records
duplicate_records <- historical_climate |>
  count(iso3_code, year) |>
  filter(n > 1)

cat("Duplicate country-year records:", nrow(duplicate_records), "\n")

# Verify final dimensions
cat("Total historical records:", nrow(historical_climate), "\n")
cat("Unique geographic entities:", n_distinct(historical_climate$iso3_code), "\n")
cat("Years:", n_distinct(historical_climate$year), "\n")


# ============================================================
# 10. Detect Potential Climate Indicator Outliers
# ============================================================

# IQR-based outlier detection function
count_iqr_outliers <- function(x) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr_value <- IQR(x, na.rm = TRUE)
  
  sum(
    x < (q1 - 1.5 * iqr_value) |
      x > (q3 + 1.5 * iqr_value),
    na.rm = TRUE
  )
}

# Count potential outliers for each climate indicator
outlier_summary <- historical_climate |>
  summarise(
    temperature_outliers = count_iqr_outliers(average_temperature_c),
    precipitation_outliers = count_iqr_outliers(precipitation_mm),
    co2_outliers = count_iqr_outliers(co2_emissions_mt),
    sea_level_outliers = count_iqr_outliers(sea_level_rise_mm)
  )

outlier_summary

# ============================================================
# 11. Prepare and Export Final Historical Dataset
# ============================================================

historical_climate_final <- historical_climate |>
  select(
    country,
    iso3_code,
    continent,
    region,
    year,
    average_temperature_c,
    precipitation_mm,
    co2_emissions_mt,
    sea_level_rise_mm
  ) |>
  mutate(
    across(
      c(
        average_temperature_c,
        precipitation_mm,
        co2_emissions_mt,
        sea_level_rise_mm
      ),
      ~ round(.x, 2)
    )
  )

# Export reproducible historical dataset
write_csv(
  historical_climate_final,
  "data/raw/synthetic_climate_historical_2000_2025.csv"
)

cat("Historical dataset exported successfully.\n")
cat("Final rows:", nrow(historical_climate_final), "\n")
cat("Final columns:", ncol(historical_climate_final), "\n")

# ============================================================
# 12. Final Historical Dataset Generation Audit
# ============================================================

stopifnot(
  nrow(historical_climate_final) == expected_rows,
  n_distinct(historical_climate_final$iso3_code) == 233,
  min(historical_climate_final$year) == 2000,
  max(historical_climate_final$year) == 2025,
  sum(is.na(historical_climate_final)) == 0
)

cat("SCRIPT 01 AUDIT PASSED\n")
cat("Historical climate dataset is ready for downstream analysis.\n")






















