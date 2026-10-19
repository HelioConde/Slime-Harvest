# Wild Ecosystem 1.0 — congelamento da fundacao do mundo selvagem

Escopo: Godot 2D. **Nao inclui captura, domesticacao, cuidado pelo jogador, mapa definitivo ou historia.**

## Regra permanente de design

**Nao ha luta entre slimes.** Nenhum slime selvagem ataca, fere, persegue para combate ou mata outro slime. Diferencas de temperamento produzem apenas brincadeiras, curiosidade, amizade, ajuda ou afastamento pacifico. O combate selvagem existente tem como alvo exclusivamente o jogador. Nao introduzir predacao, ataques entre especies ou disputas violentas em etapas futuras.

## Progressao futura que deve orientar esta fundacao

Cada territorio tera **uma especie nativa** e um chefe regional. O jogador podera liberar o encontro e pacificar a regiao por **rotas alternativas equivalentes**: lutar (opcional), cozinhar e oferecer pratos ao chefe, concluir missoes de NPCs, restaurar o ambiente ou combinar essas atividades. **Nenhuma rota pacifica pode exigir matar ou derrotar seres.** Apos **pacificar** o chefe por qualquer caminho, os slimes daquele territorio ficam mais receptivos a amizade, sem deixar de ser selvagens. **Slimes nao lutam entre si**; monstros hostis de objetivos opcionais de combate nao sao slimes.

O motor de objetivos, culinaria, eventos de NPCs, encontros, resolucoes pacificas e pacificacao sera desenvolvido/testado em cena artificial **depois** de estabilizar o Wild Ecosystem 1.0, mas **antes** de construir o mapa definitivo e a historia. Nao implementar captura ou domesticacao agora.

Ver [Especificacao de territorios e amizade](territorios_bosses_afinidade.md).

## Estado e criterios de aceite

| Area | Estado | Criterio de conclusao |
| --- | --- | --- |
| P0 — Colisoes e mundo | Testes automatizados passando; QA visual pendente | Sem paredes invisiveis, atravessar agua exposta, atravessar objetos ou ficar preso |
| P1 — Navegacao | Recalculo sob obstrucao e testes automatizados implementados; QA de trajetos longos pendente | Rotas validas em diferentes layouts e sem repeticao infinita de destinos inacessiveis |
| P2 — Necessidades | 32 perfis e revalidacao da fonte antes de absorver; balanceamento pendente | Absorver apenas recursos acessiveis existentes, descanso e fadiga consistentes |
| P3 — Relacoes pacificas entre slimes | Parcial: visitas espontaneas, curiosidade, brincadeira e respeito ao espaco testados | Afinidades duradouras, ajuda e convivencia em grupos ainda pendentes |
| P4 — Combate | Reacoes e dano basico testados; sistema de projeteis reais pendente | Ataque com telegráfico, colisoes, cooldown, escalonamento e defesa previsivel |
| P5 — Populacao | Geracao inicial testada; ciclo de vida persistente pendente | Densidade controlada, desaparecimento e reposicao sem duplicatas |
| P6 — Persistencia selvagem | Pendente | Identidade, posicao, energia, morte e respawn coerentes por slot e save legado |
| P7 — Animacoes e sons | Parcial | Quadros coerentes, sem sliding, clipes corretos para os 32 perfis |
| P8 — Desempenho e regressao | Testes headless; QA de longa duracao pendente | 60 FPS no PC de referencia com 32 slimes, 60 min sem falhas graves |

## Conquistas de estabilidade

- `tests/TerrainEdgeTest.tscn` testa agua real exposta e confirma que agua totalmente ocultada pelo gramado nao produz colisoes invisiveis. O teste expoe uma celula **apenas temporariamente em memoria** e restaura a pintura.
- `scripts/slimes/world_population.gd` inclui barreiras fisicas do mundo na grade de navegacao e oferece `invalidate_navigation()` para atualizar a grade quando uma rota bloquear.
- `scripts/slimes/slime_wander.gd` interrompe absorcao quando a fonte nao existe mais; nao recupera energia sem recurso valido.
- `tests/SlimeSurvivalTest.tscn` verifica o desaparecimento da fonte, novos obstaculos e a liberacao da passagem apos sua remocao.
- `tests/SlimeBehaviorTest.tscn` cobre medo, afeicao, curiosidade, ataques com aviso, cooldown, esquiva, linha de visao e prioridade da sobrevivencia.
- `tests/SlimePeerTest.tscn` valida encontros espontaneos e **nao violentos** entre slimes (amizade, brincadeira, curiosidade e afastamento), a ausencia de ataques entre slimes e a prioridade das necessidades vitais.

### Detalhe da camada de agua

No `World.tscn` atual, as 336 celulas da camada `water` tambem estao cobertas por `grass2`. Portanto, a colisao precisa distinguir **agua visualmente exposta** de **agua logica sobreposta por solo**. Criar blocos fisicos em todas as celulas de `water` bloquearia area desenhada como grama. Ao pintar cursos de agua definitivos, atualizar ambas as camadas e revisar os contornos visuais.

## Proximas etapas antes de mapear o jogo definitivo

1. Interacao **slime x slime** sem combate: deteccao, curiosidade, aproximacao, brincadeiras, afinidade, ajuda, coexistencia e afastamento pacifico.
2. Sincronizacao de golpes/efeitos com hitboxes reais; evitar que linhas visuais sejam confundidas com projeteis fisicos.
3. Persistencia do mundo selvagem por slot e testes de migracao/rollback.
4. Ciclo de nascimento/morte natural e equilibrio dos habitats.
5. Testes visuais de 32 especies, performance e sessao prolongada no Windows.
6. Congelar recursos novos e repetir todos os testes antes de marcar **Wild Ecosystem 1.0 = aprovado**.

**Regra de qualidade:** um teste automatizado verde e necessario, mas nao substitui os testes de aparencia, controle e estabilidade no jogo aberto. Nunca declarar o marco 100% antes dos dois tipos de validacao.
