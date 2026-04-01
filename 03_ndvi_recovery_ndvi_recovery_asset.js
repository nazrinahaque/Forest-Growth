// ============================================================
// NDVI RECOVERY — Ndvi_recovery ASSET EXTRACTION
// Author: Nazrina Haque
// Description: Computes NDVI difference (2024 - 2019) and
//              full recovery metrics (2017, 2019, 2024) for
//              the Ndvi_recovery parcel asset
//              Uses tileScale=4 for large area processing
// ============================================================


// ============================================================
// 1. AREA OF INTEREST
// ============================================================
var usStates = ee.FeatureCollection('TIGER/2018/States');

var aoi = usStates.filter(
  ee.Filter.inList('NAME', [
    'Georgia', 'Alabama', 'South Carolina', 'Florida'
  ])
).geometry();


// ============================================================
// 2. CLOUD MASK & NDVI FUNCTIONS
// ============================================================
function maskS2(image) {
  var opaque = image.select('MSK_CLASSI_OPAQUE').eq(0);
  var cirrus = image.select('MSK_CLASSI_CIRRUS').eq(0);
  return image.updateMask(opaque.and(cirrus)).divide(10000);
}

function addNDVI(image) {
  return image.addBands(
    image.normalizedDifference(['B8', 'B4']).rename('NDVI')
  );
}

function annualNDVI(year) {
  var start = ee.Date(year + '-01-01');
  var end   = ee.Date(year + '-12-31');

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
// 3. BUILD NDVI COMPOSITES & METRICS
// ============================================================
var ndvi2017 = annualNDVI(2017);
var ndvi2019 = annualNDVI(2019);
var ndvi2024 = annualNDVI(2024);

var damage        = ndvi2019.subtract(ndvi2017).rename('damage');
var recovery      = ndvi2024.subtract(ndvi2019).rename('recovery');
var fullRecovery  = ndvi2024.subtract(ndvi2017).rename('full_recovery');
var percentRecovery = recovery
  .divide(ndvi2017.subtract(ndvi2019))
  .rename('pct_recovery');

var ndviDiff = ndvi2024.subtract(ndvi2019).rename('NDVI_Diff');

Map.addLayer(ndviDiff,
  {min: -0.5, max: 0.5, palette: ['red', 'white', 'green']},
  'NDVI Difference (2024-2019)'
);


// ============================================================
// 4. LOAD Ndvi_recovery PARCEL ASSET
// ============================================================
var parcels = ee.FeatureCollection(
  "projects/ee-haquen/assets/Ndvi_recovery"
);


// ============================================================
// 5. CREATE ACRE-BASED BUFFERS
// ============================================================
var buffered = parcels.map(function(f) {
  var acres  = ee.Number(f.get('acres'));
  var radius = acres.multiply(4046.86).divide(Math.PI).sqrt();
  return f.buffer(radius);
});


// ============================================================
// 6. STACK METRICS & EXTRACT PARCEL VALUES
// tileScale=4 handles large area processing
// ============================================================
var metricsImage = damage
  .addBands(recovery)
  .addBands(fullRecovery)
  .addBands(percentRecovery);

var parcelMetrics = buffered.map(function(f) {
  var vals = metricsImage.reduceRegion({
    reducer:   ee.Reducer.mean(),
    geometry:  f.geometry(),
    scale:     30,
    maxPixels: 1e9,
    tileScale: 4
  });
  return f.set(vals);
});


// ============================================================
// 7. EXPORT CSV
// ============================================================
Export.table.toDrive({
  collection:  parcelMetrics,
  description: 'Ndvi_recovery_Metrics_2017_2019_2024',
  fileFormat:  'CSV'
});
