// Webpage ui code
// Required to work with json

/ handles dictionary of parameters passed from webpage/.ui.exectimeit
.ui.handleInput:{[dict]                                                                         / [dict] parse inputs and return raw leaderboard data
  .log.o"running query";
  params:dict`current_athlete`after`before;
  act:.data.athlete.activities . params;                                                        / get list of activities for current athlete
  .data.activity.segments . params;                                                             / get segments for selected activities
  .data.segments.leaderboards . params;                                                         / get segment leaderboards
  if[dict`include_map;
    .data.segments.streams dict`current_athlete;                                                / get segment streams
   ];
 };

.ui.exectimeit:{[dict]                                                                          / [dict] execute function and time it
  output:()!();                                                                                 / blank output
  start:.z.p;                                                                                   / set start time

  .log.o"query parameters:";
  .Q.s 0N!dict;                                                                                 / display formatted query parameters

  `:ldb set dict;
  .ui.handleInput dict;                                                                         / get leaderboards
  / replace with handler for leaderboards and maps
  data:.ldr.main dict;
  `:lo set data;

/  data:0!.segComp.leaderboard.raw dict;                                                         / return raw leaderboard data

/
  if[not(asc ids:"J"$string 2_cols[data])~asc .var.athleteList;
    if[0<count .http.athlete.clubs[];
      .log.o"creating data for athletes checklist";
      `.var.athleteList set ids;
      output,:`extraname`extradata!(`athletes;0!select from .cache.athletes where id in ids);
    ];
  ];

  id:dict`athlete_id;

  if[(0<count id)&any id in ids;
    cb:`$string id;
    cn:`Segment,`$string(.http.athlete.current[][`id]),cb;
    cond:enlist(~:),enlist $[1=count cb;(^:),cb;(&),(^:),/:cb];
    export:data:?[data;cond;0b;cn!cn];
   ];

  res:$[dict`summary;                                                                           / check if summary has been specified
    [export:.segComp.summary.raw data;                                                          / update export table
     .segComp.summary.html data];                                                               / return summary
    .segComp.leaderboard.html .segComp.leaderboard.highlight data];                             / return leaderboard
\
  res:(`int$(.z.p-start)%1000000;count data;data);
  output,:.ui.format[`table;(`time`rows`data)!res];                                             / Send formatted table

  if[dict`include_map;output,:.return.mapDetails data];                                         / create map from result subset

  :output;
 };

.return.mapDetails:{[data]
  aths:.return.athleteName each"J"$string 1_cols data;
  .log.o"retrieving segment streams";
  lines:{.return.stream.segment each x}each ids:exec Segments from .segComp.summary.raw data;
  marks:{first'[x],'enlist'[.return.segmentName each y],'y}'[lines;ids];
  bounds:(min;max)@\:raze raze lines;
  :`plottype`polyline`markers`names`bounds!(`lineMarkers;lines;marks;aths;bounds);
 };

.ui.dbstats:{([]field:("Date Range";"Meter Table Count");val:(.utl.sub("{} to {}";2#.z.d);{reverse","sv 3 cut reverse string x}0))};


.ui.format:{[name;data]                                                                         / [name;data] format dictionary to be encoded into json
    :`name`data!(name;data);
  };

.ui.defaults:{[dict]                                                                            / [dict] return existing parameters in correct format
  dict[`current_athlete]:.http.athlete.current[]`id;                                            / add id for current athlete
  dict:@[dict;`before`after;.z.d^"D"$];                                                         / parse passed date range
  if[(<). dict`before`after;:.log.e"before and after timestamps are invalid"];                  / validate date range
  dict:{@[x;y;:;0<count each x y]}[dict;`include_map`summary];
  def:(!). .var.defaults`vr`vl;                                                                 / defaults value for parameters
  :.Q.def[def]string key[def]#def,dict;                                                         / return valid optional parameters
 };

.ui.execdict:{[dict]                                                                            / [params] execute request based on passed dict of parameters
  // move init to .z.o
  if[`init in key dict;
    .log.o"new connection made";
    .http.athlete.current[];                                                                    / get athlete data
    res:.ui.format[`init;.ui.dbstats[]];
    // need some logic here to deal with users with no followers
    :res;
   ];
  if[count cl:`after`before`summary`include_map except key dict;
    .log.e("missing parameters {}";", "sv string cl);
   ];

  .log.o"executing query";                                                                      / execute query using parsed params
  data:@[.ui.exectimeit;.ui.defaults dict;{.log.e("Didn't execute due to {}";dict)}];

  .log.o("returning {} results";count data);
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
.z.wo:{.log.o"websocket opened"};
.z.wc:{.log.o"websocket closed"};
