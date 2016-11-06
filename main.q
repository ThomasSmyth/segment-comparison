
.var.homedir:getenv[`HOME],"/git/segment_comparison";
.var.accessToken:@[{first read0 x};hsym `$.var.homedir,"/settings/token.txt";{"null token"}];
.var.commandBase:"curl -G https://www.strava.com/api/v3/";
.var.dateRange.activities:();

system"l ",.var.homedir,"/settings/sampleIds.q";

.log.out:{-1 string[.z.p]," | Info | ",x;};
.log.error:{-1 string[.z.p]," | Error | ",x;};

.cache.leaderboards:@[value;`.cache.leaderboards;([segmentId:`long$(); resType:`$(); resId:`long$()] res:())];
.cache.activities:@[value;`.cache.activities;([id:`long$()] name:(); start_date:`date$(); manual:`boolean$())];
.cache.segments:@[value;`.cache.segments;([id:`long$()] name:(); starred:`boolean$())];
.cache.clubs:@[value;`.cache.clubs;([id:`long$()] name:())];

.var.defaults:flip `vr`vl`fc!flip (
  (`starred;    0b;     ("false";"true")                                        );  / show starred segments
  (`follower;   0b;     ("false";"true")                                        );  / compare with followers
  (`after;      0Nd;    {string (-/)`long$(`timestamp$x;1970.01.01D00:00)%1e9}  );  / start date
  (`before;     0Nd;    {string (-/)`long$(`timestamp$1+x;1970.01.01D00:00)%1e9});  / end date
  (`club_Id;    0N;     string                                                  );  / for club comparison
  (`segment_Id; 0N;     string                                                  );  / segment to compare on
  (`pivot;      `none;  ::                                                      );
  (`page;       0N;     string                                                  );  / number of pages
  (`per_page;   0N;     string                                                  )   / results per page
 );

/ basic connect function
connect:{[token;commandBase;datatype;extra]
  :-29!first system commandBase,datatype," -d access_token=",token," ",extra;       / return dictionary attribute-value pairs
 }[.var.accessToken;.var.commandBase];

/ show results neatly
showRes:{[segId;resType;resId]
  :([] segmentId:enlist segId) cross .cache.leaderboards[(segId;resType;resId)]`res;
 };

/ compare segments
.segComp.rs:{[dict]
  if[not `club_Id in key dict; :.log.error "Need to include club_Id"];
  clubId:dict`club_Id;
  bb:0!.return.segments[dict];
  cc:.return.leaderboard each {x[`segment_Id]:y; x}[dict]'[bb`id];
  dd:{([] segment:enlist x) cross y}'[bb`name;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  if[0=count @[value;`athleteData;()]; `athleteData set connect["athlete";""]];
  P:asc exec distinct athlete_name from dd;
  res:0!exec P#(athlete_name!moving_time) by segment:segment from dd;
  cl:`segment,`$" " sv athleteData`firstname`lastname;
  :(cl,cols[res] except cl) xcols res;
 };

/ compare segments against all users clubs
.segComp.allClubs:{[]
  bb:0!.return.clubs[];
  res:.segComp.rs each bb`id;
  :uj/[res 0; 1_res];
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
  :.Q.def[def] string key[def]!dict[key def];               / return valid optional parameters
 };

/ build url from specified altered parameters
.return.url:{[params;dict]
  if[0=count dict; :""];                                    / if no parametrs return empty string
  def:(!/) .var.defaults`vr`vl;                             / defaults value for parameters
  n:inter[(),params] where not def=.Q.def[def] {$[10=abs type x;x;string x]} each dict; / return altered parameters
  if[all `before`after in n;                                / check timestamps are valid
    if[(<=/)dict`before`after;:.log.error["Before and after timestamps are invalid"]]
  ];
  :" " sv ("-d ",/:string[n],'"="),'(exec fc from .var.defaults where vr in n)@' dict n;  / return parameters
 };

.return.cleanUrl:{[params;dict] .return.url[params] .return.clean[dict]}

/ return activities
.return.activities:{[dict]
  if[not all `before`after in key dict; :.log.error"Need to provide date range"];
  dr:.return.datelist[`check][`activities;dict`after;dict`before];
  if[0=count where not dr; :select from .cache.activities where start_date in where dr];  / return cached results if they exist
  p:.return.cleanUrl[`before`after`page`per_page;dict];     / additional url parameters
  rs:{select `long$id, name, "D"$10#\:start_date, manual from x} each connect["activities";p];
  `.cache.activities upsert rs;
  `.var.dateRange.activities set asc distinct .var.dateRange.activities,where not dr;
  :`id xkey rs;
 };

/ return segment data from activity list
.return.segments:{[dict]
  if[count cr:select from .cache.segments; :cr];            / if results cached then return here
  activ:.return.activities[dict];
  segs:connect[;""] each "activities/",/:string exec id from activ where not manual;
  rs:distinct select `long$id, name, starred from raze[segs`segment_efforts]`segment where not private;  / return segment ids from activities
  rs,:select `long$id, name, starred from connect["segments/starred";""];  / return starred segments
  `.cache.segments upsert rs;                               / upsert to segment cache
  :`id xkey rs;
 };

/ return list of users clubs
.return.clubs:{[]
  if[0=count @[value;`athleteData;()]; `athleteData set connect["athlete";""]];
  if[count .cache.clubs; :.cache.clubs];
  `.cache.clubs upsert rs:select `long$id, name from athleteData[`clubs];
  :`id xkey rs;
 };

.return.leaderboard:{[dict]
  segId:dict`segment_Id;
  clubId:dict`club_Id; 
  if[null segId; .log.error"Need to specify segmentId"; :()];
  $[null clubId;
    [tp:`following; extra:"-d following=true"];
    [tp:`club; extra:"-d club_id=",string clubId]
   ];
  if[count rs:exec res from .cache.leaderboards where segmentId=segId, resType=tp, resId=clubId; :raze rs];
  message:connect["segments/",string[segId],"/leaderboard"] extra;
  rs:select athlete_name, `minute$moving_time from message`entries;
  `.cache.leaderboards upsert (segId;tp;clubId;rs);
  :rs;
 };

.return.results:{[dict]         / replacement for .return.leaderboard
  dict
 };
