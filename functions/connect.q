.connect.simple:{[endpoint;params]                                                              / basic connect function
  request:.var.commandBase,endpoint," -H \"Authorization: Bearer ",.var.accessToken,"\" ",params;
  .log.out"Sending request - ",request;
  res:.j.k first system request;                                                                / return dictionary attribute-value pairs
  if[.var.sleepOnError & @[{`errors in key x};res;0b];                                          / sleep on error if specified
    if["rate limit"~raze res[`errors;`field];
       .log.out"rate limit reached, sleeping for ",str:string .var.sleepTime;
       system"sleep ",str;
       res:.z.s[endpoint;params];
     ];
   ];
  :res;
 };

/ TODO add error trapping for bad API calls
.connect.pagination:{[endpoint;params]                                                          / retrieve paginated results
  :last ({[endpoint;params;page;result]                                                         / iterate over pages until no params results are returned
    result,:ret:.connect.simple[endpoint;params," -d per_page=200 -d page=",string page];
    if[99h=type ret;
        if[`message in key result;:(page;result)];
    ];
    if[count ret; page+:1];
    :(page;result);
  }[endpoint;params].)/[(1;())];
 };
