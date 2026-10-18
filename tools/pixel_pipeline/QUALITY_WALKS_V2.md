# Caminhadas — revisão 2

Ensaio experimental da aventureira existente: quatro direções, oito quadros de 64×64 por direção, reprodução a 8 FPS. A referência de identidade foi aprovada pelo usuário; as novas animações permanecem para revisão visual.

## O que mudou

- Reconstrução das margens do AtlasTexture e escala uniforme, conforme a correção da versão 2.
- Recuperação dos corpos completos nas vistas de frente e costas diretamente do atlas. Os recortes Godot de 222 pixels cortavam os pés e incluíam fragmentos da linha anterior. As novas referências usam canvas 256×256, escala fixa, registro horizontal pelo centro da cabeça e deslocamento vertical comum por sequência. As coordenadas de origem e translações estão em `limpeza_referencias.json`. As imagens e recursos ativos do jogo não foram modificados.
- Refinamento img2img em 512×512, 20 passos solicitados, denoise 0,12, Euler, CFG 6, seed 1234. Com denoise baixo, o WebUI executa menos iterações efetivas de difusão; 20 é o parâmetro enviado.
- Paleta de 24 cores compartilhada com o idle V2. Sem dithering. Máscara e contorno da referência preservados após o refinamento.
- Remoção final de pixels isolados sem vizinhos em oito direções, registrada por quadro nos metadados. A redução para 64×64 deixava um pixel isolado no quadro 3 da caminhada à esquerda.

## Como avaliar

Abra `REVISAR_CAMINHADAS.html`. A coluna esquerda mostra a referência preparada em 64×64 com a mesma paleta; a direita mostra o refinamento. O botão pausa as quatro sequências; cada controle permite selecionar um quadro. Há velocidades de 4, 8 e 12 FPS.

A vista frontal original é de três quartos. As poses, os passos e os detalhes do cabelo vêm da arte existente. Este ensaio não cria uma nova mecânica de caminhada nem comprova correção anatômica. As fases declaradas no JSON são guias; não substituem a inspeção dos pixels. O cabelo ainda contém textura da referência, e o refinamento pode alterar pequenos detalhes entre quadros.

## Reprodução

O script `reproduzir.py` usa o pipeline instalado em `C:\FarmSlime\tools\pixel_pipeline` e o WebUI local. Exige `--output` e `--palette-job` (o `job.json` do idle V2). Use `--phase samples` para um quadro por direção e, depois de inspecionar as amostras, `--phase full` para os ciclos completos. Use o mesmo diretório de saída para reaproveitar o cache. Não execute duas filas de geração simultaneamente. O script preserva raws, referências e parâmetros; a limpeza final e a página de comparação são feitas pelo script `montar_revisao.py` nesta entrega.

## Estado

As gerações anteriores rejeitadas continuam separadas. Nenhum sprite ativo do jogo foi substituído. A validação estrutural e a importação Godot são verificações técnicas, não aprovação artística.

## Verificação desta entrega

- 32 quadros finais: quatro sequências com oito quadros; todas passaram na validação estrutural (dimensões, alpha binário, margem, componentes, duplicatas e apoio).
- Godot 4.7.2: quatro importações concluídas, cada recurso com oito frames de 64×64 e filtro Nearest. Logs e `godot_results.json` acompanham a entrega.
- Suíte local: 23 testes passaram; um teste GPU opt-in foi ignorado. As gerações reais foram executadas fora dessa suíte.
- Os 32 quadros foram inspecionados em prancha. A página tem seus caminhos locais conferidos; os controles não foram testados no navegador porque a automação bloqueia URLs file://.
- Resultado permanece experimental, com textura no cabelo e poses herdadas da referência.
