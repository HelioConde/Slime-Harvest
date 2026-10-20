# Sprout Sorry — protagonista padrao

O personagem escolhido para **novas fazendas** e o humano de cabelo castanho
do arquivo original:
`Sprout Sorry pack/Tests/free_character_spritesheet_by-cupnooble.png`.

Dimensoes verificadas: atlas **128x96**, grade **8 colunas x 3 linhas**,
celulas **16x32**. As colunas sao as oito orientacoes e cada linha uma
pose. O Sprout Sorry agora utiliza as oito orientacoes para andar, correr e
ficar parado (56 estados visuais no recurso SpriteFrames); o sistema fisico
de ferramentas continua nas quatro direcoes cardinais para preservar o
alcance, os alvos, as colisoes e os saves.

Mapeamento real das colunas: 0 superior esquerda, 1 cima, 2 esquerda,
3 inferior esquerda, 4 baixo, 5 inferior direita, 6 direita, 7 superior direita.
O codigo anterior usava incorretamente a coluna 0 para andar para cima;
essa orientacao foi corrigida.

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
usam poses temporarias do proprio personagem, mas o icone original da
ferramenta agora segue uma curva suave ao longo dos quadros de ataque.
Machado/picareta mostram um pequeno arco luminoso, a enxada faz um
arco terroso e o regador inclina com gotas puramente visuais.
Os efeitos obedecem ao tempo real do SpriteFrames e nao alteram as regras
de impacto/dano. Ainda nao sao animacoes de bracos desenhados pelo autor.
As oito orientacoes estao ativas para caminhar e correr; as quatro direcoes
cardinais permanecem para o uso das ferramentas.

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

## Validacao de qualidade

O teste `tests/SproutSorryPlayerTest.tscn` confere as 56 animacoes,
a coluna correta de cada direcao e o efeito de ferramentas sem carregar
os PNGs licenciados. Em um jogo real, teste **WASD incluindo diagonais**,
Shift, quatro ferramentas (teclas 1-4 e F), esquiva e persistencia de saves.
A avaliacao visual com o PNG instalado ainda deve ser realizada no Godot local.
