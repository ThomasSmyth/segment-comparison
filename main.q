
.var.homedir:getenv[`HOME],"/git/segment_comparison";
.var.accessToken:@[{first read0 x};hsym `$.var.homedir,"/settings/token.txt";{x;log.error"null token"}];
.var.commandBase:"curl -G https://www.strava.com/api/v3/";
.var.athleteData:();

system"l ",.var.homedir,"/settings/sampleIds.q";

.log.out:{-1 string[.z.p]," | Info | ",x;};
.log.error:{-1 string[.z.p]," | Error | ",x; 'x};

.cache.leaderboards:@[value;`.cache.leaderboards;([segmentId:`long$(); resType:`$(); resId:`long$()] res:())];
.cache.activities:@[value;`.cache.activities;([id:`long$()] name:(); start_date:`date$(); commute:`boolean$())];
.cache.segments:@[value;`.cache.segments;([id:`long$()] name:(); starred:`boolean$())];
.cache.clubs:@[value;`.cache.clubs;([id:`long$()] name:())];
.cache.athletes:@[value;`.cache.athletes;([id:`long$()] name:())];

.var.defaults:flip `vr`vl`fc!flip (
  (`starred      ; 0b   ; ("false";"true")                                        );  / show starred segments
  (`summary      ; 0b   ; ("false";"true")                                        );  / summarise results
  (`following    ; 0b   ; ("false";"true")                                        );  / compare with those followed
  (`include_clubs; 0b   ; ("false";"true")                                        );  / for club comparison
  (`after        ; 0Nd  ; {string (-/)`long$(`timestamp$x;1970.01.01D00:00)%1e9}  );  / start date
  (`before       ; 0Nd  ; {string (-/)`long$(`timestamp$1+x;1970.01.01D00:00)%1e9});  / end date
  (`club_id      ; (),0N; string                                                  );  / for club comparison
  (`segment_id   ; 0N   ; string                                                  );  / segment to compare on
  (`page         ; 0N   ; string                                                  )   / number of pages
 );

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

/ compare segments
.segComp.leaderboard.raw:{[dict]
//  empty:([] Segment:`long$(); athlete_id:`long$(); athlete_name:`$(); elapsed_time:`minute$());
  empty:![([] Segment:());();0b;enlist[(`$string `long$.return.athleteData[][`id])]!()];
  if[not max dict`following`include_clubs; :empty];
  segments:0!.return.segments[dict];
  details:$[(7=type dict`club_id)&(not all null dict`club_id);
    flip[dict] cross ([] segment_id:segments`id);
    {x[`segment_id]:y; x}[dict]'[segments`id]];
  lead:.return.leaderboard.all each details;
  dd:@[raze lead where 1<count each lead;`athlete_name;`$];
  `.cache.athletes upsert distinct select id:athlete_id, name:athlete_name from dd;
//  empty:![([] Segment:());();0b;enlist[(`$string `long$.return.athleteData[][`id])]!()];
//  if[0=count dd; :empty];
  P:asc exec distinct `$string athlete_id from dd;
  res:0!exec P#((`$string athlete_id)!elapsed_time) by Segment:Segment from dd;
  cl:`Segment,`$string`long$.return.athleteData[][`id];
  :(cl,cols[res] except cl) xcols res;
 };

.segComp.leaderboard.hr:{[dict]
  res:.segComp.leaderboard.raw dict;
  ath:.return.athleteName each "J"$string 1_ cols res;
  :(`Segment,ath) xcol update .return.segmentName each Segment from res;
 };

.segComp.leaderboard.html:{[dict]
  res:.segComp.leaderboard.highlight dict;
//  ath:`$.return.html.athleteURL each "J"$string 1_ cols res;
//  res:(`Segment,ath) xcol res;
  ath:.return.athleteName each "J"$string 1_ cols res;
  :(`Segment,ath) xcol update .return.html.segmentURL each Segment from res;
 };

.segComp.leaderboard.highlight:{[dict]
  aa:.segComp.leaderboard.raw dict;
  bb:aa,'?[@[aa;1_cols aa;0w^];();0b;enlist[`tt]!enlist(min@\:;(enlist,1_cols aa))];
  func:{$[x=y;"<mark>",string[x],"<mark>";string x]};
  :delete tt from ![bb;();0b;(1_cols aa)!{((';x);y;`tt)}[func] each 1_cols aa];
 };

.segComp.summary.raw:{[dict]
  aa:.segComp.leaderboard.raw dict;
  bb:aa,'?[@[aa;1_cols aa;0w^];();0b;enlist[`tt]!enlist(min@\:;(enlist,1_cols aa))];
  func:{x=y};
  res:delete tt from ![bb;();0b;(1_cols aa)!{((';x);y;`tt)}[func] each 1_cols aa];
  res:([] Athlete:`$(); Total:(); Segments:()) upsert {segs:?[x;enlist(=;y;1);();`Segment]; (y; count segs; segs)}[res] each 1_cols res;
  :res;
 };

.segComp.summary.hr:{[dict]
  res:.segComp.summary.raw dict;
  :update .return.athleteName each "J"$string Athlete, .return.segmentName@/:/:Segments from res;
 };

.segComp.summary.html:{[dict]
  res:.segComp.summary.raw dict;
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

/ return segment data from activity list
.return.segments:{[dict]
  if[count cr:select from .cache.segments; :cr];            / if results cached then return here
  activ:0!.return.activities[dict];
  if[0=count activ; :cr];
  segs:.connect.simple[;""] each "activities/",/:string exec id from activ;
  rs:distinct select `long$id, name, starred from raze[segs`segment_efforts]`segment where not private, not hazardous;  / return segment ids from activities
  rs,:select `long$id, name, starred from .connect.simple["segments/starred";""];  / return starred segments
  `.cache.segments upsert rs;                               / upsert to segment cache
  :`id xkey rs;
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
  .log.out"Retrieving activites";
  if[0<count .var.athleteData; :.var.athleteData];
  ad:.connect.simple["athlete";""];
  ad[`fullname]:`$" " sv ad[`firstname`lastname];
  `.var.athleteData set ad;
  :ad;
 };

.return.leaderboard.all:{[dict]
  if[not `segment_id in key dict; .log.error"Need to specify a segment id"; :()];
  rs:([athlete_id:`long$()] athlete_name:(); elapsed_time:`minute$(); Segment:`long$());
  if[1b=dict`following; rs,:.return.leaderboard.following[dict]];       / return leaderboard of followers
  if[not any null dict`club_id; rs,:.return.leaderboard.club[dict]];    / return leaderboard of clubs
  :`Segment xcols 0!rs;
 };

.return.leaderboard.club:{[dict]
  if[0<count rs:.cache.leaderboards[(dict`segment_id;`club;dict`club_id)]`res;
    :rs cross ([] Segment:enlist dict`segment_id);
  ];
  extra:.return.params.valid[`club_id] dict;
  message:.connect.simple["segments/",string[dict`segment_id],"/leaderboard"] extra;
  clb:select `long$athlete_id, athlete_name, `minute$elapsed_time from message`entries;
  `.cache.leaderboards upsert (dict`segment_id;`club;dict`club_id;clb);
  :clb cross ([] Segment:enlist dict`segment_id);
 };

.return.leaderboard.following:{[dict]
  if[0<count rs:.cache.leaderboards[(dict`segment_id;`following;0N)]`res;
    :rs cross ([] Segment:enlist dict`segment_id);
  ];
  extra:.return.params.valid[`following] dict;
  message:.connect.simple["segments/",string[dict`segment_id],"/leaderboard"] extra;
  fol:select `long$athlete_id, athlete_name, `minute$elapsed_time from message`entries;
  `.cache.leaderboards upsert (dict`segment_id;`following;0N;fol);
  :fol cross ([] Segment:enlist dict`segment_id);
 };
