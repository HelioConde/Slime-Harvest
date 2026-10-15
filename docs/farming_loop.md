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


## Crescimento em dias de jogo

- O autoload `GameCalendar` controla o dia global: por padrao 10 minutos reais de jogo aberto por dia (`seconds_per_day = 600`).
- Flor, cogumelo e grama com animacoes `level1`, `level2` etc. avancam uma fase a cada **3 dias de jogo** e param na ultima fase disponivel.
- A mudanca de fase tem transicao suave de escala/opacidade. As cenas originais e imagens permanecem intactas.
- O progresso de cada planta colocada no mundo e salvo em `user://slimekeepers_calendar_v1.json`, junto com dia e tempo parcial; nao avanca com o jogo fechado.
- Em execucao de debug, pressione **F9** para adiantar um dia. Teste com **F6** na cena `scenes/farming/GrowthPreview.tscn`.
- Para adicionar uma planta ao mapa, instancie a cena da flor ou cogumelo no editor. Para replantar a mesma planta por codigo, chame `replant_today()`.
- O canteiro experimental `FarmField` tambem avanca 1 fase a cada 3 dias de jogo apos a rega; as plantas usam as cenas reais das flores.
- Saves antigos do canteiro (versao 1) sao convertidos para o sistema de dias sem apagar as colheitas.
