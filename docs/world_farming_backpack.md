# Agricultura no World e mochila

O sistema funciona no mapa principal sem substituir o TileMap, o HouseBuilder ou o personagem.

## Jogar

1. Tecle **3** (enxada) e use F ou clique na grama livre para preparar o solo.
2. Na mesma celula arada use enxada novamente para plantar uma flor. A fazenda comeca com 12 sementes.
3. Tecle **1** (regador) e regue a planta. Ela avanca uma fase a cada 3 dias depois de regada.
4. Com a enxada, colha ao atingir a ultima fase. Uma flor entra no ResourceBag e uma semente volta.
5. Aperte **I** para abrir/fechar a mochila, ou Esc para fechar. Ela mostra ferramentas e recursos reais.

Plantas disponiveis nesta etapa: flores azuis, rosas e amarelas com os sprites de quatro estagios ja existentes.
O tipo de flor depende da posicao da celula, pois a escolha individual de sementes ainda esta pendente.

## Saves

- Solo arado: user://slimekeepers_world_hoeing_v1.json (inalterado).
- Plantas/sementes: user://slimekeepers_world_crops_v1.json (novo, por slot).
- Flores colhidas: ResourceBag existente, com contadores compartilhados pela hotbar e mochila.
- Tres slots recebem o arquivo novo, preservando saves antigos e o FarmField independente.
- Reset F1 no debug limpa cultivos junto ao mapa, sem apagar recursos colhidos.

## Arte e interface

Painel Sprout Lands e usado quando instalado localmente, com estilo de fallback seguro sem o pacote.
Icones e flores usam texturas que ja estao presentes no projeto.
A mochila por enquanto e de consulta e nao inclui troca de posicao de itens, crafting ou drag-and-drop.

## Testes

Abra scenes/world/World.tscn com F6 ou use o menu F5.
Teste 3, F (preparar); 3, F (plantar); 1, F (regar); F9 tres vezes para cada fase em modo debug.
Abra a mochila com I e depois confirme a colheita e o save ao continuar.
Teste automatizado: res://tests/WorldCropsTest.tscn; cobre a logica num arquivo temporario.

Pendencias: escolha de semente, mais cultivos, economia, energia, mochila arrastavel e QA visual prolongado.
