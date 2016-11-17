
/ load variables
.var.homedir:getenv[`HOME],"/git/segment_comparison";
system"l ",.var.homedir,"/settings/variables.q";

/ basic connect function
.connect.simple:{[datatype;extra]
  :-29!first system .var.commandBase,datatype," -H \"Authorization: Bearer ",.var.accessToken,"\" ",extra;       / return dictionary attribute-value pairs
 };

.connect.pagination:{[datatype;extra]
  :last {[datatype;extra;tab]                   / iterate over pages until no extra results are returned
    tab[1],:ret:.connect.simple[datatype;extra," -d per_page=200 -d page=",string tab 0];
    if[count ret; tab[0]+:1];
    :tab;
  }[datatype;extra]/[(1;())];
 };

/ show results neatly
showRes:{[segId;resType;resId]
  :([] segmentId:enlist segId) cross .cache.leaderboards[(segId;resType;resId)]`res;
 };

.segComp.wrap:{[dict]
  :$[dict`summary;.segComp.summary.html;.segComp.leaderboard.html] delete athlete_id from dict;
 };

/ compare segments
.segComp.leaderboard.raw:{[dict]
  dict:delete athlete_id from dict;
  empty:![([] Segment:());();0b;enlist[(`$string .return.athleteData[][`id])]!()];
  if[not max dict`following`include_clubs; :empty];
  segments:0!.return.segments[dict];
  details:$[(7=type dict`club_id)&(not all null dict`club_id);
    flip[dict] cross ([] segment_id:segments`id);
    {x[`segment_id]:y; x}[dict]'[segments`id]];
  lead:.return.leaderboard.all each details;
  dd:@[raze lead where 1<count each lead;`athlete_name;`$];
  `.cache.athletes upsert distinct select id:athlete_id, name:athlete_name from dd;
  P:asc exec distinct `$string athlete_id from dd;
  res:0!exec P#((`$string athlete_id)!elapsed_time) by Segment:Segment from dd;
  cl:`Segment,`$string .return.athleteData[][`id];
  :(cl,cols[res] except cl) xcols res;
 };

.segComp.leaderboard.hr:{[dict]
  res:.segComp.leaderboard.raw dict;
  ath:.return.athleteName each "J"$string 1_ cols res;
  :(`Segment,ath) xcol update .return.segmentName each Segment from res;
 };

.segComp.leaderboard.html:{[data]
  ath:.return.athleteName each "J"$string 1_ cols data;
  :(`Segment,ath) xcol update .return.html.segmentURL each Segment from data;
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
  res:([] Athlete:`$(); Total:(); Segments:()) upsert {segs:?[x;enlist(=;y;1);();`Segment]; (y; count segs; segs)}[res] each 1_cols res;
  :res;
 };

.segComp.summary.hr:{[dict]
  res:.segComp.summary.raw .segComp.leaderboard.raw dict;
  :update .return.athleteName each "J"$string Athlete, .return.segmentName@/:/:Segments from res;
 };

.segComp.summary.html:{[data]
  res:.segComp.summary.raw data;
  :update .return.html.athleteURL each "J"$string Athlete, .return.html.segmentURL@/:/:Segments from res;
 };

/ return existing parameters in correct format
.return.clean:{[dict]
  def:(!/) .var.defaults`vr`vl;                             / defaults value for parameters
  :.Q.def[def] string key[def]!(def,dict) key[def];         / return valid optional parameters
 };

/ build url from specified altered parameters
.return.params.all:{[params;dict]
  if[0=count dict; :""];                                    / if no parametrs return empty string
  def:(!/) .var.defaults`vr`vl;                             / defaults value for parameters
  n:inter[(),params] where not def~'.Q.def[def] {$[10=abs type x;x;string x]} each dict; / return altered parameters
  :" " sv ("-d ",/:string[n],'"="),'{func:exec fc from .var.defaults where vr in x; raze func @\: y}'[n;dict n];  / return parameters
 };

.return.params.valid:{[params;dict] .return.params.all[params] .return.clean[dict]}

/ return activities
.return.activities:{[dict]
  if[0=count .cache.activities;
    act:.connect.pagination["activities";""];
    `.cache.activities upsert select `long$id, name, "D"$10#/:start_date, commute from (act where not act@\:`manual); 
  ];
  :select from .cache.activities where start_date within dict`after`before;
 };

.return.activityDetail:{[id]
  :.connect.simple["activities/",string id;""];
 };

/ return segment data from activity list
.return.segments:{[dict]
  if[0=count .cache.segments;
    `.cache.segments upsert select `long$id, name, starred from .connect.simple["segments/starred";""];  / return starred segments
  ];
  activ:0!.return.activities[dict];
  if[0=count activ; :0#.cache.segments];

  chd:except[;0N] raze $[0=count .cache.segByAct;();.cache.segByAct activ`id];
  nchd:exec id from activ where not id in key .cache.segByAct;
  aa:raze {[n]
    if[0=count s:.return.activityDetail[n][`segment_efforts]; :enlist[n]!enlist[0N]];
    rs:distinct select `long$id, name, starred from s[`segment] where not private, not hazardous;
    `.cache.segments upsert rs;                             / upsert to segment cache
    :enlist[n]!enlist rs`id;
  } each nchd;
  .cache.segByAct,:aa;
  ids:distinct raze chd, value[aa], exec id from .cache.segments where starred;
  :select from .cache.segments where id in ids;
 };

.return.segmentName:{[id]
  if[count segName:.cache.segments[id]`name; :segName];     / if cached then return name
//  .log.out"Retrieving segments";
  res:.connect.simple ["segments/",string id;""]`name;      / else request data
//  .log.out"Returning segments";
  :res;
 };

.return.html.segmentURL:{[id]
  name:.return.segmentName[id];
  .h.ha["http://www.strava.com/segments/",string id;name]
 };

.return.athleteName:{[id] first value .cache.athletes id};

.return.html.athleteURL:{[id]      / for use with .cache.leaderboards
  name:.return.athleteName[id];
  .h.ha["http://www.strava.com/athletes/",string id;string name]
 };

/ return list of users clubs
.return.clubs:{[]
  .log.out"Retrieving club data";
  .return.athleteData[];
  if[count .cache.clubs; 
    .log.out"Returning cached club data";
    :.cache.clubs];
  .log.out"Returning club data from strava.com";
  `.cache.clubs upsert rs:select `long$id, name from .return.athleteData[][`clubs];
  :`id xkey rs;
 };

.return.athleteData:{[]
  if[0<count .var.athleteData; :.var.athleteData];                  / return cached result if it exists
  .log.out"Retrieving Athlete Data from Strava.com";
  ad:.connect.simple["athlete";""];
  ad[`fullname]:`$" " sv ad[`firstname`lastname];                   / add fullname to data
  ad:@[ad;`id;`long$];                                              / return athlete_id as type long
  `.var.athleteData set ad;
  :ad;
 };

.return.stream.segment:{[segId]
//  .log.out"Retrieving stream for segment: ",string[segId];
  if[0<count res:raze exec data from .cache.streams.segments where id = segId; :res];
  aa:first .connect.simple["segments/",string[segId],"/streams/latlng";""];
  data:aa`data;
  `.cache.streams.segments upsert (segId;data);
  :data;
 };

.return.stream.activity:{[actId]
  if[0<count res:raze exec data from .cache.streams.activities where id = actId; :res`data];
  aa:first .connect.simple["activities/",string[actId],"/streams/latlng";""];
  data:aa`data;
  `.cache.streams.activities upsert (actId;data);
  :data;
 };

.return.leaderboard.all:{[dict]
  if[not `segment_id in key dict; .log.error"Need to specify a segment id"; :()];
  rs:([athlete_id:`long$()] athlete_name:(); elapsed_time:`minute$(); Segment:`long$());
  if[1b=dict`following; rs,:.return.leaderboard.following[dict]];       / return leaderboard of followers
  if[1b=dict`include_clubs; rs,:.return.leaderboard.club[dict]];    / return leaderboard of clubs
  :`Segment xcols 0!rs;
 };

.return.leaderboard.club:{[dict]
  if[0<count rs:.cache.leaderboards[(dict`segment_id;`club_id;dict`club_id)]`res;
    :rs cross ([] Segment:enlist dict`segment_id);
  ];
  extra:.return.params.valid[`club_id] dict;
  message:.connect.simple["segments/",string[dict`segment_id],"/leaderboard"] extra;
  res:select `long$athlete_id, athlete_name, `minute$elapsed_time from message`entries;
  `.cache.leaderboards upsert (dict`segment_id;`club_id;dict`club_id;res);
  :res cross ([] Segment:enlist dict`segment_id);
 };

.return.leaderboard.following:{[dict]
  if[0<count rs:.cache.leaderboards[(dict`segment_id;`following;0N)]`res;
    :rs cross ([] Segment:enlist dict`segment_id);
  ];
  extra:.return.params.valid[`following] dict;
  message:.connect.simple["segments/",string[dict`segment_id],"/leaderboard"] extra;
  res:select `long$athlete_id, athlete_name, `minute$elapsed_time from message`entries;
  `.cache.leaderboards upsert (dict`segment_id;`following;0N;res);
  :res cross ([] Segment:enlist dict`segment_id);
 };
