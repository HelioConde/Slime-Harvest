# Slimekeepers: Lost Valley — Godot 2D

**Nomes anteriores:** FarmSlime / Slime Harvest.

Jogo 2D de fazenda, construcao, criaturas companheiras e exploracao em desenvolvimento no Godot 4.x.

## Funcionalidades atuais

- Personagem: movimentacao suave (aceleracao/desaceleracao), Shift, camera e animacoes direcionais, com impactos sincronizados.
- Hotbar inferior com 10 espacos e icones recortados do spritesheet atualizado 4x4: 1 Regador, 2 Machado, 3 Enxada, 4 Picareta, 5-0 materiais. Atalho P para picareta mantido. A selecao fica salva.
- Machado: corte de arvores em cinco golpes com balanco completo; queda deixa um tronco; toco pede mais tres golpes e deixa outro tronco.
- Cultivo experimental: enxada prepara/plantar/colher; regador permite o crescimento por etapas a cada tres dias do jogo.
- Picareta (tecla P): minerar pedras nivel por nivel; pedra pequena e grande geram recompensas distintas usando sprites originais.
- Flores e cogumelos: clique com qualquer ferramenta para gerar drops no chao; regeneracao configuravel por dias.
- Drops: salto inicial, magnetismo de proximidade que respeita paredes, contadores na hotbar e recursos salvos.
- Casas: HouseBuilder integrado ao mapa principal scenes/world/World.tscn.
- Arte: tilesets, personagens, flores, arvores, pedras e cogumelos presentes em assets/ e scenes/.
- Catalogo: 78 cenas referenciadas, incluindo as 64 restauradas do historico.
- Mundo selvagem: 32 especies de slimes com necessidade ecologica, cinco temperamentos (medroso, curioso, amigavel, territorial e agressivo), fuga, afeicao, ataque com aviso/cooldown e vida simples do jogador. Nao ha captura nem domesticacao.
- Checagem estrutural de referencias: `py -3 tools/validate_godot_project.py`.

## Executar

1. Importe a pasta deste projeto no Godot, usando project.godot.
2. Pressione F5 para abrir scenes/ui/MainMenu.tscn. Para testar o mundo diretamente, abra scenes/world/World.tscn e use F6.
3. Pressione 1-9/0 ou clique na hotbar para selecionar itens; F usa a ferramenta equipada.
4. Teste o machado em scenes/trees/TreeChopDemo.tscn (F6).
5. Teste mineracao e coleta na mesma TreeChopDemo (F6). Aproxime-se da pedra, equipe P e use clique ou F. Clique em drops, flores ou cogumelos para recolher.
6. Teste a enxada e o regador em scenes/farming/FarmingToolDemo.tscn (F6).
7. O campo FarmField ainda e uma cena de teste separada; sua integracao ao mapa definitivo continua pendente.

Documentos: [refinamentos](docs/gameplay_polish.md), [ferramentas](docs/tool_inventory.md), [cultivo](docs/farming_loop.md), [machado](docs/tree_chopping.md), [casas](docs/house_building.md), [proximos marcos](docs/roadmap_godot.md).

## Projeto e escopo

O repositorio e [HelioConde/Slime-Harvest](https://github.com/HelioConde/Slime-Harvest). O projeto Roblox 3D e separado e utiliza [Slimekeepers-Lost-Valley](https://github.com/HelioConde/Slimekeepers-Lost-Valley).

A implementacao foi verificada por inspecao dos arquivos GitHub, mas requer validacao de execucao local no Godot.

## Árvores frutíferas e terreno reutilizável

A macieira animada agora serve de modelo para laranjeira, pessegueiro e pereira usando os sprites existentes. O TileSet do mundo é reutilizado em seis superfícies de exemplo, preservando o World original. Abra scenes/trees/FruitTreesDemo.tscn ou scenes/world/TerrainGallery.tscn e pressione F6. Para inserir um terreno em outro mapa, instancie scenes/world/TerrainPatch.tscn. Detalhes: [árvores e terrenos](docs/fruit_trees_terrains.md).

## Enxada no mundo principal e casa fixa

No `World.tscn`, use 3 (enxada) e clique ou F sobre o chão verde: cada enxadada cria terra arada real no TileSet original. Não se pode arar em cima de objetos, fora da grama ou perto da casa inicial. Arbustos, troncos, brotos e tocos decorativos podem ser removidos com o machado antes de arar. A casa inicial mantém sua posição depois da primeira construção, com salvamento compatível. Guia: [preparo de terreno e casa fixa](docs/world_hoe.md).

## Menu inicial e atlas de ferramentas atualizado

- A cena inicial agora é `scenes/ui/MainMenu.tscn`, com interface própria; o mundo principal continua disponível em `scenes/world/World.tscn`.
- A imagem oficial do menu deve ficar em `assets/ui/main_menu/vale_encantado.png`. Caso ainda não esteja instalada, o menu exibe um fundo verde seguro sem quebrar o projeto.
- O novo atlas `tools-n-meterial-items.png` foi substituído pelo original enviado nesta conversa, 64 × 64 pixels (4 × 4 ícones). A picareta ocupa o **4º slot**, e a tecla P continua como atalho.
- `Continuar` funciona somente com save legado existente; `Novo jogo` impede sobrescrever a fazenda salva enquanto não houver separação de slots.
- `Multiplayer` fica desativado (em breve), com entrada reservada para futuras sessões de rede. O menu não inicia serviços multiplayer.
- O calendário pausa e sua HUD desaparece na tela inicial.


## Interface Sprout Lands opcional

O tema Sprout Lands pode ser instalado a partir dos dois ZIPs originais do
UI Pack e do addon Godot; sem os arquivos, a interface antiga continua funcionando.
O tema estiliza hotbar, calendario, opcoes e dialogs, preservando sprites de
menu existentes. Instrucoes de instalacao e permissao de uso:
[Guia Sprout Lands UI](docs/sprout_lands_ui.md).

## Colecao Sprout Lands (sprites + plugins)

Instalacao opcional e segura de **UI Basic**, **Sprites Basic**, **plugin UI** e **plugin TileMap**, usando os quatro ZIPs originais, sem alterar os saves nem o mapa principal. Abra `scenes/world/SproutShowcase.tscn` (F6) para visualizar o exemplo e as folhas de sprites. Guia: [Colecao Sprout Lands](docs/sprout_lands_collection.md). Os arquivos licenciados ficam apenas na instalacao local.
