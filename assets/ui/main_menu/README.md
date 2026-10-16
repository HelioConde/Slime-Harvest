# Imagem do menu inicial

O cenário aprovado (sem slimes, para animação futura) deve ser importado em:

`res://assets/ui/main_menu/vale_encantado.png`

Fonte: wallpaper original gerado para Slimekeepers: Lost Valley, 1672 × 941 px, sem slimes.

A textura é carregada em `scripts/ui/main_menu.gd` pelo nó `ValleyWallpaper`, se existir. `TextureRect.STRETCH_KEEP_ASPECT_COVERED` mantém a tela preenchida, evitando deformar a paisagem. Caso a imagem ainda não tenha sido copiada, aparece um fundo verde temporário sem erro.

O arquivo da imagem é binário e não foi incluído neste commit. Instale-o pelo pacote de assets entregue na conversa. Não altere saves ao instalar.

A primeira versão do menu inclui botões Continuar, Novo jogo, Carregar jogo, Multiplayer (em breve), Opções, Créditos e Sair. A transição para `World.tscn` preserva os saves existentes.

Para preparar multiplayer corretamente no futuro, criar um gerenciador de sessão e saves por usuário/mundo antes de ativar o botão. Não misturar dados entre partidas locais e sessões de rede.
