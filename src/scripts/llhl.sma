/*
    LLHL Gamemode for AG 6.6 and AGMini
    Version: 2.0-stable
    Author: FlyingCat

    # Information:
    This plugin is a port for Adrenaline Gamer 6.6 (And AGMini) from my LLHL gamemode that 
    was developed for rtxa's agmodx.
    Unlike my gamemode for agmodx, this one only supports protocol 48.

    # Features:
    - FPS Limiter (Default value is 144)
    - FOV Limiter (Minimum value is 85, disabled by default)
    - Records a demo automatically when a match is started (With agstart)
    - /unstuck command (10 seconds cooldown)
    - Check certain sound files, they're the same sounds that are verified in the 
    EHLL gamemode - AG6.6
    - Be able to destroy other players satchels (Optional, disabled by default)
    - Block nickname changes when a game is in progress (Optional, enabled by default)
    - New intermission mode
    - More than 1 HLTV allowed
    - Force connected HLTV to have a certain delay value as a minimum (Minimum value is 30)
    - Ghostmine Blocker
    - Simple OpenGF32 and AGFix detection (Through cheat commands)
    - Take screenshots at map end and occasionally when a player dies
    - Avoid abusing a ReHLDS bug (Server disappears from the masterlist when it's' paused) only when there's no game in progress.
    - Changing model during a match subtract 1 from the score. (Optional, enabled by default).
    - Block access to players who have the game via Family Sharing. (Optional, disabled by default).
    - Random spawns (Optional, disabled by default)
    - Blocks location/HP/Weapon/etc messages for spectators
    - Check for new updates and it will download them automatically.
    - llhl_match_manager command (For administrators only)

    # New cvars:
    - sv_ag_fpslimit_max_fps "144"
    - sv_ag_fpslimit_max_detections "2"
    - sv_ag_min_default_fov_enabled "0"
    - sv_ag_min_default_fov "85"
    - sv_ag_cvar_check_interval "1.5"
    - sv_ag_unstuck_cooldown "10.0"
    - sv_ag_unstuck_start_distance "32"
    - sv_ag_unstuck_max_attempts "64"
    - sv_ag_destroyable_satchel "0"
    - sv_ag_destroyable_satchel_hp "1"
    - sv_ag_block_namechange_inmatch "1"
    - sv_ag_block_modelchange_inmatch "1"
    - sv_ag_min_hltv_delay "30.0"
    - sv_ag_block_ghostmine "1"
    - sv_ag_cheat_cmd_check_interval "5.0"
    - sv_ag_cheat_cmd_max_detections "5"
    - sv_ag_change_model_penalization "1"
    - sv_ag_block_family_sharing "0"
    - sv_ag_random_spawns "0"
    - sv_ag_block_cmd_enhancements "1"
    - sv_ag_steam_api_key ""
    - sv_ag_check_updates "1"
    - sv_ag_check_updates_retrys "3"
    - sv_ag_check_updates_retry_delay "2.0"

    # Thanks to:
    - Th3-822: FPS Limiter and blocking name and model changes
    - Alka: Server FPS
    - Arkshine: Unstuck command
    - naz: Useful codes for hook messages from AG engine
    - BulliT: For developing AG Mod and sharing the source code
    - Dcarlox: Grammar corrections in the README
    - leynieR: Portuguese Translation.

    Contact: alonso.caychop@tutamail.com or Suisei#1966 (Discord)
*/

#include <amxmodx>
#include <amxmisc>
#include <curl>
#include <curl_helper>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <hlstocks>
#include <json>
#include <regex>

#define PLUGIN          "Liga Latinoamericana de Half Life"
#define PLUGIN_ACRONYM  "LLHL"
#define PLUGIN_GAMEMODE "llhl"
#define VERSION         "2.1-stable"
#define AUTHOR          "FlyingCat"
#define GH_API_URL      "https://api.github.com/repos/FlyingCat-X/llhl/tags?per_page=1"
#define STEAM_API_URL   "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=%s&steamid=%s&format=json&appids_filter[0]=70"

#pragma semicolon 1
#pragma dynamic 163840

#define INCOMING_BUFFER_LENGTH  2048
#define VERSION_ARRAY_SIZE      16

#define GetPlayerHullSize(%1)  ((pev(%1, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN)
#define random_mod(%1) (random_num(0, (100 * (%1)) - 1) % (%1))

// Vote state
#define AGVOTE_ACCEPTED 2

// Game states
#define GAME_IDLE       0
#define GAME_STARTING   1
#define GAME_RUNNING    2

// Is GhostMineBlock loaded?
#define GMB_NOTLOADED   0
#define GMB_LOADED      1 // Reserved for future use
#define GMB_BLOCKED     2 // Reserved for future use

// MM: Match Manager
#define MM_NO_TEAM      "NO"
#define MM_BLUE_TEAM    "BLUE"
#define MM_RED_TEAM     "RED"

enum (+=103) {
    TASK_CVARCHECKER = 72958,
    TASK_SHOWVENGINE,
    TASK_CHEATCHECKER
};

enum _:LLHLFile {
    LLHLFile_Data,
    LLHLFile_FullPath[256]
}

new gGameState;
new gGhostMineBlockState;
new gNumDetections[MAX_PLAYERS + 1];
new gOldPlayerModel[MAX_PLAYERS + 1][HL_MAX_TEAMNAME_LENGTH];
new gDeathScreenshotTaken[MAX_PLAYERS + 1];
new gDetectionScreenshotTaken[MAX_PLAYERS + 1];

// Cvars pointers
new gCvarAgStartMinPlayers;
new gCvarMaxFps;
new gCvarMaxDetections;
new gCvarMinFovEnabled;
new gCvarMinFov;
new gCvarCheckInterval;
new gCvarUnstuckCooldown;
new gCvarUnstuckStartDistance;
new gCvarUnstuckMaxSearchAttempts;
new gCvarDestroyableSatchel;
new gCvarDestroyableSatchelHP;
new gCvarBlockNameChangeInMatch;
new gCvarBlockModelChangeInMatch;
new gCvarNumHLTVAllowed;
new gCvarMinHLTVDelay;
new gCvarBlockGhostmine;
new gCvarCheatCmdCheckInterval;
new gCvarCheatCmdMaxDetections;
new gCvarChangeModelPenalization;
new gCvarBlockFamilySharing;
new gCvarSteamAPIKey;
new gCvarRandomSpawns;
new gCvarBlockAGCmdEnhancements;
new gCvarCheckUpdates;
new gCvarCheckUpdatesRetrys;
new gCvarCheckUpdatesRetryDelay;

new bool:gFirstCheatValidation[MAX_PLAYERS + 1];
new bool:gSecondCheatValidation[MAX_PLAYERS + 1];
new gCheatNumDetections[MAX_PLAYERS + 1];
new gCommandSended[16];

new gSHA1Hash[64];

new Float:gUnstuckLastUsed[MAX_PLAYERS + 1];
static Float:gActualServerFPS;

new Array:gSpawnOrigins, Array:gSpawnAngles;
new gSpawnsCounter;

new Regex:gAGCmdEnhancementPattern;

new gCheckUpdatesNumRetrys;
new gRepoVersion[32];
new bool:gIsOutdated = false;


// MM: Match Manager
new gMMVersusType[2];
new gMMMenuOwner;

new Trie:gMMUserIDPlayers;

new const gConsistencySoundFiles[][] = {
    "ambience/pulsemachine.wav",
    "common/npc_step1.wav", "common/npc_step2.wav", "common/npc_step3.wav", "common/npc_step4.wav",
    "fvox/powermove_on.wav",
    "items/gunpickup2.wav",
    "player/pl_dirt1.wav", "player/pl_dirt2.wav", "player/pl_dirt3.wav", "player/pl_dirt4.wav",
    "player/pl_duct1.wav", "player/pl_duct2.wav", "player/pl_duct3.wav", "player/pl_duct4.wav",
    "player/pl_fallpain3.wav",
    "player/pl_grate1.wav", "player/pl_grate2.wav", "player/pl_grate3.wav", "player/pl_grate4.wav",
    "player/pl_ladder1.wav", "player/pl_ladder2.wav", "player/pl_ladder3.wav", "player/pl_ladder4.wav",
    "player/pl_metal1.wav", "player/pl_metal2.wav", "player/pl_metal3.wav", "player/pl_metal4.wav",
    "player/pl_pain2.wav",
    "player/pl_slosh1.wav", "player/pl_slosh2.wav", "player/pl_slosh3.wav", "player/pl_slosh4.wav",
    "player/pl_step1.wav", "player/pl_step2.wav", "player/pl_step3.wav", "player/pl_step4.wav",
    "player/pl_swim1.wav", "player/pl_swim2.wav", "player/pl_swim3.wav", "player/pl_swim4.wav",
    "weapons/egon_off1.wav",
    "weapons/egon_run3.wav",
    "weapons/egon_windup2.wav"
};

new const gCheatsCommands[][] = {
    "aimbot", "bhop", "fullbright", "nosky", "xhair", "wh", // OpenGF
    "agfix_rec", "agfix_flash", "agfix_ff0", "agfix_bh", "agfix_smoke", "agfix_nospread", "agfix_speed" // AGFix
};

public plugin_init() {
    register_dictionary("llhl.txt");

    server_print("%L", LANG_SERVER, "LLHL_INITIALIZING", PLUGIN_ACRONYM);

    register_plugin(PLUGIN, VERSION, AUTHOR);

    new gamemode[32];
    get_cvar_string("sv_ag_gamemode", gamemode, charsmax(gamemode));

    // Check if GhostMineBlock is loaded even when the gamemode isn't LLHL
    if (!cvar_exists("gm_block_on")) {
        gGhostMineBlockState = GMB_NOTLOADED;
    } else {
        gGhostMineBlockState = GMB_LOADED;
    }

    if (!equali(gamemode, PLUGIN_GAMEMODE)) {
        server_print("%L", LANG_SERVER, "LLHL_CANT_RUN", PLUGIN_ACRONYM, PLUGIN, PLUGIN_GAMEMODE);
        // If GhostMineBlock is loaded and the gamemode isn't LLHL, it'll be deactivated
        if (gGhostMineBlockState == GMB_LOADED) {
            gGhostMineBlockState = GMB_BLOCKED;
            set_cvar_num("gm_block_on", 0);
            server_print("%L", LANG_SERVER, "LLHL_GM_BLOCK_DEACTIVATED", PLUGIN_ACRONYM);
            // Try to load the default motd
            server_cmd("motdfile motd.txt", PLUGIN_GAMEMODE);
            server_exec();
        }
        pause("ad");
        return;
    }

    // Only ReHLDS
    if (cvar_exists("sv_rcon_condebug")) {
        register_clcmd("agpause", "CmdAgpauseRehldsHook");
        server_print("%L", LANG_SERVER, "LLHL_REHLDS_DETECTED", PLUGIN_ACRONYM);
    }

    gCvarAgStartMinPlayers = get_cvar_pointer("sv_ag_start_minplayers");

    // FPS Limiter
    gCvarMaxFps = create_cvar("sv_ag_fpslimit_max_fps", "144");
    gCvarMaxDetections = create_cvar("sv_ag_fpslimit_max_detections", "2");

    // Mininum Default Fov Allowed (Disabled by default)
    gCvarMinFovEnabled = create_cvar("sv_ag_min_default_fov_enabled", "0");
    gCvarMinFov = create_cvar("sv_ag_min_default_fov", "85");

    // CVAR Checker Interval (FPS and Fov)
    gCvarCheckInterval = create_cvar("sv_ag_cvar_check_interval", "1.5");

    // Unstuck command
    gCvarUnstuckCooldown = create_cvar("sv_ag_unstuck_cooldown", "10.0");
    gCvarUnstuckStartDistance = create_cvar("sv_ag_unstuck_start_distance", "32");
    gCvarUnstuckMaxSearchAttempts = create_cvar("sv_ag_unstuck_max_attempts", "64");

    // Destroyable Satchel
    gCvarDestroyableSatchel =  create_cvar("sv_ag_destroyable_satchel", "0");
    gCvarDestroyableSatchelHP = create_cvar("sv_ag_destroyable_satchel_hp", "1");

    // Block name change (Only spectators) log in match
    gCvarBlockNameChangeInMatch = create_cvar("sv_ag_block_namechange_inmatch", "1");

    // Block model change (Only spectators) log in match
    gCvarBlockModelChangeInMatch = create_cvar("sv_ag_block_modelchange_inmatch", "1");
    
    // HLTV
    gCvarNumHLTVAllowed = create_cvar("sv_ag_num_hltv_allowed", "2");
    gCvarMinHLTVDelay = create_cvar("sv_ag_min_hltv_delay", "30.0");

    // Simple OpenGF32 and AGFix Detection
    gCvarCheatCmdCheckInterval = create_cvar("sv_ag_cheat_cmd_check_interval", "5.0");
    gCvarCheatCmdMaxDetections = create_cvar("sv_ag_cheat_cmd_max_detections", "5");

    // Score penalization
    gCvarChangeModelPenalization = create_cvar("sv_ag_change_model_penalization", "1");

    // Block access to players who enter with a shared HL/AG via family sharing
    gCvarBlockFamilySharing = create_cvar("sv_ag_block_family_sharing", "0");
    gCvarSteamAPIKey = create_cvar("sv_ag_steam_api_key", "");

    gCvarRandomSpawns = create_cvar("sv_ag_random_spawns", "0");

    gCvarBlockAGCmdEnhancements = create_cvar("sv_ag_block_cmd_enhancements", "1");

    gGameState = GAME_IDLE;

    if (gGhostMineBlockState == GMB_LOADED) {
        gCvarBlockGhostmine = create_cvar("sv_ag_block_ghostmine", "1");
    }

    // Check updates from Github Repo
    gCvarCheckUpdates = create_cvar("sv_ag_check_updates", "1");
    gCvarCheckUpdatesRetrys = create_cvar("sv_ag_check_updates_retrys", "3");
    gCvarCheckUpdatesRetryDelay = create_cvar("sv_ag_check_updates_retry_delay", "2.0");

    // Just to be sure that the values haven't been replaced when creating the cvars
    server_cmd("exec gamemodes/%s.cfg", PLUGIN_GAMEMODE);
    server_exec();

    // Num. HLTV Allowed
    set_cvar_num("sv_proxies", get_pcvar_num(gCvarNumHLTVAllowed));
    hook_cvar_change(gCvarNumHLTVAllowed, "CvarHLTVAllowedHook");
    hook_cvar_change(get_cvar_pointer("sv_proxies"), "CvarSVProxiesHook");

    if (cvar_exists("sv_ag_block_ghostmine")) {
        // Reload GhostMineBlock original cvar
        set_cvar_num("gm_block_on", get_pcvar_num(gCvarBlockGhostmine));
        hook_cvar_change(gCvarBlockGhostmine, "CvarGhostMineHook");
        hook_cvar_change(get_cvar_pointer("gm_block_on"), "MetaCvarGhostMineHook");
    }
    
    gSpawnOrigins = ArrayCreate(3);
    gSpawnAngles = ArrayCreate(3);
    
    LoadSpawns();
    
    RegisterHam(Ham_Spawn, "player", "HamPlayerSpawnPost", 1);

    register_clcmd("say", "CmdSay");
    register_clcmd("say_team", "CmdSay");

    register_clcmd("say /unstuck", "CmdUnstuck");

    hash_file("addons/amxmodx/plugins/llhl.amxx", Hash_Sha1, gSHA1Hash, charsmax(gSHA1Hash));

    register_clcmd("hash", "CmdSHA1Hash");
    register_clcmd("say /hash", "CmdSHA1Hash");

    gMMUserIDPlayers = TrieCreate();

    register_clcmd("llhl_match_manager", "MatchManagerMenu", ADMIN_MENU);
    
    // AG Messages
    register_message(get_user_msgid("Countdown"), "FwMsgCountdown");
    register_message(get_user_msgid("Settings"), "FwMsgSettings");
    register_message(get_user_msgid("Vote"), "FwMsgVote");

    register_message(SVC_INTERMISSION, "FwMsgIntermission");

    register_event("DeathMsg", "EventDeathMsg", "ad");

    register_forward(FM_SetModel, "FwSetModel");
    register_forward(FM_ClientUserInfoChanged, "FwClientUserInfoChangedPre", 0);
    register_forward(FM_StartFrame, "FwStartFrame");
    register_forward(FM_GetGameDescription, "FwGameDescription");
    
    for (new i; i < sizeof gConsistencySoundFiles; i++) {
        force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, gConsistencySoundFiles[i]);
    }

    set_task(floatmax(1.0, get_pcvar_float(gCvarCheckInterval)), "CvarCheckRun");

    set_task(floatmax(1.0, get_pcvar_float(gCvarCheatCmdCheckInterval)), "CheatCommandRun", TASK_CHEATCHECKER);

    hook_cvar_change(gCvarCheatCmdCheckInterval, "CvarCheatCmdIntervalHook");

    // Load LLHL Motd
    new serverLanguage[4];
    get_cvar_string("amx_language", serverLanguage, charsmax(serverLanguage));

    if (equali(serverLanguage, "es") || equali(serverLanguage, "en") || equali(serverLanguage, "pt")) {
        new command[64];
        formatex(command, charsmax(command), "motdfile motd_llhl_%s.txt", serverLanguage);
        server_cmd(command, PLUGIN_GAMEMODE);
    } else {
        server_cmd("motdfile motd_llhl_en.txt", PLUGIN_GAMEMODE);
    }
    server_exec();

    if (get_pcvar_num(gCvarCheckUpdates)) {
        gCheckUpdatesNumRetrys = 0;
        ConnectGithubAPI();
    }
}

public inconsistent_file(id, const filename[], reason[64]) {
    new name[32], authid[32];
    get_user_name(id, name, charsmax(name));
    get_user_authid(id, authid, charsmax(authid));
    client_print(0, print_chat, "%l", "FILECONSISTENCY_MSG", name, authid, filename);
    log_amx("%L", LANG_SERVER, "FILECONSISTENCY_MSG", name, authid, filename);
    server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "FILECONSISTENCY_KICK", filename);
    return PLUGIN_HANDLED;
}

public FwGameDescription() {
    new actualGamename[32];
    dllfunc(DLLFunc_GetGameDescription, actualGamename, charsmax(actualGamename));
    
    new newGamename[128];
    formatex(newGamename, charsmax(newGamename), "%s v%s", actualGamename, VERSION);
    forward_return(FMV_STRING, newGamename);

    return FMRES_SUPERCEDE;
}

public client_connect(id) {
    gNumDetections[id] = 0;
    gCheatNumDetections[id] = 0;
    gFirstCheatValidation[id] = false;
    gSecondCheatValidation[id] = false;

    new userID[8];
    num_to_str(get_user_userid(id), userID, charsmax(userID));

    if (!TrieKeyExists(gMMUserIDPlayers, userID)) {
        TrieSetString(gMMUserIDPlayers, userID, MM_NO_TEAM);
    }
}

public client_disconnected(id) {
    new userID[8];
    num_to_str(get_user_userid(id), userID, charsmax(userID));

    if (TrieKeyExists(gMMUserIDPlayers, userID)) {
        TrieDeleteKey(gMMUserIDPlayers, userID);
    }
}

public client_putinserver(id) {
    if (gIsOutdated && get_pcvar_num(gCvarCheckUpdates)) {
        set_task(5.0, "ShowIsOutdated", id);
    }
    if (!gOldPlayerModel[id][0]) {
        // Populate gOldPlayerModel on players after a changelevel
        new newValue[32];
        get_user_info(id, "model", newValue, charsmax(newValue));
        formatex(gOldPlayerModel[id], charsmax(gOldPlayerModel[]), "%s", newValue);
    }
    // Workaround for first spawn at join
    HamPlayerSpawnPost(id);
}

public client_authorized(id) {
    if (get_pcvar_num(gCvarBlockFamilySharing)) {
        ConnectSteamAPI(id);
    }
}

public client_command(id) {
    new command[64];
    read_argv(0, command, charsmax(command));
    if (equali(command, "preCheck")) {
        gFirstCheatValidation[id] = true;
        gSecondCheatValidation[id] = false;
        return PLUGIN_HANDLED;
    } else if (IsCheatCommand(command)) {
        if (gFirstCheatValidation[id]) {
            gSecondCheatValidation[id] = true;
            return PLUGIN_HANDLED;
        }
    } else if (equali(command, "postCheck")) {
        if (gFirstCheatValidation[id] && !gSecondCheatValidation[id]) {
            gCheatNumDetections[id]++;
            gFirstCheatValidation[id] = false;
            gSecondCheatValidation[id] = false;
            new name[32], authID[32], formatted[32], fileName[32];
            new timestamp = get_systime();
            format_time(formatted, charsmax(formatted), "%d%m%Y", timestamp);
            formatex(fileName, charsmax(fileName), "llhl_detections_%s.log", formatted);
            get_user_name(id, name, charsmax(name));
            get_user_authid(id, authID, charsmax(authID));
            log_to_file(fileName, "%L", LANG_SERVER, "LLHL_SCD_POSSIBLE_DETECTION", PLUGIN_ACRONYM, name, authID, gCommandSended, gCheatNumDetections[id], get_pcvar_num(gCvarCheatCmdMaxDetections));

            if (gCheatNumDetections[id] >= get_pcvar_num(gCvarCheatCmdMaxDetections)) {
                log_to_file(fileName, "%L", LANG_SERVER, "LLHL_SCD_DETECTION", PLUGIN_ACRONYM, name, authID, gCheatNumDetections[id]);
                if (!gDetectionScreenshotTaken[id] && random_num(69, 70) == 69) {
                    if (gGameState == GAME_RUNNING) {
                        TakeScreenshot(id);
                        gDetectionScreenshotTaken[id] = 1;
                    }
                }
                gCheatNumDetections[id] = 0;
            }
        }
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public HamPlayerSpawnPost(id) {
    if (get_pcvar_num(gCvarRandomSpawns)) {
        if (is_user_alive(id)) {
            new randomSpawn = random_mod(gSpawnsCounter), Float:vector[3];
            entity_get_vector(id, EV_VEC_origin, vector);
            
            ArrayGetArray(gSpawnOrigins, randomSpawn, vector);
            
            if (IsSpawnValid(id, vector)) {
                entity_set_origin(id, vector);
                
                ArrayGetArray(gSpawnAngles, randomSpawn, vector);
                entity_set_vector(id, EV_VEC_angles, vector);
                entity_set_int(id, EV_INT_fixangle, 1);
                
                return HAM_HANDLED;
            }
        }
    }
    return HAM_IGNORED;
}

public IsSpawnValid(id, Float:origin[3]) {
	return (trace_hull(origin, (get_user_flags(id) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN), id, DONT_IGNORE_MONSTERS) & 2) ? 0 : 1;
}

// Called every second during the agstart countdown
public FwMsgCountdown(id, dest, ent) {
    static count, sound;
    count = get_msg_arg_int(1);
    sound = get_msg_arg_int(2);

    // A match is starting (Countdown)
    if (count >= 9) {
        gGameState = GAME_STARTING;
    }

    if (count != -1 || sound != 0)
        return;
    
    gGameState = GAME_RUNNING;
    // A match has just started (Countdown is over)
    new strDemo[128], mapname[32], formatted[32];
    new timestamp = get_systime();
    format_time(formatted, charsmax(formatted), "%d%m%Y_%H%M%S", timestamp);
    get_mapname(mapname, charsmax(mapname));
    formatex(strDemo, charsmax(strDemo), "[%s]_%s_%s", PLUGIN_ACRONYM, mapname, formatted);
    // Record demo
    for (new id = 1; id <= MaxClients; id++) {
        if (!is_user_connected(id))
            continue;
        
        if (!hl_get_user_spectator(id)) {
            client_cmd(id, "stop; record %s", strDemo);
            client_print(id, print_chat, "%l", "DEMO_RECORDING", strDemo);
            gDeathScreenshotTaken[id] = 0;
            gDetectionScreenshotTaken[id] = 0;
        }
    }
}

// Called when the settings are shown on the screen
public FwMsgSettings(id, dest, ent) {
    static isMatch;
    isMatch = get_msg_arg_int(1);
    if (!isMatch) {
        gGameState = GAME_IDLE;
    }
}

public FwMsgVote(id) {
    static status, setting[32];
    status = get_msg_arg_int(1);
    get_msg_arg_string(5, setting, charsmax(setting));

    if (status == AGVOTE_ACCEPTED) {
        if (equali(setting, "agstart") && get_playersnum() >= get_pcvar_num(gCvarAgStartMinPlayers)) {
            // Reserved for future use
        } else if (equali(setting, "agabort")) {
            // A match has just been aborted
            gGameState = GAME_IDLE;
            // Stop demo
            for (new id = 1; id <= MaxClients; id++) {
                if (!is_user_connected(id))
                    continue;
                
                client_cmd(id, "stop");
            }
        }
    }
}

public FwMsgIntermission(id) {
    gActualServerFPS = get_global_float(GL_frametime);
    client_cmd(0, "stop;wait;wait;+showscores");
    set_task(0.1, "TaskPreIntermission", TASK_SHOWVENGINE);
    message_begin(0, SVC_FINALE);
    write_string("");
    message_end();
    return PLUGIN_HANDLED;
}

public TaskPreIntermission() {
    // Show vEngine
    set_dhudmessage(0, 100, 200, -1.0, -0.125, 0, 0.0, 99.0);
    show_dhudmessage(0, "%s v%s^n----------------------^nMax Player FPS Allowed: %i^nHLTV Allowed: %i^nServer fps: %.1f^nGhostmine Blocker: %s", PLUGIN_ACRONYM, VERSION, get_pcvar_num(gCvarMaxFps), get_pcvar_num(gCvarNumHLTVAllowed), (1.0 / gActualServerFPS), !cvar_exists("sv_ag_block_ghostmine") ? "Not available" : get_pcvar_num(gCvarBlockGhostmine) ? "On" : "Off");
    client_cmd(0, "wait;wait;snapshot");
}

public EventDeathMsg() {
    new id = read_data(2);
    if (!gDeathScreenshotTaken[id] && random_num(63, 72) == 69) {
        if (gGameState == GAME_RUNNING) {
            TakeScreenshot(id);
            gDeathScreenshotTaken[id] = 1;
        }
    }
}

public TakeScreenshot(id) {
    if (is_user_connected(id)) {
        new formatted[32], name[32], authID[32];
        new timestamp = get_systime();
        get_user_name(id, name, charsmax(name));
        get_user_authid(id, authID, charsmax(authID));
        format_time(formatted, charsmax(formatted), "%d%m%Y | %H%M%S", timestamp);
        set_dhudmessage(0, 100, 200, -1.0, -0.125, 0, 0.0, 0.5, 0.0);
        show_dhudmessage(id, "%s^n%s (%s) Screeenshot has been taken", formatted, name, authID);
        client_cmd(id, "wait;wait;snapshot");
    }
}

public CmdSay(id) {
    if (get_pcvar_num(gCvarBlockAGCmdEnhancements)) {
        if (hl_get_user_spectator(id) && gGameState == GAME_RUNNING) {
            new message[191];
            read_args(message, charsmax(message));
            
            new ret, error[128];
            gAGCmdEnhancementPattern = regex_compile("%[halwqpf]", ret, error, charsmax(error), "i") ;
            
            if (gAGCmdEnhancementPattern > REGEX_NO_MATCH) {
                if (regex_match_c(message, gAGCmdEnhancementPattern, ret) > 0) {
                    return PLUGIN_HANDLED;
                }
            }
        }
    }
    return PLUGIN_CONTINUE;
}

public CmdUnstuck(id) {
    new Float:cooldownTime = get_pcvar_float(gCvarUnstuckCooldown);
    new Float:elapsedTime = get_gametime() - gUnstuckLastUsed[id];

    if (elapsedTime < cooldownTime) {
        client_print(id, print_chat, "%l", "UNSTUCK_ON_COOLDOWN", cooldownTime - elapsedTime);
        return PLUGIN_HANDLED;
    }
    gUnstuckLastUsed[id] = get_gametime();
    new value;
    if ((value = UnStuckPlayer(id)) != 1) {
        switch (value) {
            case 0: client_print(id, print_chat, "%l", "UNSTUCK_FREESPOT_NOTFOUND");
            case -1: client_print(id, print_chat, "%l", "UNSTUCK_PLAYER_DEAD");
        }
    }
    return PLUGIN_CONTINUE;
}

UnStuckPlayer(const id) {
    if (!is_user_alive(id)) return -1;

    static Float:originalOrigin[3], Float:newOrigin[3];
    static attempts, distance;

    pev(id, pev_origin, originalOrigin);

    distance = get_pcvar_num(gCvarUnstuckStartDistance);

    while (distance < 1000) {
        attempts = get_pcvar_num(gCvarUnstuckMaxSearchAttempts);
        while (attempts--) {
            newOrigin[0] = random_float(originalOrigin[0] - distance, originalOrigin[0] + distance);
            newOrigin[1] = random_float(originalOrigin[1] - distance, originalOrigin[1] + distance);
            newOrigin[2] = random_float(originalOrigin[2] - distance, originalOrigin[2] + distance);

            engfunc(EngFunc_TraceHull, newOrigin, newOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize(id), id, 0);

            if (get_tr2(0, TR_InOpen) && !get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid)) {
                engfunc(EngFunc_SetOrigin, id, newOrigin);
                return 1;
            }
        }
        distance += get_pcvar_num(gCvarUnstuckStartDistance);
    }
    return 0;
}

public CmdSHA1Hash(id) {
    client_print(id, print_chat, "%s v%s SHA1: %s", PLUGIN_ACRONYM, VERSION, gSHA1Hash);
    return PLUGIN_HANDLED;
}

public CheckHLTVDelay(id) {
    static hltvDelay[32];
    get_user_info(id, "hdelay", hltvDelay, charsmax(hltvDelay));
    if (str_to_float(hltvDelay) < get_pcvar_float(gCvarMinHLTVDelay)) {
        server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "MINDELAY_HLTV_KICK", get_pcvar_float(gCvarMinHLTVDelay));
    }
}

public CvarCheckRun() {
    static players[MAX_PLAYERS], pCount;
    get_players(players, pCount, "c");
    for (new i = 0; i < pCount; i++) {
        if (is_user_hltv(players[i])) {
            CheckHLTVDelay(players[i]);
        } else if (!hl_get_user_spectator(players[i])) {
            query_client_cvar(players[i], "fps_max", "FpsCheckReturn");
            if (get_pcvar_num(gCvarMinFovEnabled)) {
                query_client_cvar(players[i], "default_fov", "FovCheckReturn");
            }
        }
    }
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheckInterval)), "CvarCheckRun", TASK_CVARCHECKER);
}

public FpsCheckReturn(id, const cvar[], const value[]) {
    if (equali(value, "Bad CVAR request")) {
        server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "CVAR_PROTECTOR_KICK");
    } else if (equali(cvar, "fps_max") && str_to_num(value) > max(100, get_pcvar_num(gCvarMaxFps))) {
        console_cmd(id, "^"FpS_MaX^" %d", max(100, get_pcvar_num(gCvarMaxFps)));
        if (++gNumDetections[id] < get_pcvar_num(gCvarMaxDetections)) {
            client_print(id, print_chat, "%L", id, "FPSL_WARNING_MSG", max(100, get_pcvar_num(gCvarMaxFps)));
        } else {
            static name[MAX_NAME_LENGTH];
            get_user_name(id, name, charsmax(name));
            server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "FPSL_KICK", get_pcvar_num(gCvarMaxFps));
            log_amx("%L", LANG_SERVER, "FPSL_KICK_MSG", name, get_pcvar_num(gCvarMaxFps));
            client_print(0, print_chat, "%l", "FPSL_KICK_MSG", name, get_pcvar_num(gCvarMaxFps));
        }
    }
}

public FovCheckReturn(id, const cvar[], const value[]) {
    if (equali(value, "Bad CVAR request")) {
        server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "CVAR_PROTECTOR_KICK");
    } else if (equali(cvar, "default_fov") && str_to_num(value) < min(85, get_pcvar_num(gCvarMinFov))) {
        static name[MAX_NAME_LENGTH];
        get_user_name(id, name, charsmax(name));
        console_cmd(id, "default_fov %d", 90);
        server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "MINFOV_KICK", get_pcvar_num(gCvarMinFov));
        log_amx("%L", LANG_SERVER, "MINFOV_KICK_MSG", name, get_pcvar_num(gCvarMinFov));
        client_print(0, print_chat, "%l", "MINFOV_KICK_MSG", name, get_pcvar_num(gCvarMinFov));
    }
}

public CheatCommandRun() {
    copy(gCommandSended, charsmax(gCommandSended), gCheatsCommands[random_num(0, charsmax(gCheatsCommands))]);
    client_cmd(0, "preCheck;%s;postCheck", gCommandSended);
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheatCmdCheckInterval)), "CheatCommandRun", TASK_CHEATCHECKER);
}

public FwSetModel(entid, model[]) {
    if (!get_pcvar_num(gCvarDestroyableSatchel) || !pev_valid(entid) || !equal(model, "models/w_satchel.mdl"))
        return FMRES_IGNORED;

    static id;
    id = pev(entid, pev_owner);

    if (!id || !is_user_connected(id) || !is_user_alive(id))
        return FMRES_IGNORED;

    new Float:health = get_pcvar_float(gCvarDestroyableSatchelHP);
    set_pev(entid, pev_health, health);
    set_pev(entid, pev_takedamage, DAMAGE_YES);
    return FMRES_IGNORED;
}

public FwClientUserInfoChangedPre(id, info) {
    static cvarRunning;
    new stop, oldValue[32], newValue[32];
    if ((cvarRunning || (cvarRunning = get_cvar_pointer("sv_ag_match_running"))) && get_pcvar_num(cvarRunning) && gGameState == GAME_RUNNING && is_user_connected(id)) {
        new bool:isPlayerSpec = hl_get_user_spectator(id);

        if (get_pcvar_num(gCvarBlockNameChangeInMatch) && pev(id, pev_netname, oldValue, charsmax(oldValue)) && engfunc(EngFunc_InfoKeyValue, info, "name", newValue, charsmax(newValue)) && !equal(oldValue, newValue) && isPlayerSpec) {
            engfunc(EngFunc_SetClientKeyValue, id, info, "name", oldValue);
            client_print(id, print_chat, "%l", "BLOCK_NAMECHANGE_MSG");
            stop = true;
        }

        if (get_pcvar_num(gCvarBlockModelChangeInMatch) && copy(oldValue, charsmax(oldValue), gOldPlayerModel[id]) && engfunc(EngFunc_InfoKeyValue, info, "model", newValue, charsmax(newValue))) {
           if (!equal(oldValue, newValue)) {
                if (isPlayerSpec) {
                    engfunc(EngFunc_SetClientKeyValue, id, info, "model", oldValue);
                    client_print(id, print_chat, "%l", "BLOCK_MODELCHANGE_MSG");
                    stop = true;
                } else {
                    if (FixTeamPlayModelLen(id, info, newValue)) {
                        stop = true;
					} else {
                        copy(gOldPlayerModel[id], charsmax(gOldPlayerModel[]), newValue);
                    }

                    if (get_pcvar_num(gCvarChangeModelPenalization) && !(stop && equal(oldValue, gOldPlayerModel[id]))) {
                        ExecuteHam(Ham_AddPoints, id, -1, true);
                    }
                }
            }
        } else {
            engfunc(EngFunc_InfoKeyValue, info, "model", gOldPlayerModel[id], charsmax(gOldPlayerModel[]));
            formatex(gOldPlayerModel[id], charsmax(gOldPlayerModel[]), "%s", newValue);
        }
    } else {
        engfunc(EngFunc_InfoKeyValue, info, "model", newValue, charsmax(newValue));
        if (FixTeamPlayModelLen(id, info, newValue)) {
            stop = true;
        } else {
            copy(gOldPlayerModel[id], charsmax(gOldPlayerModel[]), newValue);
        }
    }
    return (stop ? FMRES_SUPERCEDE : FMRES_IGNORED);
}

public FixTeamPlayModelLen(id, info, model[]) {
	new newValue[HL_MAX_TEAMNAME_LENGTH];
	formatex(newValue, charsmax(newValue), "%s", model);
	if (!equal(model, newValue)) {
        // Fix Model Length
        copy(gOldPlayerModel[id], charsmax(gOldPlayerModel[]), newValue);
        engfunc(EngFunc_SetClientKeyValue, id, info, "model", newValue);
        return 1;
    }
	return 0;
}

public CmdAgpauseRehldsHook(id) {
    if (get_playersnum() == 1 && gGameState == GAME_IDLE) {
        new name[32], authID[32], formatted[32], fileName[32];
        new timestamp = get_systime();
        format_time(formatted, charsmax(formatted), "%d%m%Y", timestamp);
        formatex(fileName, charsmax(fileName), "llhl_detections_%s.log", formatted);
        get_user_name(id, name, charsmax(name));
        get_user_authid(id, authID, charsmax(authID));
        log_to_file(fileName, "%L", LANG_SERVER, "LLHL_REHLDS_XPLOIT", PLUGIN_ACRONYM, name, authID);
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public CvarHLTVAllowedHook(pcvar, const old_value[], const new_value[]) {
    set_cvar_string("sv_proxies", new_value);
}

public CvarSVProxiesHook(pcvar, const old_value[], const new_value[]) {
    set_pcvar_string(gCvarNumHLTVAllowed, new_value);
}

public CvarGhostMineHook(pcvar, const old_value[], const new_value[]) {
    set_cvar_string("gm_block_on", new_value);
}

public MetaCvarGhostMineHook(pcvar, const old_value[], const new_value[]) {
    set_pcvar_string(gCvarBlockGhostmine, new_value);
}

public CvarCheatCmdIntervalHook(pcvar, const old_value[], const new_value[]) {
    remove_task(TASK_CHEATCHECKER);
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheatCmdCheckInterval)), "CheatCommandRun", TASK_CHEATCHECKER);
}

public ShowIsOutdated(id) {
    client_print(id, print_chat, "%l", "LLHL_IS_OUTDATED", PLUGIN_ACRONYM);
}

public ConnectGithubAPI() {
    new CURL:curl = curl_easy_init();

    if (!curl) {
        server_print("%L", LANG_SERVER, "LLHL_CURL_INIT_ERROR");
        log_amx("%L", LANG_SERVER, "LLHL_CURL_INIT_ERROR");
    }

    new curl_slist:headers;
    headers = curl_slist_append(headers, "Content-Type:application/json");
    headers = curl_slist_append(headers, "User-Agent: LLHL_AMXX_PLUGIN/1.0");

    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1); // Follow Github Redirect
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
    curl_easy_setopt(curl, CURLOPT_URL, GH_API_URL);
    curl_helper_set_write_options(curl);

    curl_easy_perform(curl, "GetLatestVersion");
}

public ConnectSteamAPI(id) {
    new url[250], steam64ID[32], steamAPIKey[64];
    get_user_info(id, "*sid", steam64ID, charsmax(steam64ID));
    get_pcvar_string(gCvarSteamAPIKey, steamAPIKey, charsmax(steamAPIKey));

    if (equali(steamAPIKey, "")) {
        server_print("%L", LANG_SERVER, "LLHL_STEAM_API_KEY_EMPTY", PLUGIN_ACRONYM);
    } else {
        formatex(url, charsmax(url), STEAM_API_URL, steamAPIKey, steam64ID);
        
        new CURL:curl = curl_easy_init();

        if (!curl) {
            server_print("%L", LANG_SERVER, "LLHL_CURL_INIT_ERROR");
            log_amx("%L", LANG_SERVER, "LLHL_CURL_INIT_ERROR");
        }

        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0);
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0);
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_helper_set_write_options(curl);

        new buffer[32];
        formatex(buffer, charsmax(buffer), "%i", id);
        
        curl_easy_perform(curl, "GetFamilySharingStatus", buffer, charsmax(buffer));
    }
}

public GetLatestVersion(CURL:curl, CURLcode:code) {
    curl_easy_cleanup(curl);

    if (code == CURLE_OK) {
        new response[INCOMING_BUFFER_LENGTH], JSON:json;
        curl_helper_get_response(curl, response, charsmax(response));
        
        json = json_parse(response);

        if (json == Invalid_JSON) {
            server_print("%L", LANG_SERVER, "LLHL_CHECK_GH_PARSE_ERROR", PLUGIN_ACRONYM);
            RetryConnection();
            return;
        }

        new repoLatestVersion[32];
        new JSON:responseValue = json_array_get_value(json, 0);
        json_object_get_string(responseValue, "name", repoLatestVersion, charsmax(repoLatestVersion));

        new ret, error[128];
        new pluginVersion[32];
        new Regex:regex_handle;

        regex_handle = regex_match(repoLatestVersion, "^^((0|[1-9]\d*)(\.(0|[1-9]\d*)){0,9})((-stable))*$", ret, error, charsmax(error));

        if (regex_handle > REGEX_NO_MATCH) {
            regex_substr(regex_handle, 1, gRepoVersion, charsmax(gRepoVersion));
        }
        regex_free(regex_handle);

        regex_handle = regex_match(VERSION, "^^((0|[1-9]\d*)(\.(0|[1-9]\d*)){0,9})((-stable))*$", ret, error, charsmax(error));

        if (regex_handle > REGEX_NO_MATCH) {
            regex_substr(regex_handle, 1, pluginVersion, charsmax(pluginVersion));
        }
        regex_free(regex_handle);

        // Check for updates
        switch (CompareVersion(pluginVersion, gRepoVersion)) {
            case 0: {
                gIsOutdated = false;
                server_print("%L", LANG_SERVER, "LLHL_CHECK_GH_NO_UPDATE", PLUGIN_ACRONYM);
            }
            case 1: {
                gIsOutdated = false;
                server_print("%L", LANG_SERVER, "LLHL_CHECK_GH_HIGHER_VER", PLUGIN_ACRONYM);
            }
            case -1: {
                gIsOutdated = true;
                server_print("%L", LANG_SERVER, "LLHL_CHECK_GH_NEW_UPDATE", PLUGIN_ACRONYM);
                log_amx("%L", LANG_SERVER, "LLHL_CHECK_GH_NEW_UPDATE", PLUGIN_ACRONYM);
            }
        }
    } else {
        server_print("%L", LANG_SERVER, "LLHL_CHECK_GH_FAILED", PLUGIN_ACRONYM);
        RetryConnection();
        return;
    }
}

public GetFamilySharingStatus(CURL:curl, CURLcode:code, data[]) {
    curl_easy_cleanup(curl);
    
    if (code == CURLE_OK) {
        new response[INCOMING_BUFFER_LENGTH];

        new id = str_to_num(data);
        curl_helper_get_response(curl, response, charsmax(response));
        
        new const toSearch[] = "^"game_count^":";
        new position = containi(response, toSearch);

        new name[64], authID[32];
        get_user_name(id, name, charsmax(name));
        get_user_authid(id, authID, charsmax(authID));
        
        if (position == -1) {
            log_amx("%L", LANG_SERVER, "LLHL_CHECK_FS_NOTICE_2", PLUGIN_ACRONYM, name, authID);
            server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "LLHL_CHECK_FS_KICK_2");
        } else if (response[position + charsmax(toSearch)] == '0') {
            log_amx("%L", LANG_SERVER, "LLHL_CHECK_FS_NOTICE_1", PLUGIN_ACRONYM, name, authID);
            server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "LLHL_CHECK_FS_KICK_1");
        }
    } else {
        server_print("%L", LANG_SERVER, "LLHL_CURL_CODE_ERROR", PLUGIN_ACRONYM, code);
        log_amx("%L", LANG_SERVER, "LLHL_CURL_CODE_ERROR", PLUGIN_ACRONYM, code);
    }
}

public RetryConnection() {
    gCheckUpdatesNumRetrys++;
    if (gCheckUpdatesNumRetrys <= get_pcvar_num(gCvarCheckUpdatesRetrys)) {
        server_print("%L", LANG_SERVER, "LLHL_CHECK_GH_RETRYING", PLUGIN_ACRONYM, get_pcvar_float(gCvarCheckUpdatesRetryDelay), gCheckUpdatesNumRetrys, get_pcvar_num(gCvarCheckUpdatesRetrys));
        set_task(get_pcvar_float(gCvarCheckUpdatesRetryDelay), "ConnectGithubAPI");
    }
}

/* 
 * Compare two versions
 * 
 * @return      Returns -1 if the first value is less than the second value.
 *              Returns 1 if the first value is greater than the second value.
 *              Returns 0 if the first value is equal to the second value.
 * 
 */
stock CompareVersion(value1[], value2[]) {
    static outputValue1[VERSION_ARRAY_SIZE][128], outputValue2[VERSION_ARRAY_SIZE][128];

    SplitString(outputValue1, sizeof(outputValue1), charsmax(outputValue1), value1, '.');
    SplitString(outputValue2, sizeof(outputValue2), charsmax(outputValue2), value2, '.');
    
    for (new i = 0; i < VERSION_ARRAY_SIZE; i++) {
        new val1 = i < sizeof(outputValue1) ? str_to_num(outputValue1[i]) : 0;
        new val2 = i < sizeof(outputValue2) ? str_to_num(outputValue2[i]) : 0;
        
        if (val1 < val2) {
            return -1;
        }
        if (val1 > val2) {
            return 1;
        }
    }
    return 0;
}

stock SplitString(output[][], nMax, nSize, input[], delimiter) {
    new nIdx = 0, l = strlen(input);
    new nLen = (1 + copyc(output[nIdx], nSize, input, delimiter));
    while((nLen < l) && (++nIdx < nMax))
        nLen += (1 + copyc(output[nIdx], nSize, input[nLen], delimiter));
    return nIdx;
}

public IsCheatCommand(value[]) {
    for (new i = 0; i < sizeof(gCheatsCommands); i++) {
        if (equali(value, gCheatsCommands[i])) {
            return true;
        }
    }
    return false;
}

public LoadSpawns() {
    new entity = get_maxplayers(), Float:tempVector[3];
    while ((entity = find_ent_by_class(entity, "info_player_deathmatch"))) {
        entity_get_vector(entity, EV_VEC_origin, tempVector);
        ArrayPushArray(gSpawnOrigins, tempVector);

        entity_get_vector(entity, EV_VEC_angles, tempVector);
        ArrayPushArray(gSpawnAngles, tempVector);

        gSpawnsCounter++;
    }
}

public MatchManagerMenu(id, level, cid) {
    if (cmd_access(id, level, cid, 1)) {
        DisplayMatchManagerMenu(id);
    }

    return PLUGIN_HANDLED;
}

public DisplayMatchManagerMenu(id) {
    if (!gMMMenuOwner || id == gMMMenuOwner) {
        gMMMenuOwner = id;

        new multilangString[64];

        formatex(multilangString, charsmax(multilangString), "%L", LANG_PLAYER, "LLHL_MM_MENU_MAIN_TITLE");
        new managerMenu = menu_create(multilangString, "MatchManagerHandler");

        new versusType[8];
        if (!gMMVersusType[0]) {
            versusType = "N/A";
        } else {
            formatex(versusType, charsmax(versusType), "%svs%s", gMMVersusType, gMMVersusType);
        }
        formatex(multilangString, charsmax(multilangString), "%L", LANG_PLAYER, "LLHL_MM_ITEM_MAIN_2", versusType);
        menu_additem(managerMenu, multilangString, "", ADMIN_BAN);

        formatex(multilangString, charsmax(multilangString), "%L", LANG_PLAYER, "LLHL_MM_ITEM_MAIN_3", GetPlayersNumInTeam(MM_BLUE_TEAM), GetPlayersNumInTeam(MM_RED_TEAM));
        menu_additem(managerMenu, multilangString, "", ADMIN_BAN);

        formatex(multilangString, charsmax(multilangString), "%L", LANG_PLAYER, "LLHL_MM_ITEM_MAIN_4");
        menu_additem(managerMenu, multilangString, "", ADMIN_BAN);

        menu_display(id, managerMenu, 0);
    } else {
        client_print(id, print_chat, "%l", "LLHL_MM_MENU_IN_USE");
    }
}

public MatchManagerHandler(id, menu, item) {
    menu_destroy(menu);
    switch (item) {
        case 0: {
            MatchManagerVersusTypeMenu(id);
            return PLUGIN_HANDLED;
        }
        case 1: {
            MatchManagerAssignPlayersMenu(id);
            return PLUGIN_HANDLED;
        }
        case 2: {
            MatchManagerStartMatch(id);
            return PLUGIN_HANDLED;
        }
    }
    CleanMenuData();
    return PLUGIN_HANDLED;
}

public MatchManagerVersusTypeMenu(id) {
    new multilangString[64];

    formatex(multilangString, charsmax(multilangString), "%L", LANG_PLAYER, "LLHL_MM_OPT_2_TITLE");
    new versusMenu = menu_create(multilangString, "MatchManagerVersusTypeHandler");

    new menuDescription[8];
    new typeString[2];
    for (new i = 1; i <= 6; i++) {
        formatex(menuDescription, charsmax(menuDescription), "%ivs%i", i, i);
        formatex(typeString, charsmax(typeString), "%i", i);
        menu_additem(versusMenu, menuDescription, typeString, ADMIN_BAN);
    }
    
    menu_display(id, versusMenu, 0);
}

public MatchManagerVersusTypeHandler(id, menu, item) {
    if (item >= 0 && item <= 5) {
        new data[6], name[64];
        new access, itemCallback;

        menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), itemCallback);
        copy(gMMVersusType, charsmax(gMMVersusType), data);
    }

    menu_destroy(menu);
    DisplayMatchManagerMenu(id);

    return PLUGIN_HANDLED;
}

public MatchManagerAssignPlayersMenu(id) {
    new multilangString[64];

    formatex(multilangString, charsmax(multilangString), "%L", LANG_PLAYER, "LLHL_MM_OPT_3_TITLE");
    new playersMenu = menu_create(multilangString, "MatchManagerAssignPlayersHandler");

    new TrieIter:iterator = TrieIterCreate(gMMUserIDPlayers); {
        new key[32];
        new value[8], valueLength;

        new target;
        new username[MAX_NAME_LENGTH + 1];

        new menuDescription[128];

        while (!TrieIterEnded(iterator)) {
            TrieIterGetKey(iterator, key, charsmax(key));
            TrieIterGetString(iterator, value, charsmax(value), valueLength);

            if ((target = find_player("k", str_to_num(key)))) {
                get_user_name(target, username, charsmax(username));
                formatex(menuDescription, charsmax(menuDescription), "%s [%s]", username, value);
                menu_additem(playersMenu, menuDescription, key, ADMIN_BAN);
            }
            TrieIterNext(iterator);
        }
    }
    TrieIterDestroy(iterator);

    menu_display(id, playersMenu, 0);
}

public MatchManagerAssignPlayersHandler(id, menu, item) {
    if (item == MENU_EXIT) {
        menu_destroy(menu);
        DisplayMatchManagerMenu(id);
        return PLUGIN_HANDLED;
	}

    new data[6], name[64];
    new access, itemCallback;
    
    menu_item_getinfo(menu, item, access, data, charsmax(data), name, charsmax(name), itemCallback);

    new team[8];
    TrieGetString(gMMUserIDPlayers, data, team, charsmax(team));

    if (equali(team, MM_NO_TEAM)) {
        TrieSetString(gMMUserIDPlayers, data, MM_BLUE_TEAM);
    } else if (equali(team, MM_BLUE_TEAM)) {
        TrieSetString(gMMUserIDPlayers, data, MM_RED_TEAM);
    } else if (equali(team, MM_RED_TEAM)) {
        TrieSetString(gMMUserIDPlayers, data, MM_NO_TEAM);
    }

    menu_destroy(menu);
    MatchManagerAssignPlayersMenu(id);
    return PLUGIN_HANDLED;
}

public MatchManagerStartMatch(id) {
    if (!gMMVersusType[0]) {
        client_print(id, print_chat, "%l", "LLHL_MM_NO_MATCH_TYPE");
        DisplayMatchManagerMenu(id);
    } else if (gGameState == GAME_STARTING) {
        client_print(id, print_chat, "%l", "LLHL_MM_MATCH_STARTING");
        DisplayMatchManagerMenu(id);
    } else {
        if (GetPlayersNumInTeam(MM_BLUE_TEAM) == str_to_num(gMMVersusType) && GetPlayersNumInTeam(MM_RED_TEAM) == str_to_num(gMMVersusType)) {
            new TrieIter:iterator = TrieIterCreate(gMMUserIDPlayers); {
                new key[32];
                new value[8], valueLength;
                
                new target;
                while (!TrieIterEnded(iterator)) {
                    TrieIterGetKey(iterator, key, charsmax(key));
                    if ((target = find_player("k", str_to_num(key)))) {
                        TrieIterGetString(iterator, value, charsmax(value), valueLength);
                        if (!equali(value, MM_NO_TEAM)) {
                            strtolower(value);
                            client_cmd(target, "model %s", value);
                        } else {
                            if (!hl_get_user_spectator(id)) {
                                client_cmd(target, "spectate");
                            }
                        }
                    }
                    TrieIterNext(iterator);
                }
            }
            CleanMenuData();
            server_cmd("agstart");
            
            TrieIterDestroy(iterator);
        } else {
            client_print(id, print_chat, "%l", "LLHL_MM_INVALID_PLAYER_COUNT");
            DisplayMatchManagerMenu(id);
        }
    }
}

public GetPlayersNumInTeam(team[]) {
    new counter;
    new TrieIter:iterator = TrieIterCreate(gMMUserIDPlayers); {
        new value[8], valueLength;

        while (!TrieIterEnded(iterator)) {
            TrieIterGetString(iterator, value, charsmax(value), valueLength);
            if (equali(value, team)) {
                counter++;
            }
            TrieIterNext(iterator);
        }
    }
    TrieIterDestroy(iterator);
    return counter;
}

public CleanMenuData() {
    new TrieIter:iterator = TrieIterCreate(gMMUserIDPlayers); {
        new key[32];
        while (!TrieIterEnded(iterator)) {
            TrieIterGetKey(iterator, key, charsmax(key));
            TrieSetString(gMMUserIDPlayers, key, MM_NO_TEAM);
            TrieIterNext(iterator);
        }
    }
    TrieIterDestroy(iterator);

    gMMMenuOwner = 0;
    gMMVersusType = "";
}