# Personagens e populacao do World (Godot 2D)

## O que foi integrado

- `World.tscn` instancia `SlimePopulation`, que carrega as 32 especies do manifesto do bestiario (`assets/slimes/bestiary/bestiario.json`). Usa uma unidade de cada especie, em pontos livres do gramado, sem sobrescrever casas, terreno ou saves.
- Cada unidade tem `CharacterBody2D`, collider circular e `slime_wander.gd`, com deslocamento e pausas aleatorias, desvio de bloqueios fisicos da layer World e limite de distancia da origem. Nao anda sobre agua ou fora do gramado; outras especies nao precisam de cenas reeditadas.
- **Por enquanto a IA e somente ambiental**: nao planta, nao rega, nao ataca e nao salva posicoes. Os slimes reaparecem redistribuidos ao abrir o World. O bestiario continua independente.
- O jogador usa os PNGs novos de `assets/Characters/new` com nomes de animacao iguais aos antigos (`idle_*, walk_*, run_*, axe_*, pick_*, hoe_*, watering_*`). Os PNGs nao foram alterados ou regravados.
- Ao iniciar uma nova fazenda, escolha Masculino/Feminino junto ao nome. A escolha e salva no metadado do slot. Saves antigos continuam disponiveis e usam masculino por padrao.
- O PNG masculino especifico de idle nao estava entre as 15 folhas de 8x4 importadas; ate esse material chegar, a postura idle usa o primeiro frame de caminhada do mesmo visual. A transicao nao usa recortes do atlas antigo. O idle feminino usa a folha dedicada.

## Testar localmente

1. Abra Godot 4.7.1 e aguarde a importacao dos PNGs; pressione F5. Crie uma nova fazenda, escolha feminino, observe as animacoes e teste WASD/Shift e 1-4 com F ou clique.
2. Saia e use Continuar: aparencia e save devem persistir. Crie outra fazenda masculina e confira a troca ao alternar slots.
3. Execute `res://scenes/world/World.tscn` com F6. Verifique os 32 nomes em `Actors/SlimePopulation` (Remote Scene Tree). Observe idle/move, contorno do lago, casa, vegetacao e paradas ao encontrar obstaculos.
4. Abra `scenes/slimes/bestiary/BestiaryPreview.tscn` com F6: as cenas originais do bestiario devem continuar funcionando.
5. Teste F1/reset sem perdade dados antigos. Os slimes sao NPCs nao persistentes, nao itens de inventario.

## Limitacoes conhecidas

- Os quadros gerados por IA tem espacamento 1774x887 dividido em 8 colunas e 4 linhas; recortes podem necessitar ajustes visuais (alinhar pes e armas). O runtime usa as texturas originais e escala para aproximar 48px da arte anterior.
- Os slimes nao contam com interacoes, tarefas, combate, domar, salvamento de posicao ou reproducao. Isso exige nova fase de gameplay.
- Teste visual local no Godot e validacao do desempenho com 32 entidades sao necessarios.
