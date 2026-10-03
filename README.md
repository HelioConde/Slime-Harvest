# Slime Harvest

Jogo de fazenda 2D inspirado em Stardew Valley, com cultivo, criação de slimes e exploração. Transforme um pequeno terreno em uma fazenda cheia de vida, descubra novas criaturas e construa sua história na vila.

## Estado inicial

Projeto novo, criado do zero e independente do GameSlime antigo. Esta etapa organiza apenas as pastas; a engine e sua versão ainda precisam ser definidas. Ainda não há jogo executável.

## Organização

| Pasta | Conteúdo |
| --- | --- |
| assets/ | Sprites, tilesets, interface, áudio e fontes |
| scenes/ | Cenas de mundo, jogador, slimes, cultivo e interface |
| scripts/ | Código separado por sistema |
| data/ | Definições de plantas, slimes e itens |
| docs/ | Estrutura e decisões do projeto |
| tests/ | Testes das mecânicas |
| tools/ | Ferramentas de desenvolvimento |

Use nomes em inglês e snake_case para arquivos e pastas. Os arquivos .gitkeep preservam pastas vazias no Git; podem ser removidos quando elas receberem conteúdo.

Veja [a estrutura completa](docs/project_structure.md).

## Próxima etapa

Definir a engine e criar o primeiro protótipo: movimentação, mapa pequeno e ciclo de preparar a terra, plantar, regar e colher.

## Sincronização local

Pasta informada pelo proprietário: C:\FarmSlime. A tarefa FarmSlime-GitSync acompanha main a cada 30 segundos. Alterações locais ou divergências pausam a sincronização. Não versionar configuração, logs ou credenciais do sincronizador.
