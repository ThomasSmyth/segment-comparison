/- load the smart meter functions
@[system;"l smartmeterfunctions.q";{-1"Failed to load smartmeterfunctions.q : ",x;exit 1}]

/- load the smart meter UI
@[system;"l ui/json.k";{-1"Failed to load json.k : ",x;exit 1}]
@[system;"l ui/smartmeterui.q";{-1"Failed to load smartmeterui.q : ",x;exit 1}]
.h.HOME:"ui/html"

/- Load the HDB
// hdbdir:$[0=count .z.x;"./smartmeterDB";.z.x 0]
// @[system;"l ",hdbdir;{-1"Failed to load specified hdb ",x,": ",y;exit 1}[hdbdir]]

/- Load main compare script
@[system;"l ../main.q";{x; -1"Failed to load main.q";exit 1}];
