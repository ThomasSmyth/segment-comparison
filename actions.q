.disk.loadCache[`activities] `.cache.activities;                                                / load cache from disk
.disk.loadCache[`segments] `.cache.segments;
.disk.loadCache[`athletes] `.cache.athletes;
.disk.loadCache[`clubs] `.cache.clubs;
.disk.loadCache[`seg_streams] `.cache.streams.segments;
.disk.loadCache[`act_streams] `.cache.streams.activities;

if[.var.loadCache.leaderboard;
  .disk.loadCache[`leaderboard] `.cache.leaderboards;
  .disk.loadCache[`segByAct] `.cache.segByAct;
 ];
