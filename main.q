
accessToken:@[{first read0 x};`:settings/token.txt;{"null token"}];

system"l settings/sampleIds.q";

actId:@[value;`actId;""];
athId:@[value;`athId;""];
athId2:string 1811586;
segId:@[value;`segId;""];
clubId:@[value;`clubId;""];

urlBase:"https://www.strava.com/api/v3/";

oauth:"oauth";
athlete:"athlete";
athleteById:"athletes/",athId;
activity:"activities/",actId;
activityStream:"activities/",actId,"/streams";
club:"clubs/",clubId;
segment:"segments/",segId;
segmentLeaderboard:"segments/",segId,"/leaderboard";
segmentAllEfforts:"segments/",segId,"/all_efforts";
uploads:"uploads";

connect:{[token;urlBase;datatype]
  message::first system"curl -G ",urlBase,datatype," -d access_token=",token;
  :-29!message;                                            / return dictionary attribute-value pairs
 }[accessToken;urlBase]

// all segments from last 30 activites
last30segs:{[id]
  last30:@[connect "athletes/",id,"/activities";`id;`long$];

  segs:connect each "activities/",/:string last30`id;

  segs2:@[raze segs`segment_efforts;`id;`long$];
  //allSegIds:exec distinct id from segs2`segment;
  :select min moving_time, first name by id from segs2;
 };



/ compare segments to followed athletes
.segComp.follow:{[]
  bb:@[.returnSegments.all[];`id;`long$];
  cc:.leaderboard.followers each string bb`id;
  dd:{([] segment:enlist x) cross y}'[bb`name;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  P:asc exec distinct athlete_name from dd;
  `folRes set pvt:exec P#(athlete_name!moving_time) by segment:segment from dd;
  :pvt;
 };

/ compare segments to a club
.segComp.club:{[cludId]
  bb:@[.returnSegments.all[];`id;`long$];
  cc:.leaderboard.club[;clubId] each string bb`id;
  dd:{([] segment:enlist x) cross y}'[bb`name;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  P:asc exec distinct athlete_name from dd;
  `clubRes set pvt:exec P#(athlete_name!moving_time) by segment:segment from dd;
  :pvt;
 };

/ compare segments across all clubs
.segComp.allClubs:{[]
  allClubs:string `long$connect["athlete"][`clubs;`id];
  bb:@[.returnSegments.all[];`id;string `long$];
  ii:(flip bb`name`id) cross (enlist each allClubs);
  cc:.leaderboard.club ./: -2#/:ii;
  dd:{([] segment:enlist x) cross y}'[1#/:ii;cc];
  dd:@[raze dd where 1<count each dd;`athlete_name;`$];
  P:asc exec distinct athlete_name from dd;
  `allClubRes set pvt:exec P#(athlete_name!moving_time) by segment:segment from dd;
  :pvt;
 };

/ return segments from last 30 activities
.returnSegments.all:{[]
  act:@[connect "athlete/activities";`id;`long$];
  segs:connect each "activities/",/:string act`id;
  `segs set segs:distinct select id, name from raze[segs`segment_efforts]`segment where not private;
  :segs;
 };

/ return starred segments
.returnSegments.starred:{[] 
  `starredSegments set star:`id`name#@[connect "segments/starred";`id;`long$];
  :star;
 };

/ return follower leaderboard for a segment
.leaderboard.followers:{[token;urlBase;segId]
  message:-29!first system"curl -G ",urlBase,"segments/",segId,"/leaderboard -d access_token=",token," -d following=true";
  :select athlete_name, moving_time from message`entries;
 }[accessToken;urlBase];

/ return club leaderboard for a segment
.leaderboard.club:{[token;urlBase;segId;clubId]
  message:-29!first system"curl -G ",urlBase,"segments/",segId,"/leaderboard -d access_token=",token," -d club_id=",clubId;
  :select athlete_name, moving_time from message`entries;
 }[accessToken;urlBase];

