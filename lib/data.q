/ save and load cached data

.data.save:{[id;tab;f;data]                                                                     / [athlete id;table;function;data] save data to disk, preserving keys
  if[not tab in key[.data.schemas]`n;                                                           / exit early if no schema is defined
    :.log.e("no schema defined for {}";tab);
   ];
  if[not .var.cache;:()];                                                                       / exit early if caching unused
  cfg:.data.schemas tab;                                                                        / get config for current table
  data:.data.w[f][id;tab;data];                                                                 / pull data from disk and append using method passed (f)
  loc:.data.loc[cfg`d][id;tab];                                                                 / get location of data on disk
  :loc set .Q.en[.var.savedir]0!data;                                                           /save data to disk
 };

.data.w.new:{[id;tab;data]                                                                      / only add new data to disk
  :data upsert .data.load[id;tab];                                                              / keep keys already on disk
 };
.data.w.matching:{[id;tab;data]                                                                 / update keys on disk
  :.data.load[id;tab]upsert data;                                                               / pull current data from disk
 };
.data.w.all:{[id;tab;data]data};                                                                / replace all data on disk

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
    .data.save[id;`activities;`new;act];
    ca:.data.load[id;`activities];
   ];
  res:select from ca where date within(start;end);
  .log.o("found {} activities in date range {} to {}";(count res;start;end));
  :res;
 };

.data.activity.get1Segment:{[id;actId]                                                          / [athlete id;activity id]
  res:.http.activity.detail actId;                                                              / pull details for passed activity
  res:select`long$id,name from res`segment_efforts;                                             / get required columnis
  .data.save[id;`segments;`matching;res];                                                       / save segments to disk
  a:@[.data.load[id;`activities]actId;`segs;:;1b];                                              / get info for current activity
  .data.save[id;`activities;`matching;([]id:(),actId),\:a];                                     / mark as complete
 };

.data.activity.segments:{[id;actIds]                                                            / [athlete id;activity id list]
  .log.o"retrieving segments for all activities";
  actIds:exec id from .data.load[id;`activities]where id in actIds,not segs;                    / find non processed activities
  .log.o("{} new activities passed";c:count actIds);
  :.data.activity.get1Segment'[id;actIds];                                                      / get segments from remaining activities
 };

.data.segments.leaderboard:{[id]
 };
