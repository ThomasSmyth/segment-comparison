// Webpage ui code
// Required to work with json

exectimeit:{[dict]                                                                              / execute function and time it
  output:()!();                                                                                 / blank output
  start:.z.p;                                                                                   / set start time

  .log.out"query parameters:";
  .Q.s 0N!dict;                                                                                 / display formatted query parameters

  data:0!.segComp.leaderboard.raw dict;                                                         / return raw leaderboard data

  res:$[dict`summary;                                                                           / check if summary has been specified
    [export::.segComp.summary.raw data;                                                         / update export table
     .segComp.summary.html data];                                                               / return summary
    .segComp.leaderboard.html .segComp.leaderboard.highlight data];                             / return leaderboard

  res:(`int$(.z.p - start)%1000000; count res; res);
  output,:format[`table;(`time`rows`data)!res];                                                 / Send formatted table

  output,:.return.mapDetails[];                                                                 / create map from result subset

  `od set data;
  `oo set output;
  :output;
 };

/ TODO return URL for map marker
.return.mapDetails:{[]
  aths:enlist .return.athleteData[]`fullname;
  .log.out"retrieving segment streams";
  lines:enlist .return.stream.segment each ids:exec id from .return.segments.starred[];
  marks:{(first each x),'(enlist each .return.segmentName each y),'(y)}'[lines;enlist ids];
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
      / use .z.wo instead of init?
      .log.out "New connection made";
      .var.athleteList:();                                                                      / clear athleteList for new connections
      .return.athleteData[];                                                                    / get athlete data
      res:format[`init;dbstats[]];
      `res1 set res;
      :res;
    ];
    '"Not all columns are in message"
  ];

  x:@[x;`before`after;.z.d^"D"$];                                                               / validate dictionary
  if[(<) . x`before`after;:.log.error "Before and after timestamps are invalid"];
  x:@[x;`club_id`athlete_id;"J"$];
  `valid_dict set x;

/  x[`include_map]:"include_map" in enlist x`include_map;
  x[`include_map]:1b;
  x[`include_clubs]:"include_clubs" in enlist x`include_clubs;
  x[`following]:"following" in enlist x`following;
  x[`summary]:"summary" in enlist x`summary;
  x:.return.clean x;                                                                            / return parameters in correct format
  r:.return.athleteData[];
  x[`athlete_id]:r`id;
  `.cache.athletes upsert r`id`fullname;

  `clean_dict set x;

  .log.out "Runningquery";                                                                     / run function using params
  data:@[exectimeit; x; {.log.error"Didn't execute due to ",x}];

  `processed set data;
  .log.out "Returning results";
  :data;
  };

evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}                                           / evaluate incoming data from websocket, outputting erros to front end

.z.wo:{
  .log.out"Websocket opened from ","."sv string"i"$0x0 vs .z.a;
 };
.z.wc:{
  .log.out"Websocket closed"
 };

.z.ws:{                                                                                         / websocket handler
  .log.out"ws query";
  `wsquery set .j.k -9!x;
  neg[.z.w] -8!.j.j `name`data!(`processing;());
  neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];
 };
