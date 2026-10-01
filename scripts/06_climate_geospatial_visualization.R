# ============================================================
# SkilledScore — Data Visualization Internship
# Supervisor: Dr. Zeeshan Usmani
# Intern: Usman Ali
#
# Task 2: Climate Change Impact Geospatial Analysis
# Script 06: Geospatial Climate Visualization
# ============================================================

# Purpose:
# Build professional multi-layered global climate maps using
# historical and projected climate data from 2000–2050,
# including temperature, precipitation, sea-level change,
# and temporal interactive visualization.

# ============================================================
# 1. Load Libraries and Climate Data
# ============================================================

library(tidyverse)
library(sf)
library(tmap)
library(rnaturalearth)

# Load complete historical + projected climate dataset
climate_complete <- read_csv(
  "data/processed/climate_complete_2000_2050.csv",
  show_col_types = FALSE
)

# Load world geographic boundaries
world_map <- ne_countries(
  scale = "medium",
  returnclass = "sf"
) |>
  select(
    country_map = admin,
    iso3_code = adm0_a3,
    geometry
  ) |>
  filter(
    !is.na(iso3_code),
    iso3_code != "-99"
  ) |>
  distinct(iso3_code, .keep_all = TRUE)

cat("Climate records:", nrow(climate_complete), "\n")
cat("Map entities:", nrow(world_map), "\n")
cat("Climate period:",
    min(climate_complete$year), "-",
    max(climate_complete$year), "\n")


# ============================================================
# 2. Integrate Climate Data with Geography
# ============================================================

climate_spatial <- world_map |>
  inner_join(
    climate_complete,
    by = "iso3_code"
  )

cat("Spatial climate records:",
    nrow(climate_spatial), "\n")

cat("Mapped climate entities:",
    n_distinct(climate_spatial$iso3_code), "\n")

cat("Unmatched climate entities:",
    n_distinct(climate_complete$iso3_code) -
      n_distinct(climate_spatial$iso3_code), "\n")

# ============================================================
# 3. Prepare Temperature Change Map Data (2000–2025)
# ============================================================

temperature_change_map <- climate_spatial |>
  filter(year %in% c(2000, 2025)) |>
  select(
    country,
    iso3_code,
    year,
    average_temperature_c,
    geometry
  ) |>
  pivot_wider(
    names_from = year,
    values_from = average_temperature_c,
    names_prefix = "temp_"
  ) |>
  mutate(
    temperature_change_c = temp_2025 - temp_2000
  )

cat("Temperature map entities:",
    nrow(temperature_change_map), "\n")

cat("Temperature change range:",
    round(min(temperature_change_map$temperature_change_c), 2), "to",
    round(max(temperature_change_map$temperature_change_c), 2), "°C\n")


# ============================================================
# 4. Build Temperature Change Choropleth
# ============================================================

# Use static map mode
tmap_mode("plot")

# Build global temperature change choropleth
temperature_change_map_plot <- tm_shape(temperature_change_map) +
  tm_polygons(
    fill = "temperature_change_c",
    fill.scale = tm_scale_continuous(
      values = c("#2166AC", "#F7F7F7", "#B2182B"),
      midpoint = 0
    ),
    fill.legend = tm_legend(
      title = "Temperature Change (°C)"
    ),
    col = "white",
    lwd = 0.2
  ) +
  tm_title(
    "Global Temperature Change, 2000–2025"
  ) +
  tm_layout(
    legend.outside = TRUE,
    frame = FALSE
  )

# Display map
temperature_change_map_plot

# ============================================================
# 5. Prepare Multi-Layer Climate Map Data
# ============================================================

climate_change_map <- climate_spatial |>
  filter(year %in% c(2000, 2025)) |>
  select(
    country,
    iso3_code,
    year,
    average_temperature_c,
    precipitation_mm,
    sea_level_rise_mm,
    geometry
  ) |>
  pivot_wider(
    names_from = year,
    values_from = c(
      average_temperature_c,
      precipitation_mm,
      sea_level_rise_mm
    )
  ) |>
  mutate(
    temperature_change_c =
      average_temperature_c_2025 - average_temperature_c_2000,
    
    precipitation_change_mm =
      precipitation_mm_2025 - precipitation_mm_2000,
    
    sea_level_change_mm =
      sea_level_rise_mm_2025 - sea_level_rise_mm_2000
  )

cat("Multi-layer map entities:",
    nrow(climate_change_map), "\n")

cat("Missing climate values:",
    sum(is.na(climate_change_map)), "\n")


# ============================================================
# 6. Create Map Points for Climate Overlays
# ============================================================

climate_overlay_points <- climate_change_map |>
  st_point_on_surface() |>
  mutate(
    precipitation_change_abs_mm = abs(precipitation_change_mm)
  )

cat("Overlay points:",
    nrow(climate_overlay_points), "\n")

cat("Precipitation change magnitude range:",
    round(min(climate_overlay_points$precipitation_change_abs_mm), 1),
    "to",
    round(max(climate_overlay_points$precipitation_change_abs_mm), 1),
    "mm\n")

cat("Sea-level change range:",
    round(min(climate_overlay_points$sea_level_change_mm), 1),
    "to",
    round(max(climate_overlay_points$sea_level_change_mm), 1),
    "mm\n")

# ============================================================
# 7. Build Multi-Layer Climate Map
# ============================================================

multi_layer_climate_map <- tm_shape(climate_change_map) +
  tm_polygons(
    fill = "temperature_change_c",
    fill.scale = tm_scale_continuous(
      values = c("#2166AC", "#F7F7F7", "#B2182B"),
      midpoint = 0
    ),
    fill.legend = tm_legend(
      title = "Temperature Change (°C)"
    ),
    col = "white",
    lwd = 0.2
  ) +
  tm_shape(climate_overlay_points) +
  tm_bubbles(
    size = "precipitation_change_abs_mm",
    fill = "sea_level_change_mm",
    size.scale = tm_scale_continuous(
      values.scale = 1.5
    ),
    size.legend = tm_legend(
      title = "|Precipitation Change| (mm)"
    ),
    fill.scale = tm_scale_continuous(
      values = c("#FFF7BC", "#FEC44F", "#D95F0E")
    ),
    fill.legend = tm_legend(
      title = "Sea-Level Change (mm)"
    ),
    col = "black",
    lwd = 0.3,
    fill_alpha = 0.75
  ) +
  tm_title(
    "Global Climate Change Indicators, 2000–2025"
  ) +
  tm_layout(
    legend.outside = TRUE,
    frame = FALSE
  )

multi_layer_climate_map

# ============================================================
# 8. Prepare Temporal Map Data (2000–2050)
# ============================================================

temporal_climate_map <- climate_spatial |>
  select(
    country,
    iso3_code,
    year,
    average_temperature_c,
    data_type,
    geometry
  ) |>
  arrange(year, country)

cat("Temporal map records:",
    nrow(temporal_climate_map), "\n")

cat("Temporal map entities:",
    n_distinct(temporal_climate_map$iso3_code), "\n")

cat("Temporal map years:",
    min(temporal_climate_map$year), "to",
    max(temporal_climate_map$year), "\n")

cat("Historical records:",
    sum(temporal_climate_map$data_type == "Historical"), "\n")

cat("Projected records:",
    sum(temporal_climate_map$data_type == "Projected"), "\n")


# ============================================================
# 9. Build Temporal Temperature Map (2000–2050)
# ============================================================

# Create folder for yearly animation frames
dir.create(
  "outputs/maps/temperature_frames",
  recursive = TRUE,
  showWarnings = FALSE
)

# Generate one complete world map for each year
for (yr in 2000:2050) {
  
  yearly_data <- temporal_climate_map |>
    filter(year == yr)
  
  yearly_map <- tm_shape(yearly_data) +
    tm_polygons(
      fill = "average_temperature_c",
      fill.scale = tm_scale_continuous(
        values = c("#2166AC", "#F7F7F7", "#B2182B"),
        limits = c(
          min(temporal_climate_map$average_temperature_c),
          max(temporal_climate_map$average_temperature_c)
        )
      ),
      fill.legend = tm_legend(
        title = "Average Temperature (°C)"
      ),
      col = "white",
      lwd = 0.1
    ) +
    tm_title(
      paste("Global Average Temperature —", yr)
    ) +
    tm_layout(
      legend.outside = TRUE,
      frame = FALSE
    )
  
  tmap_save(
    yearly_map,
    filename = sprintf(
      "outputs/maps/temperature_frames/temp_%04d.png",
      yr
    ),
    width = 1200,
    height = 650,
    units = "px"
  )
}

cat(
  "Temperature frames created:",
  length(list.files(
    "outputs/maps/temperature_frames",
    pattern = "\\.png$"
  )),
  "\n"
)
 

# ============================================================
# 10. Combine Temperature Frames into GIF
# ============================================================

library(magick)

frame_files <- list.files(
  "outputs/maps/temperature_frames",
  pattern = "\\.png$",
  full.names = TRUE
) |>
  sort()

temperature_gif <- image_read(frame_files) |>
  image_animate(
    fps = 2,
    loop = 0
  )

image_write(
  temperature_gif,
  path = "outputs/maps/global_temperature_2000_2050.gif"
)

cat("Animation frames combined:", length(frame_files), "\n")
cat("GIF successfully created.\n")

# ============================================================
# 11. Prepare Interactive Country Temperature Trends
# ============================================================

library(plotly)

temperature_trend_data <- climate_complete |>
  select(
    country,
    iso3_code,
    year,
    average_temperature_c,
    data_type
  ) |>
  arrange(country, year)

cat(
  "Countries available for interactive trends:",
  n_distinct(temperature_trend_data$iso3_code),
  "\n"
)

cat(
  "Trend period:",
  min(temperature_trend_data$year), "to",
  max(temperature_trend_data$year),
  "\n"
)

cat(
  "Trend records:",
  nrow(temperature_trend_data),
  "\n"
)

# ============================================================
# 12. Create Interactive Country Temperature Trend Chart
# ============================================================

interactive_temperature_trend <- plot_ly(
  data = temperature_trend_data,
  x = ~year,
  y = ~average_temperature_c,
  split = ~country,
  type = "scatter",
  mode = "lines",
  text = ~paste0(
    "Country: ", country,
    "<br>Year: ", year,
    "<br>Temperature: ",
    round(average_temperature_c, 2), " °C",
    "<br>Type: ", data_type
  ),
  hoverinfo = "text"
) |>
  layout(
    title = "Country Temperature Trends, 2000–2050",
    xaxis = list(title = "Year"),
    yaxis = list(title = "Average Temperature (°C)"),
    legend = list(title = list(text = "Country"))
  )

interactive_temperature_trend

# ============================================================
# 13. Improve Interactive Country Selection
# ============================================================

interactive_temperature_trend <- interactive_temperature_trend |>
  layout(
    title = "Country Temperature Trends, 2000–2050",
    xaxis = list(title = "Year"),
    yaxis = list(title = "Average Temperature (°C)"),
    legend = list(
      title = list(text = "Select Country"),
      itemclick = "toggle",
      itemdoubleclick = "toggleothers"
    )
  )

interactive_temperature_trend


# ============================================================
# 14. Export Interactive Temperature Trend Chart
# ============================================================

htmlwidgets::saveWidget(
  interactive_temperature_trend,
  file = "outputs/figures/interactive_country_temperature_trends.html",
  selfcontained = TRUE
)

cat("Interactive temperature trend chart exported successfully.\n")

# ============================================================
# 15. Final Visualization Audit
# ============================================================

visualization_audit <- tibble(
  check = c(
    "233 geographic entities mapped",
    "Complete period is 2000-2050",
    "Temperature change map created",
    "Multi-layer climate map created",
    "51 annual temperature frames created",
    "Temperature animation created",
    "Interactive country trend exported"
  ),
  passed = c(
    n_distinct(climate_spatial$iso3_code) == 233,
    min(climate_complete$year) == 2000 &
      max(climate_complete$year) == 2050,
    exists("temperature_change_map_plot"),
    exists("multi_layer_climate_map"),
    length(list.files(
      "outputs/maps/temperature_frames",
      pattern = "\\.png$"
    )) == 51,
    file.exists(
      "outputs/maps/global_temperature_2000_2050.gif"
    ),
    file.exists(
      "outputs/figures/interactive_country_temperature_trends.html"
    )
  )
)

print(visualization_audit)

if (all(visualization_audit$passed)) {
  cat("\nSCRIPT 06 AUDIT PASSED\n")
  cat("Geospatial and interactive climate visualizations completed successfully.\n")
} else {
  cat("\nSCRIPT 06 AUDIT FAILED — review failed checks.\n")
}


















