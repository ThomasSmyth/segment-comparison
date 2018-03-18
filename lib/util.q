.util.p.symbol:{[p]` sv@[(),p;0;hsym]};                                                         / [path] build filepath from a list of symbols

.util.p.string:{[p](":"=first p)_p:string p};                                                   / [path] convert filepath to string

.util.sub:{[x]                                                                                  / [params] substitute placeholders in strings
  if[10=abs type x;:x];
  :{
    if[null i:first ss[x;"{}"];:x];                                                             / exit if no substitutions available
    :($[10=abs type y;;string]y)sv @[(0,i)cut x;1;2_];
  }/[x 0;1_x];
 };
