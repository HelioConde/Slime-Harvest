# Produção do catálogo do player

## Escopo desta etapa

O catálogo contém 44 ações (7 principais + 37 adicionais), com prioridades, direções, contagens propostas, poses, prompts, referência, paleta, origem, eventos e estados por personagem. Foram encontradas 28 sequências principais em cada SpriteFrames. Existem 248 entradas por personagem, não 224: idle tem 14 entradas por direção, incluindo retorno e pausas, preservadas nesta etapa.

As outras 37 ações permanecem sem poses próprias nesses recursos. Nenhuma foi preenchida usando caminhada como ferramenta, abraço ou combate. As quantidades de quadros secundárias continuam indefinidas até desenhar e verificar o movimento. O catálogo não considera a existência de PNG como conclusão.

## Implementação reutilizada

| Arquivo / recurso | Reuso ou alteração |
|---|---|
| pipeline.py: fit_canvas, remove_background, constrain_mask, protect_contour | Mantidos: escala uniforme, transparência e proteção do contorno no img2img. |
| pipeline.py: process, shared_palette | Reutilizados para Nearest, alpha binário e paleta; corrigida paleta monocromática para aceitar sprites de uma única cor. |
| pipeline.py: clean_frame | Pequena extensão no mesmo módulo: recolore pontos internos de baixo contraste com sete vizinhos iguais, sem alterar a geometria do corpo. Em P0, fragmentos pequenos acima da cabeça e pixels isolados são removidos com registro de coordenadas. Não é outro Cleaner. |
| pipeline.py: align_frames | Preservado; não aplicado para realinhar P0 nesta produção. |
| pipeline.py: validate_frames | Reutilizado para dimensões, alpha, componentes, margem, apoio, duplicatas e continuidade. Água/partículas requerem avaliação, não exclusão cega. |
| pipeline.py: export | Agora preserva duração por entrada, FPS, origem e loop; não presume idle de quatro quadros. Repetições intencionais de idle são permitidas. |
| pipeline.py: extract_godot_frames | Mantida a assinatura pública, agora delegando ao leitor único de catálogo, que respeita a ordem real e referências repetidas. |
| catalog.py | Leitor de regiões/margens e timelines SpriteFrames; catálogo e hashes; materialização de estados por personagem/direção. |
| production.py | Orquestra funções existentes, fila sequencial limitada, trava de processo, checkpoint por quadro, cache vinculado à origem/modelo/prompt/paleta; bloqueia SD para P0. |
| app.py, ui.html | Interface legada preservada; ações vêm do endpoint /api/catalog após reiniciar o servidor. |
| cli.py, experiment.py, revise_walks.py | Experimentos legados mantidos para compatibilidade. Não são o fluxo de preservação do P0 aprovado; use production.py. |
| install.ps1, requirements.txt, start.bat, start_webui.ps1, inspect_environment.ps1 | Ambiente isolado e inicialização existentes mantidos; nenhum modelo/LoRA novo instalado. |
| test_godot.ps1, tests/godot_import_test.gd | Importação isolada ampliada para verificar qualquer contagem real, duração, FPS, loop e Nearest. |
| tests/test_pipeline.py, tests/test_jobs.py | Testes anteriores preservados; fixture de AtlasTexture passou a incluir timeline válida. |
| tests/test_catalog.py | Casos novos de retomada, OOM simulado, mudança de prompt/fontes, lock concorrente, paleta, transparência e preservação temporal. |
| godot/action_sequencer.gd | Camada opt-in de eventos e bloqueio; não substitui o controlador ativo. |
| review_catalog.py | Comparações antes/depois e lista explícita de pendências, usando exportações existentes. |

## Executar

No diretório tools/pixel_pipeline, use o Python da .venv. Crie uma saída nova ao mudar fontes ou configuração. Para as fontes congeladas da entrega, informe a pasta fontes_congeladas como --project.

```powershell
.\.venv\Scripts\python.exe production.py --project C:\FarmSlime --output data/catalogo --character feminino --actions idle walk --limit 2
```

Repita para continuar: quadros finalizados são reaproveitados. `--limit 32` pode ser usado no processamento CPU; o padrão é dois. O processamento não modifica os recursos ativos.

Para um ensaio SD com poses previamente conferidas:

```powershell
.\.venv\Scripts\python.exe production.py --project CAMINHO_DAS_FONTES --output DIRETORIO --character feminino --actions hoe --directions left --sd --limit 2 --pose-review REVISAO.json
```

A revisão deve conter personagem/sequência, todos os índices, revisor, quatro critérios, hash da sequência e hashes exatos dos arquivos de origem. O exemplo real está em pose_review.json da entrega. Não copie sua aprovação para outras poses. O perfil executado fica em profile.json. Uma falha preserva os quadros feitos e registra erro em state.json; não há repetição automática nem novo lote pesado após erro.

Para montar a página de revisão:

```powershell
.\.venv\Scripts\python.exe review_catalog.py --project CAMINHO_DAS_FONTES --output DIRETORIO
```

## Integração progressiva

O jogo atual continua usando player.gd e seus impactos existentes. O novo sequenciador deve ser anexado apenas em uma cena de avaliação com SpriteFrames aprovados; não deve emitir o mesmo impacto em paralelo ao controlador antigo. `bind(sprite, definitions)` recebe definições por nome, como pickup_slime_down; `request(action, direction, payload)` rejeita ação ausente, não validada ou sobreposição bloqueada.

Cada definição validada contém `validated`, `interruptible`, `lock_movement`, e eventos com `id` e `frame`. `action_event` entrega ação, evento, quadro e payload ao código da mecânica. `cancel()` respeita bloqueio; cancelamento forçado não inventa impactos. O estado anterior (animação, fase e velocidade) é restaurado ao terminar. idle/walk/run não são assumidos pelo sequenciador.

Os eventos do catálogo ainda têm quadro nulo quando falta uma pose; isso impede ativação prematura. São necessários sockets animados por direção (mãos, ponta da ferramenta, posição do slime). Carregar slime caminhando ainda requer a variante visual de braços ocupados combinada com a caminhada aprovada; não foi simulada com um sprite de caminhada sem ajuste.

## Verificação desta rodada

- 31 testes Python passaram; um teste GPU opt-in ficou fora da suíte padrão.
- Oito gerações img2img reais de hoe_left em quatro lotes de dois, 512px, 20 passos solicitados, denoise 0,12, seed 1234; máscara preservada.
- 37 exportações importadas no Godot 4.7.2, verificando contagem, FPS, durações, loop e Nearest.
- Sequenciador testado no Godot: rejeição de ação não validada, bloqueio de sobreposição, cancelamento, eventos atravessados sem duplicação, retorno à fase anterior e cancelamento dentro de callback.
- 248 quadros femininos e 88 masculinos passaram por processamento local. A correção conservadora recoloriu 108 e 85 pixels, respectivamente, além da quantização compartilhada. Não significa eliminação de toda textura artística.
- Só 7 das 28 sequências femininas CPU e 6 das 8 masculinas CPU passaram em todos os critérios estruturais. As demais são candidatos de diagnóstico, não assets prontos. O ensaio SD hoe_left passou estruturalmente, mas permanece sem aprovação artística final.

## Próximas dependências concretas

1. Corrigir os recortes P1 que atravessam ferramentas/pés e separar efeitos legítimos (água) de fragmentos de outras linhas; não alterar os ciclos aprovados de idle/walk.
2. Revisar movimento, proporções e sombras das referências P1 antes de ampliar img2img. Limpeza de cor não corrige biomecânica.
3. Criar poses próprias para P2/P3/P4, com atividade/objeto legíveis, e marcar contato/transferência em cada direção. Não há conjunto completo com qualidade profissional nesta entrega.
4. Aprovar comparações, sockets e eventos antes de conectar uma ação nova ao controlador e substituir sprites ativos.

A configuração editável central está em animation_catalog.json. Cada produção recebe sua cópia catalog.json e estados por personagem/direção. Novas ações podem ser cadastradas sem substituir o controlador, com identificadores seguros e eventos/poses próprios. Reinicie a interface legada após modificar a lista de ações.

A limpeza P0 retirou 537 pixels de fragmentos femininos e 11 masculinos, registrados em provenance.fragment_removals. A máscara corporal restante foi comparada com a fonte; ordem, duração e FPS permaneceram iguais. As referências anteriores à remoção estão no histórico da saída.

Antes de integrar um sprite 64×64, a escala visual e a origem devem ser comparadas com o desenho original e a escala atual do AnimatedSprite2D (o jogo usa referências maiores). A entrega não aplica uma troca cega de textura que diminuiria o personagem.

## Separação de quadros

production.py exporta com 8 pixels transparentes entre quadros e nas bordas. Cada AtlasTexture continua em 64×64, com filter_clip e regiões que consideram as margens. FPS, ordem e durações não mudam. O exportador genérico mantém padding=0 por compatibilidade; use padding=8 em novas chamadas.

Para reparar candidatos existentes: `python repair_spacing.py --output DIRETORIO --project FONTES_CONGELADAS --padding 8`. O comando confere hashes, guarda a versão anterior em history_spacing e remove somente fragmentos de componentes grandes cuja maior parte está fora do recorte. Partículas pequenas e sobreposições ambíguas ficam preservadas. A repetição parte do backup, sem remoção acumulativa. Não execute produção e reparo simultaneamente. A remoção não recupera ferramentas ou membros já cortados na referência; esses casos continuam exigindo revisão artística. Após reparar, execute review_catalog.py e test_godot.ps1 em cada exportação.
