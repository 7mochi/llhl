# ![LLHL Banner](https://raw.githubusercontent.com/FlyingCat-X/llhl/master/LLHL_logo.png)
### [Versión en Inglés](https://github.com/FlyingCat-X/llhl/blob/master/README.md) | [Versión en Español](https://github.com/FlyingCat-X/llhl/blob/master/README_ES.md) | [Versión en Portugués](https://github.com/FlyingCat-X/llhl/blob/master/README_PT.md)
Este plugin é uma adaptação para Adrenaline Gamer 6.6 (e AGMini) do meu [modo de jogo LLHL](https://github.com/rtxa/agmodx/blob/master/valve/addons/amxmodx/scripting/agmodx_llhl.sma) que foi desenvolvido para rtxa agmodx. A diferença do meu modo de jogo para agmodx, este suporta apenas o Portocolo 48.

# Considerações importantes
Se tiver um problema no seu servidor antes de abrir uma issue ou entrar em contato comigo por qualquer meio (Facebook, Whatsapp, Discord, etc) certifique-se de que o erro esteja relacionado ao plugin LLHL. Si tiver algum problema associado a o plugin tente ser o mais detalhado possível e forneça logs e maneiras de resolver esse erro. Não darei suporte / ajuda se o problema estiver relacionado a outros plugins como dproto ou reunion por exemplo.

## Características
- Limitador de FPS (o valor por padrão e de 144).
- Limitador de FOV (o valor mínimo é 85, por padrão está desabilitado).
- Uma demonstração e gravada automaticamente quando uma partida começa (con agstart).
- Comando /unstuck implementado (O tempo de espera é de 10 segundos para usá-lo de volta).
- Verificação dos arquivos de som, são os mesmos verificados no modo de jogo EHLL - AG6.6.
- Possibilidade de destruir as satchels de outros jogadores (Opcional, por padrão está desativado)
- Não são permitidas mudanças de nome e model quando um jogo está em andamento (opcional ambos ativados por padrão).
- Novo modo de espera ao terminar um mapa.
- Es forçado a ter HLTV conectado um certo valor de delay pelo mínimo (o valor padrão mínimo é 30).
- Bloqueador de ghostmines.
- Detecção simples de OpenGF32 e AGFix (Atraves do comandos do cheat)
- Faça screenshots no final de um mapa e ocasionalmente quando um jogador morre.
- Evite o abuso de um bug ReHLDS (o servidor desaparece da lista da mundial quando e pausado)  apenas quando não há uma match em andamento.
- A mudança de model durante uma partida subtrai 1 da pontuação. (Opcional, por padrão está activado).
- Verifica se há novas actualizações e vai baixar automaticamente.

## Novas cvars
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
- sv_ag_check_updates "1"
- sv_ag_check_updates_retrys "3"
- sv_ag_check_updates_retry_delay "2.0"
- sv_ag_update_dl_max_retries "3"
- sv_ag_update_dl_retry_delay "3"

## Requisitos
- Versão mais recente do HLDS (build 8308) ou ReHLDS 3.6 ou mais recente (Atenção: a versão mais recente do ReHLDS para Linux tem um bug de auto-apontar, como alternativa é recomendado baixar a versão 3.7.0.693).
- Metamod 1.21.37p ou mais recente; recomendo usar [esta versão do metamod](https://github.com/Solokiller/Metamod-P-CMake/releases/tag/v1.21p39) (incluído e pronto para uso em versões de desenvolvimento).
- Ter AMXX 1.9 instalado a versão mais recente (incluído e pronto para uso em versões de desenvolvimento).
- Módulo AMXX: [GoldSrc REST In Pawn (gRIP)](https://forums.alliedmods.net/showthread.php?t=315567)

## Downloads (Estável)
- Pacote completo: Além de ter todo o necessário para o correto funcionamento do LLHL gamemode, novos mapas são incluídos com seus respectivos arquivos adicionais (Locs, wads, sprites, sounds, etc).
- Pacote Lite: Contém apenas o necessário para o bom funcionamento do LLHL gamemode (Metamod y AMXX).

Baixe a [última versão](https://github.com/FlyingCat-X/llhl/releases/).

## Downloads (versões de desenvolvimento)
- Podem ser baixados do [Github Actions](https://github.com/FlyingCat-X/llhl/actions). Clique em qualquer um dos commits que deseja testar e baixe o artifact correspondente (Windows ou linux). Os artifacts têm tudo o que precisa para executar o LLHL  (Plugin, arquivo .cfg de gamemode, sons para verificar, amxmodx, metamod, etc).

## Instalação (a maneira fácil)
- Ter o Half-Life instalado com o Adrenaline Gamer pronto para usar.
- Baixe qualquer um dos pacotes  (full o lite).
- Extraia o conteúdo da pasta do servidor (fora da pasta ag) e confirme a substituição dos arquivos se solicitado.
- Ligue seu servidor e divirta-se.

## Agradecimientos
- Th3-822: Limitador FPS, FPS do servidor e bloqueador de mudança de nome e modelo.
- Arkshine: Comando unstuck.
- naz: Códigos úteis para hookear as mensagens do motor AG.
- BulliT: Para desenvolver o mod AG e compartilhar o código-fonte.
- Dcarlox: Correções gramaticais e tradução para o espanhol.
- leynieR: Tradução portuguesa.
- xeroblood: Metodo SplitString().