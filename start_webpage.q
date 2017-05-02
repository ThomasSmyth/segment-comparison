/- load the webpage functions

// .load.stuff:{@[system;"l ",x;{-1"Failed to load ",x," : ",x;exit 1}]}
//@[system;"l webpagefunctions.q";{-1"Failed to load webpagefunctions.q : ",x;exit 1}]


if[()~key hsym `$getenv[`SVAHOME],"/settings/token.txt";
  -1"Token file does not exist";
  :exit 1;
 ];

/ load variables
@[system;"l ",getenv[`SVAHOME],"/settings/variables.q";{x; -1"Failed to load variables.q";exit 1}];

/ Load main compare script
@[system;"l ",getenv[`SVAHOME],"/functions/main.q";{x; -1"Failed to load main.q";exit 1}];

/ load webpage UI
@[system;"l ",getenv[`SVAWEB],"/ui/webpageui.q";{-1"Failed to load webpageui.q : ",x;exit 1}]

/ set port
@[system;"p ",string .var.port;{-1"Failed to open port: ",string value `.settings.port;exit 1}]
