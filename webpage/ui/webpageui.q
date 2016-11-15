// Webpage ui code
// Required to work with json

timeit:{[dict;maxsize]
  start:.z.p;
  res:export::0!.segComp.leaderboard.raw delete athlete_id from dict;
  edata:$[all (ids:"J"$string 2_cols[res]) in .var.athleteList;
    ();
    [value `.var.athleteList set ids;
     select from .cache.athletes where id in ids]
  ];
  res:.segComp.leaderboard.html .segComp.leaderboard.highlight res;
  :(`int$(.z.p - start)%1000000; count res; maxsize sublist res; edata);
 };

dbstats:{([]field:("Date Range";"Meter Table Count");val:(((string .z.d)," to ",string .z.d);{reverse "," sv 3 cut reverse string x}[0]))}

// Format dictionary to be encoded into json
format:{[name;data]
    (`name`data)!(name;data)
  };

// Is run against data recieved
execdict:{

  `inputs set x;

  if[not all `after`before`club_id`athlete_id`following`include_clubs in key x;
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
  data:@[{[dict] timeit[dict;.var.outputrows]}; x; {.log.error"Didn't execute due to ",x}];
  `dd set data;

  // Send formatted table
  res:format[`table;(`time`rows`data`extra)!data];
//  if[count res[`data;`extra]; res[`name]:`table2];
  `res set res;
  .log.out "Returning results";
  res[`data]:delete extra from res[`data];
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
