# Interface Sprout Lands (Godot 4)

O projeto pode usar as artes do **Sprout Lands - UI Pack - Basic Pack** e o tema
`sprout_lands_theme.tres` do addon **Sprout-Lands-UI-0.2.0**.

## Instalar no computador

1. Baixe/tenha os dois ZIPs originais, sem necessidade de descompactar.
2. Abra a pasta do repositorio onde esta `project.godot`.
3. Execute no PowerShell (ajuste os dois caminhos de acordo com a pasta Downloads):

```powershell
py -3 tools/install_sprout_ui.py "C:\Downloads\Sprout Lands - UI Pack - Basic pack.zip" "C:\Downloads\Sprout-Lands-UI-0.2.0.zip"
```

4. Abra o `project.godot` no Godot 4 e aguarde a importacao dos PNGs.
5. Inicie pelo F5; verifique a hotbar, a janela de configuracoes (F10)
   e as janelas do menu principal.

O instalador salva os arquivos em `assets/ui/sprout_lands/`, incluindo um
`sprout_theme.tres` cuja textura aponta para `ui_atlas.png`. Ele nao altera
cenas, saves ou arquivos originais dos ZIPs.

Para conferir sem escrever nada:

```powershell
py -3 tools/install_sprout_ui.py "CAMINHO\UI Pack.zip" "CAMINHO\Sprout-Lands-UI-0.2.0.zip" --dry-run
```

O importador recusa substituir assets locais diferentes. Use `--replace`
somente se quiser atualizar a instalacao existente.

## O que esta conectado

- **Menu inicial:** usa o tema Sprout para o estilo de botoes comuns e formularios;
  os sprites personalizados de madeira continuam tendo prioridade.
- **Hotbar:** moldura e estados normais/hover/selecionado usam o tema, mantendo
  os dez slots, icones de ferramentas, quantidades e atalhos.
- **Configuracoes:** janela e componentes do menu em jogo passam a usar o tema.
- **Calendario:** moldura do indicador de dia usa o tema.
- **Sprites auxiliares:** atlas de inventario, blocos, clima, emotes, icones,
  caixa de dialogo e controles sao instalados para futuros menus e sistemas.
  Esses assets auxiliares ainda nao significam que mecanicas de clima, dialogo
  ou novo inventario estejam implementadas.

Se o pacote nao for instalado, **todas as telas continuam com os estilos
anteriores**, sem referencias quebradas.

## Licenciamento

Arte original: **Cup Nooble / Sprout Lands**.
Tema Godot: **Maaack / Sprout-Lands-UI** (veja a licenca do addon).

O pacote basico distribuido publicamente traz restricoes de uso comercial e
de redistribuicao. O titular deste projeto informou possuir autorizacao
para uso comercial; essa autorizacao deve ser conservada junto a documentacao
do projeto. Isso nao implica automaticamente o direito de publicar os PNGs
originais em um repositorio publico. Por esse motivo o diretorio de sprites
instalados e ignorado pelo Git. Verifique as condicoes especificas da
sua permissao antes de distribuir assets individualmente.

## Remover/voltar ao visual antigo

Feche o Godot e remova `assets/ui/sprout_lands/`; os scripts detectam a ausencia
do tema e usam os estilos locais anteriores. Nenhum save precisa ser apagado.
