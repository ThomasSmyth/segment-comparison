
//system"l ",.var.homedir,"/settings/sampleIds.q";

\c 20 1000

.var.accessToken:@[{first read0 x};` sv hsym[`$.var.homedir],`settings`token.txt;{x;log.error"no token file"}];
.var.commandBase:"curl -sG https://www.strava.com/api/v3/";
.var.athleteData:@[value;`.var.athleteData;()];
.var.athleteList:@[value;`.var.athleteList;()];

.log.out:{-1 string[.z.p]," | Info | ",x;};
.log.error:{-1 string[.z.p]," | Error | ",x; 'x};

.cache.leaderboards:@[value;`.cache.leaderboards;([segmentId:`long$(); resType:`$(); resId:`long$()] res:())];
.cache.activities:@[value;`.cache.activities;([id:`long$()] name:(); start_date:`date$(); commute:`boolean$())];
.cache.segByAct:@[value;`.cache.segByAct;()!()];
.cache.segments:@[value;`.cache.segments;([id:`long$()] name:(); starred:`boolean$())];
.cache.clubs:@[value;`.cache.clubs;([id:`long$()] name:())];
.cache.athletes:@[value;`.cache.athletes;([id:`long$()] name:())];
.cache.streams.segments:@[value;`.cache.stream.segments;([id:`long$()] data:())];
.cache.streams.activities:@[value;`.cache.stream.activites;([id:`long$()] data:())];

.var.defaults:flip `vr`vl`fc!flip (
  (`starred      ; 0b   ; ("false";"true")                                        );  / show starred segments
  (`summary      ; 0b   ; ("false";"true")                                        );  / summarise results
  (`following    ; 0b   ; ("false";"true")                                        );  / compare with those followed
  (`include_map  ; 0b   ; ("false";"true")                                        );  / show map
  (`include_clubs; 0b   ; ("false";"true")                                        );  / for club comparison
  (`after        ; 0Nd  ; {string (-/)`long$(`timestamp$x;1970.01.01D00:00)%1e9}  );  / start date
  (`before       ; 0Nd  ; {string (-/)`long$(`timestamp$1+x;1970.01.01D00:00)%1e9});  / end date
  (`club_id      ; (),0N; string                                                  );  / for club comparison
  (`athlete_id   ; (),0N; string                                                  );  / filter athletes
  (`segment_id   ; 0N   ; string                                                  )   / segment to compare on
 );
