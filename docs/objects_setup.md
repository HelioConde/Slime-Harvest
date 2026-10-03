# Objetos individuais

Arraste cenas de scenes/objects para o mapa. Cada objeto possui um Sprite2D e um AtlasTexture próprio em data/objects, recortado sem alterar a imagem original. Use um pai Node2D com y_sort_enabled para ordenar objetos e Player pela base. A origem de cada objeto está no centro inferior do recorte.

Árvores, arbustos, pedras, troncos e tocos têm colisão World (camada 1), limitada à base. Flores, cogumelos, brotos e frutas não bloqueiam passagem. Colisões são uma base inicial ajustável no Inspector. Não há coleta, derrubada ou animação implementadas nesta etapa.

Abra scenes/objects/ObjectCatalog.tscn para conferir todas as peças. Não modifica nem povoa automaticamente seu mapa. Validado: recortes dentro da imagem, pixels visíveis e referências dos recursos. Conferência visual no Godot pendente.

| Objeto | Cena |
| --- | --- |
| tree_small | scenes/objects/trees/tree_small.tscn |
| tree | scenes/objects/trees/tree.tscn |
| tree_apple | scenes/objects/trees/tree_apple.tscn |
| tree_orange | scenes/objects/trees/tree_orange.tscn |
| tree_pear | scenes/objects/trees/tree_pear.tscn |
| tree_peach | scenes/objects/trees/tree_peach.tscn |
| tree_large | scenes/objects/trees/tree_large.tscn |
| bush_small | scenes/objects/bushes/bush_small.tscn |
| bush | scenes/objects/bushes/bush.tscn |
| bush_red_berries | scenes/objects/bushes/bush_red_berries.tscn |
| bush_purple_berries | scenes/objects/bushes/bush_purple_berries.tscn |
| bush_blue_berries | scenes/objects/bushes/bush_blue_berries.tscn |
| apple | scenes/objects/fruit/apple.tscn |
| apple_leaf | scenes/objects/fruit/apple_leaf.tscn |
| orange | scenes/objects/fruit/orange.tscn |
| orange_leaf | scenes/objects/fruit/orange_leaf.tscn |
| pear | scenes/objects/fruit/pear.tscn |
| pear_leaf | scenes/objects/fruit/pear_leaf.tscn |
| peach | scenes/objects/fruit/peach.tscn |
| peach_leaf | scenes/objects/fruit/peach_leaf.tscn |
| red_berry | scenes/objects/fruit/red_berry.tscn |
| red_berry_leaf | scenes/objects/fruit/red_berry_leaf.tscn |
| purple_berry | scenes/objects/fruit/purple_berry.tscn |
| purple_berry_leaf | scenes/objects/fruit/purple_berry_leaf.tscn |
| blue_berry | scenes/objects/fruit/blue_berry.tscn |
| log_large | scenes/objects/logs/log_large.tscn |
| log_small | scenes/objects/logs/log_small.tscn |
| stump_small | scenes/objects/stumps/stump_small.tscn |
| stump | scenes/objects/stumps/stump.tscn |
| stump_large | scenes/objects/stumps/stump_large.tscn |
| stump_sprout | scenes/objects/stumps/stump_sprout.tscn |
| stump_flat | scenes/objects/stumps/stump_flat.tscn |
| stump_leaf | scenes/objects/stumps/stump_leaf.tscn |
| stump_mushroom | scenes/objects/stumps/stump_mushroom.tscn |
| mushroom_01 | scenes/objects/mushrooms/mushroom_01.tscn |
| mushroom_02 | scenes/objects/mushrooms/mushroom_02.tscn |
| mushroom_03 | scenes/objects/mushrooms/mushroom_03.tscn |
| mushroom_04 | scenes/objects/mushrooms/mushroom_04.tscn |
| mushroom_06 | scenes/objects/mushrooms/mushroom_06.tscn |
| mushroom_07 | scenes/objects/mushrooms/mushroom_07.tscn |
| mushroom_05_small_a | scenes/objects/mushrooms/mushroom_05_small_a.tscn |
| mushroom_05_small_b | scenes/objects/mushrooms/mushroom_05_small_b.tscn |
| rock_01 | scenes/objects/rocks/rock_01.tscn |
| rock_02 | scenes/objects/rocks/rock_02.tscn |
| rock_03 | scenes/objects/rocks/rock_03.tscn |
| rock_04 | scenes/objects/rocks/rock_04.tscn |
| rock_05 | scenes/objects/rocks/rock_05.tscn |
| rock_06 | scenes/objects/rocks/rock_06.tscn |
| rock_large | scenes/objects/rocks/rock_large.tscn |
| rock_round | scenes/objects/rocks/rock_round.tscn |
| rock_sprout | scenes/objects/rocks/rock_sprout.tscn |
| sprout_01 | scenes/objects/plants/sprout_01.tscn |
| sprout_02 | scenes/objects/plants/sprout_02.tscn |
| sprout_03 | scenes/objects/plants/sprout_03.tscn |
| sprout_04 | scenes/objects/plants/sprout_04.tscn |
| flower_warm_01 | scenes/objects/flowers/flower_warm_01.tscn |
| flower_warm_02 | scenes/objects/flowers/flower_warm_02.tscn |
| flower_warm_03 | scenes/objects/flowers/flower_warm_03.tscn |
| flower_warm_04 | scenes/objects/flowers/flower_warm_04.tscn |
| flower_warm_05 | scenes/objects/flowers/flower_warm_05.tscn |
| flower_warm_06 | scenes/objects/flowers/flower_warm_06.tscn |
| flower_warm_07 | scenes/objects/flowers/flower_warm_07.tscn |
| flower_warm_08 | scenes/objects/flowers/flower_warm_08.tscn |
| flower_warm_09 | scenes/objects/flowers/flower_warm_09.tscn |
| flower_warm_10 | scenes/objects/flowers/flower_warm_10.tscn |
| flower_warm_11 | scenes/objects/flowers/flower_warm_11.tscn |
| flower_warm_12 | scenes/objects/flowers/flower_warm_12.tscn |
| flower_cool_01 | scenes/objects/flowers/flower_cool_01.tscn |
| flower_cool_02 | scenes/objects/flowers/flower_cool_02.tscn |
| flower_cool_03 | scenes/objects/flowers/flower_cool_03.tscn |
| flower_cool_05 | scenes/objects/flowers/flower_cool_05.tscn |
| flower_cool_06 | scenes/objects/flowers/flower_cool_06.tscn |
| flower_cool_07 | scenes/objects/flowers/flower_cool_07.tscn |
| flower_cool_08 | scenes/objects/flowers/flower_cool_08.tscn |
| flower_cool_09 | scenes/objects/flowers/flower_cool_09.tscn |
| flower_cool_10 | scenes/objects/flowers/flower_cool_10.tscn |
| flower_cool_11 | scenes/objects/flowers/flower_cool_11.tscn |
| flower_cool_12 | scenes/objects/flowers/flower_cool_12.tscn |
