
# Refinamento das cinco mecanicas — Godot 4.7.1

Nao foi criado nenhum sprite, tileset nem sprite sheet novo. Os efeitos reaproveitam pequenos recortes das texturas originais; sons de madeira e pedra sao sintetizados brevemente na memoria.

## Movimentacao e golpes

- Movimento mais suave com aceleracao (680) e desaceleracao (950) configuraveis no script do jogador.
- Machado, picareta, regador e enxada aplicam seu efeito no quadro de impacto da animacao original, evitando dano antecipado.
- Impacto valido provoca vibracao leve da camera, som e fragmentos feitos de pixels do sprite original.
- O click e a tecla F continuam funcionando; a roda do mouse alterna os dez slots da hotbar.

## Arvores e tocos

- Arvore: cinco golpes; toco: tres golpes; a arvore cai e cada etapa gera um tronco no chao.
- Golpes parciais sao salvos para o mundo persistente, migrando os saves antigos de derrubada das versoes 1 e 2 para a versao 3.
- Numero discreto de golpes restantes aparece por alguns instantes.
- Macieiras usam seus quadros falling; arvores estaticas usam a rotacao da propria arte original; a arvore generica usa a animacao de queda ja existente.

## Pedras

- Reducao do nivel visual apos cada golpe, com pequenas lascas e som proprio.
- Pedras grandes geram large_stone; a cena rock_small agora gera small_stone com icone da celula 12 do atlas ja existente.
- A contagem do material pequeno aparece na notificacao de coleta; mochila visual para materiais adicionais continua pendente.

## Coleta e flores

- Drops executam um salto/pouso usando seu sprite real.
- Atracao gradual num raio de 72 px, com 0,3 s de atraso e coleta a 12 px. Obstaculos fisicos no layer World impedem que o item atravesse a parede.
- Clique em flores ou cogumelos os transforma em drops no chao, sem creditar imediatamente o inventario.
- Flores e cogumelos persistentes reaparecem apos 6 dias do calendario (regrow_days configuravel de 0 a 30; zero desliga regeneracao). Uma planta ja colhida permanece oculta ate seu dia de retorno.
- O mapa de testes continua simplificado e nao altera o mapa principal.

## Hotbar

- O nome do item aparece sobre a barra; P mostra Picareta, mesmo sem ocupar slot original.
- Troca por roda do mouse, atalhos 1-0 e cliques continua disponivel.
- Quantidades grandes sao apresentadas como 999+, evitando extrapolar slots.

## Testes

A pipeline GitHub Actions valida importacao, abertura do mundo e cenas, e executa os testes ResourceGameplayTest e PolishGameplayTest com Godot 4.7.1. Abrange frame de impacto, golpes de arvore e toco, migracao de persistencia parcial, drops, magnetismo atras de paredes, diferencia de material, coleta de flor/cogumelo e regeneracao de planta.

## Ajustes

- scripts/player/player.gd: move_acceleration, move_deceleration, tool_animation_speed, tool_reach.
- scripts/items/resource_drop.gd: magnet_radius, pickup_radius, magnet_speed, pickup_delay.
- scripts/farming/plant_growth.gd: regrow_days.
- scripts/trees/choppable_tree.gd e scripts/trees/choppable_stump.gd: axe_hits_required.
- scripts/rocks/mineable_rock.gd: static_hits, drop_item_id.

Ainda pendentes: testes visuais locais nas varias especies, mochila arrastavel, persistencia total de mundo e sons personalizados caso haja trilha de audio disponivel.
