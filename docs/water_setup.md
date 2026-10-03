# Água animada

Em world2.tscn, selecione Actors/Map/Water. Na paleta TileMap, escolha o único tile (0, 0) e pinte ao redor da ilha. Ele usa quatro quadros de 16 × 16 a 4 FPS. Water tem Z Index -1 para ficar abaixo do solo e da grama; as margens transparentes deixam a água aparecer.

A animação já pertence ao TileSet e não precisa de script ou AnimationPlayer. Confira em F6. O mapa existente foi preservado; nenhuma célula nova foi pintada automaticamente. Não há colisão ou impedimento de caminhar sobre a água nesta etapa.
