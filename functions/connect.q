.connect.simple:{[datatype;extra]                                                               / basic connect function
  res:-29!first system .var.commandBase,datatype," -H \"Authorization: Bearer ",.var.accessToken,"\" ",extra;  / return dictionary attribute-value pairs
  if[.var.sleepOnError & @[{`errors in key x};res;0b];                                          / sleep on error if specified
    if["rate limit"~raze res[`errors;`field];
       .log.out"rate limit reached, sleeping for ",str:string .var.sleepTime;
       system"sleep ",str;
       res:.z.s[datatype;extra];
     ];
   ];
  :res;
 };

.connect.pagination:{[datatype;extra]                                                           / retrieve paginated results
  :last {[datatype;extra;tab]                                                                   / iterate over pages until no extra results are returned
    tab[1],:ret:.connect.simple[datatype;extra," -d per_page=200 -d page=",string tab 0];
    if[count ret; tab[0]+:1];
    :tab;
  }[datatype;extra]/[(1;())];
 };
