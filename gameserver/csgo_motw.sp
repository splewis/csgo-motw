#include <cstrike>
#include <sourcemod>
#include "include/csgo_motw.inc"

#undef REQUIRE_EXTENSIONS
#include <SteamWorks>
#include <system2>

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

bool g_IsBot[MAXPLAYERS+1];

Handle g_OnMapFetched = INVALID_HANDLE;

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
    g_ApiUrlCvar = CreateConVar("sm_csgo_motw_api_url", "http://csgo-motw.appspot.com", "URL the api is hosted at. Do not include a trailing /.");
    g_DefaultCvar = CreateConVar("sm_csgo_motw_default", "de_dust2", "Default backup map. If set to the empty string \"\", the map won't be changed when no matching motw is found.");
    g_EnabledCvar = CreateConVar("sm_csgo_motw_enabled", "1", "Whether the plugin is enabled");
    g_ExpirationCvar = CreateConVar("sm_csgo_motw_expiration", "1209600");
    g_LeagueCvar = CreateConVar("sm_csgo_motw_league", "esea", "League maplist being used, allowed values: \"esea\", \"cevo\"");
    g_OffsetCvar = CreateConVar("sm_csgo_motw_offset", "0", "Offset in seconds added to the timestamp");
    AutoExecConfig();

    g_OnMapFetched = CreateGlobalForward("MOTW_OnMapFetched", ET_Ignore, Param_String);

    RegAdminCmd("sm_reloadmotw", Command_ReloadMOTW, ADMFLAG_CHANGEMAP, "Reloads the current MOTW");

    // Read the initial map from the datafile.
    if (!ReadMapFromDatafile()) {
        char default_map[PLATFORM_MAX_PATH+1];
        g_DefaultCvar.GetString(default_map, sizeof(default_map));
        SetMOTW(g_CurrentMOTW);
    }
}

public void OnClientAuthorized(int client, const char[] id) {
    g_IsBot[client] = StrEqual(id, "BOT", false);
}

public void OnClientDisconnect(int client) {
    g_IsBot[client] = false;
}

public void OnClientDisconnect_Post(int client) {
    CheckMapChange();
}

public bool ReadMapFromDatafile() {
    // Read the initial map from the datafile.
    File f = OpenFile(g_DataFile, "r");
    if (f != null) {
        char tmp[sizeof(g_CurrentMOTW)];
        f.ReadLine(tmp, sizeof(tmp));
        SetMOTW(tmp);
        delete f;
        return true;
    }
    return false;
}

public void OnConfigsExecuted() {
    UpdateCurrentMap();
}

public void CheckMapChange() {
    // Mapchanges are slightly delay to make it easier on clients to avoid
    // constantly changing maps.
    CreateTimer(5.0, Timer_ChangeMap);
}

public Action Timer_ChangeMap(Handle timer) {
    if (g_EnabledCvar.IntValue == 0  || (g_AlwaysForceMOTWCvar.IntValue == 0 && CountNumPlayers() > 0)) {
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

    char formattedUrl[1024];
    Format(formattedUrl, sizeof(formattedUrl),
           "%s?/default=%s,expiration=%s,league=%s,offset=%s",
           url, default_map, expiration, league, offset);

    if (GetFeatureStatus(FeatureType_Native, "SteamWorks_CreateHTTPRequest") == FeatureStatus_Available) {
        Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url);
        if (request == INVALID_HANDLE) {
            LogError("Failed to create HTTP request using url: %s", url);
            return;
        }

        SteamWorks_SetHTTPCallbacks(request, SteamWorks_OnMapRecieved);
        SteamWorks_SetHTTPRequestContextValue(request, replyToSerial, replySource);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "default", default_map);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "expiration", expiration);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "league", league);
        SteamWorks_SetHTTPRequestGetOrPostParameter(request, "offset", offset);
        SteamWorks_SendHTTPRequest(request);

    } else if (GetFeatureStatus(FeatureType_Native, "System2_DownloadFile") == FeatureStatus_Available) {
        System2_DownloadFile(System2_OnMapRecieved, formattedUrl, g_DataFile);

    } else {
        LogError("You must have either the SteamWorks or system2 extension installed to use workshop collections.");
    }
}

// SteamWorks HTTP callback for fetching a workshop collection
public int SteamWorks_OnMapRecieved(Handle request, bool failure, bool requestSuccessful,
                                    EHTTPStatusCode statusCode, int serial, ReplySource replySource) {
    if (failure || !requestSuccessful) {
        LogError("API request failed, HTTP status code = %d", statusCode);
        CheckMapChange();
        return;
    }

    SteamWorks_WriteHTTPResponseBodyToFile(request, g_DataFile);

    if (statusCode == k_EHTTPStatusCode200OK) {
        ReadMapFromDatafile();
        if (serial != 0) {
            int client = GetClientFromSerial(serial);
            // Save original reply source to restore later.
            ReplySource r = GetCmdReplySource();
            SetCmdReplySource(replySource);
            ReplyToCommand(client, "Got new MOTW: %s", g_CurrentMOTW);
            SetCmdReplySource(r);
        }
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

public int System2_OnMapRecieved(bool finished, const char[] error, float dltotal, float dlnow, float ultotal, float ulnow, int serial) {
    if (finished) {
        if (StrEqual(error, "")) {
            ReadMapFromDatafile();
            int client = GetClientFromSerial(serial);
            PrintToConsole(client, "Got new MOTW: %s", g_CurrentMOTW);
        } else {
            LogError("Failed to get motw data: %s", error);
        }
    }
    CheckMapChange();
}

public Action Command_ReloadMOTW(int client, int args) {
    UpdateCurrentMap(GetClientSerial(client), GetCmdReplySource());
    return Plugin_Handled;
}

public int CountNumPlayers() {
    // Note: IsFakeClient(i) is not used because it requires IsClientInGame(i)
    // to be true - which will always return false for human players during
    // mapchanges. Therefore player counts use authentication first, which
    // happens earlier. See the OnClientAuthorized forward for managing this.
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientConnected(i) && !g_IsBot[i]) {
            count++;
        }
    }
    return count;
}

public void SetMOTW(const char[] map) {
    if (IsMapValid(map)) {
        Call_StartForward(g_OnMapFetched);
        Call_PushString(map);
        Call_Finish();
        strcopy(g_CurrentMOTW, sizeof(g_CurrentMOTW), map);
    } else {
        LogError("Failed to set MOTW to: \"%s\"", map);
    }
}

// Natives.
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    CreateNative("MOTW_GetMap", Native_GetMap);
}

public int Native_GetMap(Handle plugin, int numParams) {
    int length = GetNativeCell(2);
    SetNativeString(1, g_CurrentMOTW, length);
}
