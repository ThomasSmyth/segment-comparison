.disk.loadCache[`seg_streams] `.cache.streams.segments;
.disk.loadCache[`act_streams] `.cache.streams.activities;

if[.var.loadCache.leaderboard;
  .disk.loadCache[`leaderboard] `.cache.leaderboards;
 ];
