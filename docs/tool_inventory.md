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

A **picareta** continua disponivel pelo atalho **P** com a animacao pick_*, pois o sprite fornecido nao inclui picareta entre os dez primeiros itens. Nao substituimos nenhum icone do atlas pelo desenho antigo.
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
