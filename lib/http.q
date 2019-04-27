.http.token:{
  if[0<count tk:@[get;`.var.token;()];:tk];
  :.var.token:first .load.file.txt[.var.homedir,`config;`token.txt];
 };

.http.hu:.h.hug .Q.an,"-.~";                                                                    / URI escaping for non-safe chars, RFC-3986

.http.unixTS:{(-).`long$("p"$x;1970.01.01D00:00)%1e9};                                          / [date] convert date to unix timestamp

.http.urlencode:{[d]                                                                            / [dict of params]
  if[0=count d;:""];                                                                            / return empty string if no params are passed
  if[`before in key d;d[`before]+:1];                                                           / bump end date by 1 day for inclusive range
  d:@[d;`before`after;.http.unixTS];                                                            / convert dates to unix timestamps
  v:enlist each .http.hu each{$[10=type x;;string]x}'[v:value d];                               / string any values that aren't stringed,escape any chars that need it
  k:enlist each$[all 10=type'[k];;string]k:key d;                                               / if keys aren't strings, string them
  :raze" -d ",/:"="sv'k,'v;                                                                     / return urlencoded form of dictionary
 };

.http.get.basic:{[url;params]                                                                   / [request type; additional parameters] basic http request
  cmd:.utl.sub("{} -H \"Authorization: Bearer {}\" {}";(.utl.sub url;.http.token[];.http.urlencode params));
  :.j.k first system .var.urlRoot,cmd;
 };

.http.get.simpleX:{[url;params]                                                                 / [request type;additional request parameters] basic connect function
  .log.o("retrieving {} {}";(.utl.sub url;$[`page in key params;.utl.sub("page={}";params`page);`]));
  res:.http.get.basic[url;params];                                                              / request data from strava
  if[.var.sleepOnError&@[{`errors in key x};res;0b];                                            / sleep on error if specified
    if["rate limit"~raze res[`errors;`field];                                                   / check for rate limiting error
       .log.o("rate limit reached, sleeping for {}";.var.sleepTime);
       system .utl.sub("sleep {}";.var.sleepTime);                                              / sleep until no longer rate limited
       res:.z.s[url;params];                                                                    / repeat function with same parameters after sleep
     ];
   ];
  :res;
 };

.http.get.simple:.http.get.simpleX[;()!()];                                                     / [request type] simple request with no additional params

.http.get.pgnX:{[url;params]                                                                    / [request type;additional request parameters] retrieve paginated results
  :last{[url;params;res]                                                                        / iterate over pages until no params results are returned
    res[1],:ret:.http.get.simpleX[url;params,`per_page`page!(200;res 0)];
    :@[res;0;+;0<count ret];
  }[url;params]/[(1;())];
 };

.http.get.pgn:.http.get.pgnX[;()!()];                                                           / [request type] pagination request with no additional params

.http.activity.detail:{[id]                                                                     / [activity id] return details for an activity
  :.http.get.simple .utl.sub("activities/{}";id);
 };

.http.activity.getSegments:{[id]                                                                / [activity id] get all segments for an activity
  res:.http.activity.detail id;
  if[0=count res`segment_efforts;:([]id:`long$();name:())];                                     / return blank table if no segments found
  :select`long$id,name from res[`segment_efforts][`segment]where not private,not hazardous;     / filter segment list and return required columns only
 };

.http.athlete.current:{[]                                                                       / get details of current athlete
  ad:.http.get.simple"athlete";                                                                 / http request for current athlete
  ad[`name]:`$" "sv ad`firstname`lastname;                                                      / add fullname to data
  :@[ad;`id;`long$];                                                                            / return athlete_id as type long
 };

.http.athlete.activities:{[id]                                                                  / [athlete id] retrieve activities for an athlete, NOTE only works for current athlete
  .log.o("returning activities for athlete {} from strava";id);
  act:.http.get.pgn"activities";
  act:`id`name`start_date`type`commute#/:act where not act@\:`manual;                           / retrieve valid columns
  act:update`long$id,date:"D"$10#'date from`id`name`date`sport`commute xcol act;                / rename columns, required due to column "type", and transform types
  act:update 0#'segments from update complete:0b,segments:0N from act;                          / add segment info
  .log.o("retrieved {} activities from strava";count act);
  :act;
 };

.http.segments.starred:{[]                                                                      / [] return starred segments for current athlete
  .log.o"returning starred segments for current athlete from strava";
  :@[;`id;"j"$]`id`name`starred#/:.http.get.simple"segments/starred";                           / retrieve starred segments
 };

/ currently restricted to simple + followers
.http.segments.leaderboard:{[segId]                                                             / [segment id]
  res:.http.get.simpleX[("segments/{}/leaderboard";segId);enlist[`following]!enlist`true];      / http rquest for segment leaderboard
  :([]segmentId:(),segId)cross select athlete:athlete_name,time:"v"$elapsed_time from res`entries; / get required columns
 };

.http.segments.steams:{[segId]                                                                  / [segment id]
  res:.http.get.simpleX[("segments/{}/streams";segId);`keys`key_by_type!`latlng`true];          / get stream
  :([]id:(),segId)cross([]stream:enlist raze res[`latlng;`data]);
 };
