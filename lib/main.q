// old functions file

.segComp.leaderboard.raw:{[dict]                                                                / compare segments
  dict:delete athlete_id from dict;                                                             / not required
  athId:`$string .http.athlete.current[]`id;                                                    / extract current athlete id
  empty:![([]Segment:());();0b;enlist[athId]!()];                                               / empty results table
  if[not max dict`following`include_clubs;:empty];                                              / exit early if no comparison filters selected
  segments:0!.return.segments.allActivities dict;
  if[0=count segments;:empty];
  details:$[(7=type dict`club_id)&(not all null dict`club_id);
    flip[dict]cross([]segment_id:segments`id);
    @[dict;`segment_id;:;]each segments`id
  ];
/  details:@[@[dict;`club_id;:;(),dict`club_id];`segment_id;:;]each segments`id;
  .log.o"returning segment leaderboards";
  lead:.return.leaderboard.all[1b]each details;
  lead:@[raze lead where 1<count each lead;`athlete_name;`$];		      						/ return results with more than 1 entry
  `.cache.athletes upsert distinct select id:athlete_id, name:athlete_name from lead;
  .data.saveCache[`athletes].cache.athletes;
  .log.o"pivoting results";
  P:asc exec distinct `$string athlete_id from lead;
  res:0!exec P#((`$string athlete_id)!elapsed_time)by Segment:Segment from lead;
  .log.o"returning raw leaderboard";
  :distinct[`Segment,athId,cols res]xcols res;
 };

.segComp.leaderboard.hr:{[dict]
  res:.segComp.leaderboard.raw dict;
  ath:.return.athleteName each "J"$string 1_cols res;
  :(`Segment,ath)xcol update .return.segmentName each Segment from res;
 };

.segComp.leaderboard.html:{[data]
  ath:.return.athleteName each "J"$string 1_cols data;
  :(`Segment,ath)xcol update .return.html.segmentURL each Segment from data;
 };

.segComp.leaderboard.highlight:{[data]
  bb:data,'?[@[data;1_cols data;0w^];();0b;enlist[`tt]!enlist(min@\:;(enlist,1_cols data))];
  func:{$[x=y;"<mark>",string[x],"<mark>";string x]};
  :delete tt from ![bb;();0b;(1_cols data)!{((';x);y;`tt)}[func] each 1_cols data];
 };

.segComp.summary.raw:{[data]
  bb:data,'?[@[data;1_cols data;0w^];();0b;enlist[`tt]!enlist(min@\:;(enlist,1_cols data))];
  func:{x=y};
  res:delete tt from ![bb;();0b;(1_cols data)!{((';x);y;`tt)}[func] each 1_cols data];
  tab:([]Athlete:`$();Total:();Segments:());
  :tab upsert {segs:?[x;enlist(=;y;1);();`Segment]; (y; count segs; segs)}[res] each 1_cols res;
 };

.segComp.summary.hr:{[dict]
  res:.segComp.summary.raw .segComp.leaderboard.raw dict;
  :update .return.athleteName each "J"$string Athlete, .return.segmentName@/:/:Segments from res;
 };

.segComp.summary.html:{[data]
  res:.segComp.summary.raw data;
  :update .return.html.athleteURL each "J"$string Athlete, .return.html.segmentURL@/:/:Segments from res;
 };

.return.params.all:{[params;dict]                                                               / build url from specified altered parameters
  if[0=count dict; :""];                                                                        / if no parametrs return empty string
  def:(!/) .var.defaults`vr`vl;                                                                 / defaults value for parameters
  n:inter[(),params] where not def~'.Q.def[def] {$[10=abs type x;x;string x]} each dict;        / return altered parameters
  :" "sv("-d ",/:string[n],'"="),'{func:exec fc from .var.defaults where vr in x; raze func @\: y}'[n;dict n];  / return parameters
 };

.return.params.valid:{[params;dict] .return.params.all[params] .return.clean[dict]}

.return.activities:{[dict]                                                                      / return activities
  .log.o"retrieving activity list";
  if[0=count .cache.activities;
    act:.http.get.pgn"activities";
    act:`id`name`start_date`commute#/:act where not act@\:`manual;
    data:select`long$id,name,"D"$10#'start_date,commute from act;
    .log.o("retrieved {} activities from strava";count data);
    `.cache.activities upsert data;
    .data.saveCache[`activities].cache.activities;
  ];
  res:select from .cache.activities where start_date within dict`after`before;
  .log.o("found {} activities in date range {} to {}";(count res;dict`after;dict`before));
  :res;
 };

.return.segments.activity:{[n]
  .log.o("getting segment efforts for activity: {}";n);
  if[0=count s:.http.activity.detail[n]`segment_efforts;:enlist 0N];
  rs:distinct select`long$id, name, starred from s[`segment]where not private, not hazardous;
  `.cache.segments upsert rs;                                                                   / upsert to segment cache
  .data.saveCache[`segments].cache.segments;
  :(),rs`id;
 };

.return.segments.allActivities:{[dict]                                                          / return segment data from activity list
  if[dict`starred;sd:.data.segments.starred[]];                                                 / get starred segments
  activ:0!.return.activities dict;
  if[0=count activ;
    .log.e"lack of activities in date range";
    :0#.cache.segments;
   ];
  incache:except[;0N]raze $[0=count .cache.segByAct;();.cache.segByAct activ`id];				/ remove processed activities
  newres:(),exec id from activ where not id in key .cache.segByAct;
  .cache.segByAct,:segs:newres!.return.segments.activity each newres;
  .data.saveCache[`segByAct].cache.segByAct;
  ids:distinct raze incache,value segs; / exec id from .cache.segments where starred;
  .log.o"returning segments";
  res:select from .cache.segments where id in ids;
  if[0=count res; .log.e"lack of segments in date range"];
  :res;
 };

.refresh.segments.byActivity:{[id]
  segs:.return.segments.activity id;
  tab:flip `following`include_clubs`segment_id!flip 10b,/:segs;
  :.return.leaderboard.all[0b] each tab;
 };

.return.segmentName:{[id]
  if[count segName:.cache.segments[id]`name;:segName];                                          / if cached then return name
  :.http.get.simple["segments/",string id]`name;                                                / else request data
 };

.return.html.segmentURL:{[id]
  :.h.ha["http://www.strava.com/segments/",string id].return.segmentName id;
 };

.return.athleteName:{[id]first value .cache.athletes id};

.return.html.athleteURL:{[id]                                                                   / for use with .cache.leaderboards
  :.h.ha["http://www.strava.com/athletes/",string id]string .return.athleteName id;
 };

.return.clubs:{[]                                                                               / return list of users clubs
  .log.o"Retrieving club data";
  .http.athlete.current[];
  if[count .cache.clubs;
    .log.o"Returning cached club data";
    :.cache.clubs;
  ];
  .log.o"Returning club data from strava.com";
  `.cache.clubs upsert rs:select `long$id, name from .http.athlete.current[][`clubs];
  .data.saveCache[`clubs] .cache.clubs;
  :`id xkey rs;
 };

.return.stream.segment:{[segId]
//  .log.o("retrieving stream for segment: {}";segId);
  if[0<count res:raze exec data from .cache.streams.segments where id = segId; :res];
  data:@[;`data]first .http.get.simple"segments/",string[segId],"/streams/latlng";
  `.cache.streams.segments upsert(segId;data);
  .data.saveCache[`seg_streams].cache.streams.segments;
  :data;
 };

.return.stream.activity:{[actId]
  if[0<count res:raze exec data from .cache.streams.activities where id=actId;:res`data];
  data:@[;`data]first .http.get.simple"activities/",string[actId],"/streams/latlng";
  `.cache.streams.activities upsert(actId;data);
  .data.saveCache[`act_streams].cache.streams.activities;
  :data;
 };

.return.leaderboard.all:{[getCache;dict]
  if[not`segment_id in key dict;
    .log.e"Need to specify a segment id";
    :();
   ];
  rs:([athlete_id:`long$()] athlete_name:(); elapsed_time:`minute$(); Segment:`long$());
  if[1b=dict`include_clubs;
    .log.o("returning segment: {}, club_id: {}";dict`segment_id`club_id);
    rs,:.return.leaderboard.sub[getCache;dict;`club_id;dict`club_id];                           / return leaderboard of followers
   ];
  if[1b=dict`following;
    .log.o("returning segment: {}, following";dict`segment_id);
    rs,:.return.leaderboard.sub[getCache;dict;`following;0N];                                   / return leaderboard of clubs
   ];
  :`Segment xcols 0!rs;
 };

.return.leaderboard.sub:{[getCache;dict;typ;leadId]
  if[getCache & 0<count rs:select from .cache.leaderboards where segmentId=dict`segment_id, resType=typ, resId=leadId;
    :(raze exec res from rs) cross ([] Segment:enlist dict`segment_id);
   ];
  extra:.return.params.valid[typ]dict;
  message:.http.get.simpleX["segments/",string[dict`segment_id],"/leaderboard"]extra;
  res:$[0=count message`entries;
    raze exec res from rs;
    select`long$athlete_id,athlete_name,`minute$elapsed_time from message`entries
   ];
  `.cache.leaderboards upsert(dict`segment_id;typ;leadId;res);
  .data.saveCache[`leaderboard].cache.leaderboards;
  :res cross([]Segment:enlist dict`segment_id);
 };
