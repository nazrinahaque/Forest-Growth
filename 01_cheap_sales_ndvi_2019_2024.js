// ============================================================
// NDVI RECOVERY ANALYSIS — CHEAP SALES PARCELS (2019 vs 2024)
// Author: Nazrina Haque
// Description: Computes annual NDVI composites for 2019 and
//              2024, calculates NDVI difference, creates
//              acre-based buffers around cheap sale parcels,
//              and exports parcel-level NDVI values as CSV
// ============================================================


// ============================================================
// 1. AREA OF INTEREST
// ============================================================
var usStates = ee.FeatureCollection('TIGER/2018/States');

var selectedStates = usStates.filter(
  ee.Filter.inList('NAME', [
    'Georgia', 'Alabama', 'South Carolina', 'Florida'
  ])
);

var aoi = selectedStates.geometry();
Map.centerObject(aoi, 6);


// ============================================================
// 2. CLOUD MASK FUNCTION (Sentinel-2 SR Harmonized)
// Uses scene classification bands:
//   MSK_CLASSI_OPAQUE = 0 → no opaque clouds
//   MSK_CLASSI_CIRRUS = 0 → no cirrus clouds
// ============================================================
function maskS2(image) {
  var opaque = image.select('MSK_CLASSI_OPAQUE').eq(0);
  var cirrus = image.select('MSK_CLASSI_CIRRUS').eq(0);
  return image.updateMask(opaque.and(cirrus)).divide(10000);
}


// ============================================================
// 3. NDVI FUNCTION
// NIR = B8, Red = B4
// NDVI = (NIR - Red) / (NIR + Red)
// ============================================================
function addNDVI(image) {
  return image.addBands(
    image.normalizedDifference(['B8', 'B4']).rename('NDVI')
  );
}


// ============================================================
// 4. ANNUAL NDVI COMPOSITE FUNCTION
// Filters by year, masks clouds, computes median composite
// ============================================================
function getAnnualNDVI(year) {
  var start = ee.Date.fromYMD(year, 1, 1);
  var end   = ee.Date.fromYMD(year, 12, 31);

  return ee.ImageCollection('COPERNICUS/S2_SR_HARMONIZED')
    .filterBounds(aoi)
    .filterDate(start, end)
    .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20))
    .map(maskS2)
    .map(addNDVI)
    .select('NDVI')
    .median()
    .clip(aoi);
}


// ============================================================
// 5. BUILD NDVI COMPOSITES
// 2019 = post-Hurricane Michael damage year
// 2024 = recovery / development year
// ============================================================
var ndvi2019 = getAnnualNDVI(2019);
var ndvi2024 = getAnnualNDVI(2024);


// ============================================================
// 6. NDVI DIFFERENCE
// Positive = vegetation gain (recovery)
// Negative = vegetation loss (continued damage)
// ============================================================
var ndviDiff = ndvi2024.subtract(ndvi2019).rename('NDVI_Diff');


// ============================================================
// 7. VISUALIZATION
// ============================================================
var ndviVis = {min: 0,    max: 1,   palette: ['white', 'green']};
var diffVis = {min: -0.5, max: 0.5, palette: ['red', 'white', 'green']};

Map.addLayer(ndvi2019, ndviVis, 'NDVI 2019');
Map.addLayer(ndvi2024, ndviVis, 'NDVI 2024');
Map.addLayer(ndviDiff, diffVis, 'NDVI Difference (2024 - 2019)');


// ============================================================
// 8. LOAD CHEAP SALES PARCEL POINTS
// ============================================================
var parcels = ee.FeatureCollection(
  "projects/ee-nazrinahaque/assets/Cheap_sales"
);

Map.addLayer(parcels, {}, 'Cheap Sale Parcel Points');


// ============================================================
// 9. CREATE ACRE-BASED CIRCULAR BUFFERS
// 1 acre = 4046.86 m²
// radius = sqrt(acres × 4046.86 / π)
// ============================================================
var bufferedParcels = parcels.map(function(feature) {
  var acres  = ee.Number(feature.get('acres'));
  var radius = acres.multiply(4046.86).divide(Math.PI).sqrt();
  return feature.buffer(radius);
});

Map.addLayer(bufferedParcels, {}, 'Buffered Parcels');


// ============================================================
// 10. EXTRACT MEAN NDVI DIFFERENCE PER BUFFER
// ============================================================
var parcelsWithNDVI = bufferedParcels.map(function(feature) {
  var ndviValue = ndviDiff.reduceRegion({
    reducer:   ee.Reducer.mean(),
    geometry:  feature.geometry(),
    scale:     30,
    maxPixels: 1e9
  }).get('NDVI_Diff');

  return feature.set('NDVI_Diff', ndviValue);
});


// ============================================================
// 11. EXPORT CSV
// ============================================================
Export.table.toDrive({
  collection:  parcelsWithNDVI,
  description: 'CheapSales_NDVI_Diff_2024_2019',
  fileFormat:  'CSV'
});
