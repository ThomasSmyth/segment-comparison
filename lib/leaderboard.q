/ return leaderboard tables

.ldr.main:{[dict]
  raw:.ldr.raw dict`current_athlete;                                                            / retrieve raw leaderboard
  data:0!.ldr.display[`default`summary dict`summary][dict`current_athlete;raw];                 / display data using chosen method
  :data;
 };

.ldr.display.default:{[id;data]                                                                 / [athlete id;data] display best times
  .log.o"producing default leaderboard";
  data:.ldr.html.mark data;                                                                     / highlight best times
  data:.ldr.pivot data;                                                                         / pivot results
  :.ldr.html.segments[id;data];                                                                 / convert segment id to name and add a link to segment page
 };

.ldr.display.summary:{[id;data]                                                                 / [athlete id;data] display best time counts
  .log.o"producing leaderboard summary";
  data:select from data where time=(min;time)fby segmentId;                                     / get best times by segment
  data:select total:count i,segments:name by athlete from .ldr.html.segments[id;data];          / return summary
  :`total xdesc update", "sv/:segments from data;                                               / comma separate values
 };

.ldr.map:{[dict]                                                                                / [dict] get streams and markers for all segments in date range
  data:.ldr.raw dict`current_athlete;
  sm:.data.load[dict`current_athlete;`segments];                                                / segment map
  strms:update{2 cut raze x}'[stream]from .data.load[dict`current_athlete;`segStreams];
  strms:update mark:{first[y],x[z][`name],z}[sm]'[stream;id]from strms;                         / add marker for segment start
  bounds:(min;max)@\:raze exec stream from strms;                                               / get map boundaries
  segs:exec segmentId by athlete from data where time=(min;time)fby segmentId;
  p:`plottype`names`bounds!(`lineMarkers;aths:key segs;bounds);                                 / form result dictionary
  p[`polyline]:(exec id!stream from strms)v:value segs;
  p[`markers]:(exec id!mark from strms)v;
  :p;
 };

.ldr.raw:{[id]                                                                                  / [athlete id] return raw leaderboards
  .log.o"returning raw leaderboard";
  data:@[;`athlete;`$]0!.data.load[id;`leaderboards];                                           / get leaderboards
  :select from data where 1<(count;i)fby segmentId;                                             / return segments with more then 1 entry on leaderboard
 };

.ldr.pivot:{[data]                                                                              / [data] pivot leaderboard
  .log.o"pivoting leaderboard";
  ul:exec distinct athlete from data;                                                           / get athlete list
  :0!exec ul#(athlete!time)by segmentId:segmentId from data;                                    / return unkeyed table
 };

.ldr.html.segments:{[id;data]                                                                   / [athlete id;data] add links to segments
  .log.o"adding segment links";
  segIds:exec segmentId from data;                                                              / get distinct segments
  segs:select segmentId:id,name from .data.load[id;`segments]where id in segIds;                / select only segments in leaderboard
  segs:1!update name:.html.a.segment'[segmentId;name]from segs;                                 / create hyperlinks
  :delete segmentId from`name xcols data lj segs;                                               / join segment names
 };

.ldr.html.mark:{[data]                                                                          / highlight the best time for each segment
  .log.o"marking best times";
  f:{$[y;{.utl.sub("<mark>{}<mark>";x)};]x};                                                    / function to mark best times
  :update time:f'[string time;time=(min;time)fby segmentId]from data;                           / mark best times
 };
