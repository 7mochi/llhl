# ![LLHL Banner](https://raw.githubusercontent.com/FlyingCat-X/llhl/master/LLHL_logo.png)
### [English Version](https://github.com/FlyingCat-X/llhl/blob/master/README.md) | [Spanish Version](https://github.com/FlyingCat-X/llhl/blob/master/README_ES.md) | [Portuguese Version](https://github.com/FlyingCat-X/llhl/blob/master/README_PT.md) | Chinese Version (Pending)
This plugin is a port for Adrenaline Gamer 6.6 from my [LLHL gamemode](https://github.com/rtxa/agmodx/blob/master/valve/addons/amxmodx/scripting/agmodx_llhl.sma) that was developed for rtxa's agmodx.
Unlike my gamemode for agmodx, this one only supports Protocol 48.

# Important notes
If you have any problem in your server, before opening an issue or contacting me by any means (Facebook, Whatsapp, Discord, etc.) make sure that the error is related to the LLHL plugin. If you have any problem associated to the plugin try to be as detailed as possible and provide me with logs and ways to get to the error. I won’t give you support if the problem is related to other plugins e.g. dproto or reunion.

## Features
- FPS Limiter (Default value is 144, switchable from 144 to 240 and vice versa, you can toggle between them with the fpslimitmode vote)
- FOV Limiter (Default value is 85, enabled by default).
- Records a demo automatically when a match is started (With agstart).
- /unstuck command (10 seconds cooldown).
- Check certain sound files, they're the same sounds that are verified in the EHLL gamemode - AG6.6.
- Block nickname and model changes when a game is in progress (Optional, both enabled by default).
- New intermission mode.
- More than 1 HLTV allowed.
- Force connected HLTV to have a certain delay value as a minimum (Minimum value is 30).
- Nuke blocking capabilities (Lampgauss, ghostmine, rocket, etc)
- Simple OpenGF32 and AGFix detection (Through cheat commands. Optional, enabled by default).
- Take screenshots at map end and occasionally when a player dies.
- Changing model during a match subtract 1 from the score. (Optional, enabled by default).
- Block access to players who have the game via Family Sharing. (Optional, disabled by default).
- Random spawns (Optional, disabled by default).
- Blocks location/HP/Weapon/etc messages for spectators.
- Block spectators from voting (Optional, enabled by default).
- Respawn time are now FPS-independent.
- Fixes bodies frozen in the air when using high fps.
- Check for new updates and it will notify you in the server console.
- llhl_match_manager command (For administrators only).

## New cvars
- sv_ag_fps_limit_warnings "2"
- sv_ag_fps_limit_check_interval "5.0"
- sv_ag_fov_min_enabled "1"
- sv_ag_fov_min_check_interval "1.5"
- sv_ag_fov_min "85"
- sv_ag_respawn_delay "0.75"
- sv_ag_unstuck_cooldown "10.0"
- sv_ag_unstuck_start_distance "32"
- sv_ag_unstuck_max_attempts "64"
- sv_ag_block_namechange_inmatch "1"
- sv_ag_block_modelchange_inmatch "1"
- sv_ag_min_hltv_delay "30.0"
- sv_ag_nuke_grenade "0"
- sv_ag_nuke_crossbow "0"
- sv_ag_nuke_rpg "0"
- sv_ag_nuke_gauss "1"
- sv_ag_nuke_egon "0"
- sv_ag_nuke_tripmine "0"
- sv_ag_nuke_satchel "0"
- sv_ag_nuke_snark "0"
- sv_ag_explosion_fix "0"
- sv_ag_cheat_cmd_check "1"
- sv_ag_cheat_cmd_check_interval "5.0"
- sv_ag_cheat_cmd_max_detections "5"
- sv_ag_change_model_penalization "1"
- sv_ag_block_family_sharing "0"
- sv_ag_random_spawns "0"
- sv_ag_block_cmd_enhancements "1"
- sv_ag_block_vote_spectators "1"
- sv_ag_steam_api_key ""
- sv_ag_check_updates "1"
- sv_ag_check_updates_retrys "3"
- sv_ag_check_updates_retry_delay "2.0"
- sv_ag_autoupdate "1"
- sv_ag_autoupdate_dl_max_retries "3"
- sv_ag_autoupdate_dl_retry_delay "3"

## Requirements
- Pre-anniversary edition of HLDS (Build 8684) or latest [ReHLDS](https://github.com/dreamstalker/rehlds/releases) installed. 25th Anniversary compatibility hasn't been tested.
- A base installation of [AGMOD](https://openag.pro/latest/ag.7z).
- Metamod 1.21.37p or newer, I recommend using [this version of metamod](https://github.com/theAsmodai/metamod-r/releases/tag/1.3.0.149)
- Have [AMXX 1.9](https://www.amxmodx.org/downloads-new.php) installed or newer.
- AMXX Module: [Curl](https://forums.alliedmods.net/showthread.php?t=285656).

## Download
- Full releases: Besides containing everything necessary for the proper functioning of the LLHL gamemode, it has new maps with their respective dependencies (Locs, wads, sprites, sounds, etc).
- Lite releases: Only contain what is necessary for the correct functioning of the LLHL gamemode. (Metamod, AMXX and the custom AGMOD for LLHL)

Download the [Latest Release](https://github.com/FlyingCat-X/llhl/releases/).

## Installation (The easy way)
- Have a clean installation of Half Life with Adrenaline Gamer ready.
- Download any of the latest releases (Full or lite).
- Extract it within your server installation (Outside ag folder) and accept to replace the files if you are asked.
- Turn your server on and enjoy.

## Thanks to
- Th3-822: FPS Limiter, Server FPS and blocking name and model changes.
- Arkshine: Unstuck command.
- naz: Useful codes for hook messages from AG engine.
- BulliT: For developing AG Mod and sharing the source code.
- Dcarlox: Grammar corrections and Spanish translation.
- leynieR: Portuguese Translation.
- xeroblood: SplitString() method.