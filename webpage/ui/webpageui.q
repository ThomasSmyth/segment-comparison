// Webpage ui code
// Required to work with json

timeit:{[dict]
  output:()!();
  start:.z.p;
  data:export::0!.segComp.leaderboard.raw dict;
  if[1b=x`include_map;
    segs:.return.stream.segment each exec Segment from data;
    output,:`plottype`polyline`markers!(`lineMarkers;segs;first each segs);
  ];
  
  if[not (asc ids:"J"$string 2_cols[data])~asc .var.athleteList;
    if[0<count .return.clubs;
      .log.out"Creating data for athletes checklist";
      value `.var.athleteList set ids;
      output,:`extraname`extradata!(`athletes;0!select from .cache.athletes where id in ids);
    ];
  ];

  id:dict`athlete_id;

  if[(0<count id)&(any id in ids);
    cb:`$string id;
    cn:`Segment,`$string (.return.athleteData[][`id]),cb;
    cond:enlist $[1=count cb;
      (~:),enlist(^:),cb;
      (~:),enlist(&),(^:),/:cb];
    data:?[data;cond;0b;cn!cn]];

  res:$[dict`summary;                                           / check if summary has been specified
    [export::.segComp.summary.raw data;                         / update export table
     .segComp.summary.html data];                               / return summary
    .segComp.leaderboard.html .segComp.leaderboard.highlight data];  / return leaderboard
  res:(`int$(.z.p - start)%1000000; count res; res);
  output,:format[`table;(`time`rows`data)!res];                 / Send formatted table
  :output;
 };


dbstats:{([]field:("Date Range";"Meter Table Count");val:(((string .z.d)," to ",string .z.d);{reverse "," sv 3 cut reverse string x}[0]))}


// Format dictionary to be encoded into json
format:{[name;data]
    (`name`data)!(name;data)
  };

// Is run against data recieved
execdict:{

  `inputs set x;

  if[not all `after`before`club_id`athlete_id`following`include_map`include_clubs in key x;
    :$[`init in key x;
      / Sends database stats on connect
      [
       .log.out "new connection made";
       .var.athleteList:();                                         / clear athleteList for new connections
       .return.athleteData[];                                       / get athlete data
       res:format[`init;dbstats[]];
       // need some logic here to deal with no followers/clubs
       if[count cb:0!.return.clubs[];
         res[`extraname]:`clubs;
         res[`extradata]:cb;
       ];
       `res1 set res;
       res
      ];
    '"Not all columns are in message"]
  ];

  / validate dictionary
  x:@[x;`before`after;.z.d^"D"$];
  if[(</)x`before`after;:.log.error["Before and after timestamps are invalid"]];
  x:@[x;`club_id`athlete_id;"J"$]; 
  `aa set x;

  x[`include_map]:"include_map" in enlist x`include_map;
  x[`include_clubs]:"include_clubs" in enlist x`include_clubs;
  x[`following]:"following" in enlist x`following;
  if[0=count .return.clubs; x[`following]:1b];
  x[`summary]:"summary" in enlist x`summary;
  if[x[`club_id]~`long$(); x[`club_id]:exec id from .return.clubs[]];
  x:.return.clean x;
 
  `x set x;

  / Run function using params
  .log.out "Running query";
  data:@[{[dict] timeit[dict]}; x; {.log.error"Didn't execute due to ",x}];
  `dd set data;

  res:data;
  `res set res;
  .log.out "Returning results";
//  res[`data]:delete extra from res[`data];
  :res;
  };

/ evaluate incoming data from WebSocket. Outputs error to front end.
evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}

/ WebSocket handler
.z.ws:{
  `query set .j.k -9!x;
  neg[.z.w] -8!.j.j `name`data!(`processing;());
  neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];
 };
