/ save and load cached data

.data.save:{[tab;data]
  if[not .var.cache;:()];                                                                       / exit early if caching unused
  loc:.data.loc tab;
  if[()~key loc;:loc set .db.zero tab];                                                         / save blank schema to disk
  :.[upsert;(loc;data);{.log.o("upsert failed with error '{}'";x)}];                            / save data to disk
 };

.data.load:{[tab]
  if[not .var.cache;:.data.zero tab];                                                           / return blank schema if caching is off
  loc:.data.loc tab;
  if[()~key loc;:.data.zero tab];
  :get loc;                                                                                     / return data
 };

.data.loc:{.utl.p.symbol .var.savedir,x}                                                        / retrieve location on disk

.data.zero:{[tab]
  if[not tab in key .data.schemas;:()];                                                         / exit early if no defined schema
  :.load.parse .data.schemas tab;                                                               / return blank table
 };

.data.athlete.current:{[]
  if[0<count .var.athlete.current;                                                              / return cached result if it exists
    .log.o"returning cached data for current athlete";
    :.var.athlete.current;
   ];
  `.var.athlete.current set ad:.http.athlete.current[];                                         / pull data from strava and keep in memory
  :ad;
 };

.data.athlete.clubs:{[]                                                                         / return list of users clubs
  if[count cl:.data.load`clubs;
    .log.o"returning cached clubs for current athlete";
    :cl;
   ];
  .data.save[`clubs]cl:.http.athlete.clubs[];                                                   / pull data from strava and save to disk
  :cl;
 };

.data.segments.starred:{[]                                                                      / [] return starred segments for current athlete
  if[0<count sd:select from .data.load[`segments]where starred;:sd];                            / returned cached segments if available
  .data.save[`segments]st:.http.segments.starred[];                                             / retrieve starred segments from strava
  :st;
 };

.data.athlete.activities:{[start;end]                                                           / return activities
  .log.o"retrieving activity list";
  if[0=count ca:.data.load`activities;
    act:.http.athlete.activities[];
    .data.save[`activities;act];
    ca:.data.load`activities;
   ];
  res:select from ca where start_date within(start;end);
  .log.o("found {} activities in date range {} to {}";(count res;start;end));
  :res;
 };

.data.segments.activity:{[id]
 };

.data.segments.activities:{[ids]
 };
