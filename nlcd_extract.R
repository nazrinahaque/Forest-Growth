# Load required libraries
library(raster)
library(sp)

# ===============================
# 1. Read the parcel CSV file
# ===============================
points_df <- read.csv("parcel_growth.csv")

# Convert dataframe to SpatialPointsDataFrame
coordinates(points_df) <- ~longitude + latitude
proj4string(points_df) <- CRS("+proj=longlat +datum=WGS84")

# ===============================
# 2. Load NLCD raster
# ===============================
raster_file <- "Annual_NLCD_LndCov_2023_CU_C1V0.tif"

# Check if raster exists
if (!file.exists(raster_file)) {
  stop("The raster file is missing: ", raster_file)
}

# Load raster
nlcd_raster <- try(raster(raster_file))
if (inherits(nlcd_raster, "try-error")) {
  stop("Error loading raster file: ", raster_file)
}

# ===============================
# 3. Extract NLCD values
# ===============================
nlcd_values <- raster::extract(nlcd_raster, points_df)

# ===============================
# 4. Combine results
# ===============================
result_df <- cbind(points_df@data, NLCD_value = nlcd_values)

# ===============================
# 5. Save output
# ===============================
write.csv(result_df, "parcel_growth_with_nlcd.csv", row.names = FALSE)