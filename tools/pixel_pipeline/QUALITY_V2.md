# Revisão de qualidade após rejeição do primeiro ensaio

O primeiro conjunto foi rejeitado pelo usuário por ruído e baixa qualidade. Não deve ser utilizado como referência de qualidade ou integrado ao jogo.

## Erros corrigidos no pipeline

1. **Margens Godot ignoradas.** O importador extraía apenas `AtlasTexture.region`, sem reconstruir o canvas definido por `margin`. Por exemplo, um recorte138×194 com margem118×62 deveria ocupar um canvas256×256. Agora o posicionamento e o tamanho lógico do recurso são respeitados.
2. **Referência esticada.** O img2img redimensionava recortes retangulares diretamente para quadrados. Agora usa escala uniforme e margens transparentes antes de compor no fundo branco.
3. **Borda branca opaca.** Substituir o alpha da geração pelo alpha da referência tornava fundo branco opaco onde o modelo deslocava a silhueta. Agora o fundo branco conectado à borda é removido e as máscaras são intersectadas. Na resolução final, o contorno de1pixel e lacunas são restaurados com os pixels da referência, não com o branco gerado. O interior vem do refinamento; não se trata de uma saída bruta do SD.
4. **Cache anterior.** Incluída versão de pré-processamento na chave para não reutilizar gerações feitas com o redimensionamento incorreto.

## Diagnóstico visual

- Alterar atenção para sub-quadratic não resolveu o padrão abstrato em256. A configuração Automatic foi restaurada e confirmada pela API.
- Passar a referência corrigida pelo img2img com denoise0 produziu reconstrução legível. Isso não comprova equivalência exata ao original, mas indica que a codificação/decodificação VAE consegue reconstruir a personagem.
- Geração em384 ainda ficou inadequada. Um teste512 produziu personagem reconhecível, embora cortado e fora do conceito de slime. Sem OOM nesses testes. Não é aprovação do txt2img nem prova de que resolução seja a única causa: parâmetros/prompt também variaram entre alguns ensaios.
- Com referência corrigida em512, 20 passos, denoise0,12, a identidade foi melhor preservada do que no primeiro lote. Também foi comparado0,25. O perfil0,12 foi escolhido para a próxima amostra de idle, não declarado universalmente ideal.
- Não instalaram-se modelos, LoRAs, extensões ou dependências do WebUI.

## Uso atual

A interface sugere512, 20 passos e denoise0,12. Continua oferecendo256/384 para investigação. Em hardware diferente, testar um quadro e medir memória antes de uma sequência. O ponto de entrada Python mantém os defaults antigos por compatibilidade; informe parâmetros explicitamente.

Para máscaras, a paleta padrão do img2img com máscara passa a vir das referências, não do fundo branco das imagens geradas. As ações de aprovação não mudaram: nenhuma animação se aprova automaticamente.

Testes adicionais cobrem reconstrução de margem Godot, preservação de aspecto e ausência de borda branca forçada pela máscara. As imagens comparativas ficam em `outputs/qualidade_v2` da conversa. O relatório VALIDATION.md documenta o ensaio anterior, não a qualidade desta revisão.

Resultado final desta revisão: idle de quatro quadros em64×64, quatro gerações512/20passos/0,12, máscara e contorno protegidos, paleta comum. Passou na validação estrutural e na importação Godot;23 testes locais passaram e1 teste GPU opt-in ficou desabilitado na suíte padrão (as gerações reais foram executadas separadamente). Nenhuma animação foi aprovada automaticamente ou integrada ao jogo. As caminhadas do lote inicial continuam rejeitadas.
