#if defined _csgo_motw_included
  #endinput
#endif
#define _csgo_motw_included

// Called when the MOTW is fetched from the web service.
forward void MOTW_OnMapFetched(const char[] motw);

// Gets the current stored MOTW in memory.
native void MOTW_GetMap(char[] map, int length);

// Forces the plugin to fetch the latest MOTW, normally
// only done on config/map changes.
native void MOTW_Update();

public SharedPlugin __pl_csgo_motw = {
    name = "csgo_motw",
    file = "csgo_motw.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_csgo_motw_SetNTVOptional() {
    MarkNativeAsOptional("MOTW_GetMap");
    MarkNativeAsOptional("MOTW_Update");
}
#endif
