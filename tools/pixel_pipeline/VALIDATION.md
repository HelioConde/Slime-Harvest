# Validação — 18/10/2026

## Código e integração

- 19 testes automatizados locais passaram; 1 teste opt-in de GPU ficou desabilitado na suíte padrão.
- Geração GPU foi executada separadamente: txt2img e img2img com 8/24 passos, 36 quadros de animação a 12 passos e teste adicional de ruído CPU.
- API local retornou modelo e parâmetros esperados; processamento submetido via HTTP concluiu e apareceu na biblioteca do navegador com antes/depois e links.
- Godot 4.7.2 importou e carregou recursos/cenas dos cinco exports reais. Marcadores `PIXEL_PIPELINE_IMPORT_OK` confirmaram 4/8 quadros, dimensões64 e Nearest.
- Cancelamento cooperativo, reinício, cache e pausa após erro verificados com fixtures, sem induzir OOM real no computador.
- Sprite sheets foram conferidas por roundtrip de pixels; APNG por quantidade de quadros; teste estrutural não é validação artística.

## Ensaio real

| Sequência | Quadros | Tempo API aproximado | Resultado artístico |
|---|---:|---:|---|
| Idle frontal | 4 | 51,66 s | Experimental: textura/rosto variam; silhueta toca borda |
| Walk frontal | 8 | 103,25 s | Experimental: detalhes mudam; alternância dos membros não certificada |
| Walk traseiro | 8 | 102,31 s | Experimental: fragmentos de outro quadro herdados das referências e textura variável |
| Walk esquerda | 8 | 103,15 s | Experimental: fragmento no quadro3 e alterações internas |
| Walk direita | 8 | 101,86 s | Estrutura passou; visual não aprovado — isso demonstra por que PNG válido não basta |

Total: 36 quadros, ~462,23 s. Nenhuma falha OOM observada. Não foi medido o pico de VRAM, nem feito benchmark em384. Base visual aprovada explicitamente pelo usuário; **nenhuma animação foi aprovada**. Nenhum recurso ativo do jogo foi substituído.

Inspeção visual foi feita na imagem de contato e nos exemplos brutos. Não há análise cinemática instrumentada de cada pé, centro de massa ou deslizamento; esses itens permanecem pendentes de revisão/correção humana. As fases dos guias de pose foram testadas, mas não usadas como prova de anatomia nos resultados.

## Limitações que impedem aprovação para produção

1. txt2img com o backend/modelo atual retorna padrões distorcidos, inclusive com mais passos e ruído CPU.
2. img2img conserva a aparência aproximada da referência, porém muda rosto, cabelo, roupas e textura.
3. Referências existentes incluem fragmentos e possíveis falhas de pose. Máscara preservada também preserva esses defeitos.
4. Templates são guias; o MVP não reconstrói automaticamente um rig anatômico do personagem.

O MVP funciona como ferramenta de preparação, experimentação, inspeção e exportação. O critério de animações novas consistentemente prontas para produção **não foi atingido** neste ensaio.
