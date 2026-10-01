# Climate Change Impact Geospatial Analysis

## Project Objective

Develop an interactive, multi-layered global climate analytics solution that evaluates country-level climate trends from 2000–2025 and models projected indicator trends from 2026–2050 using synthetic data.

The analysis integrates average temperature, precipitation, CO₂ emissions, and sea-level rise with geographic data to identify spatial and temporal climate patterns, examine relationships between emissions and climate impacts, and prioritize countries exhibiting greater modeled climate vulnerability.

## Environmental Problem

Climate impacts vary substantially across countries and evolve over time. Decision-makers therefore need analytical tools that combine multiple climate indicators with geographic and temporal context rather than evaluating individual metrics in isolation.

This project addresses that need through geospatial analysis, time-series exploration, predictive modeling, and a synthesized climate-vulnerability assessment designed to support evidence-informed mitigation and adaptation prioritization.

## Analytical Scope

- Historical/mock observation period: 2000–2025
- Projection period: 2026–2050
- Geographic scope: Global, aggregated at country level
- Core indicators: Temperature, precipitation, CO₂ emissions, and sea-level rise
- Data type: Synthetic climate data created for analytical and educational purposes

> **Important:** Projected values are model-based synthetic scenarios and must not be interpreted as authoritative forecasts of future climate conditions.

## Project Workflow

1. Generated reproducible synthetic global climate data for 2000–2025.
2. Cleaned and validated country-level climate indicators and outliers.
3. Integrated climate data with global geospatial boundaries using ISO3 codes.
4. Performed exploratory analysis of temperature, precipitation, CO2 emissions, and sea-level change.
5. Built country-level linear models and generated projections for 2026–2050.
6. Developed multi-layer geospatial maps, annual temperature animation, and interactive country trend visualization.
7. Constructed a composite modeled vulnerability score to identify higher-risk geographic entities.

## Key Findings

- The synthetic global dataset shows a modeled average temperature increase of approximately 0.88°C from 2000 to 2025.
- Modeled global mean sea-level rise increased by approximately 80 mm over the historical period.
- Cross-country CO2 correlations with temperature, precipitation, and sea-level indicators were weak in this synthetic dataset, so they should not be interpreted as causal relationships.
- The composite vulnerability analysis combines temperature change, absolute precipitation change, and sea-level change to identify geographic entities experiencing stronger modeled climate pressures.
- Azerbaijan, Rwanda, and New Caledonia ranked among the highest modeled-vulnerability entities under the synthetic scoring framework.
- Projections for 2026–2050 represent linear scenario extensions of synthetic historical trends, not authoritative real-world climate forecasts.

## Technical Stack

- **R** — analytical programming and statistical modeling
- **tidyverse** — data generation, transformation, cleaning, and aggregation
- **sf** — spatial data manipulation and geospatial integration
- **tmap** — thematic mapping and temporal climate visualization
- **rnaturalearth** — global geographic boundary data
- **plotly** — interactive country-level temperature trend visualization
- **broom** — model workflow support
- **magick** — assembly of annual map frames into the 2000–2050 temperature animation

## Methodology and Limitations

Climate observations for 2000–2025 were generated synthetically using reproducible random variation and predefined indicator trends. Country-level linear regression models were then fitted independently to each climate indicator and used to extend modeled trends through 2050.

Global geographic boundaries were integrated using ISO3 country codes. The vulnerability index uses equal-weight percentile ranks for temperature change, absolute precipitation change, and sea-level change.

Because the dataset is synthetic and the forecasting approach assumes linear continuation of historical patterns, the results should be interpreted as an analytical demonstration rather than real-world climate predictions or official country risk assessments. The models do not incorporate complex climate-system interactions, socioeconomic exposure, adaptation capacity, policy changes, or nonlinear climate dynamics.

## Project Structure

```text
climate-change-geospatial-analysis/
├── data/
│   ├── raw/
│   └── processed/
├── scripts/
│   ├── 01_generate_climate_data.R
│   ├── 02_clean_prepare_climate_data.R
│   ├── 03_geospatial_integration.R
│   ├── 04_exploratory_climate_analysis.R
│   ├── 05_climate_projection_modeling.R
│   ├── 06_climate_geospatial_visualization.R
│   └── 07_climate_vulnerability_analysis.R
├── outputs/
│   ├── figures/
│   ├── maps/
│   └── tables/
├── presentation/
└── README.md

## Recommendations

- Prioritize monitoring of geographic entities showing simultaneously elevated temperature, precipitation, and sea-level pressure within the modeled vulnerability framework.
- Use multiple climate indicators rather than relying on a single metric when evaluating potential climate exposure.
- Combine climate indicators with socioeconomic exposure, population, infrastructure, and adaptive-capacity data in future analyses.
- Replace synthetic observations with authoritative climate datasets before using the framework for real-world policy or investment decisions.
- Extend the predictive framework with nonlinear and scenario-based climate models to better represent long-term uncertainty.














