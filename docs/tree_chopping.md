# Derrubada de arvores no Godot 2D

1. Pressione 5 para equipar o machado. Use 1 a 4 para retornar as ferramentas de cultivo.
2. Aproxime-se da arvore tree.tscn ou tree_apple.tscn, vire-se para o tronco e aperte F.
3. Apos 3 golpes (editavel em axe_hits_required), a arvore vira tree_fall.tscn.
4. A animacao falling usa 12 quadros, 5 FPS, sem loop; quando termina, aparece stump.tscn.
5. O save fica em user://slimekeepers_felled_trees_v1.json, mantendo o toco ao retornar ao jogo.

Para testar: abra scenes/trees/TreeChopDemo.tscn e pressione F6.
Coloque instancias de tree.tscn ou tree_apple.tscn no mapa principal para cortar la.
Arvores colocadas pelo editor usam o caminho na cena como ID. Instancias geradas por codigo devem ter persistent_id unico.
A animacao falling usa provisoriamente os quadros da macieira; arte dedicada para cada especie pode ser adicionada depois.
Nao ha drop de madeira nem inventario ainda. A execucao dentro do Godot local continua pendente.