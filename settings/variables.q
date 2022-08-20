
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
.var.athleteData:();

.cache.segments:([id:`long$()] name:(); distance:(); average_grade:(); maximum_grade:(); elevation_high:(); elevation_low:(); climb_category:());
.cache.streams.segments:([id:`long$()] data:());

.var.defaults:flip `vr`vl`fc!flip (
  (`starred      ; 0b   ; ("false";"true")                                        );            / show starred segments
  (`summary      ; 0b   ; ("false";"true")                                        );            / summarise results
  (`athlete_id   ; (),0N; string                                                  );            / filter athletes
  (`segment_id   ; 0N   ; string                                                  )             / segment to compare on
 );
