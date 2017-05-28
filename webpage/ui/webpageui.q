// Webpage ui code
// Required to work with json

exectimeit:{[dict]                                                                              / execute function and time it
  output:()!();                                                                                 / blank output
  start:.z.p;                                                                                   / set start time

  .log.out"query parameters:";
  .Q.s 0N!dict;                                                                                 / display formatted query parameters

  data:0!.segComp.leaderboard.raw dict;                                                         / return raw leaderboard data

  `export set data;

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
    cond:enlist (~:),enlist $[1=count cb; (^:),cb; (&),(^:),/:cb];
    export::data:?[data;cond;0b;cn!cn]];

  res:$[dict`summary;                                                                           / check if summary has been specified
    [export::.segComp.summary.raw data;                                                         / update export table
     .segComp.summary.html data];                                                               / return summary
    .segComp.leaderboard.html .segComp.leaderboard.highlight data];                             / return leaderboard

  res:(`int$(.z.p - start)%1000000; count res; res);
  output,:format[`table;(`time`rows`data)!res];                                                 / Send formatted table

  if[1b=dict`include_map;                                                                       / create map from result subset
    output,:.return.mapDetails[data];
  ];

  :output;
 };

.return.mapDetails:{[data]
  aths:.return.athleteName each "J"$ string 1_cols data;
  .log.out"retrieving segment streams";
  lines:{.return.stream.segment each x} each ids:exec Segments from .segComp.summary.raw data;
  marks:{(first each x),'(enlist each .return.segmentName each y),'(y)}'[lines;ids];
  bounds:(min;max)@\: raze raze lines;
  :`plottype`polyline`markers`names`bounds!(`lineMarkers;lines;marks;aths;bounds);
 };

dbstats:{([]field:("Date Range";"Meter Table Count");val:(((string .z.d)," to ",string .z.d);{reverse "," sv 3 cut reverse string x}[0]))}


format:{[name;data]                                                                             / Format dictionary to be encoded into json
    (`name`data)!(name;data)
  };

execdict:{                                                                                      / run against data recieved
  `inputs set x;

  if[not all `after`before`club_id`athlete_id`following`include_map`include_clubs in key x;
    if[`init in key x;
      .log.out "new connection made";
      .var.athleteList:();                                                                      / clear athleteList for new connections
      .return.athleteData[];                                                                    / get athlete data
      res:format[`init;dbstats[]];
      // need some logic here to deal with no followers/clubs
      if[count cb:0!.return.clubs[];
        res[`extraname]:`clubs;
        res[`extradata]:cb;
      ];
      `res1 set res;
      :res;
    ];
    '"Not all columns are in message"
  ];

  x:@[x;`before`after;.z.d^"D"$];                                                               / validate dictionary
  if[(<) . x`before`after;:.log.error "Before and after timestamps are invalid"];
  x:@[x;`club_id`athlete_id;"J"$];
  `valid_dict set x;

  x[`include_map]:"include_map" in enlist x`include_map;
  x[`include_clubs]:"include_clubs" in enlist x`include_clubs;
  x[`following]:"following" in enlist x`following;
  x[`summary]:"summary" in enlist x`summary;
  if[0=count .return.clubs[]; x[`following]:1b];
  if[0=count x`club_id; x[`club_id]:exec id from .return.clubs[]];
  x:.return.clean x;                                                                            / return parameters in correct format

  `clean_dict set x;

  .log.out "Running query";                                                                     / run function using params
  data:@[exectimeit; x; {.log.error"Didn't execute due to ",x}];

  `processed set data;
  .log.out "Returning results";
  :data;
  };

evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}                                           / evaluate incoming data from websocket, outputting erros to front end

.z.ws:{                                                                                         / websocket handler
  `wsquery set .j.k -9!x;
  neg[.z.w] -8!.j.j `name`data!(`processing;());
  neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];
 };
