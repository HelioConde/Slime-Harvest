# Mundo inicial — Slimekeepers: Lost Valley

Abra scenes/world/World.tscn ou pressione F5. O Player foi validado pelo usuário; suas animações e seu script foram preservados. A cena player2teste foi removida.

Mapa fixo de 1280 × 960, com gramado, caminhos, lago bloqueado, árvores e pedras com colisão, área de solo e profundidade por Y. Os desenhos são provisórios, sem dependência de um tileset. As árvores colidem somente na base. A câmera mantém zoom 1 e nenhuma suavização, com viewport 640 × 360 ampliado para 1280 × 720.

WASD/setas: mover. Shift: correr. O campo 10×7 agora oferece um ciclo de cultivo experimental: 1–4 selecionam ferramenta e F usa a ferramenta na célula à frente do Player. E continua reservado para interação. Detalhes em [farming_loop.md](farming_loop.md).

Validação desta etapa: conferir sintaxe e referências antes do commit. Execução no Godot deve ser conferida localmente: F5, movimentar nas quatro direções, correr, testar colisão com lago/árvores/limites e sobreposição atrás das copas.

Próxima etapa: testes locais no Godot, trocar os desenhos de crescimento por sprites e conectar inventário/economia. O construtor de casa permanece no cenário independente world2.tscn.
