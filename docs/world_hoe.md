# Arar o chão verde no mundo principal

## Escopo

O jogador equipa a enxada na tecla 3 e clica num pedaço verde do World.tscn (ou usa F voltado para o chão próximo). O golpe pinta terra arada **depois do quadro de impacto**, sobre uma nova camada TileMapLayer chamada TilledSoil. A camada grass2 original não é editada, as casas e as células já pintadas permanecem intactas.

## Regras de segurança

- Só permite células onde a camada superior grass2 exibe uma textura do TileSet de grama (inclusive grama escura). Água visível sem grama por cima, caminhos, solo sem grama, pedra e bordas não verdes continuam impedidos.
- Recusa células onde existe objeto com colisão ou visual: árvores, pedras, flores, cogumelos, drops, arbustos, troncos, tocos, brotos e outros integrantes do grupo world_objects.
- Uma planta já colhida fica invisível; pode-se arar depois de recolher o drop do chão. Arbustos, troncos, brotos e tocos decorativos agora aceitam golpes de machado e geram recursos de seus próprios sprites.
- Casa inicial: bloqueia o próprio piso, paredes e uma zona de segurança configurada em house_clearance_tiles (padrão 3 células além do contorno das paredes). A casa começa a ser protegida assim que seu primeiro piso for colocado; se já existir save de construção, ele é carregado ao abrir o mundo.
- A primeira célula do piso determina uma âncora fixa para a casa inicial. O comando de demolição, desfazer e carregamento recusam deslocamentos ou remoção total desse ponto. Expansões do contorno continuam possíveis.
- Uma célula arada não pode ser arada novamente. O sistema mostra uma mensagem pequena explicando o motivo da recusa.

## Salvamento e TileSet

- Terra arada: user://slimekeepers_world_hoeing_v1.json. Arquivo independente do cultivo protótipo.
- Casa inicial: o formato de save user://house_terrain_test.json (versão 2) mantém piso e recebe um novo campo opcional anchor, sem invalidar saves v2 anteriores.
- A camada TilledSoil usa data/tilesets/world_tileset.tres, conjunto de terra arada 17 (Tilled_Dirt_v2) com conexões automáticas de cantos. As regiões originais de água, solo e grama permanecem como estavam.
- A detecção é feita sobre a camada visual superior. No mapa original, soil_water e water estão por baixo de grass2; sua mera presença não bloqueia grama visível.

## Remoção de obstáculos (sem sprites novos)

- Árvores continuam com 5 machadadas e tocos com 3; pedras continuam na picareta.
- Flores, cogumelos e vegetação baixa (grass.tscn) viram drops ao clicar.
- Arbustos e troncos caídos podem ser cortados com 2–3 machadadas; brotos pequenos com 1; tocos decorativos com 2–3. Os drops usam a textura original e ficam no chão antes de entrar no inventário.
- A remoção desses obstáculos naturais é persistente quando a cena tem persist_clearing=true. Outras futuras categorias de objetos precisam aderir ao mesmo contrato de interação; não serão removidas automaticamente por arar o solo.

## O que ainda não está incluído

A terra arada no World por enquanto é **apenas preparo do terreno**: não planta sementes automaticamente. O protótipo de plantio/rega/colheita segue em scenes/farming/FarmingToolDemo.tscn; a próxima etapa é integrar suas culturas ao World, usando as células preparadas.

## Validação

Testes no Godot 4.7.1: tests/WorldHoeTest.tscn valida uso da enxada, quadro de impacto, bloqueio por objetos, água sem grama, casa fixa, não modificar a pintura original e save; tests/ClearableObjectsTest.tscn valida remoção de arbustos, troncos, brotos e tocos com o machado e drops. A pipeline não substitui checagem visual no Godot do Windows.

## Arquivos

- scenes/world/World.tscn
- scripts/world/world_hoeing.gd
- scripts/world/clearable_object.gd
- scripts/building/house_builder.gd
- scripts/farming/plant_growth.gd
- scripts/items/resource_drop.gd
