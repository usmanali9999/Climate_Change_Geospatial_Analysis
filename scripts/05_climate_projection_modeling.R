# ============================================================
# SkilledScore — Data Visualization Internship
# Supervisor: Dr. Zeeshan Usmani
# Intern: Usman Ali
#
# Task 2: Climate Change Impact Geospatial Analysis
# Script 05: Climate Projection Modeling
# ============================================================

# Purpose:
# Build country-level linear models from historical synthetic
# climate data (2000–2025) and generate modeled projections
# for climate indicators from 2026 through 2050.
#
# Important:
# These projections are synthetic scenario estimates produced
# for analytical demonstration and are not authoritative
# real-world climate forecasts.

# ============================================================
# 1. Load Libraries and Historical Modeling Data
# ============================================================

library(tidyverse)
library(broom)

# Load cleaned historical climate dataset
climate_historical <- read_csv(
  "data/processed/climate_historical_clean.csv",
  show_col_types = FALSE
)

# Confirm modeling foundation
cat("Historical records:", nrow(climate_historical), "\n")
cat("Geographic entities:",
    n_distinct(climate_historical$iso3_code), "\n")
cat("Model training period:",
    min(climate_historical$year), "-",
    max(climate_historical$year), "\n")

# ============================================================
# 2. Define Projection Period
# ============================================================

projection_years <- tibble(
  year = 2026:2050
)

cat("Projection start:", min(projection_years$year), "\n")
cat("Projection end:", max(projection_years$year), "\n")
cat("Projection years:", nrow(projection_years), "\n")

# ============================================================
# 3. Build Country-Level Temperature Models
# ============================================================

temperature_models <- climate_historical |>
  group_by(country, iso3_code, continent, region) |>
  nest() |>
  mutate(
    model = map(
      data,
      ~ lm(average_temperature_c ~ year, data = .x)
    )
  )

cat("Temperature models created:",
    nrow(temperature_models), "\n")

cat("Expected models:",
    n_distinct(climate_historical$iso3_code), "\n")

# ============================================================
# 4. Generate Temperature Projections (2026–2050)
# ============================================================

temperature_projections <- temperature_models |>
  mutate(
    predictions = map(
      model,
      ~ predict(
        .x,
        newdata = projection_years,
        interval = "prediction",
        level = 0.95
      ) |>
        as_tibble() |>
        bind_cols(projection_years)
    )
  ) |>
  select(country, iso3_code, continent, region, predictions) |>
  unnest(predictions) |>
  rename(
    average_temperature_c = fit,
    temperature_lower_95 = lwr,
    temperature_upper_95 = upr
  )

cat("Temperature projection records:",
    nrow(temperature_projections), "\n")

cat("Expected records:",
    233 * 25, "\n")

# ============================================================
# 5. Build Remaining Climate Indicator Models
# ============================================================

climate_models <- climate_historical |>
  group_by(country, iso3_code, continent, region) |>
  nest() |>
  mutate(
    precipitation_model = map(
      data,
      ~ lm(precipitation_mm ~ year, data = .x)
    ),
    co2_model = map(
      data,
      ~ lm(co2_emissions_mt ~ year, data = .x)
    ),
    sea_level_model = map(
      data,
      ~ lm(sea_level_rise_mm ~ year, data = .x)
    )
  )

cat("Country model sets created:",
    nrow(climate_models), "\n")

cat("Models per entity: 3\n")
cat("Total models:", nrow(climate_models) * 3, "\n")

# ============================================================
# 6. Generate Remaining Climate Projections (2026–2050)
# ============================================================

climate_projections <- climate_models |>
  mutate(
    predictions = pmap(
      list(precipitation_model, co2_model, sea_level_model),
      function(precip_model, co2_model, sea_model) {
        
        tibble(
          year = projection_years$year,
          precipitation_mm = predict(
            precip_model, newdata = projection_years
          ),
          co2_emissions_mt = predict(
            co2_model, newdata = projection_years
          ),
          sea_level_rise_mm = predict(
            sea_model, newdata = projection_years
          )
        )
      }
    )
  ) |>
  select(country, iso3_code, continent, region, predictions) |>
  unnest(predictions)

cat("Climate projection records:",
    nrow(climate_projections), "\n")

cat("Expected records:", 233 * 25, "\n")

# ============================================================
# 7. Combine All Future Climate Projections
# ============================================================

future_climate <- temperature_projections |>
  left_join(
    climate_projections,
    by = c(
      "country",
      "iso3_code",
      "continent",
      "region",
      "year"
    )
  ) |>
  mutate(
    data_type = "Projected"
  ) |>
  arrange(iso3_code, year)

cat("Combined future records:",
    nrow(future_climate), "\n")

cat("Missing values:",
    sum(is.na(future_climate)), "\n")

cat("Projection period:",
    min(future_climate$year), "-",
    max(future_climate$year), "\n")


# ============================================================
# 8. Combine Historical and Projected Climate Data
# ============================================================

historical_for_combination <- climate_historical |>
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
    temperature_lower_95 = NA_real_,
    temperature_upper_95 = NA_real_,
    data_type = "Historical"
  )

climate_2000_2050 <- bind_rows(
  historical_for_combination,
  future_climate
) |>
  arrange(iso3_code, year)

cat("Total records:", nrow(climate_2000_2050), "\n")
cat("Geographic entities:",
    n_distinct(climate_2000_2050$iso3_code), "\n")
cat("Full period:",
    min(climate_2000_2050$year), "-",
    max(climate_2000_2050$year), "\n")

print(table(climate_2000_2050$data_type))


# ============================================================
# 9. Validate Projection Plausibility
# ============================================================

projection_validation <- future_climate |>
  summarise(
    min_temperature_c = min(average_temperature_c),
    max_temperature_c = max(average_temperature_c),
    min_precipitation_mm = min(precipitation_mm),
    min_co2_emissions_mt = min(co2_emissions_mt),
    min_sea_level_rise_mm = min(sea_level_rise_mm)
  )

print(projection_validation)

cat("Negative precipitation projections:",
    sum(future_climate$precipitation_mm < 0), "\n")

cat("Negative CO2 projections:",
    sum(future_climate$co2_emissions_mt < 0), "\n")

cat("Negative sea-level projections:",
    sum(future_climate$sea_level_rise_mm < 0), "\n")

# ============================================================
# 10. Correct Implausible Projection Values
# ============================================================

future_climate <- future_climate |>
  mutate(
    precipitation_mm = pmax(precipitation_mm, 0),
    co2_emissions_mt = pmax(co2_emissions_mt, 0),
    sea_level_rise_mm = pmax(sea_level_rise_mm, 0)
  )

# Rebuild combined dataset using corrected projections
climate_2000_2050 <- bind_rows(
  historical_for_combination,
  future_climate
) |>
  arrange(iso3_code, year)

# Confirm corrections
cat("Negative precipitation projections:",
    sum(future_climate$precipitation_mm < 0), "\n")

cat("Negative CO2 projections:",
    sum(future_climate$co2_emissions_mt < 0), "\n")

cat("Negative sea-level projections:",
    sum(future_climate$sea_level_rise_mm < 0), "\n")


# ============================================================
# 11. Export Climate Projection Datasets
# ============================================================

write_csv(
  future_climate,
  "data/processed/climate_projections_2026_2050.csv"
)

write_csv(
  climate_2000_2050,
  "data/processed/climate_complete_2000_2050.csv"
)

cat("Projection datasets exported successfully.\n")
cat("Future records:", nrow(future_climate), "\n")
cat("Complete 2000-2050 records:", nrow(climate_2000_2050), "\n")

# ============================================================
# 12. Final Projection Modeling Audit
# ============================================================

stopifnot(
  nrow(future_climate) == 5825,
  nrow(climate_2000_2050) == 11883,
  n_distinct(climate_2000_2050$iso3_code) == 233,
  min(climate_2000_2050$year) == 2000,
  max(climate_2000_2050$year) == 2050,
  sum(is.na(future_climate)) == 0,
  all(future_climate$precipitation_mm >= 0),
  all(future_climate$co2_emissions_mt >= 0),
  all(future_climate$sea_level_rise_mm >= 0)
)

cat("SCRIPT 05 AUDIT PASSED\n")
cat("Climate projections for 2026-2050 completed successfully.\n")
































































































