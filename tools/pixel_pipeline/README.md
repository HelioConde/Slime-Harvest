# Oficina de sprites — Slimekeepers: Lost Valley

> Revisão de qualidade: o primeiro ensaio foi rejeitado. Leia `QUALITY_V2.md`. O importador agora respeita margens Godot, não estica referências e não torna bordas brancas opacas. A interface sugere512px/20passos/denoise0,12; resultados continuam sujeitos à revisão visual.

MVP local em Python 3.10+, Pillow e API AUTOMATIC1111. Não usa OpenAI, CUDA, ROCm, serviços pagos nem dependências do WebUI para o processamento. Os originais do jogo e a instalação de Stable Diffusion são preservados.

## Instalação e execução no Windows

Na pasta `C:\FarmSlime\tools\pixel_pipeline`:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
powershell -ExecutionPolicy Bypass -File .\start_webui.ps1
.\start.bat
```

Abra http://127.0.0.1:8877. `install.ps1` cria somente `.venv` nesta pasta e instala Pillow. O script do WebUI reutiliza o ambiente existente, adiciona `--api`, seleciona DirectML 0 e não instala pacotes. Não altera `webui-user.bat`. Se já houver servidor na porta 7860 sem API, informa o conflito. O WebUI continua disponível em http://127.0.0.1:7860.

O dispositivo 0 foi identificado como RX 580 nesta máquina. Em outro computador, execute `inspect_environment.ps1` e forneça `-DeviceId` ao script de inicialização conforme o índice DirectML detectado. Nunca presuma que 0 sempre será AMD.

## Fluxo de produção

1. Criar uma base por txt2img ou selecionar a imagem existente. A categoria organiza o histórico; descreva a espécie/aparência no prompt.
2. Aprovar a identidade visual da base. Isso não aprova a animação.
3. Para caminhada, preparar oito imagens da **mesma personagem já posada**, em ordem. Usar referências distintas para cima/baixo. `cli.py templates` cria guias coloridos e JSON das fases, não um rig automático.
4. Enviar as referências, selecionar img2img e mesma seed. No ensaio revisado desta RX580, usar512px, 20passos e denoise0,12 como ponto inicial conservador. Batch e n_iter são sempre1. Nunca encadear saída do quadro anterior como referência do próximo.
5. Opcionalmente limitar o alpha à máscara das referências. O pipeline remove o fundo branco conectado à borda, intersecta as máscaras e restaura o contorno de1pixel/lacunas com cores da referência na resolução final. Isso não assegura rosto ou membros corretos; referências com fragmentos precisam de correção.
6. Aplicar paleta compartilhada, Nearest Neighbor, alpha binário, remoção de fundo branco por conectividade e limpeza opcional de pixels isolados. Fundo não uniforme exige máscara manual; o pipeline não inclui segmentador neural.
7. Informar os pontos de origem por quadro em pixels da resolução final, se houver deslocamento. Exemplo: `[[32,62],[33,61],...]`. O alvo é `(largura/2, altura-2)`. O alinhador rejeita cortes de silhueta. Sem pontos explícitos, preserva o canvas; não infere automaticamente o quadril ou o pé de apoio.
8. Conferir todos os quadros e a APNG, corrigir imagens problemáticas e reprocessar. Para um quadro isolado, quantidade 1; depois reenviar a sequência completa corrigida.
9. Registrar aprovação visual somente após corrigir falhas estruturais, marcar todos os quadros/critérios e identificar o revisor. A interface mantém resultados não aprovados na biblioteca experimental.
10. Exportar e abrir o projeto Godot de prévia separado. Só depois copiar os arquivos aprovados para uma pasta nova do jogo e ajustar seus caminhos `res://`.

## Saídas

Cada trabalho fica em `data/<id>/`:

- `input/`: referências originais; `raw/`: imagens recebidas do WebUI.
- `history.json`: parâmetros, seed, endpoint, informação retornada pelo WebUI e tempo por quadro.
- `job.json`: estado persistido; arquivos parciais ficam disponíveis após erro/cancelamento.
- `export/frames/*.png`: PNGs RGBA individuais.
- `export/sheet.png`: horizontal; `grid.png`: até quatro colunas.
- `export/preview.png`: **APNG animado**; alguns visualizadores mostram apenas o primeiro quadro. Abra no navegador.
- `export/metadata.json`: personagem, animação, direção, resolução, FPS, origem, grade, proveniência e validação.
- `export/project.godot`, `Preview.tscn`, `frames.tres`: prévia independente, Nearest e origem explícita.

Não importe a subpasta inteira como um segundo projeto dentro do projeto principal. Copie sheet/recurso/cena aprovados para uma pasta nova, remapeie `res://sheet.png` e `res://frames.tres`, e mantenha `texture_filter = 1`. O jogo atual usa sprites maiores com escala 0,16; esse valor não deve ser aplicado automaticamente aos novos quadros 64×64. Reavalie a escala de exibição sem mudar colisão/física.

## Fila, cancelamento e recuperação

Um worker executa os trabalhos sequencialmente. O cancelamento é cooperativo: o quadro atual termina e então o trabalho para; não envia interrupção global que poderia atingir outra geração do WebUI. A espera máxima por chamada é 900 s. Após falha de geração, a fila pausa; confirme o estado do WebUI antes de retomar. O servidor pode continuar gerando depois de um timeout de rede: aguarde ou interrompa essa tarefa na própria interface WebUI antes de retomar.

Cache por conteúdo de referência, parâmetros e opções do WebUI. Não há garantia de reprodução bit a bit entre drivers, versões do backend ou modelos com arquivos substituídos sob o mesmo nome. Mantenha arquivos/versionamento estáveis e limpe apenas o cache desse pipeline se mudar pesos sob o mesmo nome. Tarefas interrompidas por reinício não são retomadas automaticamente; reenvie as referências/configurações para aproveitar o cache.

Execute apenas uma instância da oficina para a mesma instalação do WebUI. Evite gerar simultaneamente na interface nativa. Reiniciar o pipeline não reinicia o WebUI. Os servidores locais são encerrados ao fechar seus processos; `start_webui.ps1` informa o PID e grava logs em `data`.

## Testes reproduzíveis

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
.\.venv\Scripts\python.exe cli.py health
.\.venv\Scripts\python.exe cli.py templates --output data/templates
.\.venv\Scripts\python.exe cli.py demo --project C:\FarmSlime --output data/demo
.\test_godot.ps1 -Export "$PWD\data\demo\walk_down"
```

`demo` extrai em modo somente leitura a personagem feminina existente: idle frontal 4 + quatro caminhadas de 8, total 36. **É fixture de processamento, não geração por difusão.** Só acrescente `--base-approved` após aprovação humana real.

Testes GPU opt-in:

Para reproduzir o ensaio completo de 36 quadros (usa GPU por vários minutos), pare o servidor da oficina para evitar duas filas e execute:

```powershell
.\.venv\Scripts\python.exe experiment.py --project C:\FarmSlime --output data/experiment --resolution 512 --steps 20 --denoise 0.12
```

O script utiliza uma paleta de referência comum às cinco sequências. Acrescente `--base-approved` somente após aprovação humana da referência. Não aprova animações automaticamente.

Teste curto de conexão + txt2img + img2img:

```powershell
$env:PIXEL_LIVE_TEST='1'
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
Remove-Item Env:PIXEL_LIVE_TEST
```

Os testes sem GPU usam fixtures sintéticas criadas localmente; validam payloads, transparência, paleta, dimensões, frames, duplicatas, origem, exportação, fases de pose, cache, erro e cancelamento. A alternância das fases JSON **não prova** que os pixels têm anatomia correta. O teste Godot carrega recursos/cena, verifica contagem/dimensões e Nearest. Aprovação artística exige revisão humana.

## Escopo e limitações

- Resoluções finais: 32, 48, 64, 96 e 128; geração256,384 ou512.
- Walk: templates de oito fases nas quatro direções. Idle e demais ações têm transporte/exportação genéricos; run/attack/hurt/death/interact/tool_use/watering/planting/harvesting/jump/water_jet precisam de referências próprias.
- Não há rig humano automático, ControlNet instalado, editor de pintura pixel a pixel, remoção de fundo semântico, LoRA convertido nem modelo especializado baixado.
- A validação de fragmentos pode marcar efeitos intencionais (água, partículas) para revisão. Atualmente ela bloqueia aprovação; corrija/separe efeitos antes de aprovar o corpo da personagem.
- Os templates são guias esquemáticos com lados anatômicos identificados, não ciclos biomecânicos prontos. Não corrige automaticamente pernas trocadas de uma referência defeituosa.
- A consistência de identidade ainda depende de referências de qualidade e ajustes manuais. Ver `ENVIRONMENT.md` e `MODEL_RESEARCH.md` para resultados e decisões reais.

O objetivo de animações prontas para produção ainda depende de superar as falhas visuais observadas no backend/modelo local. A ferramenta pode processar e exportar arte corrigida manualmente sem usar a IA.

## Revisão das caminhadas da aventureira

`revise_walks.py` reproduz o ensaio específico da personagem existente. Recupera os corpos completos de frente/costas do atlas original, cujo recorte regular cortava os pés; mantém as referências laterais existentes. Usa escala fixa e registro pelo centro da cabeça, sem modificar o recurso ativo do jogo. Exige `--output` e `--palette-job` (job.json do idle V2 para compartilhar a paleta). Comece com `--phase samples`; após inspeção, use `--phase full` no mesmo diretório para aproveitar o cache. Consulte `QUALITY_WALKS_V2.md` para limites e resultados.

## Catálogo completo e preservação do player

Use production.py para a produção atual; leia PRODUCTION.md. O catálogo reúne 44 ações e mantém os tempos reais de idle/walk. O ensaio legado de 36 quadros não é o fluxo de preservação aprovado. As novas exportações ficam separadas e exigem revisão antes de integração.
