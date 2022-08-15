// main functions file

/ return all starred segments for current athlete and cache
.return.segments.starred:{
  if[count .cache.segments;:.cache.segments];
  starred:.connect.pagination["segments/starred";""];
  / upsert to cache
  `.cache.segments upsert @[`id`name`starred#/:starred;`id;`long$];
  :.cache.segments;
 };

.return.segmentName:{[id]
  if[count segName:.cache.segments[id]`name; :segName];                                         / if cached then return name
  res:.connect.simple ["segments/",string id;""]`name;                                          / else request data
  :res;
 };

.return.html.segmentURL:{[id]
  :.h.ha["http://www.strava.com/segments/",string id] .return.segmentName[id];
 };

.return.athlete.data:{[]
  if[0<count .var.athleteData; :.var.athleteData];                                              / return cached result if it exists
  .log.out"Retrieving Athlete Data from Strava API";
  ad:.connect.simple["athlete";""];
  ad[`fullname]:`$" " sv ad[`firstname`lastname];                                               / add fullname to data
  ad:@[ad;`id;`long$];                                                                          / return athlete_id as type long
  `.var.athleteData set ad;
  :ad;
 };

.return.athlete.koms:{[]
  id:.return.athlete.data[]`id;
  kom:.connect.pagination["athletes/",string[id],"/koms";""];
  :@[`id`name`starred#/:kom@\:`segment;`id;`long$];
 };

.return.stream.segment:{[segId]
  .log.out"Retrieving stream for segment: ",string[segId];
  if[0<count res:raze exec data from .cache.streams.segments where id=segId;:res];
  stream:first .connect.simple["segments/",string[segId],"/streams/latlng";""];
  data:stream`data;
  `.cache.streams.segments upsert (segId;data);
  .disk.saveCache[`seg_streams] .cache.streams.segments;
  :data;
 };
