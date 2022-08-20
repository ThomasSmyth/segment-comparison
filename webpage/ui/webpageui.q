// Webpage ui code
// Required to work with json

exectimeit:{[dict]                                                                              / execute function and time it
  output:()!();                                                                                 / blank output
  start:.z.p;                                                                                   / set start time

  .log.out"Attempting to map starred segments";

  starred:.return.segmentsToPlot[];
  res:(`int$(.z.p - start)%1000000; count starred; starred);
  output,:format[`table;(`time`rows`data)!res];                                                 / Send formatted table

  output,:.return.mapDetails[starred];                                                          / create map from result subset

  `oo set output;
  :output;
 };

.return.segmentsToPlot:{[]
  starred:.return.segments.starred[0b];
/  ids:(exec id from starred) except .return.athlete.koms[]`id;
  starred:update name:.return.html.segmentURL'[id] from starred;
  :starred;
 };

.return.mapDetails:{[segments]
  .log.out"retrieving segment streams";
  ids:exec id from segments;
  lines:enlist .return.stream.segment each ids;
  names:enlist .return.html.segmentURL each ids;
  marks:first''[lines];
  bounds:(min;max)@\:raze raze lines;
  :`plottype`polyline`markers`segmentnames`bounds!(`lineMarkers;lines;marks;names;bounds);
 };

dbstats:{([]field:("Date Range";"Meter Table Count");val:(((string .z.d)," to ",string .z.d);{reverse "," sv 3 cut reverse string x}[0]))}

format:{[name;data]                                                                             / Format dictionary to be encoded into json
    (`name`data)!(name;data)
  };

execdict:{                                                                                      / run against data recieved
  `inputs set x;

  if[`init in key x;
    / use .z.wo instead of init? and use for Oauth page
    .log.out "New connection made";
    .return.athlete.data[];                                                                     / get athlete data
    res:format[`init;dbstats[]];
    `res1 set res;
/     :res;
     data:exectimeit`;
     `processed set data;
     .log.out "Returning results";
     :data;
  ];
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
