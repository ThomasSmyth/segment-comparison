
.var.homedir:getenv[`HOME],"/git/segment_comparison";
.var.accessToken:@[{first read0 x};hsym `$.var.homedir,"/settings/token.txt";{"null token"}];
.var.commandBase:"curl -G https://www.strava.com/api/v3/";
.var.dateRange.activities:();

system"l ",.var.homedir,"/settings/sampleIds.q";

.log.out:{-1 string[.z.p]," | Info | ",x;};
.log.error:{-1 string[.z.p]," | Error | ",x;};

.cache.leaderboards:@[value;`.cache.leaderboards;([segmentId:`long$(); resType:`$(); resId:`long$()] res:())];
.cache.activities:@[value;`.cache.activities;([id:`long$()] name:(); start_date:`date$(); manual:`boolean$(); commute:`boolean$())];
.cache.segments:@[value;`.cache.segments;([id:`long$()] name:(); starred:`boolean$())];
.cache.clubs:@[value;`.cache.clubs;([id:`long$()] name:())];

.var.defaults:flip `vr`vl`fc!flip (
  (`starred;    0b;     ("false";"true")                                        );  / show starred segments
  (`following;  0b;     ("false";"true")                                        );  / compare with those followed
  (`after;      0Nd;    {string (-/)`long$(`timestamp$x;1970.01.01D00:00)%1e9}  );  / start date
  (`before;     0Nd;    {string (-/)`long$(`timestamp$1+x;1970.01.01D00:00)%1e9});  / end date
  (`club_id;    0N;     string                                                  );  / for club comparison
  (`segment_id; 0N;     string                                                  );  / segment to compare on
  (`pivot;      `none;  ::                                                      );
  (`page;       0N;     string                                                  );  / number of pages
  (`per_page;   0N;     string                                                  )   / results per page
 );

/ basic connect function
.connect.simple:{[datatype;extra]
  :-29!first system .var.commandBase,datatype," -d access_token=",.var.accessToken," ",extra;       / return dictionary attribute-value pairs
 };

.connect.pagination:{[datatype;extra]
  tab:(1;());
  data:last {[datatype;extra;tab]
    tab[1],:ret:.connect.simple[datatype;extra," -d page=",string tab 0];
    if[count ret; tab[0]+:1];
    tab
  }[datatype;extra]/[tab];
  :data;
 };


/ show results neatly
showRes:{[segId;resType;resId]
  :([] segmentId:enlist segId) cross .cache.leaderboards[(segId;resType;resId)]`res;
 };

/ compare segments
.segComp.rs.leaderboard:{[dict]
  if[not `club_id in key dict; :.log.error "Need to include club_id"];
  bb:0!.return.segments[dict];
  cc:.return.leaderboard.all each {x[`segment_id]:y; x}[dict]'[bb`id];
  dd:{([] segment:enlist x) cross y}'[bb`name;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  if[0=count @[value;`athleteData;()]; `athleteData set .connect.simple["athlete";""]];
  P:asc exec distinct athlete_name from dd;
  res:0!exec P#(athlete_name!moving_time) by segment:segment from dd;
  cl:`segment,`$" " sv athleteData`firstname`lastname;
  :(cl,cols[res] except cl) xcols res;
 };

.segComp.rs.summary:{[dict]
  if[not `club_id in key dict; :.log.error "Need to include club_id"];
  bb:0!.return.segments[dict];
  cc:.return.leaderboard.all each {x[`segment_id]:y; x}[dict]'[bb`id];
  dd:{([] segment:enlist x) cross y}'[bb`name;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  ee:select segment, athlete_name, moving_time, minTime:(min;moving_time) fby segment from dd;
  :`total xdesc select total:count[segment], segment by athlete_name from ee where moving_time=minTime, 1=(count;i) fby segment;
 };

/ compare segments against all users clubs
.segComp.allClubs.leaderboard:{[]
  bb:0!.return.clubs[];
  res:.segComp.rs.leaderboard each bb`id;
  :uj/[res 0; 1_res];
 };

.webpage.parseDict:{[x]
  `aa set x;
  x:.return.clean x;
  `bb set x;

  // for testing purposes
  dt:`n xkey flip `n`d`t!flip (
    (`activities;  `before`after!(2016.10.28;2016.10.10);   `.return.activities);
    (`none;        `before`after!(2016.10.28;2016.10.10);   `.return.activities);
    (`segments;    `before`after!(2016.10.28;2016.10.27);   `.return.segments);
    (`clubs;       ()!();                                   `.return.clubs);
    (`leaderboard; `segment_id`club_id!(13423965;236501);   `.return.leaderboard.all)
  );

  `dt set pvt:dt x`pivot;
  `x set x;

  // Run function using params
  .log.out "Running query";
  data:@[{[dt] timeit[dt`t;dt`d;outputrows]}; pvt; {'"Didn't execute due to ",x}];
  `dd set data;
  :data;
 };

/ return dictionary of date status
.return.datelist.check:{[t;s;e]                                   / [type;start;end]
  v:sv[`;`.var.dateRange,t];
  if[14<>type s,e; :.log.error"Need to provide a date range"];
  dr:asc distinct (s,e),s+til 1^(e+1)-s;
  d:(!/)flip dr,'0b;
  d[value v]:1b;
  :d;
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
  n:inter[(),params] where not def=.Q.def[def] {$[10=abs type x;x;string x]} each dict; / return altered parameters
  if[all `before`after in n;                                / check timestamps are valid
    if[(<=/)dict`before`after;:.log.error["Before and after timestamps are invalid"]]
  ];
  :" " sv ("-d ",/:string[n],'"="),'{func:exec fc from .var.defaults where vr in x; raze func @\: y}'[n;dict n];  / return parameters
 };

.return.params.valid:{[params;dict] .return.params.all[params] .return.clean[dict]}

/ return activities
.return.activities:{[dict]
  if[not all `before`after in key dict; :.log.error"Need to provide date range"];
  dr:.return.datelist[`check][`activities;dict`after;dict`before];
  if[0=count where not dr; :select from .cache.activities where start_date in where dr];  / return cached results if they exist
  p:.return.params.valid[`before`after`per_page;dict];     / additional url parameters
  activ:.connect.pagination["activities";p];           / connect and return activites
  rs:{select `long$id, name, "D"$10#\:start_date, manual, commute from x} each activ;  / extract relevent fields
  `.cache.activities upsert rs;
  `.var.dateRange.activities set asc distinct .var.dateRange.activities,where not dr;
  :`id xkey rs;
 };

/ return segment data from activity list
.return.segments:{[dict]
  if[count cr:select from .cache.segments; :cr];            / if results cached then return here
  activ:.return.activities[dict];
  segs:.connect.simple[;""] each "activities/",/:string exec id from activ where not manual;
  rs:distinct select `long$id, name, starred from raze[segs`segment_efforts]`segment where not private;  / return segment ids from activities
  rs,:select `long$id, name, starred from .connect.simple["segments/starred";""];  / return starred segments
  `.cache.segments upsert rs;                               / upsert to segment cache
  :`id xkey rs;
 };

.return.segmentName:{[id]
  if[count segName:.cache.segments[id]`name; :segname]; / if cached then return name
  .connect.simple ["segments/",string id;""]`name}      / else request data

.return.html.segmentURL:{[id]
  name:.return.segmentName[id];
  .h.ha["http://www.strava.com/segments/",string id;name]
 };

.return.html.athleteURL:{[id;name]      / for use with .cache.leaderboards
  .h.ha["http://www.strava.com/athletes/",string id;name]
 };

/ return list of users clubs
.return.clubs:{[]
  if[0=count @[value;`athleteData;()]; `athleteData set .connect.simple["athlete";""]];
  if[count .cache.clubs; :.cache.clubs];
  `.cache.clubs upsert rs:select `long$id, name from athleteData[`clubs];
  :`id xkey rs;
 };

.return.leaderboard.all:{[dict]
  if[not `segment_id in key dict; .log.error"Need to specify a segment id"; :()];
  if[not any `club_id`following in key dict; .log.error"Need to specify club_id or athletes followed"; :()];
  rs:([athlete_id:`long$()] athlete_name:(); moving_time:`minute$());
  if[1b=dict`following; rs,:.return.leaderboard.following[dict]];       / return leaderboard of followers
  if[`club_id in key dict; rs,:.return.leaderboard.club[dict]];         / return leaderboard of clubs
  :0!rs;
 };

.return.leaderboard.club:{[dict]
  if[0<count rs:.cache.leaderboards[(dict`segment_id;`club;dict`club_id)]`res; :rs];
  extra::.return.params.valid[`club_id] dict;
  message::.connect.simple["segments/",string[dict`segment_id],"/leaderboard"] extra;
  clb:select `long$athlete_id, athlete_name, `minute$moving_time from message`entries;
  `.cache.leaderboards upsert (dict`segment_id;`club;dict`club_id;clb);
  :clb;
 };

.return.leaderboard.following:{[dict]
  if[0<count rs:.cache.leaderboards[(dict`segment_id;`following;0N)]`res; :rs];
  extra:.return.params.valid[`following] dict;
  message:.connect.simple["segments/",string[dict`segment_id],"/leaderboard"] extra;
  fol:select `long$athlete_id, athlete_name, `minute$moving_time from message`entries;
  `.cache.leaderboards upsert (dict`segment_id;`following;0N;fol);
  :fol;
 };
