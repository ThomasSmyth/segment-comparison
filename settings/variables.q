
\c 20 1000

.h.HOME:getenv[`SVAWEB],"/ui/html"
.var.port:"J"$getenv`SVAPORT;
.var.homedir:hsym `$getenv`SVAHOME;
.var.savedir:hsym `$getenv[`SVAHOME],"/cache";
.var.saveCache.all:1b;
.var.loadCache.all:1b;
.var.loadCache.leaderboard:1b;                                                                  / leave false to refresh results on launch
.var.sleepOnError:1b;
.var.sleepTime:60;

.var.accessToken:@[{first read0 x};` sv .var.homedir,`settings`token.txt;{x;log.error"no token file"}];
.var.commandBase:"curl -sG https://www.strava.com/api/v3/";
.var.athleteData:@[value;`.var.athleteData;()];
.var.athleteList:@[value;`.var.athleteList;()];

.cache.leaderboards:@[value;`.cache.leaderboards;([segmentId:`long$(); resType:`$(); resId:`long$()] res:())];
.cache.activities:@[value;`.cache.activities;([id:`long$()] name:(); start_date:`date$(); commute:`boolean$())];
.cache.segByAct:@[value;`.cache.segByAct;()!()];
.cache.segments:@[value;`.cache.segments;([id:`long$()] name:(); starred:`boolean$())];
.cache.clubs:@[value;`.cache.clubs;([id:`long$()] name:())];
.cache.athletes:@[value;`.cache.athletes;([id:`long$()] name:())];
.cache.streams.segments:@[value;`.cache.stream.segments;([id:`long$()] data:())];
.cache.streams.activities:@[value;`.cache.stream.activites;([id:`long$()] data:())];

.var.defaults:flip `vr`vl`fc!flip (
  (`starred      ; 0b   ; ("false";"true")                                        );            / show starred segments
  (`summary      ; 0b   ; ("false";"true")                                        );            / summarise results
  (`following    ; 0b   ; ("false";"true")                                        );            / compare with those followed
  (`include_map  ; 0b   ; ("false";"true")                                        );            / show map
  (`include_clubs; 0b   ; ("false";"true")                                        );            / for club comparison
  (`after        ; 0Nd  ; {string (-/)`long$(`timestamp$x;1970.01.01D00:00)%1e9}  );            / start date
  (`before       ; 0Nd  ; {string (-/)`long$(`timestamp$1+x;1970.01.01D00:00)%1e9});            / end date
  (`club_id      ; (),0N; string                                                  );            / for club comparison
  (`athlete_id   ; (),0N; string                                                  );            / filter athletes
  (`segment_id   ; 0N   ; string                                                  )             / segment to compare on
 );
