csgo-motw
===========================

**work in progress, not working yet**

This is a simple web API and sourcemod plugin for CS:GO meant to allow
a server to follow a given league's current map (or its MOTW, map of the week).

The web service already runs at http://csgo-motw.appspot.com, but you can run
a version it yourself, if desired. Data is served from [webserver/data.json](webserver/data.json),
and pull requests to update it are accepted.

### Download
TODO

### Game server plugin
TODO

### Web server
See [webserver/api.md](webserver/api.md).
TODO

Deployment: ``~/dev/google_appengine/appcfg.py -A csgo-motw update app.yaml``
