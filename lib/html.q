/ html helpers

.html.a.default:{[url;text].h.htac[`a;(`href`target)!(url;"_blank");text]};                     / [url;text] create an anchor tag

.html.a.segment:{[segId;text]                                                                   / [segment id;text] link to a segment
  url:.utl.sub("https://www.strava.com/segments/{}";segId);                                     / build up url
  :.html.a.default[url;text];                                                                   / create tag
 };

