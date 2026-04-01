# Remote Sensing — NDVI Recovery & Land Cover Analysis
**Author:** Nazrina Haque | PhD Candidate, Oregon State University  
**Tools:** Google Earth Engine (JavaScript) | R  
**Satellite:** Copernicus Sentinel-2 SR Harmonized | USGS NLCD  

---

## Overview
This repository contains remote sensing scripts for measuring
**vegetation damage, recovery, and land cover change** following
Hurricane Michael (2018) across the Southeastern United States.

The central research question is:

> **Do timberland parcels affected by Hurricane Michael show
> more or less vegetation cover by 2023/2024 compared to
> their pre-storm baseline?**

Scripts compute annual NDVI composites, derive recovery metrics,
extract USGS National Land Cover Database (NLCD) classifications,
create acre-based parcel buffers, and export parcel-level values
as regression-ready CSV files for econometric analysis.

---

## Research Questions
- Did hurricane-affected parcels recover their vegetation by 2024?
- Are damaged parcels more likely to show land use change by 2023?
- Do cheap sale parcels show more vegetation loss than others?
- How does NDVI-measured recovery compare to NLCD land cover class?

---

## Study Area
Georgia, Alabama, South Carolina, and Florida.
Hurricane Michael made landfall on **October 10, 2018** as a Category 5 storm.

---

## Repository Structure

### Google Earth Engine Scripts (JavaScript)
| File | Description |
|------|-------------|
| `hurricane_michael_ndvi_change.js` | Pre/post NDVI change detection around Michael landfall |
| `ndvi_hurricane_recovery.js` | Multi-year NDVI recovery 2017 to 2024 |
| `01_michael_ndvi_change_basic.js` | Pre/post NDVI composites and raster export |
| `02_michael_ndvi_parcel_extraction.js` | Parcel NDVI extraction at 10m resolution |
| `03_michael_ndvi_parcel_extraction_30m.js` | Parcel NDVI extraction at 30m for faster processing |
| `04_michael_ndvi_acre_buffers.js` | Acre-based buffers with NDVI extraction |
| `01_cheap_sales_ndvi_2019_2024.js` | NDVI difference 2019 to 2024 for cheap sale parcels |
| `02_recovery_metrics_2017_2019_2024.js` | Four recovery metrics across 2017, 2019, 2024 |
| `03_ndvi_recovery_asset_extraction.js` | Recovery metrics for Ndvi_recovery parcel asset |
| `04_ndvi_recovery_full_metrics.js` | Full recovery metrics with tileScale for large areas |

### R Scripts
| File | Description |
|------|-------------|
| `04_nlcd_landcover_extraction.R` | Extracts USGS NLCD 2023 land cover class at each parcel |

---

## Recovery Metrics (NDVI-based)

| Metric | Formula | Interpretation |
|--------|---------|----------------|
| `damage` | NDVI 2019 - NDVI 2017 | Vegetation loss from storm |
| `recovery` | NDVI 2024 - NDVI 2019 | Short-term regrowth |
| `full_recovery` | NDVI 2024 - NDVI 2017 | Full recovery vs baseline |
| `pct_recovery` | recovery / (2017 - 2019) | Percent of damage recovered |
| `NDVI_Diff` | NDVI 2024 - NDVI 2019 | Simple two-year difference |

---

## Land Cover Classes (NLCD 2023)

| NLCD Value | Class | Vegetation Status |
|------------|-------|------------------|
| 41 | Deciduous Forest | ✅ Full recovery |
| 42 | Evergreen Forest | ✅ Full recovery |
| 43 | Mixed Forest | ✅ Full recovery |
| 52 | Shrub/Scrub | 🔄 Early recovery |
| 71 | Grassland/Herbaceous | ⚠️ Partial recovery |
| 21-24 | Developed | ❌ Land use change |
| 81-82 | Agriculture | ❌ Land use change |

---

## Full Analysis Workflow
```
Sentinel-2 SR Harmonized imagery
            ↓
Cloud masking + NDVI calculation
            ↓
Annual median composites: 2017, 2019, 2024
            ↓
Recovery metrics:
damage / recovery / full_recovery / pct_recovery
            ↓
Parcel points → acre-based circular buffers
radius = sqrt(acres × 4046.86 / π)
            ↓
Mean NDVI extraction per buffer (30m, tileScale=4)
            ↓
Export NDVI CSV to Google Drive
            ↓
R: Extract NLCD 2023 land cover class per parcel
            ↓
Label: forested / shrub / developed / other
            ↓
Regression-ready dataset with NDVI + NLCD variables
```

---

## Key Parameters

| Parameter | Value |
|-----------|-------|
| Satellite | Copernicus S2 SR Harmonized |
| Cloud filter | Less than 20% cloud cover |
| NDVI bands | NIR = B8, Red = B4 |
| Composite method | Annual median |
| Extraction scale | 30m |
| tileScale | 4 (large area processing) |
| NLCD source | USGS Annual NLCD 2023 |
| NLCD resolution | 30m |
| Buffer method | Circular, sized by parcel acreage |

---

## Parcel Assets Used

| Asset | Description |
|-------|-------------|
| `projects/ee-nazrinahaque/assets/Cheap_sales` | Cheap sale parcels under $100/acre |
| `projects/ee-haquen/assets/Ndvi_recovery` | NDVI recovery analysis parcels |
| `parcel_growth.csv` | Parcel locations for NLCD extraction |

---

## Output Files

| File | Contents |
|------|----------|
| `CheapSales_NDVI_Diff_2024_2019.csv` | NDVI difference per cheap sale parcel |
| `Hurricane_Recovery_Metrics_2017_2019_2024.csv` | Four recovery metrics per parcel |
| `Ndvi_recovery_Metrics_2017_2019_2024.csv` | Recovery metrics for Ndvi_recovery asset |
| `parcel_growth_with_nlcd.csv` | NLCD land cover class per parcel |

---

## How to Run GEE Scripts
1. Open [Google Earth Engine Code Editor](https://code.earthengine.google.com)
2. Copy and paste any `.js` script
3. Click **Run**
4. Click **Tasks** tab → click **Run** to export CSV to Drive

## How to Run R Scripts
```r
# Install required packages
install.packages(c("raster", "sp"))

# Run script
source("04_nlcd_landcover_extraction.R")
```

---

## Connection to Other Repos

| Repo | How it uses these scripts |
|------|--------------------------|
| [hurricane_timberland](https://github.com/nazrinahaque/hurricane_timberland) | Uses NDVI and NLCD outputs in land value regressions |
| [disturbance_risk](https://github.com/nazrinahaque/disturbance_risk) | Uses NDVI difference for disturbance risk indicators |
| [michael](https://github.com/nazrinahaque/michael) | Combines outputs with hurricane windswath spatial data |

---

## Tools
![R](https://img.shields.io/badge/-R-276DC3?style=flat&logo=r&logoColor=white)
![Google Earth Engine](https://img.shields.io/badge/-Google%20Earth%20Engine-4285F4?style=flat&logo=google&logoColor=white)
![JavaScript](https://img.shields.io/badge/-JavaScript-F7DF1E?style=flat&logo=javascript&logoColor=black)
![NLCD](https://img.shields.io/badge/-USGS%20NLCD-6D4C41?style=flat)
![Sentinel-2](https://img.shields.io/badge/-Sentinel--2-0072C6?style=flat)

---

## Contact
Nazrina Haque | haquen@oregonstate.edu  
Department of Applied Economics, Oregon State University
