/ save and load cached data

.data.save:{[id;tab;data]                                                                       / [athlete id;table;data] save data to disk, preserving keys
  if[not tab in key[.data.schemas]`n;                                                           / exit early if no schema is defined
    :.log.e("no schema defined for {}";tab);
   ];
  if[not .var.cache;:()];                                                                       / exit early if caching unused
  cfg:.data.schemas tab;                                                                        / get config for current table
  data:.data.load[id;tab]upsert data;                                                           / pull existing data and overwrite duplicate keys
  loc:.data.loc[cfg`d][id;tab];                                                                 / get location of data on disk
  :loc set .Q.en[.var.savedir]0!data;                                                           /save data to disk
 };

.data.load:{[id;tab]                                                                            / [athlete id;table]
  if[not tab in key[.data.schemas]`n;                                                           / exit early if no schema is defined
    :.log.e("no schema defined for {}";tab);
   ];
  if[not .var.cache;:.data.zero tab];                                                           / return blank schema if caching is off
  cfg:.data.schemas tab;                                                                        / get config for current table
  loc:.data.loc[cfg`d][id;tab];                                                                 / get location of data on disk
  if[0=count key loc;:.data.zero tab];                                                          / return empty schema if no data exists
  :cfg[`k]xkey select from get loc;                                                             / return data and apply keys
 };

.data.loc.splay:{[id;tab]` sv .var.savedir,tab,`};                                              / get location of splay
.data.loc.partition:{[id;tab]` sv .Q.par[.var.savedir;athId;tab],`};                            / get location of partition

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

.data.athlete.activities:{[id;start;end]                                                        / [athlete;start date;end date] return activities in date range for given athlete
  .log.o"retrieving activity list";
  if[0=count ca:.data.load[id;`activities];
    act:.http.athlete.activities[id];
    .data.save[id;`activities;act];
    ca:.data.load[id;`activities];
   ];
  res:select from ca where date within(start;end);
  .log.o("found {} activities in date range {} to {}";(count res;start;end));
  :res;
 };

.data.segments.activity:{[id;actId]                                                             / [athlete id;activity id]
  res:.http.activity.detail actId;
  :select id,name from res`segment_efforts;
 };

.data.segments.activities:{[id;actIds]                                                          / [athlete id;activity id list]
  .log.o"retrieving segments for all activities";
  :ids;
 };
