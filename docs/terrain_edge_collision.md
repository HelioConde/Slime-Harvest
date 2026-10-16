# Colisões do terreno pelas bordas dos sprites

O script `scripts/world/terrain_edge_collision.gd` lê o TileSet e cria colisões apenas nos pixels de **água exposta**, sem bloquear grama/terra desenhadas por cima. A malha segue o recorte alfa dos sprites existentes (amostragem de 1 pixel com limiar de 0,20). A camada criada chama-se `TerrainEdgeCollision` dentro de `World.tscn`.

## Como funciona

- Lê `water`, `grass2` e `soil_water` do `data/tilesets/world_tileset.tres` através das três `TileMapLayer` do mapa.
- Para cada pixel do TileSet, detecta se a água está visível ou coberta pela parte opaca de outro terreno.
- Junta pixels de água consecutivos em linhas e mescla linhas iguais em retângulos, reduzindo o número de `CollisionShape2D` em vez de adicionar um por pixel.
- Usa `collision_layer=1`, compatível com a máscara de colisão do Player. Os sprites originais continuam inalterados.
- Não apaga nem muda a pintura do World e não grava os colliders no TileSet compartilhado. Eles são recriados em runtime.
- A configuração `alpha_threshold` define o quanto de transparência conta como solo sólido. Ajuste no Inspector para revisar as margens quando necessário.
- O parâmetro `max_collision_rectangles` é um limite de segurança para evitar geração excessiva em mapas muito grandes.

## Onde usar

Abra `scenes/world/World.tscn`, selecione `Actors/Map/TerrainEdgeCollision` e confira no Inspector os NodePaths para água, grama e solo. No jogo, ative `Debug > Visible Collision Shapes` no Godot para visualizar os colliders. Pressione F5 para testar a movimentação nas margens.

Para atualizar a geometria após editar os tiles durante o jogo, chame `rebuild_collision()` no nó TerrainEdgeCollision. Pinturas feitas diretamente no editor são lidas na próxima inicialização automaticamente.

## Limites desta etapa

Esta implementação cobre a costa da **água presente no World**. Desníveis, penhascos, rios de outros mapas e pontes futuras precisam de suas próprias regras de passagem antes de reutilizar o sistema; não se deve aplicar colisão sólida a todos os tiles de grama, solo ou pedra. Como o contorno é pixelado, a colisão fica próxima da borda visual, podendo exigir pequenos ajustes de tolerância no teste local.

## Testes

`tests/TerrainEdgeTest.tscn` valida a presença da água bloqueada, solo opaco livre, camada física do personagem, recálculo dos colliders e preservação das células pintadas. A execução via GitHub Actions passou no Godot 4.7.1. Testar no Windows ainda é importante para avaliar a sensação de movimento em curvas e bordas.
