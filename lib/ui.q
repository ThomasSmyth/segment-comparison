// Webpage ui code
// Required to work with json

/ handles dictionary of parameters passed from webpage/.ui.exectimeit
.ui.handleInput:{[dict]
  `:ldb set dict;
  .log.o"running query";
  empty:([]Segment:()),'flip enlist[`$string dict`athlete_id]!();                               / empty results table
  if[not max dict`following`include_clubs;:empty];                                              / exit early if no comparison filters selected
  act:.data.athlete.activities . dict`athlete_id`after`before;                                  / get list of activities for current athlete
  .data.activity.segments[id;key[act]`id];                                                      / get segments for selected activities
  / get leaderboards
  :();
  .data.segments.leaderboards[id];
 };


.ui.exectimeit:{[dict]                                                                          / execute function and time it
  output:()!();                                                                                 / blank output
  start:.z.p;                                                                                   / set start time

  .log.o"query parameters:";
  .Q.s 0N!dict;                                                                                 / display formatted query parameters

  data:.ui.handleInput dict;                                                                    / get leaderboards

/  data:0!.segComp.leaderboard.raw dict;                                                         / return raw leaderboard data

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

  res:(`int$(.z.p-start)%1000000;count res;res);
  output,:format[`table;(`time`rows`data)!res];                                                 / Send formatted table

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

.ui.dbstats:{([]field:("Date Range";"Meter Table Count");val:(string[.z.d]," to ",string .z.d;{reverse","sv 3 cut reverse string x}0))}


.ui.format:{[name;data]                                                                         / [name;data] format dictionary to be encoded into json
    :`name`data!(name;data);
  };

.ui.execdict:{[dict]                                                                            / [params] execute request based on passed dict of parameters
  if[`init in key dict;
    .log.o"new connection made";
    .http.athlete.current[];                                                                    / get athlete data
    res:.ui.format[`init;.ui.dbstats[]];
    // need some logic here to deal with no followers/clubs
    if[count cb:0!.http.athlete.clubs[];
      res[`extraname`extradata]:(`clubs;cb);
     ];
    :res;
   ];
  if[count cl:`after`before`club_id`athlete_id`following`include_map`include_clubs except key dict;
    .log.e("missing parameters {}";", "sv string cl);
   ];

  `inputD set dict;

  dict[`athlete_id]:.http.athlete.current[]`id;
  dict:@[dict;`before`after;.z.d^"D"$];                                                         / parse passed date range
  if[(<). dict`before`after;:.log.e"before and after timestamps are invalid"];                  / validate date range
  dict:@[dict;`club_id;"J"$];

  dict:{@[x;y;:;0<count each x y]}[dict;`include_map`include_clubs`following`summary];
  if[0=count cl:.http.athlete.clubs[];dict[`following]:1b];
  if[0=count dict`club_id;dict[`club_id]:exec id from cl];

  .log.o"executing query";                                                                      / execute query using parsed params
  data:@[.ui.exectimeit;.return.clean dict;{.log.e"Didn't execute due to ",dict}];

  .log.o"returning results";
  :data;
  };

.ui.evaluate:{@[.ui.execdict;x;{enlist[`error]!enlist x}]}                                      / evaluate incoming data from websocket, outputting errors to front end

.z.ws:{                                                                                         / websocket handler
  .log.o"handling websocket event";
  `id set x;
  neg[.z.w] -8!.j.j .ui.format[`processing;()];
  neg[.z.w] -8!.j.j .ui.evaluate .j.k -9!x;
 };
.z.wo:{.log.o"websocket opened"};
.z.wc:{.log.o"websocket closed"};
