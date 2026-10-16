# Árvores frutíferas e terrenos reutilizáveis

## Árvores usando a primeira macieira como modelo

Em vez de inventar novos sprites, reaproveitamos a grade 48x48 dos spritesheets originais. Todas as espécies usam os mesmos recortes de coordenadas da primeira árvore, apontando para a arte específica de cada espécie:

| Espécie | Cena | Textura original |
| --- | --- | --- |
| Maçã | scenes/objects/trees/tree_apple.tscn | tree apple sprites.png |
| Laranja | scenes/objects/trees/tree_orange.tscn | tree orange sprites.png |
| Pêssego | scenes/objects/trees/tree_peach.tscn | tree peach sprites.png |
| Pera | scenes/objects/trees/tree_pear.tscn | tree pear sprites.png |

As quatro cenas possuem idle, growing (4 quadros), wind_swaying (6) e falling (12). O corte ainda usa cinco machadadas, queda, toco de três machadadas e dois troncos no total. A queda reaproveita SpriteFrames da espécie: a laranjeira cai com seu próprio desenho.

A animação falling da macieira foi ajustada para não repetir, permitindo completar automaticamente a queda, criar toco e drop. A animação growing está disponível para ligação futura ao calendário, mas ainda NÃO representa crescimento ao longo dos dias.

Para testar: abrir scenes/trees/FruitTreesDemo.tscn e pressionar F6. Usar tecla 2 (machado) e clique ou F perto da árvore. O cenário de testes não persiste árvores derrubadas; o mapa principal continua inalterado.

## Terrenos usando o TileSet já existente

O mesmo recurso data/tilesets/world_tileset.tres permanece sendo usado. Ele já continha dezoito terrenos. O componente scenes/world/TerrainPatch.tscn encapsula um TileMapLayer, reaproveitando as mesmas fontes e usando set_cells_terrain_connect para formar contornos.

| Terreno | terrain_set_index | Atlas original |
| --- | ---: | --- |
| Grama | 9 | Grass_tiles_v2 |
| Grama escura | 3 | Darker_Grass_Tiles_v2 |
| Terra | 11 | Soil_Ground_Tiles |
| Terra escura | 5 | Darker_Soil_Ground_Tiles |
| Pedra | 13 | Stone_Ground_Tiles |
| Terra arada | 17 | Tilled_Dirt_v2 |

Teste visual: abrir scenes/world/TerrainGallery.tscn e pressionar F6 para visualizar seis modelos lado a lado.

Reutilização: instanciar scenes/world/TerrainPatch.tscn no mapa desejado, escolher terrain_set_index, size_in_tiles e organic_border no Inspector. O script gera células em runtime apenas quando o TileMapLayer está vazio; células pintadas manualmente continuam intactas. Camadas de materiais diferentes devem ser conectadas manualmente ou sobrepostas usando TileMapLayers distintos; não há mistura automática entre dois terrain sets.

Os exemplos são separados de scenes/world/World.tscn. Não foram alteradas a pintura original do World, a casa nem os dados de TileMap anteriores.

## Validação

GitHub Actions executa tests/FruitTerrainTest.tscn no Godot 4.7.1: verifica quatro animações em cada espécie, queda não repetitiva com 12 quadros, cinco golpes, toco final, seis terrenos com células geradas e proteção de células pintadas manualmente. Teste headless não substitui revisão visual local do pixel art.
