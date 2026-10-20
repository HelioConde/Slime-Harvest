# Sprout Sorry — protagonista padrao

O personagem escolhido para **novas fazendas** e o humano de cabelo castanho
do arquivo original:
`Sprout Sorry pack/Tests/free_character_spritesheet_by-cupnooble.png`.

Dimensoes verificadas: atlas **128x96**, grade **8 colunas x 3 linhas**,
celulas **16x32**. As colunas sao as oito orientacoes e cada linha uma
pose. O motor atual utiliza quatro orientacoes (cima, baixo, esquerda e
direita) e monta 28 animacoes para compatibilidade com o controlador Player.

## Instalar no seu projeto (sem publicar o PNG)

Na pasta que contem `project.godot`, execute:

```powershell
py -3 tools/install_sprout_sorry.py "C:\Downloads\Sprout Sorry pack.zip"
```

Substitua o caminho pelo ZIP que voce ja possui. Se preferir, copie o
PNG manualmente para:
`assets/Characters/sprout_sorry/free_character_spritesheet_by-cupnooble.png`.

O importador valida assinatura PNG e dimensoes, nao substitui um arquivo
diferente sem `--replace`, e aceita `--dry-run`. O diretorio esta no
`.gitignore` para proteger os arquivos licenciados.

## No Godot

1. Abra o jogo com F5 e escolha `Novo jogo`.
2. No campo de aparencia, `Sprout Sorry (principal)` ja vem selecionado.
3. Escolha a fazenda e inicie para conferir andar, correr e usar 1-4/F.
4. Personagens `Masculino classico` e `Feminino classico` continuam
   disponiveis. Fazendas salvas nao tem sua aparencia sobrescrita.
5. Abra `tests/SproutSorryPlayerTest.tscn` (F6) para verificar o gerador
   usando um atlas sintetico, sem precisar publicar assets.

**Limite conhecido:** este ZIP tem apenas poses simples de caminhada,
nao sprites completos das ferramentas. Para preservar interacoes e
momentos de impacto, as animacoes de machado, picareta, enxada e regador
usam poses temporarias do proprio personagem e exibem o icone original
da ferramenta sobreposto, em movimento. Sao animacoes de transicao,
nao movimentos detalhados de bracos desenhados pelo autor.
As orientacoes diagonais tambem ficam reservadas para movimento futuro.

Se o ZIP nao foi instalado, o avatar `sprout_sorry` usa automaticamente
o antigo personagem masculino, sem erro fatal. A cena `Player.tscn`
permanece exibindo o personagem classico no inspetor; a troca acontece
em tempo de execucao conforme o save.

## Creditos e uso comercial

Arte: **Cup Nooble / Sprout Lands**. O `read_me.txt` do **Sprout Sorry
Basic Pack** incluído no ZIP diz uso **nao comercial**, autoriza
modificacoes e exige credito Cup Nooble; e proibe redistribuir o pacote
isoladamente. Voce informou ter permissao para uso comercial; guarde
comprovante de que essa autorizacao especifica tambem cobre o
**Sprout Sorry Pack**. A licenca Premium de outro pack nao altera
automaticamente os termos deste ZIP.

Nao adicione os sprites originais ao GitHub publico sem conferir o alcance
da autorizacao. O jogo distribuido deve manter os creditos obrigatorios.
