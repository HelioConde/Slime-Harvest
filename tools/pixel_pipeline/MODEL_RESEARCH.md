# Modelos e extensão — pesquisa em 18/10/2026

Comparação documental, não benchmark de modelos que não estão instalados. Não foram baixados checkpoints nem LoRAs.

| Opção | Evidência e formato | Qualidade/consistência | DirectML, VRAM e tempo | Licença / decisão |
|---|---|---|---|---|
| SD 1.5 instalado | safetensors local, hash 6ce0161689 | Testes reais apresentaram artefatos; txt2img não utilizável | Executou DirectML 0; tempos no relatório; sem OOM observado | Preservado como baseline. Procedência/licença do arquivo local não comprovada pelo nome. |
| PublicPrompts All-In-One-Pixel-Model | Card descreve sprites `pixelsprite` e cenários `16bitscene`; árvore oferece checkpoint `.ckpt` e Diffusers | Autor avisa que saída não é pixel-perfect; consistência temporal não demonstrada | Família SD1; compatibilidade concreta no fork não testada; VRAM/tempo não medidos | Card declara CreativeML OpenRAIL-M. Não baixado; preferir distribuição safetensors verificável e revisar licença integral antes de uso comercial. |
| Onodofthenorth SD_PixelArt_SpriteSheet_Generator | Card oferece quatro vistas; árvore possui `PixelartSpritesheet_V.1.ckpt` e Diffusers | Exemplos de direções, sem garantia de oito passos coerentes | Não testado nesta RX 580; sem benchmark comparável | Card declara Apache-2.0, mas verificar licença dos pesos/base e de qualquer merge separadamente; não baixado. |
| LoRA pixel_art local | Cabeçalho safetensors, nomes Diffusers | Não avaliado com geração | Empacotamento não validado no carregador A1111 local | Origem/licença desconhecida; mantido desativado. |
| AziibPixelMix (megaaziib) | Repositório oficial oferece `AziibPixelMix_Full.safetensors`, 5,67 GB | Especializado em pixel art; nenhuma avaliação temporal local | Não medido; arquivo maior não permite inferir diretamente VRAM de inferência | Card declara `other`, sem condições comerciais claras na página consultada. Não baixado enquanto licença exata estiver pendente. |

Os dois candidatos especializados pertencem à família SD1, mas a documentação consultada não estabelece de modo suficiente a versão exata de treinamento e uma distribuição safetensors pronta para este A1111. Portanto não são apresentados como checkpoints SD1.5 já validados. Sem teste local e procedência, não há recomendação de substituir o baseline.

Fontes primárias:

- https://huggingface.co/PublicPrompts/All-In-One-Pixel-Model
- https://huggingface.co/PublicPrompts/All-In-One-Pixel-Model/tree/main
- https://huggingface.co/Onodofthenorth/SD_PixelArt_SpriteSheet_Generator
- https://huggingface.co/Onodofthenorth/SD_PixelArt_SpriteSheet_Generator/tree/main
- https://huggingface.co/megaaziib/aziibpixelmix
- https://huggingface.co/megaaziib/aziibpixelmix/tree/main

## sd-webui-pixelart

Fonte: https://github.com/mrreplicart/sd-webui-pixelart

Código consultado: https://raw.githubusercontent.com/mrreplicart/sd-webui-pixelart/master/scripts/pixelart.py

O script usa hooks do WebUI/Gradio e pós-processamento com quantização, dithering e redimensionamento. Converte a imagem a RGB e depois a RGBA; isso não preserva uma máscara de transparência previamente existente. Também não implementa validação de poses, alinhamento temporal nem exportação SpriteFrames.

Não foi instalada: isso exigiria alterar e reiniciar a instalação preservada e não resolveria os critérios principais do pipeline. Foi implementada alternativa independente em Pillow. Compatibilidade de execução da extensão com a versão instalada **não testada**; a análise é de código, não uma afirmação de incompatibilidade.

## Próximos ensaios controlados

Antes de ampliar produção: comparar 256/384 com mesma referência, sampler e seed, verificar geração de ruído CPU versus DirectML, revisar logs/driver, e testar modelo SD1.5 especializado apenas após verificar origem, formato e licença. Registrar identidade, leitura de silhueta, coerência dos membros, paleta, VRAM e tempo por quadro. ControlNet permanece desabilitado até haver margem de memória e evidência de benefício.
