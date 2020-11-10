# LLHL
This plugin is a port for Adrenaline Gamer 6.6 (And AGMini) from my [LLHL gamemode](https://github.com/rtxa/agmodx/blob/master/valve/addons/amxmodx/scripting/agmodx_llhl.sma) that was developed for rtxa's agmodx.
Unlike my gamemode that I made for agmodx, this one only supports Protocol 48.

## Features
- FPS Limiter (Default value is 144)
- FOV Limiter (Minimum value is 85)
- Records a demo automatically when a match is started (With agstart)
- /unstuck command (10 seconds cooldown)
- Check certain sound files, they're the same sounds that are verified in the EHLL gamemode - AG6.6
- Be able to destroy other players satchels (Optional, disabled by default)
- Block nickname and model changes when a game is in progress (Optional, both enabled by default)
- New intermission mode
- Force connected HLTV to have a certain delay value as a minimum (Minimum value is 30)

## New cvars
- sv_ag_fpslimit_max_fps "144"
- sv_ag_fpslimit_max_detections "2"
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

## Requirements
- Last HLDS (build 8308) or ReHLDS 3.6 or newer (Warning: Last version of ReHLDS for Linux has an auto-aim bug, download version 3.7.0.693 instead).
- Metamod 1.21.37p or newer, I recommend using [this version of metamod](https://github.com/Solokiller/Metamod-P-CMake/releases/tag/v1.21p39) (included and ready to use in development builds)
- [AMXX 1.9](https://www.amxmodx.org/downloads-new.php) installed or newer (included and ready to use in development builds)

## Download
- At the moment because the plugin is in a development phase I haven't uploaded any releases, but you can try development builds, you can download them from [Github Actions](https://github.com/FlyingCat-X/llhl/actions). Click on any of the commits you want to try and download the corresponding artifact. (Windows or linux). The artifacts come with everything you need to run LLHL (Plugin, Gamemode .cfg file, Sounds to verify, amxmodx, metamod, etc).
- Alternatively you can compile the plugin on your own.

## Thanks to
- Th3-822: FPS Limiter and blocking name and model changes
- Alka: Server FPS
- Arkshine: Unstuck command
- naz: Useful codes for hook messages from AG engine
- BulliT: For developing AG Mod and sharing the source code
