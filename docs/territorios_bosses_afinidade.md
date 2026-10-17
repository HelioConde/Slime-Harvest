# Territorios, chefes regionais e amizade — especificacao de design (Godot 2D)

> **Estado: design aprovado para planejamento, NAO implementado.**
> Esta especificacao nao autoriza iniciar o desenho do mapa definitivo, a historia, a captura ou domesticacao agora.
> Primeiro estabilizar o sistema Wild Ecosystem 1.0 e seus testes.

## Regra principal

1. Cada territorio tem **uma especie nativa de slime**, com habitat, necessidade ambiental e temperamento proprios.
2. A regiao comeca com slimes selvagens **mais cautelosos, desconfiados ou defensivos**.
3. O chefe regional so aparece quando o jogador cumpre **condicoes ligadas ao ambiente** daquele territorio.
4. O chefe so pode ser considerado derrotado mediante um evento de combate/objetivo registrado pelo sistema.
5. **Depois de derrotar o chefe**, os slimes nativos daquele territorio ficam mais amigaveis, se aproximam com mais facilidade e aceitam melhor futuros sistemas de amizade.
6. O resultado e **local**: libertar um territorio nao altera os slimes de outro.
7. **Slimes nao lutam entre si.** Criaturas selvagens podem reagir/atacar o jogador segundo seu temperamento, mas nunca atacam outros slimes. Quando uma condicao exigir derrotar X monstros, trata-se de **inimigos hostis especificos**, nao dos slimes pacificos do bioma.
8. Aumentar a facilidade de amizade **nao significa domesticar, capturar ou adicionar o slime ao inventario**. Essas mecanicas permanecem adiadas.

## Ciclo de um territorio

`selvagem_bloqueado` -> `condicao_ambiental_cumprida` -> `chefe_ativo` -> `chefe_derrotado` -> `regiao_pacificada`

- **Selvagem bloqueado:** a condicao de aparecimento do chefe ainda nao foi completada; slimes podem fugir, observar ou defender o habitat.
- **Condicao cumprida:** o sistema confirma os objetivos e autoriza o surgimento do chefe em um local seguro e determinado.
- **Chefe ativo:** o chefe regional esta presente; se o jogador sair, retomar sem duplicar o chefe ou perder progresso.
- **Chefe derrotado:** registrar derrota uma unica vez e emitir um evento local.
- **Regiao pacificada:** aplicar o modificador de comportamento/afinidade somente aos slimes da especie nativa do territorio.

*Importante:* a convivencia amigavel **antes** da derrota nao precisa ser impossivel; a derrota reduz a desconfiança e a dificuldade de criar laços. Os valores numericos serao balanceados e testados em uma etapa futura.

## Exemplos de condicoes ambientais (ilustrativos; X ainda a definir)

| Exemplo de territorio | Especie nativa | Condicao para fazer aparecer o chefe | Transformacao apos o chefe |
| --- | --- | --- | --- |
| Margens do lago | Gota | Restaurar X pontos de agua / concluir um evento aquatico | Gotas mais confiantes na presenca do jogador |
| Vulcao | Brasinha | Entregar ou lancar X cargas de lava em pontos especificos do vulcao | Brasinhas menos hostis e mais receptivos |
| Pedreiras | Pedrito | Derrotar X monstros **hostis** das minas ou reativar marcos rochosos | Pedritos reduzem a defesa territorial |
| Bosque | Brotinho | Recuperar X pontos de vegetacao ou resolver uma anomalia ambiental | Brotinhos se aproximam com maior frequencia |

Esses exemplos **nao** definem o mapa, o enredo, os nomes oficiais de chefes nem as quantidades definitivas. Sao exemplos para validar o motor de objetivos.

## Requisitos de arquitetura antes de criar os mapas

### Dados independentes do mapa

Uma definicao de territorio devera ter, no minimo:
- `territory_id` estavel e unico.
- `native_species_id` existente no bestiario.
- `biome_id`/regras de habitat e limites fisicos.
- `boss_id` e regras de spawn/despawn seguro.
- Uma lista de `trigger_requirements` baseada em eventos validados, com alvos configuraveis.
- `state` do territorio e seu `pacified` booleano derivado do estado.
- Multiplicadores configuraveis de confianca/amistosidade **antes/depois**, sem alterar o temperamento de todos os slimes do jogo.

### Eventos que o motor devera suportar

- `enemy_defeated(enemy_type, territory_id)`: conta **somente** inimigos hostis autorizados no territorio, sem duplicacao de mortes.
- `environment_offering(altar_or_location_id, resource_id, quantity, territory_id)`: valida a entrega/uso ambiental (ex.: lava), descontando recurso apenas quando o evento realmente acontecer.
- `environment_restored(objective_id, territory_id)`: objetivo ambiental concluido e confirmado.
- `boss_defeated(boss_id, territory_id)`: registra o fim do encontro uma vez e ativa a pacificacao.

### Persistencia e consistencia

- Salvar por slot: `territory_id`, progresso validado dos gatilhos, estado atual, encontro ativo/encerrado e chefe derrotado.
- Mudanca de mapa, pausa, derrota do jogador, fechamento e recarregamento **nao podem duplicar** chefes, itens oferecidos ou progresso.
- Contadores nunca ultrapassam a meta e nao contam mortes/eventos de territorios diferentes.
- O chefe nao deve nascer dentro de casa, parede, lago nao navegavel ou objetos.
- Atualizacao de versao devera aceitar territorios ainda inexistentes em saves antigos.

### Comportamento selvagem apos a pacificacao

- Permanece selvagem e com sua necessidade de agua, minerais, plantas etc.
- Reacoes ao jogador tornam-se menos hostis/medrosas de forma **regional**.
- Estados de percepcao, fuga, curiosidade e afeto continuam baseados na especie e na situacao.
- A futura facilidade de amizade usa o modificador regional; nao liberar automaticamente captura, inventario, tarefas ou cuidados.
- Slimes continuam com convivencia pacifica entre si.

## Testes de aceitacao futuros

- Uma especie nativa por territorio; perfis nao se misturam indevidamente.
- Cada tipo de gatilho funciona com quantidades configuraveis e objetivo corretamente filtrado por territorio.
- O chefe nao surge antes de **todas** as condicoes obrigatorias.
- O chefe surge **uma unica vez** quando elas sao satisfeitas; eventos repetidos nao criam duplicatas.
- Chefe ativo e progresso restaurados apos salvar/carregar; derrotar ativa a pacificacao de apenas uma regiao.
- Reducao demonstravel da hostilidade/fuga e maior abertura a amizade **apos** a pacificacao, respeitando necessidades vitais.
- Nenhuma luta entre slimes e nenhum objetivo exige matar slimes.
- Sem captura, domesticacao ou cuidados do jogador nesta fase tecnica.

## Sequencia de desenvolvimento

1. **Agora:** concluir Wild Ecosystem 1.0, interacoes pacificas, navegacao e persistencia de vida selvagem.
2. **Antes dos mapas:** construir/testar motor generico de territorio, eventos, chefes e pacificacao em uma **cena artificial de teste**, sem lore.
3. **Depois de aprovar o motor:** desenhar mapa definitivo e historia e preencher definicoes concretas de regioes, monstros hostis e chefes.

Documentos relacionados: [Wild Ecosystem 1.0](wild_ecosystem_1_0.md), [Roadmap Godot](roadmap_godot.md).
