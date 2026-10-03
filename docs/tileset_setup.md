# TileSets do mundo

Abra scenes/world/world2.tscn. Sua pintura original e a instância do Player foram preservadas. A camada existente usa data/tilesets/world_tileset.tres, com os atlases adicionados.

## Pintura

Na aba Terrains, selecione o conjunto correspondente à imagem e seu terrain, então Connect. Há 18 conjuntos independentes em Match Corners, cada um com as 16 combinações. Para combinar visuais diferentes, use TileMapLayers separados: cada terreno foi configurado contra vazio (-1), sem prometer transições diretas entre materiais.

O atlas Grass_Tile_Layers mantém source ID 1 para preservar as células existentes. Todos os tiles possuem tamanho 16 × 16. As variantes decorativas permanecem disponíveis na paleta de tiles; somente as 16 peças estruturais entram na seleção automática.

Água: o atlas principal Water.png tem uma célula animada com quatro quadros a 4 FPS. Pinte água em uma camada inferior e as margens de terreno em uma superior. A água não contém sprites de borda próprios.

## Recursos individuais

data/tilesets/palettes contém um TileSet por imagem completa: construções, móveis, cercas, pontes, terreno, encostas e versões antigas. Peças sem um conjunto completo reconhecido ficam disponíveis para montagem manual. Animações de portas, baús, portões e caixas de correio são paletas de quadros; não foram convertidas em animação automática do mapa.

Recortes individuais do pacote, imagens de exemplo e referências de bitmask foram preservados como arquivos originais. Os recortes repetem peças dos atlases completos; não entram como duplicatas no TileSet principal. Animais, personagens, itens e plantas continuam como sprites originais para cenas próprias, sem serem divididos em terrenos.

## Catálogo

| Atlas | Conexão |
| --- | --- |
| Barn structures.png | Montagem manual |
| Chikcen_Houses.png | Montagem manual |
| Water tray.png | Montagem manual |
| Basic_Furniture.png | Montagem manual |
| Chest.png | Montagem manual |
| Fence gates animation sprites .png | Montagem manual |
| Fences.png | Montagem manual |
| Mailbox Animation Frames.png | Montagem manual |
| Paths.png | Montagem manual |
| STONE PATH.png | Montagem manual |
| Stone_Path.png | Montagem manual |
| Wooden_Bridge.png | Montagem manual |
| Wooden_Bridge_v2.png | Montagem manual |
| Wooden_House_Roof_Tilset.png | Montagem manual |
| Wooden_House_Walls_Tilset.png | Montagem manual |
| door animation sprites.png | Montagem manual |
| Bush_Tiles.png | Montagem manual |
| Darker_Grass_Hill_Tiles_Slopes_v2.png | Montagem manual |
| Darker_Grass_Hills_Tiles_v2.png | Terrain: 16 padrões de cantos |
| Darker_Grass_Tile_Layers.png | Terrain: 16 padrões de cantos |
| Darker_Grass_Tile_Layers2.png | Terrain: 16 padrões de cantos |
| Darker_Grass_Tiles_v2.png | Terrain: 16 padrões de cantos |
| Darker_Soil_Ground_Hills_Tiles.png | Terrain: 16 padrões de cantos |
| Darker_Soil_Ground_Tiles.png | Terrain: 16 padrões de cantos |
| Grass_Hill_Tiles_Slopes v.2.png | Montagem manual |
| Grass_Hill_Tiles_v2.png | Terrain: 16 padrões de cantos |
| Grass_Tile_Layers.png | Terrain: 16 padrões de cantos |
| Grass_Tile_layers2.png | Terrain: 16 padrões de cantos |
| Grass_tiles_v2.png | Terrain: 16 padrões de cantos |
| Ground_Hill_Tiles_Slopes.png | Montagem manual |
| Soil_Ground_HiIls_Tiles.png | Terrain: 16 padrões de cantos |
| Soil_Ground_Tiles.png | Terrain: 16 padrões de cantos |
| Stone_Ground_Hills_Tiles.png | Terrain: 16 padrões de cantos |
| Stone_Ground_Tiles.png | Terrain: 16 padrões de cantos |
| Grass_tiles_v2_simple.png | Montagem manual |
| Hills.png | Montagem manual |
| Tilled Dirt.png | Montagem manual |
| Tilled_Dirt.png | Terrain: 16 padrões de cantos |
| Tilled_Dirt_Wide.png | Terrain: 16 padrões de cantos |
| Tilled_Dirt_Wide_v2.png | Terrain: 16 padrões de cantos |
| Tilled_Dirt_v2.png | Terrain: 16 padrões de cantos |
| Water.png | Água animada |
| Water.png | Montagem manual |
| Water_1.png | Montagem manual |
| Water_2.png | Montagem manual |
| Water_3.png | Montagem manual |
| Water_4.png | Montagem manual |

## Validação e retomada

Verificadas as referências a arquivos, presença das 16 máscaras únicas por terrain, dimensões e preservação exata dos dados pintados em world2. Execução e encaixe visual ainda devem ser conferidos no Godot. A cena inicial do projeto continua World.tscn; para conferir seu mapa, abra world2 e use F6.

Próxima etapa: desenhar o mundo com os atlases escolhidos, depois definir colisões por camada e altura. Os novos atlases não recebem colisões globais automaticamente: solo é caminhável, e prédios/encostas precisam de limites definidos de acordo com o mapa.
