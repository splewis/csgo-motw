#include <cstrike>
#include <sourcemod>
#include "SteamWorks.inc"

#pragma semicolon 1
#pragma newdecls required

#define TEMP_DATAFILE "data/csgo_motw.txt"

ConVar g_EnabledCvar;

ConVar g_ApiUrlCvar;
ConVar g_DefaultCvar;
ConVar g_ExpirationCvar;
ConVar g_LeagueCvar;
ConVar g_OffsetCvar;

char g_DefaultMap[PLATFORM_MAX_PATH+1];
char g_DataFile[PLATFORM_MAX_PATH+1];

public Plugin myinfo = {
    name = "[CS:GO] Map of the week [motw]",
    author = "splewis",
    description = "Overrides the server's map to always be the current MOTW",
    version = "1.0.0",
    url = "https://github.com/splewis/csgo-motw"
};

public void OnPluginStart() {
    BuildPath(Path_SM, g_DataFile, sizeof(g_DataFile), TEMP_DATAFILE);
    g_ApiUrlCvar = CreateConVar("sm_csgo_motw_api_url", "http://csgo-motw.appspot.com", "URL the api is hosted at");
    g_EnabledCvar = CreateConVar("sm_csgo_motw_enabled", "1", "Whether the plugin is enabled");
    g_DefaultCvar = CreateConVar("sm_csgo_motw_default", "de_dust2", "Default backup map");
    g_ExpirationCvar = CreateConVar("sm_csgo_motw_expiration", "1209600");
    g_LeagueCvar = CreateConVar("sm_csgo_motw_league", "esea", "League maplist being used, allowed values: \"esea\", \"cevo\"");
    g_OffsetCvar = CreateConVar("sm_csgo_motw_offset", "0", "Offset in seconds added to the timestamp");
    AutoExecConfig();

    HookConVarChange(g_ApiUrlCvar, OnAPIChange);
    HookConVarChange(g_DefaultCvar, OnAPIChange);
    HookConVarChange(g_ExpirationCvar, OnAPIChange);
    HookConVarChange(g_LeagueCvar, OnAPIChange);
    HookConVarChange(g_OffsetCvar, OnAPIChange);

    // Read the initial map from the datafile.
    if (!ReadMapFromDatafile()) {
        char default_map[128];
        g_DefaultCvar.GetString(default_map, sizeof(default_map));
        strcopy(g_DefaultMap, sizeof(g_DefaultMap), default_map);
    }
}

public bool ReadMapFromDatafile() {
    // Read the initial map from the datafile.
    File f = OpenFile(g_DataFile, "r");
    if (f != null) {
        f.ReadLine(g_DefaultMap, sizeof(g_DefaultMap));
        delete f;
        return true;
    }
    return false;
}

public int OnAPIChange(Handle cvar, const char[] oldValue, const char[] newValue) {
    UpdateCurrentMap();
}

public void OnConfigsExecuted() {
    UpdateCurrentMap();
    CheckMapChange();
    if (IsMapValid(g_DefaultMap)) {
        SetNextMap(g_DefaultMap);
    }
}

public void CheckMapChange() {
    if (g_EnabledCvar.IntValue != 0) {
        char mapName[PLATFORM_MAX_PATH+1];
        GetCurrentMap(mapName, sizeof(mapName));
        if (!StrEqual(mapName, g_DefaultMap, false) && IsMapValid(g_DefaultMap)) {
            // TODO: there's probably a better way of doing this.
            // The problem is that OnMapStart is usually called twice before the real start map
            // first on de_dust, then on the real startup default map, so checking the first
            // OnMapStart is unreliable.
            CreateTimer(10.0, Timer_ChangeMap);
        }
    }
}

public Action Timer_ChangeMap(Handle timer) {
    char mapName[PLATFORM_MAX_PATH+1];
    GetCurrentMap(mapName, sizeof(mapName));
    if (!StrEqual(mapName, g_DefaultMap, false) && IsMapValid(g_DefaultMap)) {
        ServerCommand("changelevel %s", g_DefaultMap);
    }
}

public void UpdateCurrentMap() {
    char url[128];
    g_ApiUrlCvar.GetString(url, sizeof(url));

    char league[128];
    g_LeagueCvar.GetString(league, sizeof(league));

    char default_map[128];
    g_LeagueCvar.GetString(default_map, sizeof(default_map));

    char offset[128];
    g_OffsetCvar.GetString(offset, sizeof(offset));

    char expiration[128];
    g_ExpirationCvar.GetString(expiration, sizeof(expiration));

    if (GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest") == FeatureStatus_Available) {
        Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        if (request == INVALID_HANDLE) {
            LogError("Failed to create HTTP request using url: %s", url);
            return;
        }

        SteamWorks_SetHTTPCallbacks(request, OnMapRecievedFromAPI);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "default", default_map);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "expiration", expiration);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "league", league);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "offset", offset);
        SteamWorks_SendHTTPRequest(request);

    } else {
        LogError("You must have the SteamWorks extension installed to use workshop collections.");
    }
}

// SteamWorks HTTP callback for fetching a workshop collection
public int OnMapRecievedFromAPI(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode) {
    if (failure || !requestSuccessful) {
        LogError("API request failed, HTTP status code = %d", statusCode);
        return;
    }

    SteamWorks_WriteHTTPResponseBodyToFile(request, g_DataFile);
    ReadMapFromDatafile();

    LogMessage("got map %s", g_DefaultMap);
    if (IsMapValid(g_DefaultMap)) {
        CheckMapChange();
    }
}
