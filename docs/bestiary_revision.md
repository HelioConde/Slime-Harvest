# Revisão 2 — movimentos de trabalho e margem dos efeitos

Mantidos os 32 personagens, os nomes das 788 animações, 9.456 quadros de 64 × 64 e o pivô (30,53).

## Movimentos revisados

| Espécie / animação | Quadros distintos antes | Agora, entre 12 |
| --- | ---: | ---: |
| ferrito / perfurar | 2 | 12 |
| guardito / defender | 3 | 12 |
| carreguim / carregar | 6 | 11 |
| construlim / levantar_parede | 8 | 12 |
| construlim / work_loop | 8 | 10 |
| construlim / attack | 7 | 12 |

- Ferrito: antecipação, avanço e rotação da broca, esforço do corpo, rachadura e fragmentos no contato; extração com recuo e elevação do minério.
- Guardito: escudo avança, corpo se firma, impacto comprime e desloca o slime e a postura se recupera; ataque com investida corporal.
- Carreguim: corpo baixo sob a carga, duas caixas oscilando com atraso, passos curtos, esforço; pegar e entregar conectam a carga ao corpo. O ataque mantém a caixa e usa o peso do corpo. Sua contagem passa de 11 para 9 quadros distintos: retenções são deliberadas, não foi adicionada variação só para aumentar o número.
- Construlim: três colocações sucessivas de tijolos na ação levantar_parede; work_loop mantém a parede pronta e trabalha a argamassa. levantar_parede passa a ser execução única. Ataque ergue a parede, empurra e fragmenta os tijolos.
- Terrinho: preparação da escavação, ferramenta penetrando o solo e terra retirada em arco.
- Brotinho: abrir o baú, absorver sementes e colocar uma semente no solo têm ações próprias. Plantar não faz a muda crescer instantaneamente.
- Colhita e Pomelo: trajetória de frutos com margem para folhas e impacto. Também revisados partículas de Raizela, halo de Lumito, jatos de água, raio de Prismita, bolhas de Riacho e outras ocorrências detectadas.

## Verificação objetiva

- Antes: 166 quadros com pixels dentro da faixa de dois pixels das bordas. Agora: zero, nos 9.456 quadros. As linhas/colunas 0, 1, 62 e 63 estão transparentes.
- O renderizador também registra tentativas de desenhar fora do quadro antes do recorte: zero nesta revisão. A margem não foi obtida apagando pixels das bordas.
- As 32 fontes Aseprite foram abertas e exportadas pelo Aseprite; quadros, cinco camadas, tags e PNGs foram comparados. Os PNGs entregues usam a composição nativa do Aseprite.
- A auditoria completa de quadros distintos, limites e sequências idênticas está em auditoria-animacoes.json.
- Permanecem 135 sequências reutilizadas dentro da mesma espécie. O número não representa ações independentes desenhadas do zero. Aliases como work_loop/regar e happy/receber_carinho são mantidos para a integração. A lista exata consta da auditoria.
- A inspeção inclui sequências visuais e carregamento/reprodução das cenas isoladas no Godot. Não é um teste completo de gameplay.

## Gota e integração com combate

O jato tem preparação, emissão nos quadros 3–9 (índices 2–8) e recuperação nos quadros 10–12. A largura foi reduzida para manter respingos dentro do quadro. Esses números descrevem o efeito visual, não uma hitbox.

As cenas atuais não possuem detecção de colisão, dano ou impacto ligado a alvos. Essa sincronização continua pendente e deve usar os eventos reais de colisão do jogo; não foi simulada como se estivesse implementada. Trabalho, inventário e IA também continuam fora deste pacote visual.

## Conferir

Abra visualizar.html e selecione espécie/ação; pause para inspecionar cada quadro. revisao-movimentos.png mostra as sequências completas. revisao-trabalhos.gif é uma prévia em repetição (inclusive da construção, cuja ação real é única).

No Godot: res://scenes/slimes/bestiary/BestiaryPreview.tscn, F6. Todas as espécies continuam em cenas separadas. O mapa e o personagem principal não são alterados.
