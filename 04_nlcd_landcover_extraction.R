# ============================================================
# NLCD LAND COVER EXTRACTION — PARCEL GROWTH ANALYSIS
# Author: Nazrina Haque
# Description: Extracts 2023 National Land Cover Database
#              (NLCD) land cover classification values at
#              parcel locations to assess whether hurricane-
#              affected lands show vegetation recovery or
#              land use change by 2024
#
# Research Question:
#   Do parcels affected by Hurricane Michael show more or
#   less vegetation cover by 2023/2024 compared to baseline?
#
# NLCD Land Cover Classes (key values):
#   41 = Deciduous Forest
#   42 = Evergreen Forest
#   43 = Mixed Forest
#   52 = Shrub/Scrub (early recovery)
#   71 = Grassland/Herbaceous
#   81 = Pasture/Hay
#   82 = Cultivated Crops
#   90 = Woody Wetlands
# ============================================================


# ============================================================
# 1. LOAD LIBRARIES
# ============================================================
library(raster)
library(sp)


# ============================================================
# 2. LOAD PARCEL DATA
# ============================================================
points_df <- read.csv("parcel_growth.csv")

if (nrow(points_df) == 0) stop("CSV file is empty.")

cat("✅ Parcels loaded:", nrow(points_df), "\n")
print(head(points_df))


# ============================================================
# 3. CONVERT TO SPATIAL OBJECT
# ============================================================
coordinates(points_df)  <- ~longitude + latitude
proj4string(points_df)  <- CRS("+proj=longlat +datum=WGS84")

cat("✅ Converted to spatial object\n")
cat("   CRS:", proj4string(points_df), "\n")


# ============================================================
# 4. LOAD NLCD 2023 RASTER
# Source: USGS Annual NLCD Land Cover 2023
# Resolution: 30m
# ============================================================
raster_file <- "Annual_NLCD_LndCov_2023_CU_C1V0.tif"

if (!file.exists(raster_file)) {
  stop("Raster file missing: ", raster_file)
}

nlcd_raster <- try(raster(raster_file))

if (inherits(nlcd_raster, "try-error")) {
  stop("Error loading raster: ", raster_file)
}

cat("✅ NLCD raster loaded\n")
cat("   Resolution:", res(nlcd_raster), "meters\n")
cat("   CRS:", projection(nlcd_raster), "\n")


# ============================================================
# 5. EXTRACT NLCD VALUES AT PARCEL LOCATIONS
# ============================================================
nlcd_values <- raster::extract(nlcd_raster, points_df)

cat("✅ NLCD values extracted\n")
cat("   Non-NA values:", sum(!is.na(nlcd_values)), "\n")
cat("   NA values:    ", sum(is.na(nlcd_values)), "\n")


# ============================================================
# 6. COMBINE AND LABEL LAND COVER CLASSES
# ============================================================
result_df <- cbind(points_df@data, NLCD_value = nlcd_values)

# Add human-readable land cover labels
result_df$NLCD_class <- NA

result_df$NLCD_class[result_df$NLCD_value == 11] <- "Open Water"
result_df$NLCD_class[result_df$NLCD_value == 21] <- "Developed Open Space"
result_df$NLCD_class[result_df$NLCD_value == 22] <- "Developed Low Intensity"
result_df$NLCD_class[result_df$NLCD_value == 23] <- "Developed Medium Intensity"
result_df$NLCD_class[result_df$NLCD_value == 24] <- "Developed High Intensity"
result_df$NLCD_class[result_df$NLCD_value == 31] <- "Barren Land"
result_df$NLCD_class[result_df$NLCD_value == 41] <- "Deciduous Forest"
result_df$NLCD_class[result_df$NLCD_value == 42] <- "Evergreen Forest"
result_df$NLCD_class[result_df$NLCD_value == 43] <- "Mixed Forest"
result_df$NLCD_class[result_df$NLCD_value == 52] <- "Shrub/Scrub"
result_df$NLCD_class[result_df$NLCD_value == 71] <- "Grassland/Herbaceous"
result_df$NLCD_class[result_df$NLCD_value == 81] <- "Pasture/Hay"
result_df$NLCD_class[result_df$NLCD_value == 82] <- "Cultivated Crops"
result_df$NLCD_class[result_df$NLCD_value == 90] <- "Woody Wetlands"
result_df$NLCD_class[result_df$NLCD_value == 95] <- "Emergent Herbaceous Wetlands"

# Flag forested parcels (classes 41, 42, 43)
result_df$is_forested <- as.integer(
  result_df$NLCD_value %in% c(41, 42, 43)
)

# Flag early recovery (shrub/scrub — common post-hurricane)
result_df$is_shrub <- as.integer(
  result_df$NLCD_value == 52
)

# Flag developed land (possible land use change post-hurricane)
result_df$is_developed <- as.integer(
  result_df$NLCD_value %in% c(21, 22, 23, 24)
)

cat("\n✅ Land cover classes labeled\n")


# ============================================================
# 7. SUMMARY OF LAND COVER DISTRIBUTION
# ============================================================
cat("\n=== NLCD Land Cover Distribution ===\n")
print(table(result_df$NLCD_class, useNA = "ifany"))

cat("\n=== Vegetation Status Summary ===\n")
cat("  Forested parcels:   ", sum(result_df$is_forested,  na.rm = TRUE), "\n")
cat("  Shrub/scrub parcels:", sum(result_df$is_shrub,     na.rm = TRUE), "\n")
cat("  Developed parcels:  ", sum(result_df$is_developed, na.rm = TRUE), "\n")


# ============================================================
# 8. SAVE OUTPUT
# ============================================================
write.csv(result_df, "parcel_growth_with_nlcd.csv", row.names = FALSE)

cat("\n✅ Output saved: parcel_growth_with_nlcd.csv\n")
cat("   Columns:", paste(names(result_df), collapse = ", "), "\n")
