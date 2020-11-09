# LLHL
This plugin is a port for Adrenaline Gamer 6.6 (And AGMini) from my [LLHL gamemode](https://github.com/rtxa/agmodx/blob/master/valve/addons/amxmodx/scripting/agmodx_llhl.sma) that was developed for rtxa's agmodx.
Unlike my gamemode that I made for agmodx, this one only supports Protocol 48.

## Features
- FPS Limiter (Default value is 144)
- Records a demo automatically when a match is started (With agstart)
- /unstuck command (10 seconds cooldown)
- Check certain sound files, they're the same sounds that are verified in the EHLL gamemode - AG6.6
- Be able to destroy other players satchels (Optional, disabled by default)
- Block nickname and model changes when a game is in progress (Optional, both enabled by default)
- New intermission mode

## New cvars
- sv_ag_fpslimit_max_fps "144"
- sv_ag_fpslimit_max_detections "2"
- sv_ag_fpslimit_check_interval "1.5"
- sv_ag_unstuck_cooldown "10.0"
- sv_ag_unstuck_start_distance "32"
- sv_ag_unstuck_max_attempts "64"
- sv_ag_destroyable_satchel "0"
- sv_ag_destroyable_satchel_hp "1"
- sv_ag_block_namechange_inmatch "1"

## Thanks to
- Th3-822: FPS Limiter and blocking name and model changes
- Alka: Server FPS
- Arkshine: Unstuck command
- naz: Useful codes for hook messages from AG engine
- BulliT: For developing AG Mod and sharing the source code
