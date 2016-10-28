
homedir:getenv[`HOME],"/git/segment_comparison";

accessToken:@[{first read0 x};hsym `$homedir,"/settings/token.txt";{"null token"}];

system"l ",homedir,"/settings/sampleIds.q";

cache:@[value;`cache;([segmentId:`long$(); resType:`$(); resId:`long$()] res:())];
segCache:@[value;`segCache;([id:`long$()] name:(); starred:`boolean$())];
clubCache:@[value;`clubCache;([id:`long$()] name:())];
gotStarred:0b;

urlBase:"https://www.strava.com/api/v3/";

/ basic connect function
connect:{[token;urlBase;datatype]
  message::first system"curl -G ",urlBase,datatype," -d access_token=",token;
  :-29!message;                                                 / return dictionary attribute-value pairs
 }[accessToken;urlBase]

/ show results neatly
showRes:{[segId;resType;resId]
  :([] segmentId:enlist segId) cross cache[(segId;resType;resId)]`res;
 };

/ compare segments to followed athletes
.segComp.follow:{[]
  bb:0!.returnSegments.all[];
  cc:.leaderboard.followers each bb`id;
  dd:{([] segment:enlist x) cross y}'[bb`name;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  if[0=count @[value;`athleteData;()]; `athleteData set connect["athlete"]];
  P:asc exec distinct athlete_name from dd;
  res:0!exec P#(athlete_name!moving_time) by segment:segment from dd;
  cl:`segment,`$" " sv athleteData`firstname`lastname;
  :(cl,cols[res] except cl) xcols res;
 };

/ compare segments to a club
.segComp.club:{[clubId]
  bb:0!.returnSegments.all[];
  cc:.leaderboard.club[;clubId] each bb`id;
  dd:{([] segment:enlist x) cross y}'[bb`name;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  if[0=count @[value;`athleteData;()]; `athleteData set connect["athlete"]];
  P:asc exec distinct athlete_name from dd;
  res:0!exec P#(athlete_name!moving_time) by segment:segment from dd;
  cl:`segment,`$" " sv athleteData`firstname`lastname;
  :(cl,cols[res] except cl) xcols res;
 };

/ new all clubs
.segComp.allClubs:{[]
  bb:0!.return.allClubs[];
  res:.segComp.club each bb`id;
  :uj/[res 0; 1_res];
 };

/ return segments from last 30 activities
.returnSegments.all:{[]
  if[count aa:select from segCache; :aa];                     / if results cached then return here
  activ:raze `long${$[x`manual;();x`id]} each connect "athlete/activities";
  segs:connect each "activities/",/:string activ;
  segs:distinct select `long$id, name, starred from raze[segs`segment_efforts]`segment where not private;
  `segCache upsert segs;
  :segs;
 };

/ return starred segments
.returnSegments.starred:{[] 
  if[gotStarred; :select from segCache where starred];
  `gotStarred set 1b;
  star:select `long$id, name, starred from connect "segments/starred";
  `segCache upsert star;
  :star;
 };

.return.allClubs:{[]
  if[0=count @[value;`athleteData;()]; `athleteData set connect["athlete"]];
  if[count clubCache; :clubCache];
  `clubCache upsert allClubs:select `long$id, name from athleteData[`clubs];
  :allClubs;
 };

/ return follower leaderboard for a segment
.leaderboard.followers:{[token;urlBase;segId]
  if[count rs:exec res from cache where segmentId=segId, resType=`follower, resId=0N; :raze rs];
  message:-29!first system"curl -G ",urlBase,"segments/",string[segId],"/leaderboard -d access_token=",token," -d following=true";
  leadFol:select athlete_name, moving_time from message`entries;
  `cache upsert ([] segmentId:enlist segId; resType:`follower; resId:0N; res:enlist leadFol);
  :leadFol;
 }[accessToken;urlBase];

/ return club leaderboard for a segment
.leaderboard.club:{[token;urlBase;segId;clubId]
  if[count res:exec res from cache where segmentId=segId, resType=`club, resId=clubId; :raze res];
  message:-29!first system"curl -G ",urlBase,"segments/",string[segId],"/leaderboard -d access_token=",token," -d club_id=",string[clubId];
  leadClub:select athlete_name, moving_time from message`entries;
  `cache upsert ([] segmentId:enlist segId; resType:`club; resId:clubId; res:enlist leadClub);
  :leadClub;
 }[accessToken;urlBase];

