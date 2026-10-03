# Construção de teste em camadas

B abre a construção. Escolha **Piso**, **Parede** ou **Telhado**; esquerdo pinta e direito apaga somente na camada selecionada. B/Esc fecha e libera o jogador.

O piso usa 25 materiais (uma célula custa 1; remover devolve 1). Para testar a montagem, parede e telhado não cobram materiais adicionais. Nenhuma camada cria células automaticamente em outra camada. Assim você pinta o chão, contorna com paredes e deixa a entrada sem parede, depois pinta a cobertura com a extensão desejada.

Piso e parede usam os sprites originais de Wooden_House_Walls. A parede tem colisão; o piso não. O telhado usa as cinco linhas originais de Wooden_House_Roof: borda superior, inclinação superior, faixa central única, inclinação inferior e borda inferior. A faixa central fica na altura média da cobertura pintada.

Na construção, a cobertura aparece ao selecionar Telhado e fica escondida ao selecionar Piso ou Parede. Fora da construção, desaparece quando o jogador pisa na área de piso e reaparece ao sair. Ver telhado alterna a ocultação manual.

Salvar/Carregar guarda três conjuntos independentes em user://house_terrain_test.json (versão 2). Saves antigos de pintura automática não são importados, pois não distinguem as camadas. Desfazer restaura as três camadas e o saldo.

A casa manual em scenes/world/world2.tscn foi preservada como referência; seus tiles não são convertidos automaticamente pelo construtor. Cantos e recortes muito específicos ainda precisam de acabamento; este construtor não reproduz automaticamente todos os detalhes decorativos desenhados à mão (janelas, chaminé e porta).

Validação: parser GDScript aprovado. Execução e aparência pendentes de teste no Godot.
