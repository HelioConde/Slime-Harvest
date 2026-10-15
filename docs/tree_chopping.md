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

## Repetir o teste de derrubada

A cena `scenes/trees/TreeChopDemo.tscn` define `persist_felling = false` nas duas arvores. Isso evita que o save antigo substitua as arvores por tocos no proximo F6. Ao final dos 5 golpes, a queda e o toco continuam acontecendo normalmente enquanto a cena estiver aberta.

No mapa principal, `persist_felling = true` por padrao, entao uma arvore derrubada permanece como toco ao reabrir o jogo. A cena de teste nao apaga nem modifica os registros persistidos; saves anteriores continuam protegidos.

Se quiser testar salvamento persistente, instancie uma arvore comum numa cena com `persist_felling = true`. Para testes de repeticao, use `TreeChopDemo.tscn`.


## Ordem visual da arvore e do jogador

Os pes do Player e a base do tronco determinam a profundidade via Y-sort (Godot 4).
- Personagem com Y maior do que a base do tronco: personagem na frente da arvore.
- Personagem com Y menor do que a base do tronco: arvore/copa na frente do personagem.
- Arvore e Player usam z_index = 10 para serem ordenados na mesma camada.
- TreeChopDemo.tscn usa y_sort_enabled = true na raiz e z_index = 10 no Player.
- World.tscn usa y_sort_enabled = true em Actors e Actors/Map para permitir arvores aninhadas no mapa.
- As substituicoes por tree_fall.tscn e stump.tscn ja herdam o z_index da arvore original.
- Tilemaps, HouseBuilder e terrenos foram preservados.

Teste: abra TreeChopDemo.tscn com F6, ande em volta do tronco com WASD e compare a copa e o jogador.
Por fim derrube a arvore e verifique o toco. Teste visual local pendente.

## Arvores recuperadas do catalogo

As cinco cenas antigas `tree_small`, `tree_large`, `tree_orange`, `tree_pear` e `tree_peach` voltaram com seus sprites e colisoes originais. Tambem usam o mesmo sistema de cinco golpes e deixam stump.

Essas cinco cenas possuem apenas um sprite por especie: na falta da animacao real de seis quadros `wind_swaying`, exibem seis movimentos curtos de rotacao (1,2 segundo por golpe). `tree.tscn` e `tree_apple.tscn` continuam usando os seis quadros reais, sem loop. Todas compartilham z_index=10 para Y-sort com o jogador.


## Recursos (atualizacao 15/10/2026)

A arvore deixa um tronco apos `tree_fall.tscn`; o stump exige tres golpes e deixa outro. Ambos aparecem no chao e podem ser recolhidos com clique. A picareta (atalho P) reduz o nivel das pedras a cada golpe, cada um soltando uma pedra. Flores e cogumelos podem ser recolhidos com clique sem mudar a ferramenta. Os itens e o estado das pedras sao salvos pelo ResourceBag. Para repetir o teste, a TreeChopDemo desativa persistencia de arvores, pedras e plantas.
