/ save and load cached data

.data.save:{[id;tab;f;data]                                                                     / [athlete id;table;function;data] save data to disk, preserving keys
  if[not tab in key[.data.schemas]`n;                                                           / exit early if no schema is defined
    :.log.e("no schema defined for {}";tab);
   ];
  if[not .var.cache;:()];                                                                       / exit early if caching unused
  cfg:.data.schemas tab;                                                                        / get config for current table
  data:.data.w[f][id;tab;cfg[`k]xkey data];                                                     / pull data from disk and append using method passed (f)
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
.data.loc.partition:{[id;tab]` sv .Q.par[.var.savedir;id;tab],`};                               / get location of partition

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

.data.segments.starred:{[]                                                                      / [] return starred segments for current athlete
  if[0<count sd:select from .data.load[`segments]where starred;:sd];                            / returned cached segments if available
  .data.save[`segments]st:.http.segments.starred[];                                             / retrieve starred segments from strava
  :st;
 };

.data.athlete.activities:{[id;start;end]                                                        / [athlete;start date;end date] return activities in date range for given athlete
  .log.o"retrieving activity list";
  if[0=count ca:.data.load[id;`activities];                                                     / if no activities cached then retrieve list
    // TODO on second pass only check for most recent data
    // if more exits get it else proceed as normal
    act:.http.athlete.activities id;                                                            / request actvities for current user from Strava
    .data.save[id;`activities;`new;act];                                                        / save activities for current user
    ca:.data.load[id;`activities];                                                              / retrieve activities from disk
   ];
  res:select from ca where date within(start;end);
  .log.o("found {} activities in date range {} to {}";(count res;start;end));
  :res;
 };

.data.activity.getSegments1Activity:{[id;actId]                                                 / [athlete id;activity id] get all segments from 1 activity
  .log.o("gettings segments for activity {}";actId);
  res:.http.activity.getSegments actId;                                                         / return segments from an activity
  .data.save[id;`segments;`matching;res];                                                       / save segments to disk
  a:@[.data.load[id;`activities]actId;`segs;:;1b];                                              / get info for current activity
  a:@[.data.load[id;`activities]actId;`complete`segments;:;(1b;res`id)];                        / mark as complete in activities table
  .data.save[id;`activities;`matching;([]id:(),actId),\:a];                                     / mark as complete
 };

.data.activity.segments:{[id;start;end]                                                         / [athlete id;start;end] retrieve segments from activities in date range
  .log.o("retrieving segments for activities in range {} to {}";(start;end));

  actIds:exec id from .data.load[id;`activities]where date within(start;end),not complete;      / find non processed activities
  .log.o("{} new activities found";c:count actIds);
  :.data.activity.getSegments1Activity'[id;actIds];                                             / get segments from non processed activities
 };

.data.segments.get1Leaderboard:{[id;segId]                                                      / [athlete id;segment id] get leaderboard for a single segment
  res:.http.segments.leaderboard segId;                                                         / get segment leaderboard
  :.data.save[id;`leaderboards;`matching;res];
 };

.data.segments.leaderboards:{[id;start;end]                                                     / [athlete id;start date;end date] get leaderboards for segments in range
  segs:distinct raze exec segments from .data.load[id;`activities]where date within(start;end); / get all segments in date range
  disk:exec distinct segmentId from .data.load[id;`leaderboards];
  segs:segs except disk;                                                                        / remove cached segments
  .log.o("{} new segments found";count segs);
  .data.segments.get1Leaderboard'[id;segs];                                                     / get segment leaderboards
 };

.data.leaderboard.get:{[id;start;end]                                                           / [athlete id;start;end]
  segs:distinct raze exec segments from .data.load[id;`activities]where date within(start;end); / find all segments in date range
  :select from .data.load[id;`leaderboards]where segmentId in segs;                             / return leaderboards from date range
 };

.data.segments.get1Stream:{[id;segId]                                                           / [athlete id;segment id] retrieve stream data for a segment
  res:.http.segments.steams segId;
  .data.save[id;`segStreams;`matching;res];                                                     / save stream to disk
 };

.data.segments.streams:{[id;start;end]                                                          / [athlete id]
  segs:exec distinct segmentId from .data.leaderboard.get[id;start;end];                        / get segment ids in date range
  strm:distinct exec id from .data.load[id;`segStreams];                                        / get completed segment ids from disk
  segs:segs except strm;                                                                        / remove completed segments
  .log.o("{} new segment streams to retrieve";count segs);
  .data.segments.get1Stream'[id;segs];                                                          / get streams
 };