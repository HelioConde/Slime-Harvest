# Barra de ferramentas e equipamentos — Slimekeepers: Lost Valley

## Grupos e controles

A hotbar aparece na parte inferior em todas as cenas que possuem Player. Uma ferramenta fica equipada por vez.

| Tecla | Acessorio | Grupo | Animacoes |
|---|---|---|---|
| 1 | Picareta | accessory_pickaxe | pick_down/up/left/right |
| 2 | Machado | accessory_axe | axe_down/up/left/right |
| 3 | Enxada | accessory_hoe | hoe_down/up/left/right |
| 4 | Regador | accessory_watering_can | watering_down/up/left/right |

Todos os acessorios existem como nos no ToolInventory, e o personagem recebe o grupo equipado correspondente (equipped_axe, por exemplo).
O slot ativo recebe borda dourada, e os icones vetoriais nao dependem de fontes externas.

Tecla F usa o acessorio equipado diante do personagem; clique esquerdo usa a ferramenta perto do cursor. Cliques nos slots nao sao enviados ao mapa.
As animacoes das ferramentas nao entram em loop. O proximo comando fica bloqueado ate o fim da animacao.
A selecao persiste em user://slimekeepers_equipment_v1.json.

## Acoes

- Picareta: equipa e anima o golpe, pronta para integrar objetos mineraveis (mineracao efetiva ainda pendente).
- Machado: cinco golpes, cada um aguarda os seis quadros de wind_swaying, depois animacao de queda e toco persistente.
- Enxada: prepara terra; no segundo uso planta automaticamente uma semente; quando a flor amadurece, colhe.
- Regador: rega o canteiro experimental, permitindo avancar um estagio a cada 3 dias de jogo.

## Testes no Godot

- scenes/trees/TreeChopDemo.tscn (F6): teste do machado e troca pela cena stump.
- scenes/farming/FarmingToolDemo.tscn (F6): teste do preparo do solo, plantio e rega.
- scenes/world/World.tscn (F5): verifica a hotbar e o mapa principal, que ainda nao contem FarmField.

Arquivos: scripts/items/tool_inventory.gd, scripts/ui/tool_hotbar.gd, scripts/ui/tool_icon.gd e scenes/ui/ToolHotbar.tscn.
Os .gd usam tabulacoes. E necessario executar testes no editor Godot local.
