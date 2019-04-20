/ logging functions

.log.o:{
  msg:string[.z.p]," | Out | ",.utl.sub x;
  if[.log.write;.log.getHandle[]msg];
  -1 msg;
 };

.log.e:{
  msg:string[.z.p]," | Err | ",x:.utl.sub x;
  if[.log.write;.log.getHandle[]msg];
  -1 msg;
  'x;
 };

.log.getHandle:{
  .log.h:@[value;`.log.h;{[x]neg hopen .log.logfile}];
  :.log.h;
 };
