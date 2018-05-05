.http.token:{
  if[0<count tk:@[get;`.var.token;()];:tk];
  :.var.token:first .load.file.txt[.var.homedir,`config;`token.txt];
 };

.http.hu:.h.hug .Q.an,"-.~";                                                                    / URI escaping for non-safe chars, RFC-3986

.http.urlencode:{[d]                                                                            / [dict of params]
  if[0=count d;:""];                                                                            / return empty string if no params are passed
  v:enlist each .http.hu each{$[10=type x;;string]x}'[v:value d];                               / string any values that aren't stringed,escape any chars that need it
  k:enlist each$[all 10=type'[k];;string]k:key d;                                               / if keys aren't strings, string them
  :raze" -d ",/:"="sv'k,'v;                                                                     / return urlencoded form of dictionary
 };

.http.get.basic:{[url;params]                                                                   / [request type; additional parameters] basic http request
  cmd:.utl.sub("{} -H \"Authorization: Bearer {}\" {}";(url;.http.token[];.http.urlencode params));
  :.j.k first system .var.commandBase,cmd;
 };

.http.get.simpleX:{[url;params]                                                                 / [request type;additional request parameters] basic connect function
  `dt set url;`ex set params;
  .log.o("retrieving {} data";url);
  res:.http.get.basic[url;params];                                                              / request data from strava
  if[.var.sleepOnError&@[{`errors in key x};res;0b];                                            / sleep on error if specified
    if["rate limit"~raze res[`errors;`field];                                                   / check for rate limiting error
       .log.o("rate limit reached, sleeping for {}";.var.sleepTime);
       system .utl.sub("sleep {}";var.sleepTime);                                               / sleep until no longer rate limited
       res:.z.s[url;params];
     ];
   ];
  :res;
 };

.http.get.simple:.http.get.simpleX[;()!()];                                                     / [request type] simple request with no additional params

.http.get.pgnX:{[url;params]                                                                    / [request type;additional request parameters] retrieve paginated results
  :last{[url;params;res]                                                                        / iterate over pages until no params results are returned
    res[1],:ret:.http.get.simpleX[url;params,`per_page`page!(200;res 0)];
    :@[res;0;+;0<count ret];
  }[url;params]/[(1;())];
 };

.http.get.pgn:.http.get.pgnX[;()!()];                                                           / [request type] pagination request with no additional params

.http.activity.detail:{[id]                                                                     / [activity id] return details for an activity
  :.http.get.simple .utl.sub("activities/{}";id);
 };

.http.athlete.current:{[]
  .log.o"retrieving data for current athlete from strava";
  ad:.http.get.simple"athlete";
  ad[`name]:`$" "sv ad`firstname`lastname;                                                      / add fullname to data
  :@[ad;`id;`long$];                                                                            / return athlete_id as type long
 };

.http.athlete.clubs:{[]                                                                         / return list of users clubs
  .log.o"returning club data for current athlete from strava";
  :`id xkey@[;`id;"j"$]`id`name#/:.http.athlete.current[]`clubs;
 };

.http.segments.starred:{[]                                                                      / [] return starred segments for current athlete
  .log.o"returning starred segments for current athlete from strava";
  :@[;`id;"j"$]`id`name`starred#/:.http.get.simple"segments/starred";                           / retrieve starred segments
 };

.http.athlete.activities:{
  .log.o"returning activities for current athlete from strava";
  act:.http.get.pgn"activities";
  act:`id`name`start_date`commute#/:act where not act@\:`manual;
  act:select`long$id,name,"D"$10#'start_date,commute from act;
  .log.o("retrieved {} activities from strava";count act);
  :act;
 };