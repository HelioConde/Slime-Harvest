# Slimekeepers: Lost Valley — roadmap da versão Godot 2D

## M0 — Base e identidade
- [x] Nome de exibição atualizado para **Slimekeepers: Lost Valley**.
- [x] Preservar Player, recursos existentes, mapa provisório e construção de casa.
- [x] Implementar primeiro ciclo de cultivo em mapa provisório.
- [x] Restaurar as 64 cenas originais ausentes do catalogo, mantendo texturas e colisoes.
- [x] Criar verificacao automatica de referencias e componentes principais.
- [ ] Validar visualmente/corrigir falhas de execucao no Godot local.

## M1 — Fazendinha jogável
- [ ] Integrar o ciclo de cultivo ao mapa de tiles `World.tscn` sem perder a construção de casas.
- [x] Animar a passagem dos estágios `level1..level4` das flores a cada 3 dias e salvar os dias de jogo.
- [ ] Integrar os canteiros ao novo mapa principal e confirmar as cenas visualmente no Godot.
- [x] Machado corta arvores em **5 golpes**, respeita o balanco antes de cada novo golpe, executa queda sem loop e cria toco persistente (teste visual local pendente).
- [x] Hotbar inferior com 10 slots do spritesheet original, contadores de recursos, grupos, atalhos e persistencia da selecao.
- [x] Árvores de maçã, laranja, pêssego e pera animadas a partir da primeira macieira, com spritesheets próprios.
- [x] Componente de terreno reutilizável e galeria de seis variações usando o TileSet original, sem alterar o mapa principal.
- [x] Sistema de drops e contadores persistentes de troncos, pedras, flores e cogumelos.
- [x] Picareta minerando pedras por nivel, toco removivel em tres golpes e coleta de flores/cogumelos com clique.
- [x] Refinamentos: golpes sincronizados, efeitos com sprites existentes, audio local, magnetismo com parede, movimento suave e progresso parcial de arvore/toco.
- [x] Flores/cogumelos reaparecem apos dias configuraveis e pedras pequenas usam recurso proprio do atlas.
- [ ] Mochila visual completa, energia, moedas e colecoes.
- [ ] Três tipos de cultivos, colheita e venda em um ponto do mapa.
- [ ] Salvar e carregar posição do jogador, mundo, casa e inventário de modo consistente.

## M2 — Companheiro slime
- [ ] Primeiro slime amigável: animações idle/pulo, seguir jogador e vínculo.
- [ ] Alimentação com produtos cultivados, felicidade e recompensas.
- [ ] Habitat e integração à fazenda.

## M3 — Vale
- [ ] Área de exploração, recursos, personagens e pequenos objetivos.
- [ ] Dia/noite, clima e evolução da fazenda.
- [ ] Ajuste de controles, interface e performance.

## Marco tecnico antes de historia e mapa definitivo

- [x] Corrigir o teste de agua oculta, validando a fisica apenas da agua efetivamente exposta.
- [x] Atualizar a navegacao dos slimes quando novos obstaculos surgirem ou forem removidos.
- [x] Impedir absorcao de recursos indisponiveis.
- [ ] Completar relacoes pacificas entre os proprios slimes: curiosidade, brincadeiras, afinidade, ajuda, convivencia e afastamento sem confronto.
- [ ] Testar projeteis e colisao de combate fisico, alem de efeitos visuais.
- [ ] Persistir estados individuais dos slimes nos saves.
- [ ] Concluir simulacao ecologica e limite de populacao por bioma.
- [ ] Aprovar sprites, animacoes, FPS e testes prolongados.

Checklist e criterios de conclusao: [Wild Ecosystem 1.0](wild_ecosystem_1_0.md).

## Organização e escopo

Esta trilha é **Godot 2D**, não a implementação 3D/Roblox existente em outro repositório. Compartilhamos conceito e identidade, mas não portamos recursos entre motores sem adequação.

Prioridade de trabalho: primeiro deixar o jogo **divertido e funcional**, depois ampliar arte e conteúdo.

## Novo sistema no World

- [x] Enxada prepara diretamente grama verde do mapa principal usando TileSet existente e save separado.
- [x] Bloqueio de células ocupadas e margem de segurança da casa inicial.
- [x] Casa inicial possui âncora fixa: não permite mover nem demolir totalmente após posicionar.
- [x] Arbustos, troncos, brotos e tocos decorativos podem ser eliminados usando sprites atuais.
- [ ] Conectar plantio, rega e colheita às células aradas do mapa principal.
- [ ] Expandir interação para novos objetos que forem adicionados futuramente.
