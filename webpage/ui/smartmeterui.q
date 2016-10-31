// Smart Meter Usage Report 
// Required to work with json

// Number of rows to output to front end
outputrows:50;

// Format dictionary to be encoded into json
format:{[name;data]
    (`name`data)!(name;data)
  };

// Is run against data recieved
execdict:{
  $[all `start_date`end_date`region_filter`custtype_filter`grouping`pivot in key x;
    [
      `aa set x;
      sd:"D"$x[`start_date];
      ed:"D"$x[`end_date];
      gr:$[any raze null each x[`grouping];();`$x[`grouping]];
      pv:"none";
      pv:$["none"~x[`pivot];();`$x[`pivot]];
      rf:$[any raze null each x[`region_filter];();`$x[`region_filter]];
      cf:$[any raze null each x[`custtype_filter];();`$x[`custtype_filter]];

      dt:`n xkey flip `n`d`t!flip (
        ("activities";`before`after!(2016.10.28;2016.10.10); `.return.activities);
        ("none";      `before`after!(2016.10.28;2016.10.10); `.return.activities);
        ("segments";  ()!();                                 `aa);
        ("clubs";     ()!();                                 `bb)
      );

      `dt set dt x`pivot;

      // Run function using params
      data:@[{[dt] timeit[dt`t;dt`d;outputrows]}; dt x`pivot; {'"Didn't execute due to ",x}];
      `bb set data;

      // Send formatted table
      format[`table;(`time`rows`data)!data]
     ];
    `init in key x;
      // Sends database stats on connect
      format[`init;dbstats[]];
    '"Not all columns are in message"]
  };

// evaluate incoming data from WebSocket. Outputs error to front end.
evaluate:{@[execdict;x;{(enlist `error)!(enlist x)}]}

// WebSocket handler
.z.ws:{neg[.z.w] -8!.j.j[evaluate[.j.k -9!x]];}
