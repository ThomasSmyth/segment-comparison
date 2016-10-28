

.var.homedir:getenv[`HOME],"/git/segment_comparison";
.var.accessToken:@[{first read0 x};hsym `$.var.homedir,"/settings/token.txt";{"null token"}];
.var.commandBase:"curl -G https://www.strava.com/api/v3/";

system"l ",.var.homedir,"/settings/sampleIds.q";

.log.out:{-1 string[.z.p]," | Info | ",x;};
.log.error:{-1 string[.z.p]," | Error | ",x;};

.cache.leaderboards:@[value;`.cache.leaderboards;([segmentId:`long$(); resType:`$(); resId:`long$()] res:())];
.cache.segments:@[value;`.cache.segments;([id:`long$()] name:(); starred:`boolean$())];
.cache.clubs:@[value;`.cache.clubs;([id:`long$()] name:())];


defaults:(!/) flip (
    (`starred;  0b);
    (`follower; 1b);
    (`clubId;   0b));

/ basic connect function
connect:{[token;commandBase;datatype;extra]
  :-29!first system commandBase,datatype," -d access_token=",token," ",extra;       / return dictionary attribute-value pairs
 }[.var.accessToken;.var.commandBase];

/ show results neatly
showRes:{[segId;resType;resId]
  :([] segmentId:enlist segId) cross .cache.leaderboards[(segId;resType;resId)]`res;
 };

/ compare segments
.segComp.rs:{[clubId]
  bb:0!.return.segments[];
  cc:.return.leaderboard[;clubId] each bb`id;
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

/ return segments from last 30 activities
.return.segments:{[]
  if[count aa:select from .cache.segments; :aa];                     / if results cached then return here
  activ:raze `long${$[x`manual;();x`id]} each connect["athlete/activities";""];
  segs:connect[;""] each "activities/",/:string activ;
  segs:distinct select `long$id, name, starred from raze[segs`segment_efforts]`segment where not private;
  rs:select `long$id, name, starred from connect["segments/starred";""];
  `.cache.segments upsert r:segs,rs;
  :`id xkey r;
 };

/ return list of users clubs
.return.clubs:{[]
  if[0=count @[value;`athleteData;()]; `athleteData set connect["athlete";""]];
  if[count .cache.clubs; :.cache.clubs];
  `.cache.clubs upsert rs:select `long$id, name from athleteData[`clubs];
  :`id xkey rs;
 };

.return.leaderboard:{[segId;clubId] 
  if[null segId; .log.error"Need to specify segmentId"; :()];
  $[null clubId;
    [tp:`following; extra:"-d following=true"];
    [tp:`club; extra:"-d club_id=",string clubId]
   ];
  if[count rs:exec res from .cache.leaderboards where segmentId=segId, resType=tp, resId=clubId; :raze rs];
  message:connect["segments/",string[segId],"/leaderboard"] extra;
  rs:select athlete_name, moving_time from message`entries;
  `.cache.leaderboards upsert (segId;tp;clubId;rs);
  :rs;
 };
