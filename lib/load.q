.load.file.q:{[d;f]                                                                             / [directory;file] load file
  if[()~key p:.utl.p.symbol d,f;
    .log.e("file does not exist {}";.Q.s1 p);
    :();
   ];
  .log.o("loading file {}";.Q.s1 p);
  :@[system;"l ",.utl.p.string p;{y;.log.e("failed to load {}";x);exit 1}.Q.s1];
 };

.load.dir.q:{[d]                                                                                / [directory] load all files in a directory
  .log.o("checking dir {}";.Q.s1 d:.utl.p.symbol d);
  if[0=count fl:{x where x like"*.q"}key d;
    .log.e("no q files in directory {}";.Q.s1 d);
    :();
   ];
  .log.o("found q files: {}";", "sv .utl.p.string'[fl]);
  .load.file.q[d]each fl;
 };

.load.file.csv:{[d;f;t]                                                                         / [directory;file;types] load csv file
  if[()~key p:.utl.p.symbol d,f;                                                                / check file exists
    .log.e("file does not exist {}";.Q.s1 p);
    :();
   ];
  .log.o("loading file {}";.Q.s1 p);
  i:where t in .Q.A;
  tab:(@[t;i;:;"*"];1#",")0:p;                                                                  / parse data, loading nested columns as strings
  :({@[x;y;z$"|"vs']}/[tab]).(cols tab;t)@\:i;                                                  / parse nested columns
 };

.load.file.txt:{[d;f]                                                                           / [directory;file] read txt file from disk
  if[()~key p:.utl.p.symbol d,f;                                                                / check file exists
    .log.e("file does not exist {}";.Q.s1 p);
    :();
   ];
  .log.o("parsing file {}";.Q.s1 p);
  :read0 p;
 };

.load.parse:{[d]                                                                                / [dict] create table from dictionary of parameters
  :d[`k]xkey flip d[`c]!d[`t]$\:();
 };

