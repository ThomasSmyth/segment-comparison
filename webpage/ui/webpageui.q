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
      [
       .log.out "connection made";
       `res1 set format[`init;dbstats[]];
       res1
      ];
    '"Not all columns are in message"]
  ];

  x:@[x;`pivot;`$];
  data:.webpage.parseDict x;

  // Send formatted table
  `res set res:format[`table;(`time`rows`data)!3#data];
   if[`leaderboard~x`pivot;
     res[`name]:`table3;
     res[`data;`data]:update athlete_name:.return.html.athleteURL'[athlete_id;athlete_name] from res[`data;`data];
//     res[`extra]:select distinct athlete_name from res[`data;`data];
     res[`extra]:.return.html.segmentURL 13423965;
     `res set res];
   :res;
  };

// evaluate incoming data from WebSocket. Outputs error to front end.
evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}

// WebSocket handler
.z.ws:{neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];}
