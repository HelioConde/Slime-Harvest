# Bestiário de Slimekeepers: Lost Valley

32 espécies; 788 animações; 9456 quadros.

Cada espécie tem 20 estados comuns e todas as ações exclusivas enumeradas no bestiário fornecido. Os movimentos comuns reutilizam a base do slime azul. Detalhes de identidade ficam em uma camada editável própria. Gota segue a aparência azul original. Chuvão tem corpo maior.

- Quadros 64 × 64, 12 por animação; cada linha do atlas é uma animação.
- Pivô (30,53), imagem sem recorte automático, fundo transparente.
- 5 camadas Aseprite: Sombra, Corpo, Identidade, Rosto, Efeitos.
- Cada pasta contém Aseprite editável, PNG, mapa JSON e GIFs de idle, trabalho e ataque.
- Os objetos de trabalho e os projéteis são efeitos visuais em camada própria. Não implementam inventário, IA, colisões, dano, profissões ou automação agrícola.
- Direção das ações: direita. Espelhar a cena inteira preserva o pivô.
- Os estados comuns são: idle, blink, move, land, work_start, work_loop, work_finish, attack_charge, attack, hurt, sleep, happy, idle_feliz, seguir_jogador, cansado, acordar, comemorar, receber_carinho, irritado, derrotado_dissipar.
- Ações de execução única param no último quadro; o jogo decide a transição seguinte. Derrota termina transparente.
- Não substitui o slime azul existente e não adiciona criaturas ao mapa.

## Godot

Cenas individuais: res://scenes/slimes/bestiary/<especie>.tscn

Catálogo de prévia: res://scenes/slimes/bestiary/BestiaryPreview.tscn. Abra e pressione F6 para escolher espécie e animação.

O pacote godot contém somente arquivos novos nas pastas assets, scenes, scripts e docs. Não contém project.godot nem altera World.tscn.

## Espécies

1. Terrinho — Preparar o solo; 26 animações.
2. Brotinho — Plantar sementes; 26 animações.
3. Gota — Regar plantações; 27 animações.
4. Colhita — Colher plantações; 24 animações.
5. Polenita — Polinizar cultivos; 24 animações.
6. Compô — Fertilizar o solo; 24 animações.
7. Capinito — Remover ervas daninhas; 24 animações.
8. Raizela — Cuidar de mudas; 23 animações.
9. Carreguim — Transportar recursos; 26 animações.
10. Seletim — Organizar baús; 24 animações.
11. Lenhoco — Cortar árvores; 25 animações.
12. Pedrito — Quebrar pedras; 24 animações.
13. Ferrito — Extrair minérios; 24 animações.
14. Pomelo — Colher frutos; 24 animações.
15. Riacho — Pescar; 24 animações.
16. Funguinho — Coletar cogumelos; 24 animações.
17. Brasinha — Aquecer estações; 24 animações.
18. Chefito — Cozinhar receitas; 24 animações.
19. Gelito — Refrigerar alimentos; 24 animações.
20. Faísca — Gerar energia; 24 animações.
21. Engrenito — Fabricar equipamentos; 25 animações.
22. Construlim — Construir estruturas; 24 animações.
23. Melado — Produzir mel; 25 animações.
24. Fiapo — Produzir fibras; 23 animações.
25. Alquimita — Preparar poções; 25 animações.
26. Ventinho — Movimentar moinhos; 25 animações.
27. Lumito — Iluminar caminhos; 25 animações.
28. Curinha — Curar companheiros; 25 animações.
29. Guardito — Proteger a fazenda; 26 animações.
30. Noturno — Coletar recursos noturnos; 24 animações.
31. Prismita — Detectar cristais raros; 25 animações.
32. Chuvão — Regar grandes regiões; 27 animações.

## Revisão 2

Consulte REVISAO.md para as mudanças de movimento, margens, reutilizações e limites da validação. Construlim/levantar_parede agora é execução única; work_loop mantém a parede enquanto aplica argamassa.
