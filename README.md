# Slimekeepers: Lost Valley — Godot 2D

**Nome anterior:** FarmSlime / Slime Harvest.

Jogo 2D de fazenda, criaturas companheiras e exploração em desenvolvimento no **Godot 4.x**. Nossa prioridade agora é validar um ciclo jogável simples antes de ampliar os sistemas de slimes, economia, vila e exploração.

## Onde estamos

- **Personagem:** movimentação, corrida, câmera e suporte a animações direcionais.
- **Mapa inicial:** `scenes/world/World.tscn`, selecionado como cena principal; terreno provisório com campo 10×7, lago, árvores, pedras e colisões.
- **Cultivo experimental:** selecionar ferramenta nas teclas 1 a 4 e usar F próximo do canteiro; preparar, plantar, regar, esperar crescer e colher. Salva automaticamente em `user://slimekeepers_farm_v1.json`.
- **Construção de casas:** sistema de piso, paredes e telhados por camadas com 25 materiais, em `scenes/world/world2.tscn`. Esse cenário é um laboratório separado e **não** foi substituído pelo mapa principal.
- **Recursos:** tilesets, arte de objetos, animais e personagens já organizados em `assets/`.

Leia [o tutorial de cultivo](docs/farming_loop.md), [a construção de casas](docs/house_building.md) e [os próximos marcos](docs/roadmap_godot.md).

## Abrir no Godot

1. Abra o Godot e importe a pasta que contém `project.godot`.
2. Pressione **F5** para jogar o mapa principal. Use **WASD/setas** para andar, **Shift** para correr, **1–4** para alternar a ferramenta e **F** para usá-la.
3. Para testar a construção de casas, abra `scenes/world/world2.tscn` e pressione **F6**.

> A execução precisa ser validada localmente no Godot; a implementação foi revisada em código, mas não foi testada com o editor nesta atualização.

## GitHub e nomes

Este repositório continua em [HelioConde/Slime-Harvest](https://github.com/HelioConde/Slime-Harvest), preservando histórico e sincronização da pasta local `C:\FarmSlime`. O nome exibido pelo Godot agora é **Slimekeepers: Lost Valley**.

O repositório [HelioConde/Slimekeepers-Lost-Valley](https://github.com/HelioConde/Slimekeepers-Lost-Valley) já existe e contém a versão 3D/Roblox. Por isso, não renomeamos nem sobrescrevemos repositórios neste passo. Planejar uma possível estrutura única só depois de ambos os projetos estarem estáveis.

## Estrutura

`assets/` recursos visuais e sonoros; `scenes/` cenas; `scripts/` comportamentos; `data/` definições; `docs/` manuais; `tests/` testes e `tools/` utilitários.

Não versionar saves, arquivos temporários, logs ou credenciais. Os recursos usados devem ter licenças documentadas.
