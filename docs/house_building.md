# Construção de casas dentro do jogo

Em scenes/world/world2.tscn, use F6 e pressione B. O modo principal é Casa automática.

Escolha largura (3 a 12 tiles) e altura do telhado (5, 7 ou 9 tiles). Uma prévia da casa completa acompanha o mouse. Clique esquerdo constrói uma fachada retangular com cobertura e abertura na frente. Bordas, peças centrais, faixa central e extremidades do telhado são escolhidas automaticamente conforme a posição. Clique direito numa casa automática para removê-la. Desfazer reverte a construção/remoção inteira. Ver telhado oculta a cobertura para inspeção. B ou Esc sai.

Peças ativa a edição manual por camada (Paredes/Telhado): esquerdo coloca, direito apaga. As duas camadas usam TileMapLayer de 16 × 16. A montagem automática usa um modelo retangular compatível com os sprites, sem exigir escolher cantos individualmente. Não é um terrain para casas de contorno irregular.

A área inteira da casa precisa estar sobre solo livre em soil_water. Bloqueia sobreposição com casas existentes, Player e corpos físicos. Paredes têm colisão World; a peça de abertura (3,2) não bloqueia a passagem. A cobertura não tem colisão. Não há interior separado ou porta que abre/fecha nesta etapa.

Salvar guarda células e regiões das casas em user://house_world2.json. Carregar valida antes de substituir as células da construção. Saves anteriores com somente peças continuam aceitos; peças antigas não se tornam casas automáticas. Não carrega automaticamente ao iniciar. Alterações só persistem quando Salvar é acionado. Limite de 2048 peças e histórico de 256 ações.

## Validação

Sintaxe verificada com gdparse; peças de todas as 30 combinações de dimensões conferidas nos TileSets; montagem visual examinada em prévia local. Execução real no Godot pendente.

Teste: B → ajustar tamanho → construir em área livre → tentar sobrepor → ocultar cobertura → remover com direito → desfazer → salvar → reiniciar → carregar. Se não houver HouseBuilder em Actors/Map, instancie scenes/building/HouseBuilder.tscn ali com player_path ../../Player e ground_path ../soil_water.

Próxima etapa: piso, móveis, porta funcional e interior da casa.
