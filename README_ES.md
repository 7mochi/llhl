# ![LLHL Banner](https://raw.githubusercontent.com/FlyingCat-X/llhl/master/LLHL_logo.png)
### [Versión en Inglés](https://github.com/FlyingCat-X/llhl/blob/master/README.md) | [Versión en Español](https://github.com/FlyingCat-X/llhl/blob/master/README_ES.md) | [Versión en Portugués](https://github.com/FlyingCat-X/llhl/blob/master/README_PT.md) | Versión en Chino (Pendiente)
Este plugin es una adaptación para Adrenaline Gamer 6.6 de mi [LLHL gamemode](https://github.com/rtxa/agmodx/blob/master/valve/addons/amxmodx/scripting/agmodx_llhl.sma) que fue desarrollado para el agmodx de rtxa.
A diferencia de mi gamemode para agmodx, este solo es compatible con Protocolo 48.

# Consideraciones importantes
Si tienes algún problema en tu servidor, antes de abrir una issue o contactarme por cualquier medio (Facebook, Whatsapp, Discord, etc) asegurate de que el error es relacionado al plugin LLHL. Si tienes algún problema asociado al plugin trata de ser lo mas detallado posible y brindarme logs y maneras de como llegar a que salga dicho error. No daré soporte/ayuda si el problema es relacionado a otros plugins como dproto o reunion por ejemplo.

## Características
- Limitador de FPS (el valor por defecto es de 144, se puede cambiar de 144 a 240 y viceversa, puedes alternar entre ellos con el voto fpslimitmode).
- Limitador de FOV (el valor por defecto es de 85, por defecto está activado).
- Se graba una demo automaticamente cuando se inicia una partida (con agstart).
- Comando /unstuck implementado (El tiempo de espera es de 10 segundos para volverlo a usar).
- Verificación de archivos de sonido, son los mismos que son checkeados en el EHLL gamemode - AG6.6.
- No se permiten cambios de nombre y model cuando hay una partida en curso (Opcional, ambos activados por defecto).
- Nuevo modo de espera al finalizar un mapa.
- Se fuerza al HLTV conectado a tener un cierto valor de delay como mínimo (Valor mínimo por defecto es 30).
- Bloqueador de ghostmines.
- Detección simple de OpenGF32 y AGFix (Mediante comandos del cheat).
- Toma screenshots al termino de un mapa y ocasionalmente cuando un jugador muere.
- Se evita el abuso de un bug de ReHLDS (el servidor desaparece de la lista mundial cuando está pausado) solo cuando no hay una partida en curso.
- Cambiar de model durante una partida resta 1 de la puntuación. (Opcional, por defecto está activado).
- Bloquear el acceso a los jugadores que tengan el juego vía prestamo familiar. (Opcional, por defecto está desactivado).
- Spawns aleatorias (Opcional, por defecto está desactivado).
- Bloquea mensajes de ubicación/HP/arma/etc para los espectadores.
- Verifica si hay nuevas actualizaciones y las descargará automáticamente.
- Comando llhl_match_manager implementado (Solo para administradores)

## Nuevas cvars
- sv_ag_fps_limit_warnings "2"
- sv_ag_fps_limit_check_interval "5.0"
- sv_ag_fov_min_enabled "1"
- sv_ag_fov_min_check_interval "1.5"
- sv_ag_fov_min "85"
- sv_ag_unstuck_cooldown "10.0"
- sv_ag_unstuck_start_distance "32"
- sv_ag_unstuck_max_attempts "64"
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
- sv_ag_autoupdate "1"
- sv_ag_autoupdate_dl_max_retries "3"
- sv_ag_autoupdate_dl_retry_delay "3"

## Requerimientos
- Edición de preaniversario de HLDS (Build 8684) o el último [ReHLDS](https://github.com/dreamstalker/rehlds/releases) instalado. La compatibilidad con la versión del 25avo aniversario no ha sido probada.
- Una instalacion base de [AGMOD](https://openag.pro/latest/ag.7z).
- Metamod 1.21.37p o más reciente; recomiendo usar [esta versión de metamod](https://github.com/theAsmodai/metamod-r/releases/tag/1.3.0.149).
- Tener [AMXX 1.9](https://www.amxmodx.org/downloads-new.php) instalado o una versión más reciente.
- Módulo AMXX: [Curl](https://forums.alliedmods.net/showthread.php?t=285656).

## Descargas
- Paquete full: Además de tener todo lo necesario para el correcto funcionamiento del LLHL gamemode, se incluyen nuevos mapas con sus respectivos archivos adicionales (Locs, wads, sprites, sounds, etc).
- Paquete lite: Solo contiene lo necesario para el adecuado funcionamiento del LLHL gamemode (Metamod, AMXX el custom AGMOD para LLHL).

Descargar la [Última versión](https://github.com/FlyingCat-X/llhl/releases/).

## Instalación (La manera fácil)
- Tener instalado Half-Life con Adrenaline Gamer listo para usar.
- Descarga cualquiera de los paquetes (full o lite).
- Extrae el contenido dentro de la carpeta de tu servidor (fuera de la carpeta ag) y confirma el reemplazo de archivos si es que se te pregunta.
- Enciende tu servidor y disfruta.

## Agradecimientos
- Th3-822: Limitador de FPS, FPS del Servidor y bloqueador de cambios de nombre y model.
- Arkshine: Comando unstuck.
- naz: Códigos útiles para hookear los mensajes del motor de AG.
- BulliT: Por desarrollar el AG mod y compartir el código fuente.
- Dcarlox: Correcciones gramaticales y traducción al español.
- leynieR: Traducción al Portugués.
- xeroblood: Metodo SplitString().