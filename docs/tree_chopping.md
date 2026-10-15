# Derrubada de arvores no Godot 2D

1. Pressione **2** para equipar o machado (ou clique no segundo slot da barra). Os outros slots sao 1 Picareta, 3 Enxada e 4 Regador.
2. Aproxime-se de tree.tscn ou tree_apple.tscn, equipe o machado e clique na copa da arvore. F, olhando para o tronco, tambem funciona.
3. Sao cinco golpes (editavel em axe_hits_required). Cada golpe aceito executa axe_down/up/left/right no personagem e os seis quadros wind_swaying na arvore, uma vez. Novos golpes so sao aceitos quando o balanco anterior termina. Apos o quinto balanco, a arvore vira tree_fall.tscn.
4. A animacao falling usa 12 quadros, 5 FPS, sem loop; quando termina, aparece stump.tscn.
5. O save fica em user://slimekeepers_felled_trees_v1.json, mantendo o toco ao retornar ao jogo.

Para testar: abra scenes/trees/TreeChopDemo.tscn, pressione F6, selecione 2, clique na copa e realize os cinco golpes ate a queda.
Coloque instancias de tree.tscn ou tree_apple.tscn no mapa principal para cortar la.
Arvores colocadas pelo editor usam o caminho na cena como ID. Instancias geradas por codigo devem ter persistent_id unico.
A animacao falling usa provisoriamente os quadros da macieira; arte dedicada para cada especie pode ser adicionada depois.
Nao ha drop de madeira nem inventario ainda. A execucao dentro do Godot local continua pendente.