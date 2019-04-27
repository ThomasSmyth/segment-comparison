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
.var.athlete.current:0Ni;                                                                       / ID of current user

// Cached data (may need retrieve from disk instead)
.cache.segByAct:()!();                                                                          / store all segments by activity
.cache.followers:([id:`long$()]name:());                                                        / store follower ids

// Logging
.log.logfile:.utl.p.symbol .var.logdir,`$.utl.sub("log_{}";"_"^.Q.n .Q.n?16#string .z.p);       / log file
.log.write:1b;
