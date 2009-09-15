loader(function(cb) {
    var url = 'http://www.google.com/jsapi?key=' + Helium.GOOGLE_KEY;
    load(url, cb);
})  .provides('google.load');

loader(function(cb) { google.load('maps', '2.x', {callback: cb}) })
    .provides('GMap2', 'GClientGeocoder')
    .requires('google.load');

