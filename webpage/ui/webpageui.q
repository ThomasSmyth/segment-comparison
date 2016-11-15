// Webpage ui code
// Required to work with json

timeit:{[func;dict;maxsize]
 start:.z.p;
 res:export::0!func @ dict;
 (`int$(.z.p - start)%1000000; count res; maxsize sublist res)}

dbstats:{([]field:("Date Range";"Meter Table Count");val:(((string .z.d)," to ",string .z.d);{reverse "," sv 3 cut reverse string x}[0]))}

// Format dictionary to be encoded into json
format:{[name;data]
    (`name`data)!(name;data)
  };

// Is run against data recieved
execdict:{

  `inputs set x;

  if[not all `after`before`club_id`following`include_clubs in key x;
    :$[`init in key x;
      // Sends database stats on connect
      [
       .log.out "connection made";
       .return.athleteData[];
       res1:format[`init;dbstats[]];
       res1[`extra]:0!.return.clubs[];
       `res1 set res1;
       res1
      ];
    '"Not all columns are in message"]
  ];

  / validate dictionary
  x:@[x;`before`after;.z.d^"D"$];
  if[(</)x`before`after;:.log.error["Before and after timestamps are invalid"]];
  x:@[x;`club_id;"J"$]; 
  `aa set x;

  x[`following]:"following" in enlist x`following;
  x[`summary]:"summary" in enlist x`summary;
  x[`include_clubs]:"include_clubs" in enlist x`include_clubs;
  if[x[`club_id]~`long$(); x[`club_id]:exec id from .return.clubs[]];
  x:.return.clean x;

  `x set x;

  // Run function using params
  .log.out "Running query";
  func:$[x`summary;.segComp.summary.html;.segComp.leaderboard.html];
  data:.[{[func;dict] timeit[func;dict;.var.outputrows]}; (func;x); {.log.error"Didn't execute due to ",x}];
  `dd set data;

  // Send formatted table
  `res set res:format[`table;(`time`rows`data)!data];
  .log.out "Returning results";
   :res;
  };

// evaluate incoming data from WebSocket. Outputs error to front end.
evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}

// WebSocket handler
.z.ws:{
  `query set .j.k -9!x;
  neg[.z.w] -8!.j.j `name`data!(`processing;());
  neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];
 };
