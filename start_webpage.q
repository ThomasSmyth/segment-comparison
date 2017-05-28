/ startup webpage

if[()~key hsym `$getenv[`SVAHOME],"/settings/token.txt";
  -1"Token file does not exist";
  :exit 1;
 ];

.startup.loadFile:{[v;f]                                                                        / load file
  :@[system;"l ",getenv[v],"/",f;{y; -1"Failed to load ",x;exit 1}f];
 };


.startup.loadFile[`SVAHOME] "/settings/variables.q";                                            / load variables
.startup.loadFile[`SVAHOME] "/functions/logging.q";                                             / load logging functions
.startup.loadFile[`SVAHOME] "/functions/main.q";                                                / Load main compare script
.startup.loadFile[`SVAWEB] "/ui/webpageui.q";                                                   / load webpage UI
.startup.loadFile[`SVAHOME] "/actions.q";                                                       / actions to perform on startup

@[system;"p ",string .var.port;{-1"Failed to open port: ",string value `.var.port;exit 1}];     / set port
