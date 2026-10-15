# Protótipo de cultivo — Slimekeepers: Lost Valley

Cena principal: `scenes/world/World.tscn`. Sistema: `scripts/farming/farm_field.gd` e `scenes/farming/FarmField.tscn`.

## Primeiro ciclo jogável

1. Ande até o **canteiro de terra** no centro inferior do mapa (10 colunas × 7 linhas). Posicione-se perto da célula.
2. Aperte **1** e use **F** para preparar o solo.
3. Aperte **2** e use **F** sobre a mesma célula para plantar (começa com 12 sementes).
4. Aperte **3** e use **F** para regar. As plantas avançam uma etapa a cada **12 segundos**, enquanto regadas.
5. Após três etapas (aproximadamente 36 segundos), aperte **4** e use **F** para colher. A colheita devolve 1 semente.
6. Complete o objetivo de **3 colheitas** mostrado no HUD.

WASD/setas andam; Shift corre. O uso de ferramentas reaproveita o sinal `tool_use_requested` do Player e seu cooldown existente. Não há venda ou moeda nesta etapa.

## Persistência

Os canteiros, sementes e quantidade colhida são salvos automaticamente em `user://slimekeepers_farm_v1.json`. O save é separado do teste de casas (`user://house_terrain_test.json`). Limpar esse arquivo reinicia somente o cultivo.

## Testes locais pendentes

- Pressionar F dentro e fora do canteiro; validar alinhamento de 32 px e alcance do Player.
- Garantir que não seja possível plantar sem preparar, regar sem plantar ou colher antes de amadurecer.
- Trocar 1–4 durante o jogo, fechar e abrir de novo e verificar persistência.
- Validar a renderização dos canteiros, HUD e compatibilidade com os sprites existentes em Godot 4.x.
- Confirmar que `world2.tscn` e a construção da casa continuam funcionando sem mudanças.

Este é um protótipo: o visual de sementes, brotos e colheitas é desenhado por código para validar diversão e feedback antes dos sprites definitivos.
