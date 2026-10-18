# Requisitos e cobertura do MVP

| Requisito | Implementação / evidência | Limite |
|---|---|---|
| Inspeção inicial | GPU/driver, RAM, processos, modelos, cabeçalho LoRA, API, remote e atlas examinados antes de criar arquivos | VRAM observada por amostra, não monitoramento contínuo do pico |
| Preservar instalação e jogo | Ferramenta nova em tools; venv próprio; API iniciada sem preparação de dependências | WebUI escreve seus logs/cache/params normais durante execução |
| Personagens, slimes, NPCs, animais, objetos, vegetação, itens | Prompt livre, categorias, txt2img/img2img, referência PNG | Sem modelos específicos por categoria |
| Pesquisa de modelos | MODEL_RESEARCH.md, fontes primárias, formato e licenças declaradas | Sem benchmark dos candidatos não instalados; licenças incertas não tratadas como autorização comercial |
| Pixel art | Nearest, quantização, paleta compartilhada/configurável, dithering, alpha binário, limpeza opcional | Não transforma automaticamente imagem ruim em arte de qualidade |
| Remoção de fundo | Flood fill branco conectado à borda; máscara de referência opcional | Sem segmentação semântica de cenários complexos |
| Consistência | Referência posada própria por quadro, seed fixa, denoise limitado, paleta comum e mask opcional | Identidade e anatomia não garantidas pela difusão |
| Oito fases de caminhada | Manifestos e guias front/back/left/right com lados anatômicos e oposição dos membros | Guias esquemáticos; não retargeting nem verificação anatômica automática dos pixels |
| Outras ações e slimes | Enum extensível e fluxo genérico de quadros | Usuário fornece poses próprias para ação/habilidade |
| Alinhamento | Origens por quadro, alvo comum, rejeição de clipping | Sem inferência automática de pé/centro de massa |
| Exportação | RGBA individual, horizontal, grade, APNG, JSON, SpriteFrames e cena Godot | APNG pode parecer estático em visualizadores sem suporte |
| Interface portuguesa | Geração, processamento, antes/depois, fila, biblioteca e revisão por quadro | Não possui pintura de pixels dentro do navegador |
| Fila e histórico | Worker único, cache, tempos, persistência atômica, pausa após erro | Usar uma instância por WebUI; não retomada automática de jobs após reinício |
| Cancelamento | Após quadro em andamento, mantém resultados parciais | Não aborta imediatamente a computação GPU |
| Hardware AMD | DirectML 0, SD1.5, 256, batch 1, no-half e lowvram | 384 disponível, mas não qualificado por benchmark; ControlNet não instalado |
| Testes | Unitários, contratos API, cache/erro/cancelamento, geração real e Godot headless | Aprovação visual continua humana |
| Protótipo feminino | Base existente aprovada pelo usuário; ensaio de idle4 + walk8 em quatro direções; exportação64 | Novos quadros experimentais, não aprovados para produção |
| Integração no jogo | Recurso/cena/projeto de prévia e teste de importação | Nenhum sprite ativo substituído |

Critério de sucesso artístico permanece aberto: o backend/modelo atual gerou artefatos e as referências herdadas têm problemas. A criação de PNGs, aprovação de testes ou metadados corretos não encerram esse critério.
