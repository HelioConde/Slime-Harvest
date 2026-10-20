# Corrigir personagem e HUD Sprout Lands em partidas existentes

## O que causava as capturas antigas

- A escolha Sprout Sorry era padrao somente ao criar uma nova fazenda. Um save antigo com aparencia `masculino` continuava com o aventureiro classico.
- O arquivo `sprout_theme.tres` ja fornecia bordas e botoes marrons. Mas a hotbar, a mochila e o HP ainda nao usavam o **atlas de inventario** com slots e coracoes do Sprout Lands UI Basic.
- Os arquivos PNG licenciados sao locais e NAO ficam no GitHub, mesmo quando o codigo esta atualizado.

## Passos no Windows

1. Feche o Godot. Na raiz do projeto execute `git switch main` e `git pull origin main`.
2. Extraia `Slimekeepers-Sprites-Sprout-Lands-Prontos-Godot.zip` **diretamente** na pasta que contem `project.godot`. Nao deixe `assets` dentro de outra pasta.
3. Confira os dois arquivos:

   - `assets/Characters/sprout_sorry/free_character_spritesheet_by-cupnooble.png` (128 x 96).
   - `assets/ui/sprout_lands/inventory_atlas.png` (368 x 336).

4. Abra o projeto no Godot e aguarde a importacao dos assets.
5. Carregue **a fazenda existente**, abra as opcoes pela engrenagem ou F10 e encontre **Personagem principal**.
6. Escolha `Sprout Sorry` e aperte **Aplicar**. O avatar e alterado imediatamente e salvo no slot ativo.
7. A hotbar passa a usar slots reais do atlas de inventario Sprout. O HUD de vida exibe coracoes pixel art. `I` abre a mochila com fundos de slots do mesmo atlas.

Se a aparencia nao for aplicada, a tela indica que o PNG Sprout Sorry nao foi encontrado/importado, em vez de salvar uma escolha que continuaria invisivel.
Salvamentos antigos com escolha explicita de personagem classico nao sao sobrescritos so por atualizar o Git; use o seletor para alterar quando desejar.
Se o save legado nao possuir uma escolha anterior, usa Sprout Sorry quando o PNG estiver presente.

## Diagnostico rapido

No PowerShell, dentro da raiz do projeto:

```powershell
Test-Path 'assets/Characters/sprout_sorry/free_character_spritesheet_by-cupnooble.png'
Test-Path 'assets/ui/sprout_lands/inventory_atlas.png'
git status --short
git log -1 --oneline
```

As duas chamadas Test-Path precisam mostrar **True**. Arquivos em `addons/` por si so nao sao suficientes; os caminhos em `assets/` sao exigidos pelo codigo do jogo.

## Compatibilidade e licenca

- Nao regrava os desenhos originais, colisoes, terrenos, construcoes ou recursos salvos.
- Os personagens masculino e feminino antigos continuam opcionais.
- Quando o atlas de inventario nao esta instalado, os componentes mantem o visual de seguranca anterior.
- Os arquivos do pack permanecem na instalacao local; credito da arte: Cup Nooble. Os codigos dos addons sao de Maaack.

## Validação

O CI roda o Godot duas vezes: sem os packs de terceiros (fallback) e com imagens PNG sintéticas geradas somente para testar caminhos, SpriteFrames, slots e corações. Isso nao e um teste visual do jogo com as artes originais; a validacao final deve ser feita no seu Godot.
