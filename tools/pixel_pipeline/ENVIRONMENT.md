# Inspeção e plano técnico — 18/10/2026

Inspeção realizada no Windows do usuário, não em máquina remota.

## Evidências antes da implementação

- Projeto correto: `C:\FarmSlime`, remote `https://github.com/HelioConde/Slime-Harvest.git`, nome `Slimekeepers: Lost Valley`, commit inicial `b4a7d83`.
- `C:\Users\helio\Documents\Slimekeepers-Lost-Valley` é o repositório Roblox e não foi modificado.
- O projeto Godot já estava aberto e tinha alterações locais em sprites, scripts e cenas. Nenhuma delas foi incluída nos commits do pipeline.
- Python do WebUI: 3.10.11; Pillow antigo no venv do WebUI 9.5.0. Criado venv próprio com Pillow 11.3.0.
- RX 580: **8.589.934.592 bytes (8 GiB)** pelo `HardwareInformation.qwMemorySize` do driver. `Win32_VideoController.AdapterRAM` reportava cerca de 4 GiB truncados: não usado como capacidade definitiva.
- DirectML enumerou RX 580 no índice 0 e Intel UHD 730 no índice 1.
- RAM visível: 16.559.992 KiB; livre no início: 5.405.268 KiB. Esses valores são instantâneos.
- Checkpoint único: `v1-5-pruned-emaonly.safetensors`, 4.265.146.304 bytes, hash WebUI `6ce0161689`.
- LoRA único: `pixel_art.safetensors`, 3.226.184 bytes. Cabeçalho lido via safetensors, metadado `format=pt`, chaves `unet.down_blocks...attn1.to_k.lora.down.weight`.
- O carregador A1111 instalado, sem `diffusers_weight_map`, divide chaves no primeiro ponto: essa família vira `unet`, sem correspondência às camadas. Há conversão de nomes Diffusers no código, mas não comprova suporte a esse empacotamento. **Não habilitado nem convertido.** Compatibilidade prática não aprovada.
- Nenhuma extensão de terceiros instalada. A pasta extensions continha apenas o arquivo marcador.
- API inicialmente desligada, conexão recusada. Nenhum Python do WebUI rodando. `webui-user.bat` sem argumentos configurados.
- Godot 4.7.2 instalado em `C:\godot`; projeto usa filtragem Nearest no código de skins.
- Atlas femininos: células ~222 px e caminhada lateral revisada com células 256 px; escala do jogo 0,16. Não substituir diretamente por sprites 64 px com essa escala.

## Plano adotado

1. Implementar tudo em `tools/pixel_pipeline`, preservar jogo/WebUI.
2. Usar stdlib HTTP + Pillow, interface loopback e processamento CPU.
3. Testar API/base antes de LoRA. Geração sequencial, batch 1, 256 px; 384 apenas opção experimental não medida.
4. Manter referências por quadro, paleta comum, origem explícita, mask opcional e revisão obrigatória.
5. Exportar prévia Godot isolada; testar sem tocar nas animações ativas.
6. Manter histórico e resultados de falhas, com aprovação de identidade separada da aprovação de animação.

## Execução real

WebUI iniciado usando seu venv com `--skip-prepare-environment --use-directml --device-id 0 --lowvram --no-half --no-half-vae --opt-split-attention-v1 --api`. Sem reinstalação, extensão ou download de pesos. `cmd-flags` da API confirmou os parâmetros. DirectML enumeração + índice explícito + contadores GPU do processo confirmam execução local na RX 580. A indicação de ONNX CPU no log se refere ao provider ONNX; não determina o dispositivo do PyTorch DirectML.

Uma amostra durante execução registrou 2.266.169.344 bytes de memória GPU dedicada e 576.577.536 compartilhada para o processo do WebUI. Não é pico de consumo. A API `/memory` retornou CUDA indisponível, portanto seus campos CUDA não foram tratados como medição DirectML. O fallback `mem_get_info` do código DirectML tem constante de 8 GiB; por isso a capacidade foi obtida do driver, independentemente desse fallback.

Testes a 256 px: txt2img 8 passos ~29,5 s; img2img 8 passos/denoise 0,30 ~10,6 s. Teste adicional 24 passos não eliminou distorções. Nenhum OOM observado nesses testes, mas isso não estabelece ausência de OOM em 384 px ou com ControlNet.

Visualmente, txt2img produziu padrões geométricos sem personagem utilizável. Img2img preservou uma aparência aproximada, porém introduziu artefatos severos e alterou detalhes. Causa exata não isolada: resolução, backend/driver e modelo ainda precisam de diagnóstico comparativo. Não atribuir automaticamente a falta de VRAM.

A identidade da personagem existente foi explicitamente aprovada pelo usuário nesta sessão. Animações continuam experimentais. Nas referências já existentes foram observados fragmentos desconectados na linha traseira, diferenças de escala entre idle/walk e alternância anatômica que não pode ser certificada apenas por atlas.

Os relatórios finais e imagens do ensaio ficam nos outputs da conversa. O processamento de fixtures é identificado como `existing_game_atlas`; gerações reais têm `mode=img2img`, parâmetros e tempos individuais. Nenhum desses rótulos equivale a aprovação visual.

Ensaio completo finalizado: 36 gerações img2img, 12 passos, denoise 0,25, seed 1234, 256×256, exportadas em 64×64. Tempo total das chamadas ~462,23 s (7min42s), média ~12,84 s/quadro. Paleta final comum às cinco sequências, extraída das referências aprovadas; máscara de cada referência preservada. Sem OOM observado. Cinco importações Godot concluídas: idle_down4, walk_down8, walk_up8, walk_left8, walk_right8.

Teste adicional txt2img com `randn_source=CPU` por override temporário e 16 passos também produziu padrões sem personagem utilizável. A opção original GPU foi restaurada pelo WebUI. Isso não isolou a causa do problema; não foi adotado como correção.
