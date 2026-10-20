# Colecao Sprout Lands para Godot

A colecao oficial https://itch.io/c/4596914/-plugins-for-the-sprout-lands possui 2 plugins:
- Sprout Lands UI Godot Plugin 0.2.0
- Sprout Lands TileMap Godot Plugin 0.2.0

## Instalar os quatro arquivos ZIP

1. Atualize a copia local do repositorio.
2. Abra um terminal na pasta que contem project.godot.
3. Execute (ajuste os caminhos de acordo com a sua pasta Downloads):

~~~powershell
py -3 tools/install_sprout_collection.py "C:\Downloads\Sprout Lands - UI Pack - Basic pack.zip" "C:\Downloads\Sprout Lands - Sprites - Basic pack.zip" "C:\Downloads\Sprout-Lands-UI-0.2.0.zip" "C:\Downloads\Sprout-Lands-Tilemap-0.2.0.zip"
~~~

Acrescente --dry-run para conferir sem gravar nada. Use --replace somente
quando quiser substituir instalacoes locais que tenham sido personalizadas.

Os arquivos sao extraidos em:
- assets/ui/sprout_lands/ — tema Godot ja usado no jogo.
- assets/sprout_lands/ui_pack/ — conteudo completo do UI Basic.
- assets/sprout_lands/sprites/ — conteudo completo do Sprites Basic.
- addons/sprout_lands_ui/ — plugin Godot UI, completo.
- addons/sprout_lands_tilemap/ — plugin TileMap, base e exemplos.

Arquivos .import sao regenerados pelo Godot. O projeto nao habilita
plugins automaticamente, nao altera project.godot, World.tscn nem os saves.

## Teste no Godot

Abra scenes/world/SproutShowcase.tscn e pressione F6.
A galeria mostra 16 categorias de sprites com setas esquerda/direita,
ou com os botoes na interface. TAB oculta a galeria para visualizar o
mapa-exemplo do addon TileMap.

Para criar outro mapa sem mexer no World, instancie:
res://addons/sprout_lands_tilemap/base/scenes/sprout_lands_tile_map.tscn

Exemplo completo:
res://addons/sprout_lands_tilemap/examples/scenes/harvest_hill_example.tscn

Os sprites estao disponiveis no FileSystem do Godot: personagens, galinhas,
vacas, ninho, ferramentas, plantas, decoracoes, moveis, baus, pontes,
caminhos, grama, cercas, casas, agua e terra arada.

A instalacao desses arquivos NAO implementa automaticamente mecanicas
de animais, economia, NPCs, inventario novo nem climas. Integracoes no
World serao feitas separadamente para preservar mapas e saves existentes.

## Licenca e atribucao

Arte Sprout Lands: Cup Nooble — https://cupnooble.itch.io/
Plugins (codigo): Maaack / Marek Belski, sob MIT.

O Basic Pack publica restricao de uso comercial. O usuario informou
possuir permissao de uso comercial e forneceu licenca Premium, que permite
jogos comerciais e projetos abertos, exige credito a Cup Nooble, e
proibe redistribuir o pack de assets separadamente. Guarde a
documentacao da licenca e nao publique os arquivos originais dos packs.
Os diretorios de arte e addons sao ignorados no repositorio publico;
o codigo de integracao e testes nao incluem texturas de terceiros.
