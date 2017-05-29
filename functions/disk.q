.disk.saveCache:{[table;data]
  if[not .var.saveCache.all; :()];
  loc:` sv .var.savedir,table;
  :loc set data;
 };

.disk.loadCache:{[table;mem]
  if[not .var.loadCache.all; :()];
  loc:` sv .var.savedir,table;
  if[not ()~key loc; :mem set get loc];
 };
