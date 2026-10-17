# Personagens e populacao do World (Godot 2D)

## O que foi integrado

- `World.tscn` instancia `SlimePopulation`, que carrega as 32 especies do manifesto do bestiario (`assets/slimes/bestiary/bestiario.json`). Usa uma unidade de cada especie, em pontos livres do gramado, sem sobrescrever casas, terreno ou saves.
- Cada unidade tem `CharacterBody2D`, collider circular e `slime_wander.gd`, com deslocamento e pausas aleatorias, desvio de bloqueios fisicos da layer World e limite de distancia da origem. Nao anda sobre agua ou fora do gramado; outras especies nao precisam de cenas reeditadas.
- **IA selvagem**: as 32 especies possuem necessidades, temperamento, fuga, curiosidade, afeicao e ataques territoriais/agressivos somente contra o jogador; slimes nunca atacam outros slimes. Nao executam trabalhos de fazenda nem salvam posicoes. Os slimes reaparecem distribuidos ao abrir o World. O bestiario continua independente.
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
- Ja existem reacoes selvagens de proximidade e ataques simples ao jogador. Ainda faltam combate profundo, interacoes entre especies, tarefas, domesticacao, salvamento de posicao e reproducao.
- Teste visual local no Godot e validacao do desempenho com 32 entidades sao necessarios.

## Correcao de visibilidade (16/10/2026)

- `grass2` usa z-index 1 e `TilledSoil` z-index 2; antes, os slimes ficavam no z 0 e eram escondidos pela grama. `Actors/SlimePopulation` agora usa z-index 3 para mostrar os slimes acima do solo. Ainda falta refinar a oclusao nas copas das arvores grandes.
- `scenes/player/Player.tscn` agora referencia `assets/Characters/animation/player_masculino_frames.tres` **diretamente no inspetor**. O recurso possui 28 animacoes e e exibido mesmo sem rodar o jogo.
- A versao feminina pode ser visualizada em `scenes/player/FemaleSpritePreview.tscn` ou em `assets/Characters/animation/player_feminino_frames.tres`. Ao criar uma nova fazenda e selecionar Feminino, o controlador troca o SpriteFrames do Player no runtime.
- As folhas originais permanecem em `assets/Characters/new/`. Os 28 estados incluem 8 quadros por direcao, em recortes das imagens originais 1774x887. Escala de exibição 0.25 para manter proporcao com o mapa.
- **Observacao:** o pacote masculino nao contem uma sequencia exclusiva de caminhada distinta da corrida: a caminhada usa a folha de corrida em velocidade menor, ate ser produzido um spritesheet proprio.
- Teste importante: abrir Player.tscn e verificar `AnimatedSprite2D > Sprite Frames` no inspetor. Validar os 4 lados, armas e posicao dos pes no mapa.

## Ajuste de fluidez do Player (16/10/2026)

- A folha masculina `exec-fd8ae2cc...` possui passos caminhando, mas havia sido usada no `idle`. Agora fornece o `walk` (8 quadros); para parado usamos a pose estavel do ultimo quadro, sem andar parado. A folha masculina `exec-9749d5d0...` fica exclusiva para `run`.
- `idle` feminino usa ida-e-volta nos oito quadros (14 exposicoes) para evitar salto seco do ultimo quadro para o primeiro.
- Medimos a deriva lateral das folhas originais e alinhamos os desenhos, sem alterar a colisao, o ponto de interacao ou os PNGs. Compensacoes no `player_motion_alignment.gd`, aplicadas quando cada quadro muda.
- 9 FPS para caminhar, 12 FPS para correr; velocidade acompanha parcialmente a velocidade fisica. Ao trocar entre caminhar/correr preserva a fase do passo.
- Golpes mantem os eventos de impacto no mesmo quadro, mas agora usam duracoes variaveis: preparacao mais lenta, contato rapido e retorno mais suave.
- Falta criar sprites extras (idle masculino com piscadas reais e eventualmente locomocao com diagonais) para acabamento definitivo. Inspecione no F5 e teste todas as direcoes.


## IA selvagem: temperamentos e reacoes (17/10/2026)

`SlimePopulation` continua colocando 32 especies de forma selvagem, sem captura nem rotina de cuidados do jogador. Os scripts foram divididos por responsabilidade:

- `scripts/slimes/slime_needs.gd`: necessidade ecologica, regeneracao de reserva e risco de dissipar.
- `scripts/slimes/slime_temperaments.gd`: temperamento especifico das 32 especies, distancia de alerta, alcance e animacoes.
- `scripts/slimes/slime_wander.gd`: maquina de estados com roaming, busca de habitat e interacao social.
- `scripts/slimes/world_population.gd`: margens de agua, pontos de recursos e rotas caminhaveis.

Temperamentos:
- **Medroso**: foge quando o jogador aproxima; tenta desviar de obstaculos.
- **Amigavel**: se aproxima e exibe afeicao (animacao de felicidade/coracao); nao pode ser domesticado nesta etapa.
- **Curioso**: observa o jogador, sem partir para combate.
- **Territorial**: protege uma area ao redor de seu ponto inicial; persegue apenas invasoes proximo ao lar.
- **Agressivo**: persegue o jogador enquanto estiver no alcance de percepcao. Ataque tem aviso, golpe e tempo de recarga.

Gota possui postura territorial e a animacao `disparar_jato` com trilha visual azul; o jogador recebe dano apenas se continuar dentro do alcance e sem obstaculos no momento do golpe. Uma perseguição nao tem alcance infinito. Ataques tem recarga e o jogador possui invulnerabilidade breve, HP de teste e retorno seguro ao spawn quando HP chega a zero. Nao ha perda de itens, save sobrescrito, captura, domesticacao ou trabalhos no campo.

**Prioridade ecologica**: a IA nao procura o jogador se a reserva essencial estiver criticamente baixa; medrosos ainda podem fugir de perigo. Criaturas nao atravessam agua nem paredes para reagir. As interacoes sociais nao persistem entre aberturas do World; mais tarde podemos persistir memoria de encontros.

Testes: `tests/SlimeBehaviorTest.tscn` (fuga, curiosidade, afeicao, aviso de ataque, dano, recarga, defesa do Gota e respawn); `tests/SlimeSurvivalTest.tscn` (habitat, absorcao e fome). Testes visuais locais no Godot ainda sao recomendados.


## Regra de convivencia selvagem

**Slimes nao lutam entre si.** Independentemente de agressividade ou territorialidade, os slimes so podem interagir uns com os outros pacificamente: observar, brincar, mostrar afeicao, compartilhar recursos, ajudar ou se afastar. Slimes hostis podem atacar o **jogador**, mas nao outros slimes. Proibidos combate intraespecies, predacao, dano ou morte causada por outro slime. Nao implementar captura/domesticacao nesta fase.
