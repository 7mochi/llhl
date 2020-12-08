# ![LLHL Banner](https://raw.githubusercontent.com/FlyingCat-X/llhl/master/LLHL_logo.png)
### [Versión en Inglés](https://github.com/FlyingCat-X/llhl/blob/master/README.md) | [Versión en Español](https://github.com/FlyingCat-X/llhl/blob/master/README_ES.md) | [Versión en Portugués](https://github.com/FlyingCat-X/llhl/blob/master/README_PT.md)
Este plugin es una adaptación para Adrenaline Gamer 6.6 (y AGMini) de mi [LLHL gamemode](https://github.com/rtxa/agmodx/blob/master/valve/addons/amxmodx/scripting/agmodx_llhl.sma) que fue desarrollado para el agmodx de rtxa.
A diferencia de mi gamemode para agmodx, este solo es compatible con Protocolo 48.

## Características
- Limitador de FPS (el valor por defecto es de 144).
- Limitador de FOV (el valor mínimo es de 85, por defecto está desactivado).
- Se graba una demo automaticamente cuando se inicia una partida (con agstart).
- Comando /unstuck implementado (El tiempo de espera es de 10 segundos para volverlo a usar).
- Verificación de archivos de sonido, son los mismos que son checkeados en el EHLL gamemode - AG6.6.
- Posibilidad de destruir las satchels de otros jugadores (Opcional, por defecto está desactivado).
- No se permiten cambios de nombre y model cuando hay una partida en curso (Opcional, ambos activados por defecto).
- Nuevo modo de espera al finalizar un mapa.
- Se fuerza al HLTV conectado a tener un cierto valor de delay como mínimo (Valor mínimo por defecto es 30).
- Bloqueador de wallhack.
- Bloqueador de ghostmines.
- Detección simple de OpenGF32 y AGFix (Mediante comandos del cheat).
- Toma screenshots al termino de un mapa y ocasionalmente cuando un jugador muere.
- Se evita el abuso de un bug de ReHLDS (el servidor desaparece de la lista mundial cuando está pausado) solo cuando no hay una partida en curso.

## Nuevas cvars
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

## Requerimientos
- Última version de HLDS (build 8308) o ReHLDS 3.6 o más nueva (Advertencia: la versión más reciente de ReHLDS para Linux tiene un bug de auto apuntado, como alternativa se recomienda descargar la version 3.7.0.693).
- Metamod 1.21.37p o más reciente; recomiendo usar [esta versión de metamod](https://github.com/Solokiller/Metamod-P-CMake/releases/tag/v1.21p39) (incluido y listo para usar en versiones de desarrollo).
- Tener [AMXX 1.9](https://www.amxmodx.org/downloads-new.php) instalado o una versión más reciente (incluido y listo para usar en versiones de desarrollo).

## Descargas (Estables)
- Paquete full: Además de tener todo lo necesario para el correcto funcionamiento del LLHL gamemode, se incluyen nuevos mapas con sus respectivos archivos adicionales (Locs, wads, sprites, sounds, etc).
- Paquete lite: Solo contiene lo necesario para el adecuado funcionamiento del LLHL gamemode (Metamod y AMXX).

Descargar la [Última versión](https://github.com/FlyingCat-X/llhl/releases/).

## Descargas (versiones de desarrollo)
- Se pueden descargar de [Github Actions](https://github.com/FlyingCat-X/llhl/actions). Click en cualquiera de los commits que desees probar y descarga el artifact correspondiente (Windows o linux). Los artifacts tienen todo lo que se necesita para correr el LLHL (Plugin, archivo .cfg del gamemode, sonidos a verificar, amxmodx, metamod, etc).

## Instalación (La manera fácil)
- Tener instalado Half-Life con Adrenaline Gamer listo para usar.
- Descarga cualquiera de los paquetes (full o lite).
- Extrae el contenido dentro de la carpeta de tu servidor (fuera de la carpeta ag) y confirma el reemplazo de archivos si es que se te pregunta.
- Enciende tu servidor y disfruta.

## Agradecimientos
- Th3-822: Limitador de FPS y bloqueador de cambios de nombre y model.
- Alka: FPS del servidor.
- Arkshine: Comando unstuck.
- naz: Códigos útiles para hookear los mensajes del motor de AG.
- BulliT: Por desarrollar el AG mod y compartir el código fuente.
- Dcarlox: Correcciones gramaticales y traducción al español.
- leynieR: Traducción al Portugués.