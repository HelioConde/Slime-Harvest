# Menu de fazenda — Godot 4.7.1

O menu no GitHub ja seleciona automaticamente a arte em camadas, quando os PNGs forem importados pelo Godot.

## Instalar a arte

1. Em C:\FarmSlime, execute git pull --ff-only origin main (depois de verificar git status).
2. Extraia Slimekeepers_Menu_Fazenda_Godot.zip na **raiz** C:\FarmSlime — o ZIP ja contem assets/ui/main_menu/.
3. Abra Godot e aguarde importar as texturas. Pressione F5 para testar o novo fundo e os botoes.
4. Publique as artes: git add assets/ui/main_menu e git commit -m "feat(menu): sprites de fazenda" e git push origin main.

Arquivos principais: fazenda_wallpaper.png (1672x941, sem slimes), farm_logo.png, farm_frame.png, btn_*.png (normal, hover, pressed, disabled), wood_*.png para botoes traduziveis depois. As fotos geradas sao independentes dos scripts e dos saves.

Se as artes nao estiverem presentes, o menu usa a paisagem anterior e controles de texto como fallback. Nenhum recurso user:// e alterado pela instalacao. A interface tem uma camada SlimeAnimationLayer vazia para animar slimes posteriormente.

O botao Multiplayer fica desativado ate existir sistema de sessoes, autoridade de rede e saves por mundo/personagem. Novo jogo nao sobrescreve a fazenda legada; existe apenas um save ate a implementacao dos tres espacos independentes.

Aviso: sprites btn_*.png contem texto PT-BR pintado na imagem; futuros idiomas devem usar as variantes wood_* sem letras com Label/Text overlay.
