# Cultivo com a barra de ferramentas

Teste de cultivo: abra scenes/farming/FarmingToolDemo.tscn e pressione F6.

1. Equipe enxada com 3 e pressione F ou clique na celula para preparar o solo.
2. Use a enxada novamente na celula para plantar uma semente (12 iniciais).
3. Equipe regador com 1 e regue a mesma celula.
4. Espere os dias de jogo ou pressione F9 no debug para avancar um dia; a planta cresce uma fase a cada 3 dias regados.
5. Equipe enxada com 3 novamente e colha uma planta madura.
6. A colheita recupera uma semente; o salvamento dos canteiros continua em user://slimekeepers_farm_v1.json.

Acoes: 1 Regador, 2 Machado, 3 Enxada, 4 Picareta, 5-0 Materiais. Uma ferramenta equipada por vez.
O sistema de cultivo existe como prototipo separado; World.tscn preserva o HouseBuilder e o mapa original.

## Novo preparo de terra no mundo principal

Além do protótipo de flores, o World.tscn agora permite arar grama com a enxada 3 e reaproveita o TileSet Tilled_Dirt_v2. As células aradas são persistentes em save próprio; água, objetos e proximidade da casa impedem o preparo. **O plantio e a rega ainda devem ser conectados a essas células numa etapa posterior**, portanto usar a enxada no mundo principal não consome sementes nem cria flores automaticamente. Veja [preparo de terra](world_hoe.md).
