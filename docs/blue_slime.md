# Slime azul — cena independente

Abra scenes/slimes/BlueSlime.tscn. Selecione AnimatedSprite2D e abra Sprite Frames no inspetor: as 20 animacoes ja estao recortadas, nomeadas e com os tempos configurados.

Para testar as acoes em uma janela, abra scenes/slimes/BlueSlimePreview.tscn e pressione F6. Use a lista para escolher uma animacao, pausar ou reiniciar.

O mapa World.tscn e o personagem principal nao foram alterados. O slime nao e instanciado no mundo.

- 240 quadros; celulas 64 x 64; filtragem nearest para pixel art.
- Origem no chao em (30,53) do quadro.
- Acoes direcionais voltadas para a direita.
- Recurso compartilhado: assets/slimes/blue/blue_slime_frames.tres.
- Fonte editavel: assets/slimes/blue/slime-azul-fofo.aseprite.
- Cena base sem scripts, colisao ou IA: apenas a arte animada.
- As animacoes de rega, ataque e procura sao visuais; nao executam acoes no jogo.

Em GDScript: $BlueSlime/AnimatedSprite2D.play(&"regar")

| Tag | Animacao | Repeticao |
|---|---|---|
| idle | Idle | Continua |
| idle_feliz | Idle feliz | Continua |
| piscar | Piscar | Uma vez |
| saltar_mover | Saltar / mover | Continua |
| aterrissar | Aterrissar | Uma vez |
| seguir_jogador | Seguir jogador | Continua |
| procurar_planta | Procurar planta | Continua |
| preparar_rega | Preparar rega | Uma vez |
| regar | Regar | Continua |
| regar_area | Regar em área | Continua |
| recarregar_agua | Recarregar água | Continua |
| cansado | Cansado | Continua |
| dormir | Dormir | Continua |
| acordar | Acordar | Uma vez |
| comemorar | Comemorar | Uma vez |
| receber_carinho | Receber carinho | Continua |
| atacar_jato_agua | Atacar com jato de água | Uma vez |
| irritado | Irritado | Continua |
| acertado_recuo | Acertado / recuo | Uma vez |
| derrotado_dissipar | Derrotado / dissipar | Uma vez |
