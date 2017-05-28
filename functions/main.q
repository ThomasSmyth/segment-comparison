
.connect.simple:{[datatype;extra]                               / basic connect function
  res:-29!first system .var.commandBase,datatype," -H \"Authorization: Bearer ",.var.accessToken,"\" ",extra;       / return dictionary attribute-value pairs
  if[.var.sleepOnError & @[{`errors in key x};res;0b];          / sleep on error if specified
    if["rate limit"~raze res[`errors;`field];
       .log.out"rate limit reached, sleeping for ",str:string .var.sleepTime;
       system"sleep ",str;
       res:.z.s[datatype;extra];
     ];
   ];
  :res;
 };

.connect.pagination:{[datatype;extra]           / retrieve paginated results
  :last {[datatype;extra;tab]                   / iterate over pages until no extra results are returned
    tab[1],:ret:.connect.simple[datatype;extra," -d per_page=200 -d page=",string tab 0];
    if[count ret; tab[0]+:1];
    :tab;
  }[datatype;extra]/[(1;())];
 };

.segComp.leaderboard.raw:{[dict]                                / compare segments
  `dict2 set dict;
  dict:delete athlete_id from dict;
  empty:![([] Segment:());();0b;enlist[(`$string .return.athleteData[][`id])]!()];
  if[not max dict`following`include_clubs; :empty];
  segments:0!.return.segments[dict];
  if[0=count segments; :empty];
  details:$[(7=type dict`club_id)&(not all null dict`club_id);
    flip[dict] cross ([] segment_id:segments`id);
    @[dict;`segment_id;:;] each segments`id];
//  details:@[ @[dict;`club_id;:;(),dict`club_id] ;`segment_id;:;] each segments`id;
  .log.out"returning segment leaderboards";
  lead:.return.leaderboard.all each details;
  dd:@[raze lead where 1<count each lead;`athlete_name;`$];
  `.cache.athletes upsert distinct select id:athlete_id, name:athlete_name from dd;
  .log.out"pivoting results";
  P:asc exec distinct `$string athlete_id from dd;
  res:0!exec P#((`$string athlete_id)!elapsed_time) by Segment:Segment from dd;
  cl:`Segment,`$string .return.athleteData[]`id;
  .log.out"returning raw leaderboard";
  :(cl,cols[res] except cl) xcols res;
 };

.segComp.leaderboard.hr:{[dict]
  res:.segComp.leaderboard.raw dict;
  `resRAW set res;
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

.return.clean:{[dict]                                                                           / return existing parameters in correct format 
  def:(!/) .var.defaults`vr`vl;                                                                 / defaults value for parameters
  :.Q.def[def] string key[def]#def,dict;                                                        / return valid optional parameters
 };

.return.params.all:{[params;dict]                                                               / build url from specified altered parameters
  if[0=count dict; :""];                                                                        / if no parametrs return empty string
  def:(!/) .var.defaults`vr`vl;                                                                 / defaults value for parameters
  n:inter[(),params] where not def~'.Q.def[def] {$[10=abs type x;x;string x]} each dict;        / return altered parameters
  :" " sv ("-d ",/:string[n],'"="),'{func:exec fc from .var.defaults where vr in x; raze func @\: y}'[n;dict n];  / return parameters
 };

.return.params.valid:{[params;dict] .return.params.all[params] .return.clean[dict]}

.return.activities:{[dict]                                                                      / return activities
  .log.out"retrieving activity list";
  if[0=count .cache.activities;
    act:.connect.pagination["activities";""];
    data:{select `long$id, name, "D"$10#start_date, commute from x} each act where not act@\:`manual;
    .log.out"retrieved ",string[count data]," activities from strava";
    `.cache.activities upsert data;
  ];
  res:select from .cache.activities where start_date within dict`after`before;
  .log.out"found ",string[count res]," activities in date range ",raze string dict[`after]," to ",dict[`before];
  :res;
 };

.return.activityDetail:{[id]
  :.connect.simple["activities/",string id;""];
 };

.return.segments:{[dict]                                                                        / return segment data from activity list
  if[0=count .cache.segments;
    `.cache.segments upsert {select `long$id, name, starred from x} each .connect.simple["segments/starred";""];  / return starred segments
  ];
  activ:0!.return.activities[dict];
  if[0=count activ;
    .log.error"lack of activities in date range";
    :0#.cache.segments;
  ];
  incache:except[;0N] raze $[0=count .cache.segByAct;();.cache.segByAct activ`id];
  newres:exec id from activ where not id in key .cache.segByAct;
  aa:raze {[n]
    if[0=count s:.return.activityDetail[n][`segment_efforts]; :enlist[n]!enlist[0N]];
    rs:distinct select `long$id, name, starred from s[`segment] where not private, not hazardous;
    `.cache.segments upsert rs;                                                                 / upsert to segment cache
    :enlist[n]!enlist rs`id;
  } each newres;
  .cache.segByAct,:aa;
  ids:distinct raze incache, value[aa], exec id from .cache.segments where starred;
  .log.out"returning segments";
  res:select from .cache.segments where id in ids;
  :$[0<count res; res; .log.error"lack of segments in date range"];
 };

.return.segmentName:{[id]
  if[count segName:.cache.segments[id]`name; :segName];                                         / if cached then return name
  res:.connect.simple ["segments/",string id;""]`name;                                          / else request data
  :res;
 };

.return.html.segmentURL:{[id]
  name:.return.segmentName[id];
  .h.ha["http://www.strava.com/segments/",string id;name]
 };

.return.athleteName:{[id] first value .cache.athletes id};

.return.html.athleteURL:{[id]                                                                   / for use with .cache.leaderboards
  name:.return.athleteName[id];
  .h.ha["http://www.strava.com/athletes/",string id;string name]
 };

.return.clubs:{[]                                                                               / return list of users clubs
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
  if[0<count .var.athleteData; :.var.athleteData];                                              / return cached result if it exists
  .log.out"Retrieving Athlete Data from Strava.com";
  ad:.connect.simple["athlete";""];
  ad[`fullname]:`$" " sv ad[`firstname`lastname];                                               / add fullname to data
  ad:@[ad;`id;`long$];                                                                          / return athlete_id as type long
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
  if[1b=dict`include_clubs;
    {.log.out"returning segment: ",x,", club_id: ",y} . string dict`segment_id`club_id;
    rs,:.return.leaderboard.sub[dict;`club_id;dict`club_id];                                    / return leaderboard of followers
   ];
  if[1b=dict`following;
    .log.out"returning segment: ",string[dict`segment_id],", following";
    rs,:.return.leaderboard.sub[dict;`following;0N];                                            / return leaderboard of clubs
   ];
  :`Segment xcols 0!rs;
 };

.return.leaderboard.sub:{[dict;typ;leadId]
  if[0<count rs:select from .cache.leaderboards where segmentId=dict`segment_id, resType=typ, resId=leadId;
    :(raze exec res from rs) cross ([] Segment:enlist dict`segment_id);
   ];
  extra:.return.params.valid[typ] dict;
  message:.connect.simple["segments/",string[dict`segment_id],"/leaderboard"] extra;
  res:$[0=count message`entries;
    raze exec res from rs;
    select `long$athlete_id, athlete_name, `minute$elapsed_time from message`entries
  ];
  `.cache.leaderboards upsert (dict`segment_id;typ;leadId;res);
  .disk.saveTable[`leaderboard] .cache.leaderboards;
  :res cross ([] Segment:enlist dict`segment_id);
 };

.disk.saveTable:{[table;data]
  if[not .var.saveCache; :()];
  loc:` sv .var.savedir,table;
  :loc set data;
 };

.disk.loadTable:{[table;mem]
  if[not .var.loadCache; :()];
  loc:` sv .var.savedir,table;
  :mem set get loc;
 };

