// Webpage ui code
// Required to work with json

/ handles dictionary of parameters passed from webpage/.ui.exectimeit
.ui.handleInput:{[dict]                                                                         / [dict] parse inputs and return raw leaderboard data
  .log.o"running query";
  params:dict`current_athlete`after`before;
  `params set params;
  .data.athlete.activities . params;                                                            / get list of activities for current athlete
  .data.activity.segments . params;                                                             / get segments for selected activities
  .data.segments.leaderboards . params;                                                         / get segment leaderboards
  if[dict`include_map;
    .data.segments.streams . params;                                                            / get segment streams
   ];
 };

.ui.exectimeit:{[dict]                                                                          / [dict] execute function and time it
  output:()!();                                                                                 / blank output
  start:.z.p;                                                                                   / set start time

  .log.o("query parameters: {}";.Q.s1 0N!dict);                                                 / display formatted query parameters

  `rawinp set dict;
  .ui.handleInput dict;                                                                         / get leaderboards
  / replace with handler for leaderboards and maps
  raw:.ldr.raw . dict`current_athlete`after`before`athlete_list;
  al:asc distinct[raw`athlete]except dict`athlete_name;                                         / list of athletes for filter
  raw:.ldr.filterRaw[raw;dict`athlete_list];
  data:.ldr.main[raw;dict];

  output,:`extraname`extradata!(`athletes;{flip`id`name!(x;x)}al);                              / get athletes for filter

  output,:.ui.format[`table;(`time`rows`data)!(`int$(.z.p-start)%1000000;count data;data)];     / Send formatted table
  if[dict`include_map;output,:.ldr.map[raw;dict]];                                              / create map from result subset
  `:npo set output;
  :output;
 };

.ui.dbstats:{([]field:("Date Range";"Meter Table Count");val:(.utl.sub("{} to {}";2#.z.d);{reverse","sv 3 cut reverse string x}0))};


.ui.format:{[name;data]                                                                         / [name;data] format dictionary to be encoded into json
    :`name`data!(name;data);
  };

.ui.defaults:{[dict]                                                                            / [dict] return existing parameters in correct format
  kl:`summary`include_map`before`after`athlete_name`athlete_list`current_athlete;               / allowed keys
  dict[`current_athlete`athlete_name]:.http.athlete.current[]`id`name;                          / add id for current athlete
  dict:@[dict;`before`after;.z.d^"D"$];                                                         / parse passed date range
  if[(<). dict`before`after;:.log.e"before and after timestamps are invalid"];                  / validate date range
  dict:@[dict;`include_map`summary;0<count@];                                                   / check for boolean keys
  dict[`athlete_name]:` sv dict[`athlete_name],`;
  dict[`athlete_list]:$[count dict`athlete_id;dict[`athlete_name],`$dict`athlete_id;()];        / list of valid athletes to return
  :kl#dict;                                                                                     / return required keys
 };

.ui.execdict:{[dict]                                                                            / [params] execute request based on passed dict of parameters
  // move init to .z.o
  `dt set dict;
  if[count cl:`after`before`summary`include_map except key dict;
    .log.e("missing parameters {}";", "sv string cl);
  ];

  .log.o"executing query";                                                                      / execute query using parsed params
  data:@[.ui.exectimeit;.ui.defaults dict;{.log.e("Didn't execute due to {}";x)}];

  .log.o("returning {} results";count data[`data;`data]);
  :data;
 };

.ui.evaluate:{@[.ui.execdict;x;{enlist[`error]!enlist x}]}                                      / evaluate incoming data from websocket, outputting errors to front end

.z.ws:{                                                                                         / websocket handler
  .log.o"handling websocket event";
  neg[.z.w] -8!.j.j .ui.format[`processing;()];
  .log.o"processing request";
  res:.ui.evaluate .j.k -9!x;
  .log.o"sending result to front end";
  neg[.z.w] -8!.j.j res;
 };
.z.wo:{
  .log.o"new connection made";
  / TODO cache athlete data at this stage
  res:.ui.format[`init;.ui.dbstats[]];
  // need some logic here to deal with users with no followers
  neg[.z.w] -8!.j.j res;
 };
.z.wc:{.log.o"websocket closed"};
