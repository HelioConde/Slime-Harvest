# Territorios, chefes e caminhos de convivencia — especificacao (Godot 2D)

> **Estado: design para desenvolvimento futuro, NAO implementado.**
> Antes de desenhar o mapa definitivo e a historia, estabilizar o Wild Ecosystem 1.0 e testar o motor generico de progresso regional em um mapa artificial.
> Captura, domesticacao e cuidados de slime nao fazem parte da fase atual.

## Regra central: liberdade de estilo de jogo

- **Cada territorio tera uma especie nativa de slime**, com habitat, necessidades, comportamento e chefe regional proprios.
- O jogador pode conquistar a confianca de uma regiao **sem atacar, derrotar ou matar nenhum inimigo**. O caminho pacifico deve ser completo e viavel.
- Existem varias **vias equivalentes de resolucao**, com desafios diferentes: **combate opcional**, **culinaria/oferendas**, **missoes e diplomacia com NPCs**, **restauracao do ambiente** e **combinacoes** de atividades.
- Cada caminho deve poder conduzir a um **encontro com o chefe** e a um **desfecho regional positivo**, sem forcar um combate ou uma receita obrigatoria para todos.
- Depois que o chefe for **pacificado, convencido, satisfeito ou vencido**, a regiao fica pacificada; os slimes nativos ficam mais receptivos e futuros vinculos de amizade se tornam mais faceis.
- Um desfecho pacifico nao e uma derrota disfarcada: mostrar animacoes, dialogos, gratidao e consequencias coerentes com a escolha.
- Jogadores podem fazer atividades de caminhos distintos sem perder o progresso. Nenhum sistema deve obrigar a escolher uma classe moral, faccao ou via irreversivel.
- **Slimes nunca lutam entre si.** Objetivos de combate, quando existirem, envolvem monstros hostis separados dos slimes da regiao ou um confronto opcional com o proprio chefe. Nao exigir matar slimes.
- Chefes e slimes continuam criaturas vivas e com necessidades mesmo apos pacificar a area. Pacificacao nao significa captura, domesticacao ou acesso automatico ao inventario.

## Fluxo nao linear de um territorio

`explorando` -> `caminhos_de_progresso` -> `encontro_com_chefe` -> `resolucao_da_regiao` -> `regiao_pacificada`

**Caminhos de progresso (paralelos e acumulaveis):**

1. **Aventura/combate:** cumprir objetivos de aventura, eventualmente derrotar monstros hostis, despertar/desafiar o chefe e vence-lo em combate opcional.
2. **Culinaria/acolhimento:** descobrir gostos e restricoes alimentares do chefe; cultivar, coletar ou trocar ingredientes; preparar e servir um prato relevante.
3. **NPCs/diplomacia:** conhecer moradores, completar missoes, descobrir a causa do problema e negociar com o chefe.
4. **Ecologia/exploracao:** recuperar lugares degradados, reparar estruturas naturais ou cumprir rituais ambientais sem combate.
5. **Misto:** parte das missoes, uma receita e uma tarefa ambiental podem completar o mesmo progresso sem exigir nenhuma rota inteira.

**Gatilho de encontro:** a definicao regional descreve diferentes formas de abrir o encontro (ex.: desafio de combate OU presente culinario OU cadeia de missoes). Nao exigir *todos* os tipos de gatilho quando forem alternativas. Durante o encontro o jogador pode optar por resolver pacificamente, mesmo que tenha aberto o caminho por combate, caso as condicoes correspondentes estejam completas.

**Resolucao:** registrar `resolution_method` como `combat`, `culinary`, `diplomacy`, `restoration` ou `mixed` e `resolved=true`. O estado `boss_defeated` continua disponivel apenas como dado especifico de vitoria por combate, **nao** como exigencia de progresso.

**Amizade regional:** a pacificacao e local, nao global; aumenta receptividade e reduz medo/hostilidade entre slimes nativos e o jogador. Valores serao balanceados depois. Ja deve ser possivel existir afeicao limitada antes do encontro; vencer ou convencer o chefe facilita a confianca, nao a inventa magicamente.

## Exemplos apenas para prototipo do motor (nao canonicos)

| Territorio | Especie nativa | Rota de aventura | Rota pacifica alternativa |
| --- | --- | --- | --- |
| Lago | Gota | Superar uma ameaca hostil que ameaca a agua | Preparar uma refeicao hidratante, restaurar uma nascente ou ajudar o guardiao por missao de NPC |
| Vulcao | Brasinha | Desafiar o chefe ao concluir objetivos de aventura | Cozinhar um prato especial de calor, oferecer X cargas de lava em receptaculos ou resolver uma missao de mineradores |
| Pedreiras | Pedrito | Derrotar X monstros hostis da mina | Preparar comida mineral, consertar marcos rochosos ou negociar com exploradores locais |
| Bosque | Brotinho | Resolver uma ameaca hostil ao bosque | Cultivar ingredientes, cozinhar uma refeicao, reflorestar ou ajudar moradores |

Exemplos nao fixam mapas, narrativa, numero X, boss especifico, receitas finais ou especies adicionais.

## Motor de dados desacoplado dos mapas

Definicao de cada territorio:
- `territory_id`: identificador persistente e unico.
- `native_species_id`: ID existente no bestiario.
- `biome_id` e regras ambientais.
- `boss_id` e regras de apresentacao do encontro.
- `progress_routes[]`: varias rotas independentes, cada qual com `route_id`, `route_type`, `requirements[]` e `completion_condition`.
- `encounter_unlock`: expressao de alternativas (**OR**) e, dentro de cada rota, requisitos combinados (**AND**) quando necessario.
- `resolution_options[]`: metodos aceitos para resolver o encontro sem violencia obrigatoria.
- `boss_encounter_state`: `locked`, `available`, `active` ou `closed`.
- `resolved`, `resolution_method`, `pacified` e modificadores regionais de afinidade.

Eventos previstos (nao implementados):
- `enemy_defeated(enemy_id, territory_id, event_id)` — somente inimigos hostis permitidos, nunca slimes.
- `recipe_prepared(recipe_id, quality, event_id)` e `food_offered(boss_id, recipe_id, quantity, territory_id, event_id)` — validar ingrediente/receita, qualidade opcional e consumo real uma vez.
- `npc_quest_completed(quest_id, territory_id, event_id)` — apenas missao concluida de fato.
- `environment_restored(objective_id, territory_id, event_id)` e `environment_offering(location_id, resource_id, quantity, territory_id, event_id)` — entrega validada.
- `boss_resolved(boss_id, territory_id, resolution_method, event_id)` — um unico fechamento para qualquer caminho; `boss_defeated` e apenas uma das origens opcionais.

## Salvamento e protecoes

- Salvar por slot progresso **separado por territorio, rota e objetivo**, eventos processados, estado do encontro, metodo de resolucao e pacificacao.
- Repetir um evento, recarregar, trocar de mapa ou voltar ao encontro nao duplica recompensas, chefe, progresso nem desconta comida/recursos novamente.
- Objetivos de tipos diferentes nao devem se substituir indevidamente; uma rota pacifica nao depende de mortes ou vitorias em combate.
- Nao sobrescrever saves antigos; definir migracao para territorios ainda inexistentes.
- Instanciar o chefe em local seguro para qualquer rota e permitir sair/retomar um encontro sem perder progresso.
- Nao obrigar violencia por causa do desfecho escolhido; recompensas **funcionalmente equivalentes**, podendo variar em cosmeticos, cenas e dialogos.
- A convivencia dos slimes entre si permanece nao violenta independentemente da rota.

## Testes de aceitacao previstos

- Cada territorio tem exatamente uma especie nativa configurada.
- Um jogador passa por TODA a progressao regional **sem atacar, matar ou derrotar nenhum ser**.
- Uma rota de combate e uma pacifica podem chegar ao mesmo estado `pacified=true`.
- Receitas/outras oferendas exigem ingredientes corretos e nao debitam itens em falhas; entregas repetidas nao contam em dobro.
- Concluir missao de NPC e validar gatilho ambiental liberam encontro de maneira independente.
- Progresso misto funciona, sem bloqueio irreversivel entre rotas.
- O chefe fica disponivel so com os requisitos aplicaveis completos e nao aparece duas vezes.
- O resultado modifica APENAS os slimes do territorio correspondente e sobrevive a salvar/carregar.
- Nenhum slime machuca outro slime; nao existem requisitos de matar slimes.
- Captura, domesticacao e sistemas de cuidado nao sao implementados nesta fase.

## Sequencia de producao

1. **Agora:** finalizar o laboratorio selvagem Wild Ecosystem 1.0, convivencia pacifica, navegacao, animacoes, persistencia e desempenho.
2. **Depois:** construir motor generico de territorios, rotas alternativas, receitas, eventos de NPC, encontro, resolucao e pacificacao em **cena artificial de testes**.
3. **Por ultimo:** desenhar mapa e historia oficiais e inserir objetivos, receitas, dialogos, personagens e chefes reais.

Leituras: [Wild Ecosystem 1.0](wild_ecosystem_1_0.md) e [Roadmap Godot](roadmap_godot.md).
