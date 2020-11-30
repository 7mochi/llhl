/*
    LLHL Gamemode for AG 6.6 and AGMini
    Version: 1.0.1-stable
    Author: FlyingCat

    # Information:
    This plugin is a port for Adrenaline Gamer 6.6 (And AGMini) from my LLHL gamemode that 
    was developed for rtxa's agmodx.
    Unlike my gamemode that I made for agmodx, this one only supports protocol 48

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
    - Force connected HLTV to have a certain delay value as a minimum (Minimum value is 30)
    - Wallhack Blocker
    - Ghostmine Blocker
    - Simple OpenGF32 and AGFix detection (Through cheat commands)
    - Take screenshots at map end and occasionally when a player dies
    - Avoid abusing a ReHLDS bug (Server disappears from the masterlist when it's' paused) only when there's no game in progress.

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

    # Thanks to:
    - Th3-822: FPS Limiter and blocking name and model changes
    - Alka: Server FPS
    - Arkshine: Unstuck command
    - naz: Useful codes for hook messages from AG engine
    - BulliT: For developing AG Mod and sharing the source code

    Contact: alonso.caychop@tutamail.com or Suisei#9999 (Discord)
*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hlstocks>

#define PLUGIN          "Liga Latinoamericana de Half Life"
#define PLUGIN_ACRONYM  "LHLL"
#define PLUGIN_GAMEMODE "llhl"
#define VERSION         "1.0.1-stable"
#define AUTHOR          "FlyingCat"

#pragma semicolon 1

#define GetPlayerHullSize(%1)  ((pev(%1, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN)
#define __is_user_alive(%1) (gIsAlive[%1])

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

enum (+=103) {
    TASK_CVARCHECKER = 72958,
    TASK_SHOWVENGINE,
    TASK_OPENGFCHECKER,
    TASK_AGFIXCHECKER
};

new gGameState;
new gGhostMineBlockState;
new bool:gIsAlive[MAX_PLAYERS + 1];
new gNumDetections[MAX_PLAYERS + 1];
new gOldPlayerModel[MAX_PLAYERS + 1][32];
new gDeathScreenshotTaken[MAX_PLAYERS + 1];

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
new gCvarMinHLTVDelay;
new gCvarBlockGhostmine;
new gCvarCheatCmdCheckInterval;
new gCvarCheatCmdMaxDetections;

new bool:gFirstCheatValidation[MAX_PLAYERS + 1];
new bool:gSecondCheatValidation[MAX_PLAYERS + 1];
new gCheatNumDetections[MAX_PLAYERS + 1];

new Float:gUnstuckLastUsed[MAX_PLAYERS + 1];
new Float:gServerFPS;
static Float:gActualServerFPS;

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

public plugin_init() {
    server_print("[%s] Initializing plugin", PLUGIN_ACRONYM);
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
        server_print("[%s] The '%s' plugin can only be run in the '%s' gamemode on AG 6.6 or its Mini version for HL", PLUGIN_ACRONYM, PLUGIN, PLUGIN_GAMEMODE);
        // If GhostMineBlock is loaded and the gamemode isn't LLHL, it'll be deactivated
        if (gGhostMineBlockState == GMB_LOADED) {
            gGhostMineBlockState = GMB_BLOCKED;
            set_cvar_num("gm_block_on", 0);
            server_print("[%s] GhostMine blocker has been deactivated", PLUGIN_ACRONYM);
        }
        pause("ad");
        return;
    }

    // Only ReHLDS
    if (cvar_exists("sv_rcon_condebug")) {
        register_concmd("agpause", "CmdAgpauseRehldsHook");
        server_print("[%s] ReHLDS detected, pauses will be blocked when there are no games in progress to avoid abusing a bug.", PLUGIN_ACRONYM);
    }
    
    register_dictionary("llhl.txt");

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
    
    // Minimum Delay Value (HLTV)
    gCvarMinHLTVDelay = create_cvar("sv_ag_min_hltv_delay", "30.0");

    // Simple OpenGF32 and AGFix Detection
    gCvarCheatCmdCheckInterval = create_cvar("sv_ag_cheat_cmd_check_interval", "5.0");
    gCvarCheatCmdMaxDetections = create_cvar("sv_ag_cheat_cmd_max_detections", "5");

    gGameState = GAME_IDLE;

    if (gGhostMineBlockState == GMB_LOADED) {
        gCvarBlockGhostmine = create_cvar("sv_ag_block_ghostmine", "1");
    }

    // Just to be sure that the values haven't been replaced when creating the cvars
    server_cmd("exec gamemodes/%s.cfg", PLUGIN_GAMEMODE);
    server_exec();

    if (cvar_exists("sv_ag_block_ghostmine")) {
        // Reload GhostMineBlock original cvar
        set_cvar_num("gm_block_on", get_pcvar_num(gCvarBlockGhostmine));
        hook_cvar_change(gCvarBlockGhostmine, "CvarGhostMineHook");
        hook_cvar_change(get_cvar_pointer("gm_block_on"), "MetaCvarGhostMineHook");
    }

    register_clcmd("say /unstuck", "CmdUnstuck");
    
    RegisterHam(Ham_Spawn, "player", "HamPlayerSpawnPre", 0);
    RegisterHam(Ham_Spawn, "player", "HamPlayerSpawnPost", 1);
    RegisterHam(Ham_Killed, "player", "HamPlayerKilledPost", 1);
    
    // AG Messages
    register_message(get_user_msgid("Countdown"), "FwMsgCountdown");
    register_message(get_user_msgid("Settings"), "FwMsgSettings");
    register_message(get_user_msgid("Vote"), "FwMsgVote");

    register_message(SVC_INTERMISSION, "FwMsgIntermission");

    register_event("DeathMsg", "EventDeathMsg", "ad");

    register_forward(FM_SetModel, "FwSetModel");
    register_forward(FM_ClientUserInfoChanged, "FwClientUserInfoChangedPre", 0);
    register_forward(FM_StartFrame, "FwStartFrame");
    
    for (new i; i < sizeof gConsistencySoundFiles; i++) {
        force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, gConsistencySoundFiles[i]);
    }

    set_task(floatmax(1.0, get_pcvar_float(gCvarCheckInterval)), "CvarCheckRun");

    // Start by executing OpenGF32 commands
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheatCmdCheckInterval)), "OpenGFCommandRun", TASK_OPENGFCHECKER);

    hook_cvar_change(gCvarCheatCmdCheckInterval, "CvarCheatCmdIntervalHook");
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

public client_connect(id) {
    gIsAlive[id] = false;
    gNumDetections[id] = 0;
    gOldPlayerModel[id][0] = 0;
    gCheatNumDetections[id] = 0;
    gFirstCheatValidation[id] = false;
    gSecondCheatValidation[id] = false;
}

public client_disconnected(id) {
    gIsAlive[id] = false;
}

public client_command(id) {
    new command[64];
    read_argv(0, command, charsmax(command));
    if (equali(command, "preCheck")) {
        gFirstCheatValidation[id] = true;
        gSecondCheatValidation[id] = false;
        return PLUGIN_HANDLED;
    } else if (equali(command, "bhop") || (equali(command, "agfix_bh"))) {
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
            log_to_file(fileName, "[%s - Simple Cheat Detector] %s (%s) has been detected a possible use of OpenGF32/AGFix. Remaining attemps: %i/%i", PLUGIN_ACRONYM, name, authID, gCheatNumDetections[id], get_pcvar_num(gCvarCheatCmdMaxDetections));

            if (gCheatNumDetections[id] >= get_pcvar_num(gCvarCheatCmdMaxDetections)) {
                log_to_file(fileName, "[%s - Simple Cheat Detector] %s (%s) has been detected OpenGF32/AGFix after %i attempts", PLUGIN_ACRONYM, name, authID, gCheatNumDetections[id]);
                gCheatNumDetections[id] = 0;
            }
        }
        return PLUGIN_HANDLED;
    }
    return PLUGIN_CONTINUE;
}

public HamPlayerSpawnPre(id) {
    gIsAlive[id] = false;
    return HAM_IGNORED;
}

public HamPlayerSpawnPost(id) {
    gIsAlive[id] = bool:is_user_alive(id);
    return HAM_IGNORED;
}

public HamPlayerKilledPost(id) {
    gIsAlive[id] = false;
    return HAM_IGNORED;
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
    gActualServerFPS = gServerFPS;
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
    show_dhudmessage(0, "LLHL Mode vEngine^n----------------------^nServer fps: %.1f^nGhostmine Blocker: %s", gActualServerFPS, !cvar_exists("sv_ag_block_ghostmine") ? "Not available" : get_pcvar_num(gCvarBlockGhostmine) ? "On" : "Off");
    client_cmd(0, "wait;wait;snapshot");
}

public EventDeathMsg() {
    new id = read_data(2);
    if (!gDeathScreenshotTaken[id] && random_num(63, 72) == 69) {
        if (gGameState == GAME_RUNNING) {
            TakeDeathScreenshot(id);
            gDeathScreenshotTaken[id] = 1;
        }
    }
}

public TakeDeathScreenshot(id) {
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

public OpenGFCommandRun() {
    client_cmd(0, "preCheck;bhop off;postCheck");
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheatCmdCheckInterval)), "AGFixCommandRun", TASK_AGFIXCHECKER);
}

public AGFixCommandRun() {
    client_cmd(0, "preCheck;agfix_bh;postCheck");
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheatCmdCheckInterval)), "OpenGFCommandRun", TASK_OPENGFCHECKER);
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
    if ((cvarRunning || (cvarRunning = get_cvar_pointer("sv_ag_match_running"))) && get_pcvar_num(cvarRunning) && gGameState == GAME_RUNNING && is_user_connected(id) && hl_get_user_spectator(id)) {
        new changed, oldValue[32], newValue[32];
        if (get_pcvar_num(gCvarBlockNameChangeInMatch) && pev(id, pev_netname, oldValue, charsmax(oldValue)) && engfunc(EngFunc_InfoKeyValue, info, "name", newValue, charsmax(newValue)) && !equal(oldValue, newValue)) {
            engfunc(EngFunc_SetClientKeyValue, id, info, "name", oldValue);
            client_print(id, print_chat, "%l", "BLOCK_NAMECHANGE_MSG");
            changed = true;
        }

        if (get_pcvar_num(gCvarBlockModelChangeInMatch) && copy(oldValue, charsmax(oldValue), gOldPlayerModel[id]) && engfunc(EngFunc_InfoKeyValue, info, "model", newValue, charsmax(newValue))) {
            if (!equal(oldValue, newValue)) {
                engfunc(EngFunc_SetClientKeyValue, id, info, "model", oldValue);
                client_print(id, print_chat, "%l", "BLOCK_MODELCHANGE_MSG");
                changed = true;
            }
        } else {
            engfunc(EngFunc_InfoKeyValue, info, "model", gOldPlayerModel[id], charsmax(gOldPlayerModel[]));
        }

        if (changed){
            return FMRES_HANDLED;
        }
    } else {
        engfunc(EngFunc_InfoKeyValue, info, "model", gOldPlayerModel[id], charsmax(gOldPlayerModel[]));
    }
    return FMRES_IGNORED;
}

public FwStartFrame() {
    static Float:gametime, Float:framesPer = 0.0;
    static Float:tempFps;
    
    gametime = get_gametime();
    
    if(framesPer >= gametime) {
        tempFps += 1.0;
    } else {
        framesPer = framesPer + 1.0;
        gServerFPS = tempFps;
        tempFps = 0.0;
    }
}

public CmdAgpauseRehldsHook(id) {
    if (get_playersnum() == 1 && gGameState == GAME_IDLE) {
        new name[32], authID[32], formatted[32], fileName[32];
        new timestamp = get_systime();
        format_time(formatted, charsmax(formatted), "%d%m%Y", timestamp);
        formatex(fileName, charsmax(fileName), "llhl_detections_%s.log", formatted);
        get_user_name(id, name, charsmax(name));
        get_user_authid(id, authID, charsmax(authID));
        log_to_file(fileName, "[%s] %s (%s) tried to pause the server when no one else was around. Possible ReHLDS Bug Exploit", PLUGIN_ACRONYM, name, authID);
        return FMRES_SUPERCEDE;
    }
    return FMRES_IGNORED;
}

public CvarGhostMineHook(pcvar, const old_value[], const new_value[]) {
    set_cvar_string("gm_block_on", new_value);
}

public MetaCvarGhostMineHook(pcvar, const old_value[], const new_value[]) {
    set_pcvar_string(gCvarBlockGhostmine, new_value);
}

public CvarCheatCmdIntervalHook(pcvar, const old_value[], const new_value[]) {
    remove_task(TASK_OPENGFCHECKER);
    remove_task(TASK_AGFIXCHECKER);
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheatCmdCheckInterval)), "OpenGFCommandRun", TASK_OPENGFCHECKER);
}