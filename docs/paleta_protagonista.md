# Paleta do protagonista — Slimekeepers: Lost Valley

**Status:** proposta visual V1, registrada para revisão. Não altera sprites, animações, escala ou mecânicas.

A análise usou o repositório `HelioConde/Slime-Harvest`: personagens em `assets/Characters/new/`, `player_masculino_frames.tres`, os recursos do Sprout Lands em `assets/tilesets/` e `assets/Objects/`, a cena `World.tscn` e a referência existente `paleta-cenario.zip` disponibilizada na conversa. O pacote contém uma paleta compartilhada com mais cores; este arquivo seleciona **28 cores** dela para desenho mais limpo em 64×64.

## Paleta principal (HEX)

| Grupo | Função | HEX |
|---|---|---|
| Contornos | Contorno base | `#3F3B4A` |
| Contornos | Borda media | `#514A58` |
| Contornos | Borda iluminada | `#655663` |
| Cabelo castanho | Sombra profunda | `#5E4646` |
| Cabelo castanho | Sombra | `#735557` |
| Cabelo castanho | Meio-tom | `#90625D` |
| Cabelo castanho | Luz | `#A57662` |
| Cabelo castanho | Brilho pontual | `#C49A6C` |
| Pele | Sombra quente | `#B77B6C` |
| Pele | Meio-tom | `#E9BA9A` |
| Pele | Base | `#F4D1AF` |
| Pele | Luz | `#F7DEC0` |
| Couro, botas e luvas | Sombra | `#81534F` |
| Couro, botas e luvas | Base escura | `#A36858` |
| Couro, botas e luvas | Base clara | `#BA7D65` |
| Couro, botas e luvas | Luz nas bordas | `#D59877` |
| Camisa creme | Sombra | `#9C927E` |
| Camisa creme | Base | `#DCD0AF` |
| Camisa creme | Luz | `#EEE2C5` |
| Colete verde | Sombra | `#3E5553` |
| Colete verde | Meio-tom | `#5E7D68` |
| Colete verde | Base | `#6E967C` |
| Colete verde | Luz | `#97BB8E` |
| Lenco agua-petroleo | Sombra | `#425B71` |
| Lenco agua-petroleo | Base | `#5B8793` |
| Lenco agua-petroleo | Luz | `#9BD4C3` |
| Metais e fivela | Ouro sombra | `#9D8553` |
| Metais e fivela | Ouro luz | `#D2BE82` |

## Cores contextuais do mundo (não incluídas nas 28)

- Grama principal: `#C0D470`, amostrada na captura do World.
- Solo claro: `#E8CFA6`.
- HUD escura: `#213A31`.

Esses tons são **referências para contraste**, não para colorir o protagonista inteiro.

## Diretrizes

1. Conservar contornos coloridos escuros (ex.: `#3F3B4A`), sem bordas pretas absolutas.
2. Manter cabelo castanho com cinco tons no máximo; rosto e luvas devem permanecer legíveis em 64×64.
3. Camisa creme + colete verde-acinzentado + lenço azul-petróleo dialogam com o cenário sem camuflar a silhueta.
4. Fivela e reflexos dourados ocupam áreas pequenas; evitar dourado intenso nas roupas.
5. O fundo de cada frame deve ser **transparente**. Sem sombra embutida: criar sombra como elemento separado, com opacidade baixa, se necessário.
6. Para sprites em 64×64, redesenhar detalhes manualmente em vez de redimensionar cegamente a arte de 222×222; preservar o alinhamento dos pés.
7. No Godot, utilizar `texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST` e validar em grama, areia, ambiente escuro e com slimes próximos.

## Arquivos

- [Paleta GPL para Aseprite/GIMP](../assets/Characters/palette_protagonista_28.gpl)
- [Definição JSON das cores](../assets/Characters/palette_protagonista_28.json)

**Critério de aprovação:** a paleta não pode reduzir a leitura da silhueta nem criar ruído visual na resolução real do jogo. O passo seguinte é testar uma pose frontal e uma lateral antes de aplicar às animações inteiras.
