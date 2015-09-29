#if defined _csgo_motw_included
  #endinput
#endif
#define _csgo_motw_included

forward void MOTW_OnMapFetched(const char[] motw);

native void MOTW_GetMap(char[] map, int lenght);

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
}
#endif
