/**
 * Loads the `_gat` object for Google Analytics
 **/
var gaJsHost = ('https:' == document.location.protocol) ? 'https://ssl.' : 'http://www.';
file(gaJsHost + 'google-analytics.com/ga.js')
    .provides('_gat');

/**
 * Loads a `pageTracker` object for making Analytics API calls.
 * Requires `Helium.GOOGLE_ANALYTICS_ID` to be set.
 **/
loader(function(cb) {
    try {
        window.pageTracker = _gat._getTracker(Helium.GOOGLE_ANALYTICS_ID);
    } catch (err) {}
})  .provides('pageTracker')
    .requires('_gat');

/**
 * Loads the `google.load` function, required to load other
 * parts of the Google API. Requires `Helium.GOOGLE_API_KEY`
 * to be set beforehand.
 **/
loader(function(cb) {
    var url = 'http://www.google.com/jsapi?key=' + Helium.GOOGLE_API_KEY;
    load(url, cb);
})  .provides('google.load');

/**
 * Loads the Google Maps API. Requires `Helium.GOOGLE_API_KEY`
 * to be set beforehand.
 **/
loader(function(cb) { google.load('maps', '2.x', {callback: cb}) })
    .provides('GMap2', 'GClientGeocoder',
              'GEvent', 'GLatLng', 'GMarker')
    .requires('google.load');

