JS.Packages(function() { with(this) {
        
    file('http://cdn.othermedia.com/ojay/0.4.0/core-min.js')
        .provides("Ojay", "Ojay.HTML")
        .requires('YAHOO', 'JS.Class', 'JS.Observable', 'JS.State', 'JS.MethodChain');
    
    file('http://cdn.othermedia.com/ojay/0.4.0/pkg/overlay-min.js')
        .provides("Ojay.ContentOverlay")
        .requires('Ojay');
    
    file('http://cdn.othermedia.com/ojay-yui/2.7.0.js')
        .provides('YAHOO');
}});

