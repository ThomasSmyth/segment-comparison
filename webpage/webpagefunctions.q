timeit:{[func;dict;maxsize]
 start:.z.p;
 res:export::0!func @ dict;
 (`int$(.z.p - start)%1000000; count res; maxsize sublist res)}

dbstats:{([]field:("Date Range";"Meter Table Count");val:(((string .z.d)," to ",string .z.d);{reverse "," sv 3 cut reverse string x}[0]))}
