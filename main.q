
accessToken:@[{first read0 x};`:settings/token.txt;{"null token"}];

system"l settings/sampleIds.q";

actId:@[value;`actId;""];
athId:@[value;`athId;""];
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

// last 30 activites

last30:@[connect "athletes/",athId,"/activities";`id;`long$];

segs:connect each "activities/",/:string last30`id;

segs:@[raze segs`segment_efforts;`id;`long$]`segments;
allSegIds:exec distinct {x`id} each segment from segs
