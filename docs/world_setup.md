# Mundo inicial — Slime Harvest

Abra scenes/world/World.tscn ou pressione F5. O Player foi validado pelo usuário; suas animações e seu script foram preservados. A cena player2teste foi removida.

Mapa fixo de 1280 × 960, com gramado, caminhos, lago bloqueado, árvores e pedras com colisão, área de solo e profundidade por Y. Os desenhos são provisórios, sem dependência de um tileset. As árvores colidem somente na base. A câmera mantém zoom 1 e nenhuma suavização, com viewport 640 × 360 ampliado para 1280 × 720.

WASD/setas: mover. Shift: correr. O campo ainda não planta nem rega; E/F continuam usando os sinais do Player.

Validação desta etapa: conferir sintaxe e referências antes do commit. Execução no Godot deve ser conferida localmente: F5, movimentar nas quatro direções, correr, testar colisão com lago/árvores/limites e sobreposição atrás das copas.

Próxima etapa: tileset definitivo e interação com células do campo para preparo, plantio e rega.
