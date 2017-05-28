.log.logdir:hsym `$getenv[`SVAHOME],"/logs";													/ log dir
.log.logfile:` sv .log.logdir,`$"log_",ssr/[16#string .z.p;":D.";"_"];   						/ log file
.log.h:neg hopen .log.logfile;
.log.write:1b;

.log.out:{
  msg:string[.z.p]," | Info | ",x;
  if[.log.write; .log.h msg];
  -1 msg;
 };

.log.error:{
  msg:string[.z.p]," | Error | ",x;
  if[.log.write; .log.h msg];
  -1 msg;
  'x
 };
