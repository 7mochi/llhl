/*
    LLHL Gamemode for AG 6.6 and AGMini
    Version: 1.0-beta
    Date: 31/10/20
    Author: FlyingCat

    # Information:
    This plugin is a port for Adrenaline Gamer 6.6 (And AGMini) from my LLHL gamemode that 
    was developed for rtxa's agmodx.
    Unlike my gamemode that I made for agmodx, this one only supports protocol 48

    # Features:
    - FPS Limiter (Default value is 144)
    - Records a demo automatically when a match is started (With agstart)
    - /unstuck command (10 seconds cooldown)
    - Check certain sound files, they're the same sounds that are verified in the 
    EHLL gamemode - AG6.6
    - Be able to destroy other players satchels (Optional, disabled by default)
    - Block nickname changes when a game is in progress (Optional, enabled by default)
    - New intermission mode

    # New cvars:
    - sv_ag_fpslimit_max_fps "144"
    - sv_ag_fpslimit_max_detections "2"
    - sv_ag_fpslimit_check_interval "1.5"
    - sv_ag_unstuck_cooldown "10.0"
    - sv_ag_unstuck_start_distance "32"
    - sv_ag_unstuck_max_attempts "64"
    - sv_ag_destroyable_satchel "0"
    - sv_ag_destroyable_satchel_hp "1"
    - sv_ag_block_namechange_inmatch "1"

    # Thanks to:
    - Th3-822: FPS Limiter
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
#define VERSION         "1.0-beta"
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

enum (+=103) {
    TASK_FPSLIMITER = 72958,
    TASK_SHOWVENGINE
};

new gGameState;
new bool:gIsAlive[MAX_PLAYERS + 1];
new gNumDetections[MAX_PLAYERS + 1];

// Cvars pointers
new gCvarAgStartMinPlayers;
new gCvarMaxFps;
new gCvarMaxDetections;
new gCvarCheckInterval;
new gCvarUnstuckCooldown;
new gCvarUnstuckStartDistance;
new gCvarUnstuckMaxSearchAttempts;
new gCvarDestroyableSatchel;
new gCvarDestroyableSatchelHP;
new gCvarBlockNameChangeInMatch;

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

    if (!equali(gamemode, PLUGIN_GAMEMODE)) {
        server_print("[%s] The '%s' plugin can only be run in the '%s' gamemode on AG 6.6 or its Mini version for HL", PLUGIN_ACRONYM, PLUGIN, PLUGIN_GAMEMODE);
        pause("ad");
        return;
    }
    
    register_dictionary("llhl.txt");

    gCvarAgStartMinPlayers = get_cvar_pointer("sv_ag_start_minplayers");

    // FPS Limiter
    gCvarMaxFps = create_cvar("sv_ag_fpslimit_max_fps", "144");
    gCvarMaxDetections = create_cvar("sv_ag_fpslimit_max_detections", "2");
    gCvarCheckInterval = create_cvar("sv_ag_fpslimit_check_interval", "1.5");
    // Unstuck command
    gCvarUnstuckCooldown = create_cvar("sv_ag_unstuck_cooldown", "10.0");
    gCvarUnstuckStartDistance = create_cvar("sv_ag_unstuck_start_distance", "32");
    gCvarUnstuckMaxSearchAttempts = create_cvar("sv_ag_unstuck_max_attempts", "64");
    // Destroyable Satchel
    gCvarDestroyableSatchel =  create_cvar("sv_ag_destroyable_satchel", "0");
    gCvarDestroyableSatchelHP = create_cvar("sv_ag_destroyable_satchel_hp", "1");
    // Block name change (Only spectators) log in match
    gCvarBlockNameChangeInMatch = create_cvar("sv_ag_block_namechange_inmatch", "1");

    gGameState = GAME_IDLE;

    // Just to be sure that the values haven't been replaced when creating the cvars
    server_cmd("exec gamemodes/%s.cfg", PLUGIN_GAMEMODE);
    server_exec();

    register_clcmd("say /unstuck", "CmdUnstuck");
    
    RegisterHam(Ham_Spawn, "player", "HamPlayerSpawnPre", 0);
    RegisterHam(Ham_Spawn, "player", "HamPlayerSpawnPost", 1);
    RegisterHam(Ham_Killed, "player", "HamPlayerKilledPost", 1);
    
    // AG Messages
    register_message(get_user_msgid("Countdown"), "FwMsgCountdown");
    register_message(get_user_msgid("Settings"), "FwMsgSettings");
    register_message(get_user_msgid("Vote"), "FwMsgVote");

    register_message(SVC_INTERMISSION, "FwMsgIntermission");

    register_forward(FM_SetModel, "FwSetModel");
    register_forward(FM_ClientUserInfoChanged, "FwClientUserInfoChanged");
    register_forward(FM_StartFrame, "FwStartFrame");
    
    for (new i; i < sizeof gConsistencySoundFiles; i++) {
        force_unmodified(force_exactfile, {0,0,0}, {0,0,0}, gConsistencySoundFiles[i]);
    }

    set_task(floatmax(1.0, get_pcvar_float(gCvarCheckInterval)), "FpsCheckRun");
}

public inconsistent_file(id, const filename[], reason[64]) {
    new name[32], authid[32];
    get_user_name(id, name, charsmax(name));
    get_user_authid(id, authid, charsmax(authid));
    client_print(0, print_chat, "%L", LANG_PLAYER, "FILECONSISTENCY_MSG", name, authid, filename);
    server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "FILECONSISTENCY_KICK", filename);
    return PLUGIN_HANDLED;
}

public client_connect(id) {
    gIsAlive[id] = false;
    gNumDetections[id] = 0;
}

public client_disconnected(id) {
    gIsAlive[id] = false;
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
    client_cmd(0, "stop;wait;wait;+showscores;+showscores");
    set_task(0.1, "TaskPreIntermission", TASK_SHOWVENGINE, .flags = "b");
    message_begin(0, SVC_FINALE);
    write_string("");
    message_end();
    return PLUGIN_HANDLED;
}

public TaskPreIntermission() {
    // Show vEngine
    set_dhudmessage(0, 100, 200, -1.0, -0.125, 0, 0.0, 10.0, 0.2);
    show_dhudmessage(0, "LLHL Mode vEngine^n----------------------^nServer fps: %.1f", gActualServerFPS);
}

public CmdUnstuck(id) {
    new Float:cooldownTime = get_pcvar_float(gCvarUnstuckCooldown);
    new Float:elapsedTime = get_gametime() - gUnstuckLastUsed[id];

    if (elapsedTime < cooldownTime) {
        client_print(id, print_chat, "%L", id, "UNSTUCK_ON_COOLDOWN", cooldownTime - elapsedTime);
        return PLUGIN_HANDLED;
    }
    gUnstuckLastUsed[id] = get_gametime();
    new value;
    if ((value = UnStuckPlayer(id)) != 1) {
        switch (value) {
            case 0: client_print(id, print_chat, "%L", LANG_PLAYER, "UNSTUCK_FREESPOT_NOTFOUND");
            case -1: client_print(id, print_chat, "%L", LANG_PLAYER, "UNSTUCK_PLAYER_DEAD");
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

public FpsCheckRun() {
    static players[MAX_PLAYERS], pCount;
    get_players(players, pCount, "ch");
    for (new i = 0; i < pCount; i++) {
        if (!hl_get_user_spectator(players[i])) {
            query_client_cvar(players[i], "fps_max", "FpsCheckReturn");
        }
    }
    set_task(floatmax(1.0, get_pcvar_float(gCvarCheckInterval)), "FpsCheckRun", TASK_FPSLIMITER);
}

public FpsCheckReturn(id, const cvar[], const value[]) {
    if (equali(value, "Bad CVAR request")) {
        server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "FPSL_PROTECTOR_KICK");
    } else if (equali(cvar, "fps_max") && str_to_num(value) > max(100, get_pcvar_num(gCvarMaxFps))) {
        console_cmd(id, "^"FpS_MaX^" %d", max(100, get_pcvar_num(gCvarMaxFps)));
        if (++gNumDetections[id] < get_pcvar_num(gCvarMaxDetections)) {
            client_print(id, print_chat, "%L", id, "FPSL_WARNING_MSG", max(100, get_pcvar_num(gCvarMaxFps)));
        } else {
            static name[MAX_NAME_LENGTH];
            get_user_name(id, name, charsmax(name));
            server_cmd("kick #%d ^"%L^"", get_user_userid(id), id, "FPSL_KICK", get_pcvar_num(gCvarMaxFps));
            client_print(0, print_chat, "%L", LANG_PLAYER, "FPSL_KICK_MSG", name);
        }
    }
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

public FwClientUserInfoChanged(id) {
    static const name[] = "name";
    static oldName[32], newName[32], cvar;
    pev(id, pev_netname, oldName, charsmax(oldName));
    if (oldName[0]) {
        get_user_info(id, name, newName, charsmax(newName));
        if (get_pcvar_num(gCvarBlockNameChangeInMatch) && !equal(oldName, newName) && (cvar || (cvar = get_cvar_pointer("sv_ag_match_running"))) && get_pcvar_num(cvar) && gGameState == GAME_RUNNING && hl_get_user_spectator(id)) {
            set_user_info(id, name, oldName);
            client_print(id, print_chat, "%L", LANG_PLAYER, "BLOCK_NAMECHANGE_MSG");
            return FMRES_HANDLED;
        }
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