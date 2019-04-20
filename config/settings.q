\c 20 1000

.h.HOME:getenv`SVAWEB;
.var.port:"J"$getenv`SVAPORT;
.var.homedir:hsym`$getenv`SVAHOME;
.var.savedir:hsym`$getenv`SVADATA;
.var.confdir:hsym`$getenv`SVACONF;
.var.logdir:hsym`$getenv`SVALOG;
.var.cache:1b;
.var.loadCache.leaderboard:1b;                                                                  / leave false to refresh results on launch
.var.sleepOnError:1b;                                                                           / sleep on API rate limiting or attempt to reconnect immediately
.var.sleepTime:60;                                                                              / how long to sleep if ratelimited by Strava API

.var.urlRoot:"curl -sG https://www.strava.com/api/v3/";
.var.athlete.current:();
.var.athleteList:();

.cache.segByAct:()!();

.log.logfile:.utl.p.symbol .var.logdir,`$.utl.sub("log_{}";"_"^.Q.n .Q.n?16#string .z.p);       / log file
.log.write:1b;

.var.defaults:flip`vr`vl`fc!flip(
  (`summary        ; 0b   ; ("false";"true")                                        );          / summarise results
  (`include_map    ; 0b   ; ("false";"true")                                        );          / show map
  (`after          ; 0Nd  ; {string(-).`long$(`timestamp$x;1970.01.01D00:00)%1e9}   );          / start date
  (`before         ; 0Nd  ; {string(-).`long$(`timestamp$1+x;1970.01.01D00:00)%1e9} );          / end date
  (`athlete_id     ; (),0N; string                                                  );          / filter athletes
  (`current_athlete; 0N   ; {::}                                                    )           / current athlete
 );
