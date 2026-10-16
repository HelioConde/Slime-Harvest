# Hotbar — Slimekeepers: Lost Valley (Godot 2D)

## Sprites reais e layout

- Arte original: res://assets/Objects/Items/tools-n-meterial-items.png.
- Grade: quatro colunas por tres linhas (64 x 48 px). Cada icone ocupa exatamente 16 x 16 px.
- A interface recorta os icones com AtlasTexture (sem redezenhar e sem gerar arquivos raster substitutos).
- Visual: dez slots escuros com bordas suaves, moldura verde e dourada, selecao dourada, numeros discretos e tooltip; centralizada na parte inferior.
- Os sprites 11 (pedra processada) e 12 (pedra pequena) continuam no arquivo para a futura mochila, mas nao ocupam a hotbar.

| Slot/tecla | Icone do atlas | Identificador | Comportamento atual |
|---|---|---|---|
| 1 | Regador | watering_can | Regar plantacao |
| 2 | Machado | axe | Cortar arvores |
| 3 | Enxada | hoe | Preparar / plantar / colher |
| 4 | Grama | grass_drop | Item de recurso (coleta pendente) |
| 5 | Galho | branch | Item de recurso (coleta pendente) |
| 6 | Madeira | wood | Item de recurso (coleta pendente) |
| 7 | Tronco | trunk | Item de recurso (coleta pendente) |
| 8 | Gravetos | twigs | Item de recurso (coleta pendente) |
| 9 | Tabua | plank | Item de recurso (coleta pendente) |
| 10 / tecla 0 | Pedra grande | large_stone | Item de recurso (mineracao pendente) |

O atlas original enviado em 16/10 foi atualizado para 4x4 (64x64). A **picareta agora ocupa o slot 4** e continua acessivel por P como atalho secundario, usando a animacao original pick_*.
A selecao visual muda por clique ou pelas teclas 1-9 e 0. Recursos podem ser selecionados, mas nao executam golpe nem mostram quantidade ficticia.
Os atalhos de ferramentas anteriores mudaram: regador 1, machado 2, enxada 3.
F ou clique esquerdo usa a ferramenta equipada perto de um alvo valido. Clique sobre a propria interface nao deve atacar.
A selecao continua salva em user://slimekeepers_equipment_v1.json.

## Arquivos

- scripts/ui/tool_hotbar.gd: barra responsiva, 10 slots, recortes do atlas, estilos e selecao.
- scripts/items/tool_inventory.gd: slots, grupos e selecao salva.
- scripts/player/player.gd: atalhos e acoes dos itens.
- scenes/ui/ToolHotbar.tscn: cena de interface.
- scripts/ui/tool_icon.gd: legado dos icones vetoriais, mantido sem uso para nao apagar trabalho anterior.

## Verificar no Godot

Abrir scenes/trees/TreeChopDemo.tscn e pressionar F6. Os 10 slots devem ficar na base da janela; selecione o machado no slot 2 e corte a arvore. Verifique regador e enxada no teste scenes/farming/FarmingToolDemo.tscn, usando as teclas 1 e 3.
A arte deve ser pixel-perfect, sem interpolacao borrada, e a interface nao deve extrapolar a janela de 640x360.

## Ajustes de interface apos captura 15/10/2026

- Hotbar reduzida para ate 504 unidades logicas: dez slots com altura 46, painel de 58 e margens laterais de pelo menos 12 na janela 640x360.
- O painel permanece fixo na tela via CanvasLayer (nao se move com a camera do personagem).
- Sprite original 16x16 e recortado com AtlasTexture; filtro NEAREST mantido para pixels nitidos.
- Numeracao reduzida, borda dourada mais discreta e sombras menores.
- TreeChopDemo usa fundo em CanvasLayer e instrucoes curtas em painel ancorado no canto superior direito.
- Calendario ocupa uma placa compacta no canto superior esquerdo.
- FarmingHUD movido para a direita para nao sobrepor o calendario.
- Nenhum spritesheet, tilemap ou arquivo de save foi alterado por este ajuste.

## Revisao apos avaliacao do print: 15/10/2026

- Selecionar um novo item executa pulso suave de cor (0,22 s); os icones pixel art nao sao escalados em tween.
- Em viewport menor que 480 unidades, a barra reduz altura dos slots e icones para caber sem extrapolar as margens.
- TreeChopDemo define camera zoom 1,5 exclusivamente no teste, deixando o World original inalterado.
- O painel de instrucoes abre ao clicar em `?` e volta a recolher clicando em `×`.
- A cena usa flores, grama, cogumelos e pedras originais como decoracao, sem adicionar objetos de gameplay ou alterar os saves.
- As arvores da cena continuam com persist_felling=false, reaparecendo a cada F6.

## Coleta de recursos e contadores

- Arvore: 5 golpes de machado. A animacao de queda termina e gera um tronco visivel no chao.
- Toco: 3 machadadas adicionais. Ao ser removido, gera mais um tronco.
- Pedra: tecla P equipa a picareta. Clique na pedra ou use F olhando para ela; cada golpe reduz levelN em um e gera uma pedra no chao. Pedras sem sprites levelN encolhem por golpe.
- Troncos e pedras dropados: clique para recolher (ate 60 px logicos do personagem). O numero aparece sobre o icone no slot 7 (tronco) ou no slot 0 (pedra).
- Flores e cogumelos: clique com qualquer item equipado quando proximo. O objeto primeiro vira um drop com seu proprio sprite; so entra no inventario quando o jogador o recolhe.
- O inventario salva automaticamente em user://slimekeepers_resources_v1.json. Recursos nao recolhidos persistentes reaparecem apos recarregar o mundo.
- A TreeChopDemo foi configurada para repetir o teste sem salvar cortes, pedras mineradas ou plantas recolhidas ao fechar F6. Os recursos ja recolhidos no inventario continuam registrados.
- O inventario e um contador real de itens, nao uma mochila visual completa.

## Teste automatizado

GitHub Actions executa o Godot 4.7.1 em modo headless e chama tests/ResourceGameplayTest.tscn. O teste valida 5 machadadas, bloqueio durante o balanco, queda, spawn do toco, 3 golpes no toco, dois troncos recolhidos, niveis das pedras, drops de pedra, coleta de flor com regador e cogumelo com machado.


## Magnetismo de drops (15/10/2026)

Todos os itens no chao — troncos, pedras, flores e cogumelos — aguardam um instante antes de serem atraidos. A partir de **72 px do mundo** (valor padrao) o drop comeca a se deslocar suavemente ate o jogador, e quando chega a **12 px** e coletado automaticamente. Ele tambem pode ser recolhido manualmente com clique. O alcance, a velocidade e o atraso inicial sao editaveis em `scripts/items/resource_drop.gd`: `magnet_radius`, `pickup_radius`, `magnet_speed` e `pickup_delay`. Todos os drops seguem o mesmo comportamento.

A coleta da flor/cogumelo agora acontece em duas etapas: 1) o clique gera um item no chao e marca a planta como retirada; 2) aproximar o personagem (ou clicar no drop) credita o recurso no inventario. Os drops persistentes mantem a arte e a animacao da planta no save, inclusive apos recarregar o jogo. A cena de testes mantem os objetos repostos a cada execucao, sem alterar o progresso do mapa principal.


## Refinamento da jogabilidade

A hotbar agora identifica o item selecionado e aceita roda do mouse; a picareta usa o sprite do slot 4 (P e atalho secundario). O impacto e sincronizado com o quadro da animacao. Para detalhes de drops, efeitos, regrowth e testes, consulte [refinamentos](gameplay_polish.md).
