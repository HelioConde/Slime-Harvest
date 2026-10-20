# Agricultura no World e mochila

O sistema funciona no mapa principal sem substituir o TileMap, o HouseBuilder ou o personagem.

## Jogar

1. Tecle **3** (enxada) e use F ou clique na grama livre para preparar o solo.
2. Na mesma celula arada use enxada novamente para plantar uma flor. A fazenda comeca com 12 sementes.
3. Tecle **1** (regador) e regue a planta. Ela avanca uma fase a cada 3 dias depois de regada.
4. Com a enxada, colha ao atingir a ultima fase. Uma flor entra no ResourceBag e uma semente volta.
5. Aperte **I** para abrir/fechar a mochila, ou Esc para fechar. Ela mostra ferramentas, recursos, sementes e moedas.
6. Com a mochila aberta, escolha a variedade de flor (azul, rosa ou amarela) antes de plantar. Fora da mochila, **Q** alterna a variedade.
7. Na banca provisoria dentro da mochila, venda as flores colhidas e compre sementes com moedas.

Plantas disponiveis nesta etapa: flores azuis, rosas e amarelas com os sprites de quatro estagios ja existentes.
A proxima flor plantada respeita a variedade escolhida. Cultivos ja plantados nao mudam de tipo quando voce troca a semente.

## Economia inicial

| Produto | Valor de venda |
| --- | ---: |
| Flor azul | 5 moedas |
| Flor rosa | 7 moedas |
| Flor amarela | 9 moedas |

Uma nova semente custa **3 moedas**. O estoque comeca com 12 sementes, compartilhadas entre as tres variedades.
A banca na mochila e provisoria: ainda nao ha NPC, predio de loja ou mercado com estoque dinamico.
Somente flores podem ser vendidas; ferramentas e materiais continuam protegidos.
Vendas e moedas sao atualizadas juntas em `ResourceBag`, evitando credito duplicado.
Compras exigem saldo suficiente e nao aceitam valores invalidos.

## Saves

- Solo arado: user://slimekeepers_world_hoeing_v1.json (inalterado).
- Plantas/sementes: user://slimekeepers_world_crops_v1.json (novo, por slot).
- Flores colhidas e saldo de moedas: ResourceBag existente, com contadores compartilhados pela hotbar e mochila.
- Variedade de semente selecionada: novo campo opcional no JSON existente de cultivos, compativel com saves anteriores.
- Tres slots recebem o arquivo novo, preservando saves antigos e o FarmField independente.
- Reset F1 no debug limpa cultivos junto ao mapa, sem apagar recursos colhidos.

## Arte e interface

Painel Sprout Lands e usado quando instalado localmente, com estilo de fallback seguro sem o pacote.
Icones e flores usam texturas que ja estao presentes no projeto.
A mochila agora permite selecionar sementes e vender flores, mas ainda nao inclui troca de posicao de itens, crafting ou drag-and-drop.

## Testes

Abra scenes/world/World.tscn com F6 ou use o menu F5.
Teste 3, F (preparar); 3, F (plantar); 1, F (regar); F9 tres vezes para cada fase em modo debug.
Abra a mochila com I, escolha outra semente, venda uma flor, compre uma semente e confira as moedas ao continuar.
O teste WorldCropsTest tambem cobre vendas, compras, selecao de semente e persistencia da carteira.
Teste automatizado: res://tests/WorldCropsTest.tscn; cobre a logica num arquivo temporario.

Pendencias: NPC de loja, mais cultivos, preco dinamico, energia, mochila arrastavel e QA visual prolongado.
