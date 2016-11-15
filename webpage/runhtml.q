/- load the webpage functions

// .load.stuff:{@[system;"l ",x;{-1"Failed to load ",x," : ",x;exit 1}]}
//@[system;"l webpagefunctions.q";{-1"Failed to load webpagefunctions.q : ",x;exit 1}]

/- load webpage UI
@[system;"l ui/webpageui.q";{-1"Failed to load webpageui.q : ",x;exit 1}]
.h.HOME:"ui/html"

/ set port 
.settings.port:5700;
@[system;"p ",string .settings.port;{-1"Failed to open port: ",string value `.settings.port;exit 1}]

/- Load main compare script
@[system;"l ../main.q";{x; -1"Failed to load main.q";exit 1}];
