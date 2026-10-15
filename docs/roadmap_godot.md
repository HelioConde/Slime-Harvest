# Slimekeepers: Lost Valley — roadmap da versão Godot 2D

## M0 — Base e identidade
- [x] Nome de exibição atualizado para **Slimekeepers: Lost Valley**.
- [x] Preservar Player, recursos existentes, mapa provisório e construção de casa.
- [x] Implementar primeiro ciclo de cultivo em mapa provisório.
- [ ] Validar visualmente/corrigir falhas de execução no Godot local.

## M1 — Fazendinha jogável
- [ ] Integrar o ciclo de cultivo ao mapa de tiles `World.tscn` sem perder a construção de casas.
- [x] Animar a passagem dos estágios `level1..level4` das flores a cada 3 dias e salvar os dias de jogo.
- [ ] Integrar os canteiros ao novo mapa principal e confirmar as cenas visualmente no Godot.
- [ ] Inventário, ferramentas acessíveis, energia e moedas.
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

## Organização e escopo

Esta trilha é **Godot 2D**, não a implementação 3D/Roblox existente em outro repositório. Compartilhamos conceito e identidade, mas não portamos recursos entre motores sem adequação.

Prioridade de trabalho: primeiro deixar o jogo **divertido e funcional**, depois ampliar arte e conteúdo.
