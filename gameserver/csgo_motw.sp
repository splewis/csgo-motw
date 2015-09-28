#include <cstrike>
#include <sourcemod>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

#define TEMP_DATAFILE "data/csgo_motw.txt"

ConVar g_EnabledCvar;

ConVar g_AlwaysForceMOTWCvar;
ConVar g_ApiUrlCvar;
ConVar g_DefaultCvar;
ConVar g_ExpirationCvar;
ConVar g_LeagueCvar;
ConVar g_OffsetCvar;

char g_CurrentMOTW[PLATFORM_MAX_PATH+1];
char g_DataFile[PLATFORM_MAX_PATH+1];

public Plugin myinfo = {
    name = "[CS:GO] Map of the week [motw]",
    author = "splewis",
    description = "Changes the servers map to be the current MOTW",
    version = "1.0.0",
    url = "https://github.com/splewis/csgo-motw"
};

public void OnPluginStart() {
    BuildPath(Path_SM, g_DataFile, sizeof(g_DataFile), TEMP_DATAFILE);
    g_AlwaysForceMOTWCvar = CreateConVar("sm_csgo_motw_always_force_motw", "1", "Whether the map is always forced to the MOTW. If set to 0, the server will only change to it when there are 0 connected clients.");
    g_ApiUrlCvar = CreateConVar("sm_csgo_motw_api_url", "http://csgo-motw.appspot.com", "URL the api is hosted at");
    g_DefaultCvar = CreateConVar("sm_csgo_motw_default", "de_dust2", "Default backup map");
    g_EnabledCvar = CreateConVar("sm_csgo_motw_enabled", "1", "Whether the plugin is enabled");
    g_ExpirationCvar = CreateConVar("sm_csgo_motw_expiration", "1209600");
    g_LeagueCvar = CreateConVar("sm_csgo_motw_league", "esea", "League maplist being used, allowed values: \"esea\", \"cevo\"");
    g_OffsetCvar = CreateConVar("sm_csgo_motw_offset", "0", "Offset in seconds added to the timestamp");
    AutoExecConfig();

    RegAdminCmd("sm_reloadmotw", Command_ReloadMOTW, ADMFLAG_CHANGEMAP, "Reloads the current MOTW");

    // Read the initial map from the datafile.
    if (!ReadMapFromDatafile()) {
        char default_map[PLATFORM_MAX_PATH+1];
        g_DefaultCvar.GetString(default_map, sizeof(default_map));
        strcopy(g_CurrentMOTW, sizeof(g_CurrentMOTW), default_map);
    }
}

public bool ReadMapFromDatafile() {
    // Read the initial map from the datafile.
    File f = OpenFile(g_DataFile, "r");
    if (f != null) {
        f.ReadLine(g_CurrentMOTW, sizeof(g_CurrentMOTW));
        delete f;
        return true;
    }
    return false;
}

public void OnConfigsExecuted() {
    UpdateCurrentMap();
}

public void CheckMapChange() {
    if (g_EnabledCvar.IntValue != 0) {
        char mapName[PLATFORM_MAX_PATH+1];
        GetCurrentMap(mapName, sizeof(mapName));
        if (!StrEqual(mapName, g_CurrentMOTW, false) && IsMapValid(g_CurrentMOTW)) {
            CreateTimer(3.0, Timer_ChangeMap);
        }
    }
}

public Action Timer_ChangeMap(Handle timer) {
    if (g_AlwaysForceMOTWCvar.IntValue == 0 && CountNumPlayers() > 0) {
        return;
    }

    char mapName[PLATFORM_MAX_PATH+1];
    GetCurrentMap(mapName, sizeof(mapName));
    if (!StrEqual(mapName, g_CurrentMOTW, false) && IsMapValid(g_CurrentMOTW)) {
        ServerCommand("changelevel %s", g_CurrentMOTW);
    }
}

static void UpdateCurrentMap(int replyToSerial=0, ReplySource replySource=SM_REPLY_TO_CONSOLE) {
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

        LogMessage("sending api request");
        SteamWorks_SetHTTPCallbacks(request, OnMapRecievedFromAPI);
        SteamWorks_SetHTTPRequestContextValue(request, replyToSerial, replySource);
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
public int OnMapRecievedFromAPI(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statusCode, int serial, ReplySource replySource) {
    LogMessage("got api response");
    if (failure || !requestSuccessful) {
        LogError("API request failed, HTTP status code = %d", statusCode);
        CheckMapChange();
        return;
    }

    SteamWorks_WriteHTTPResponseBodyToFile(request, g_DataFile);

    if (statusCode == k_EHTTPStatusCode200OK) {
        ReadMapFromDatafile();
        if (serial != 0) {
            int client = GetClientOfUserId(serial);
            // Save original reply source to restore later.
            ReplySource r = GetCmdReplySource();
            SetCmdReplySource(replySource);
            ReplyToCommand(client, "Got new MOTW: %s", g_CurrentMOTW);
            SetCmdReplySource(r);
        }
        LogMessage("got map %s", g_CurrentMOTW);
    } else if (statusCode == k_EHTTPStatusCode400BadRequest) {
        char errMsg[1024];
        File f = OpenFile(g_DataFile, "r");
        if (f != null) {
            f.ReadLine(errMsg, sizeof(errMsg));
            delete f;
            LogError("Error message: %s", errMsg);
        }
        g_DefaultCvar.GetString(g_CurrentMOTW, sizeof(g_CurrentMOTW));
    }

    CheckMapChange();
}

public Action Command_ReloadMOTW(int client, int args) {
    UpdateCurrentMap(GetClientSerial(client), GetCmdReplySource());
}

public int CountNumPlayers() {
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
            count++;
        }
    }
    return count;
}
