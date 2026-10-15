# Slimekeepers: Lost Valley — Godot 2D

**Nomes anteriores:** FarmSlime / Slime Harvest.

Jogo 2D de fazenda, construcao, criaturas companheiras e exploracao em desenvolvimento no Godot 4.x.

## Funcionalidades atuais

- Personagem: movimentacao com WASD/setas, corrida com Shift, camera e animacoes direcionais.
- Hotbar inferior com 10 espacos e icones recortados do spritesheet original 4x3: 1 Regador, 2 Machado, 3 Enxada, 4-0 materiais. Picareta no atalho P. A selecao fica salva.
- Machado: corte de arvores em cinco golpes com balanco completo; animacao de queda, toco e persistencia.
- Cultivo experimental: enxada prepara/plantar/colher; regador permite o crescimento por etapas a cada tres dias do jogo.
- Casas: HouseBuilder integrado ao mapa principal scenes/world/World.tscn.
- Arte: tilesets, personagens, flores, arvores, pedras e cogumelos presentes em assets/ e scenes/.
- Catalogo: 78 cenas referenciadas, incluindo as 64 restauradas do historico.
- Checagem estrutural de referencias: `py -3 tools/validate_godot_project.py`.

## Executar

1. Importe a pasta deste projeto no Godot, usando project.godot.
2. Pressione F5 para abrir scenes/world/World.tscn.
3. Pressione 1-9/0 ou clique na hotbar para selecionar itens; F usa a ferramenta equipada.
4. Teste o machado em scenes/trees/TreeChopDemo.tscn (F6).
5. Teste a enxada e o regador em scenes/farming/FarmingToolDemo.tscn (F6).
6. O campo FarmField ainda e uma cena de teste separada; sua integracao ao mapa definitivo continua pendente.

Documentos: [ferramentas](docs/tool_inventory.md), [cultivo](docs/farming_loop.md), [machado](docs/tree_chopping.md), [casas](docs/house_building.md), [proximos marcos](docs/roadmap_godot.md).

## Projeto e escopo

O repositorio e [HelioConde/Slime-Harvest](https://github.com/HelioConde/Slime-Harvest). O projeto Roblox 3D e separado e utiliza [Slimekeepers-Lost-Valley](https://github.com/HelioConde/Slimekeepers-Lost-Valley).

A implementacao foi verificada por inspecao dos arquivos GitHub, mas requer validacao de execucao local no Godot.
