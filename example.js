// http://jsfiddle.net/9xjt8223/

// create a map in the "map" div, set the view to a given place and zoom
var map = L.map('map').setView([48.858190, 2.294470], 12);

var monumentsLayerGroup = false;
var gardensLayerGroup = false;
var layerControl = false;

// add an OpenStreetMap tile layer
var osm = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
}).addTo(map);


document.getElementById('gardens').onclick = function(evt) {
    
    lineArray = [[[ 48.864183, 2.326120 ],[ 48.855232, 2.299642 ],[ 48.846958, 2.337150 ]],[[ 48.864183, 2.326120 ],[ 48.855232, 2.299642 ],[ 48.846958, 2.337150 ]]];
        
//    if(gardensLayerGroup === false) {       
        // Tuileries: 48.864183, 2.326120
        // Champs de Mars: 48.855232, 2.299642
        // Luxembourg: 48.846958, 2.337150
        gardensLayerGroup = L.layerGroup();
//    }
  
    lineArray.forEach(function(line){
      gardensLayerGroup.addLayer(L.polyline(line,{color:'red',opacity:1}));
    }); 

    gardensLayerGroup.addTo(map);
        
//    if(layerControl === false) {
//        layerControl = L.control.layers().addTo(map);
//    }
    
    layerControl.addOverlay(gardensLayerGroup, "Gardens");

         
//    return false;
}  



document.getElementById('monuments').onclick = function(evt) {

    if(monumentsLayerGroup === false) {
        // Eiffel Tower: 48.858543, 2.294492
        // Louvre: 48.860315, 2.338222
        // Arc de Triomphe: 48.873978, 2.295007
        monumentsLayerGroup = L.layerGroup()
        .addLayer(L.marker([ 48.858543, 2.294492 ]))
        .addLayer( L.marker([ 48.860315, 2.338222 ]))
        .addLayer(L.marker([ 48.873978, 2.295007 ]))
        .addTo(map);    
    }
    
      
    if(layerControl === false) {
        layerControl = L.control.layers().addTo(map);
    }
    
    layerControl.addOverlay(monumentsLayerGroup, "Monuments");
         
    return false;
}  

