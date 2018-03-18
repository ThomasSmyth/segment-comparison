/ init webpage

.init.init:{
  shome:hsym`$home:getenv`SVAHOME;
  {system"l ",1_string` sv x,`lib,y}[shome]'[`util.q`log.q`load.q];                             / load log and load libraries
  system"l ",1_string` sv shome,`config`settings.q;                                             / load settings
  .load.dir.q shome,`lib;                                                                       / load all libraries
  .log.o"initialising environment";
  if[()~key tf:.util.p.symbol shome,`config`token.txt;                                          / check for token file
    .log.e("Token file {} does not exist";tf);
    :exit 1;
   ];
  .load.dir.q shome,`config;                                                                    / load settings and functions
  .load.file.q[(`$getenv`SVAWEB;`ui)]`webpageui.q;                                              / load webpage UI
  @[{system"p ",string x;.log.o("opened port {}";x)};                                           / open port
    .var.port;
    {y;.log.e("failed to open port {}";x)}.var.port
   ];
  .log.o"initialisation complete";
 };

.init.start:{
  .data.schemas:`n xkey .load.file.csv[.var.confdir;`schema.csv;"sS*S"];
 };

.init.init[];
.init.start[];
