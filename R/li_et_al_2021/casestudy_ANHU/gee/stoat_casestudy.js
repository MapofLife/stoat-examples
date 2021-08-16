var records = ee.FeatureCollection("users/rl839/annas_hummingbird_all"),
    boundingBox = 
    /* color: #d63000 */
    /* shown: false */
    ee.Geometry.Polygon(
        [[[-151.4, 22.8],
          [-94.1, 22.8],
          [-94.1, 59.7],
          [-151.4, 59.7]]]);

// Load Landsat 8 EVI data, 2013-2017, within region of interest
var evi = ee.ImageCollection('LANDSAT/LC08/C01/T1_8DAY_EVI')
              .filterDate('2013-01-01', '2017-12-31');
              
// GENERATE DIFFERENT LAYERS FOR DIFFERENT ANNOTATION RUNS

// SET PARAMETERS
// Monthly vs Overall, 30m vs 1km
var TEMPORAL = "Monthly";
//var TEMPORAL = "Overall";
//var SPATIAL = "30m";
var SPATIAL = "1km";


// 1. MONTHLY 30m LAYER
// Combine values across years to generate one layer per month - group by months, then mean all values, code from:
// https://gis.stackexchange.com/questions/279622/writing-code-for-monthly-ndvi-medians-in-google-earth-engine
if (TEMPORAL == "Monthly") {
  if (SPATIAL == "30m") {
    print("Generating Monthly 30m layer");
    var months = ee.List.sequence(1, 12);
    var byMonth = ee.ImageCollection.fromImages(
      months.map(function (m) {
        return evi.filter(ee.Filter.calendarRange(m, m, 'month'))
                    .mean()
                    .clip(boundingBox)
                    .set('month', m)
                    .reproject({crs: 'EPSG:4326', scale: 30}); // explicitly define scale as 30m since EPSG:4326 is like 111000 m by default?
    }));
  }
  
  // 2. MONTHLY 1km LAYER
  // Same as above, with additional step of coarsening grain
  else if (SPATIAL == "1km") {
    print("Generating Monthly 1km layer");
    var months = ee.List.sequence(1, 12);
    var byMonth = ee.ImageCollection.fromImages(
      months.map(function (m) {
        return evi.filter(ee.Filter.calendarRange(m, m, 'month'))
                    .mean()
                    .clip(boundingBox)
                    .set('month', m)
                    .reproject({crs: 'EPSG:4326', scale: 30}) // explicitly define scale as 30m since EPSG:4326 is like 111000 m by default?
                    .reduceResolution({reducer: ee.Reducer.mean(),  maxPixels: 1500})
                    .reproject({crs: 'EPSG:4326', scale: 1000});
    }));
  }
}

// 3. OVERALL MEAN 30m LAYER
// Combine all values across all years of interest for a single layer
if (TEMPORAL == "Overall") {
  print("Generating Overall 30m layer");
  var overall = evi
    .reduce(ee.Reducer.mean())
    .clip(boundingBox)
    .rename("EVI") // reducing renames to EVI_mean, change back to EVI
    .reproject({crs: 'EPSG:4326', scale: 30});

  // 4. OVERALL MEAN 1km LAYER
  // Coarsen previous layer to 1km
  if (SPATIAL == "1km") {
    print("Coarsening to 1km layer");
    overall = overall
      .reduceResolution({reducer: ee.Reducer.mean(), maxPixels: 1500})
      .reproject({crs: 'EPSG:4326', scale: 1000});
  }
}


// Function to extract the EVI of a single record
var extract = function (record) {
  var point = ee.Geometry.Point([record.lng, record.lat]);
  var scene;
  
  if (TEMPORAL == "Monthly") {
    // get month from event date and convert to number
    var month = ee.Number.parse(ee.Date(record.date).format('M'));
    // get the EVI layer associated with that month
    scene =  byMonth.filterMetadata('month', 'equals', month).first();
  }
  
  if (TEMPORAL == "Overall") {
    scene = overall;
  }
  
  // extract EVI layer value at point location
  var value = scene.select("EVI").reduceRegion({
    reducer:ee.Reducer.mean(),
    geometry:point, 
    scale:scene.projection().nominalScale(),
    tileScale:4,
  }).get("EVI");
  return value;
};

// Function for running EVI extraction on multiple records
var extractCustom = function(element){
  var record = {
    id: ee.Feature(element).get("event_id"),
    date: ee.Feature(element).get("date"),
    lat: ee.Feature(element).get("latitude"),
    lng: ee.Feature(element).get("longitude"),
  };
  
  var result = {
    id: record.id,
    date: record.date,
    lat: record.lat,
    lng: record.lng,
    value: extract(record)
  };
  return ee.Feature(null, result);
};

// Run extraction on all records

var recordList = records;
//recordList = recordList.limit(100);
var resultFeatures = recordList.map(extractCustom);
Export.table.toDrive(resultFeatures);
