# Casa construída pelo jogador

Em scenes/world/world2.tscn, pressione F6. B abre o modo de construção. O Player para durante a edição; B ou Esc restaura seu estado anterior.

Escolha Paredes ou Telhado e clique na miniatura da peça. Botão esquerdo coloca (segurar pinta); direito apaga somente a camada escolhida. Desfazer reverte a última célula (até 256 mudanças). Ver telhado mostra/oculta a cobertura para editar as paredes. Salvar guarda a casa em user://house_world2.json; Carregar restaura após validar formato, peças, limites e espaço livre. Carregar substitui somente a casa atual. Não há carregamento automático ao iniciar.

São camadas TileMapLayer independentes com tiles de 16 × 16. Paredes: z_index 5 e colisão World por célula. Telhado: z_index 20, acima do Player, sem colisão. Não altera os TileSets compartilhados nem os tiles pintados do terreno.

Construção permitida em células presentes em soil_water, com limite de 2048 peças. O terreno base funciona como área permitida; água sem chão não aceita construção. A prévia vermelha identifica posições bloqueadas. Todas as peças da categoria Paredes são sólidas: deixe uma abertura para entrar. Não há portas operáveis, interior separado, custos de materiais ou encaixe automático de telhado nesta primeira versão.

## Validação

Sintaxe GDScript verificada com gdparse. Referências, identificação das peças e preservação dos dados pintados verificadas antes do commit. Execução real no Godot ainda pendente.

Teste local: B → escolher paredes → desenhar contorno com entrada → selecionar telhado → pintar → esconder cobertura → apagar e desfazer → salvar → mudar uma peça → carregar → B para sair → conferir colisões. Tente colocar sobre o Player, água sem solo e um obstáculo. Reinicie e carregue para conferir persistência. Se estiver usando F5 na cena World original, abra world2 e use F6.

## Próxima etapa

Porta funcional, piso e móveis, ocultação do telhado quando o Player estiver dentro e validação de um contorno fechado.
