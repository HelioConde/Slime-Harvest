# Player pronto para sprites

Abra scenes/player/Player.tscn e execute com F6 (ou F5, cena principal).
WASD/setas: andar. Shift: correr. E: interagir. F: sinal de uso de ferramenta.
Sem frames, um retângulo verde permite testar movimentação. Não é o sprite final.

## Adicionar arte

1. Selecione AnimatedSprite2D e abra Sprite Frames no Inspector.
2. Preencha idle_down, idle_up, idle_left e idle_right com os frames correspondentes.
3. Preencha walk_down, walk_up, walk_left e walk_right.
4. run_* é opcional: sem esses frames, walk_* acelera durante a corrida.
5. Use Adicionar frames de uma folha de sprites, selecione o spritesheet e ajuste a grade conforme o tamanho real de cada frame. Não há recorte automático: a folha existente não teve seu layout presumido.
6. Para sprites de 32x32, a posição (0, -16) alinha os pés à origem. Para outros tamanhos, ajuste a posição de AnimatedSprite2D e o retângulo de colisão nos pés.

Sem idle_*, o primeiro frame de walk_* fica parado. Sem frames à esquerda, walk_right/idle_right são espelhados. Não renomeie as animações usadas pelo script.

## Componentes

- CharacterBody2D: movimento top-down, diagonal normalizada, parada imediata.
- CollisionShape2D: colisão nos pés; layer Player, mask World.
- Camera2D: segue o jogador com suavização, zoom editável.
- InteractionRay: alcance 24 px na direção cardinal; consulta layer Interactable.
- ToolOrigin: origem de ferramentas, 16 px à frente.

Crie objetos interativos na layer 3 com colisão e método interact(player). O raio seleciona o primeiro objeto encontrado. Ferramentas ainda não cultivam: tool_use_requested(origin, direction) é o ponto de conexão para o próximo sistema. Cooldown evita disparos repetidos.

Para menus/diálogos, use set_controls_enabled(false); ao fechar, true.
Ajuste walk_speed, run_multiplier e tool_cooldown no Inspector.

## Validação

Sintaxe do controlador validada com gdparse (gdtoolkit). Revisão estrutural das referências, Input Map e animações. Execução Godot não disponível no ambiente de edição remoto; validar localmente F6, oito direções, corrida, paredes na layer 1 e frames adicionados.
