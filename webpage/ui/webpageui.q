// Webpage ui code
// Required to work with json

// Number of rows to output to front end
outputrows:50;

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

  x[`following]:"following" in x`following;
  if[not "include_clubs" in enlist x`include_clubs; x[`club_id]:enlist 0N];
  if[x[`club_id]~`long$(); x[`club_id]:exec id from .return.clubs[]];
  x:.return.clean x;

  `x set x;

  // Run function using params
  .log.out "Running query";
  data:.[{[func;dict] timeit[func;dict;outputrows]}; (.segComp.leaderboard;x); {.log.error"Didn't execute due to ",x}];
  `dd set data;

  data[2]:update Segment:.return.html.segmentURL'[Segment] from data[2];
  // Send formatted table
  `res set res:format[`table;(`time`rows`data)!data];
   :res;
  };

// evaluate incoming data from WebSocket. Outputs error to front end.
evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}

// WebSocket handler
.z.ws:{neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];}
