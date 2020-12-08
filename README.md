# LLHL 1.1-stable
### [English Version](https://github.com/FlyingCat-X/llhl/blob/master/README.md) | [Spanish Version](https://github.com/FlyingCat-X/llhl/blob/master/README_ES.md) | [Portuguese Version](https://github.com/FlyingCat-X/llhl/blob/master/README_PT.md)
This plugin is a port for Adrenaline Gamer 6.6 (And AGMini) from my [LLHL gamemode](https://github.com/rtxa/agmodx/blob/master/valve/addons/amxmodx/scripting/agmodx_llhl.sma) that was developed for rtxa's agmodx.
Unlike my gamemode for agmodx, this one only supports Protocol 48.

## Features
- FPS Limiter (Default value is 144).
- FOV Limiter (Minimum value is 85, disabled by default).
- Records a demo automatically when a match is started (With agstart).
- /unstuck command (10 seconds cooldown).
- Check certain sound files, they're the same sounds that are verified in the EHLL gamemode - AG6.6.
- Be able to destroy other players satchels (Optional, disabled by default).
- Block nickname and model changes when a game is in progress (Optional, both enabled by default).
- New intermission mode.
- More than 1 HLTV allowed.
- Force connected HLTV to have a certain delay value as a minimum (Minimum value is 30).
- Wallhack Blocker.
- Ghostmine Blocker.
- Simple OpenGF32 and AGFix detection (Through cheat commands).
- Take screenshots at map end and occasionally when a player dies.
- Avoid abusing a ReHLDS bug (Server disappears from the masterlist when it's' paused) only when there's no game in progress.

## New cvars
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

## Requirements
- Last version of HLDS (build 8308) or ReHLDS 3.6 or newer (Warning: Last version of ReHLDS for Linux has an auto-aim bug, download version 3.7.0.693 instead).
- Metamod 1.21.37p or newer, I recommend using [this version of metamod](https://github.com/Solokiller/Metamod-P-CMake/releases/tag/v1.21p39) (included and ready to use in development builds).
- Have [AMXX 1.9](https://www.amxmodx.org/downloads-new.php) installed or newer (included and ready to use in development builds).

## Download (Stable)
- Full releases: Besides containing everything necessary for the proper functioning of the LLHL gamemode, it has new maps with their respective dependencies (Locs, wads, sprites, sounds, etc).
- Lite releases: Only contain what is necessary for the correct functioning of the LLHL gamemode. (Metamod and AMXX)

Download the [Latest Release](https://github.com/FlyingCat-X/llhl/releases/).

## Download (Dev builds)
- You can download them from [Github Actions](https://github.com/FlyingCat-X/llhl/actions). Click on any of the commits you want to try and download the corresponding artifact. (Windows or linux). The artifacts come with everything you need to run LLHL (Plugin, Gamemode .cfg file, Sounds to verify, amxmodx, metamod, etc).

## Installation (The easy way)
- Have a clean installation of Half Life with Adrenaline Gamer ready.
- Download any of the latest releases (Full or lite).
- Extract it within your server installation (Outside ag folder) and accept to replace the files if you are asked.
- Turn your server on and enjoy.

## Thanks to
- Th3-822: FPS Limiter and blocking name and model changes.
- Alka: Server FPS.
- Arkshine: Unstuck command.
- naz: Useful codes for hook messages from AG engine.
- BulliT: For developing AG Mod and sharing the source code.
- Dcarlox: Grammar corrections and Spanish translation.
- leynieR: Portuguese Translation.