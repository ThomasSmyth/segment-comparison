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

  if[not all `after`before`region_filter`custtype_filter`grouping`pivot in key x;
    :$[`init in key x;
      // Sends database stats on connect
      [.log.out "connection made";
       format[`init;dbstats[]]];
    '"Not all columns are in message"]
  ];

  `aa set x;
  x:.return.clean @[x;`pivot;`$];
  `bb set x;

  // for testing purposes
  dt:`n xkey flip `n`d`t!flip (
    (`activities;  `before`after!(2016.10.28;2016.10.10);   `.return.activities);
    (`none;        `before`after!(2016.10.28;2016.10.10);   `.return.activities);
    (`segments;    `before`after!(2016.10.28;2016.10.27);   `.return.segments);
    (`clubs;       ()!();                                   `.return.clubs);
    (`leaderboard; `segment_Id`club_Id!(13423965;236501);   `.return.leaderboard)
  );

  `dt set dt x`pivot;

  // Run function using params
  .log.out "Running query";
  data:@[{[dt] timeit[dt`t;dt`d;outputrows]}; dt x`pivot; {'"Didn't execute due to ",x}];
  `dd set data;

  // Send formatted table
  res:format[`table;(`time`rows`data)!data];
  :res
  };

// evaluate incoming data from WebSocket. Outputs error to front end.
evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}

// WebSocket handler
.z.ws:{neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];}
