# ============================================================
# SkilledScore — Data Visualization Internship
# Supervisor: Dr. Zeeshan Usmani
# Intern: Usman Ali
#
# Task 2: Climate Change Impact Geospatial Analysis
# Script 03: Geographic Data Integration
# ============================================================

# Purpose:
# Integrate the prepared climate datasets with global geographic
# boundaries, validate spatial joins, and prepare country-level
# spatial data for geospatial analysis and visualization.

# ============================================================
# 1. Load Libraries and Prepared Climate Data
# ============================================================

library(tidyverse)      # Data manipulation and validation
library(sf)             # Spatial data processing
library(rnaturalearth)  # Global country boundary data

# Load processed climate datasets from Script 02
climate_clean <- read_csv(
  "data/processed/climate_historical_clean.csv",
  show_col_types = FALSE
)

country_climate_summary <- read_csv(
  "data/processed/country_climate_summary_2000_2025.csv",
  show_col_types = FALSE
)

# Confirm successful import
cat("Country-year records:", nrow(climate_clean), "\n")
cat("Country summaries:", nrow(country_climate_summary), "\n")


# ============================================================
# 2. Load Global Geographic Boundaries
# ============================================================

# Load Natural Earth country polygons as an sf spatial object
world_map <- ne_countries(
  scale = "medium",
  returnclass = "sf"
)

# Inspect spatial structure
cat("Geographic features loaded:", nrow(world_map), "\n")
cat("Coordinate reference system:", st_crs(world_map)$input, "\n")

# Check geometry types
table(st_geometry_type(world_map))

# ============================================================
# 3. Prepare Geographic Join Key
# ============================================================

# Retain map identifiers needed for climate-data integration
world_map_clean <- world_map |>
  select(
    map_country = admin,
    iso3_code = adm0_a3,
    geometry
  ) |>
  filter(
    !is.na(iso3_code),
    iso3_code != "-99"
  ) |>
  distinct(iso3_code, .keep_all = TRUE)

# Validate geographic identifiers
cat("Map entities available for joining:", nrow(world_map_clean), "\n")
cat("Duplicate ISO3 codes:",
    sum(duplicated(world_map_clean$iso3_code)), "\n")

# ============================================================
# 4. Join Climate Data to World Geography
# ============================================================

# Join 2000–2025 country climate summaries to map polygons
climate_map_summary <- world_map_clean |>
  inner_join(
    country_climate_summary,
    by = "iso3_code"
  )

# Validate spatial join
cat("Climate entities before join:",
    nrow(country_climate_summary), "\n")

cat("Successfully mapped entities:",
    nrow(climate_map_summary), "\n")

cat("Unmatched climate entities:",
    nrow(country_climate_summary) - nrow(climate_map_summary), "\n")

# ============================================================
# 5. Validate Spatial Geometry
# ============================================================

# Check whether all joined country geometries are valid
geometry_validation <- climate_map_summary |>
  mutate(geometry_valid = st_is_valid(geometry))

cat("Valid geometries:",
    sum(geometry_validation$geometry_valid), "\n")

cat("Invalid geometries:",
    sum(!geometry_validation$geometry_valid), "\n")

cat("Missing geometries:",
    sum(st_is_empty(climate_map_summary)), "\n")

# ============================================================
# 6. Create Country-Year Spatial Climate Dataset
# ============================================================

# Attach country polygons to every historical country-year record
climate_map_historical <- world_map_clean |>
  inner_join(
    climate_clean,
    by = "iso3_code"
  )

# Validate spatial time-series structure
cat("Spatial country-year records:",
    nrow(climate_map_historical), "\n")

cat("Geographic entities:",
    n_distinct(climate_map_historical$iso3_code), "\n")

cat("Years covered:",
    min(climate_map_historical$year), "-",
    max(climate_map_historical$year), "\n")

# ============================================================
# 7. Export Integrated Spatial Climate Datasets
# ============================================================

# Save country-level spatial summary
st_write(
  climate_map_summary,
  "data/processed/climate_map_summary_2000_2025.gpkg",
  delete_dsn = TRUE,
  quiet = TRUE
)

# Save historical country-year spatial dataset
st_write(
  climate_map_historical,
  "data/processed/climate_map_historical_2000_2025.gpkg",
  delete_dsn = TRUE,
  quiet = TRUE
)

cat("Spatial datasets exported successfully.\n")
cat("Summary spatial entities:", nrow(climate_map_summary), "\n")
cat("Historical spatial records:", nrow(climate_map_historical), "\n")

# ============================================================
# 8. Final Geospatial Integration Audit
# ============================================================

stopifnot(
  inherits(climate_map_summary, "sf"),
  inherits(climate_map_historical, "sf"),
  nrow(climate_map_summary) == 233,
  nrow(climate_map_historical) == 6058,
  all(st_is_valid(climate_map_summary)),
  !any(st_is_empty(climate_map_summary)),
  n_distinct(climate_map_historical$iso3_code) == 233,
  min(climate_map_historical$year) == 2000,
  max(climate_map_historical$year) == 2025
)

cat("SCRIPT 03 AUDIT PASSED\n")
cat("Climate data is fully integrated with global geography.\n")

































