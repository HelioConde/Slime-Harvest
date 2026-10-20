# Biblioteca de 19 pacotes — Slimekeepers: Lost Valley

O jogo agora tem um instalador dos 19 arquivos originais fornecidos pelo dono do projeto, um **catalogo navegavel com F7** e sistemas opcionais no mapa principal. Os PNGs de terceiros permanecem fora dos commits publicos. Abrir o repositorio sem os ZIPs continua sendo suportado.

## Instalar no Windows

1. Atualize seu projeto com `git switch main` e `git pull origin main`.
2. Coloque os **19 ZIPs originais** em uma mesma pasta sem alterar seus nomes, por exemplo `C:\MeusPacks`.
3. No terminal na pasta de `project.godot`, use:

```powershell
py -3 tools/install_all_art_packs.py --source-dir 'C:\MeusPacks' --dry-run
py -3 tools/install_all_art_packs.py --source-dir 'C:\MeusPacks'
```

Se voce recebeu o ZIP local consolidado em vez dos ZIPs originais, extraia-o **diretamente** na pasta de `project.godot` e nao execute o instalador novamente. O programa nao substitui arquivos personalizados sem `--replace`.

## Integracao por pacote

| Pacote | Destino local | Uso nesta etapa |
| --- | --- | --- |
| FREE 64 Tiny Animals | `expansion_packs/tiny_animals/` | Seis animais pacificos em pontos seguros do World; os 64 ficam na biblioteca |
| FREE Mana Seed Character Base Demo | `expansion_packs/mana_character/` | Folhas de personagem para NPCs futuros, galeria F7 |
| SuperRetroRanch FreeTier v34 | `expansion_packs/ranch/` | Folhas de cultivos, personagens e tiles, galeria F7 |
| PostApocalypse AssetPack | `expansion_packs/post_apocalypse/` | Props de ruinas para futuros biomas, galeria F7 |
| char free | `expansion_packs/char_free/` | Alternativa de personagem, galeria F7 |
| Little Dreamyland Free Pack | `expansion_packs/dreamyland/` | Animacoes de coelho, cenarios e cultivos, galeria F7 |
| Mana Seed inverno | `expansion_packs/season_winter/` | Exibicao sazonal, tiles/waterfall, galeria F7 |
| Mana Seed Farmer Free Sample | `expansion_packs/mana_farmer/` | Base personalizavel de fazendeiro, galeria F7 |
| Treasure Chests 1.2a | `expansion_packs/treasure_chests/` | Bau interativo no World: madeira, uma vez por slot |
| Mana Seed outono | `expansion_packs/season_autumn/` | Exibicao sazonal, galeria F7 |
| Mana Seed primavera | `expansion_packs/season_spring/` | Exibicao sazonal, galeria F7 |
| Mana Seed verao | `expansion_packs/season_summer/` | Exibicao sazonal, galeria F7 |
| Gentle Forest 3.0a | `expansion_packs/gentle_forest/` | Tiles para mapas e biomas, galeria F7 |
| Breakable Pots 1.1a | `expansion_packs/breakable_pots/` | Vaso interativo no World: pedras, uma vez por slot |
| Sprout Lands Sprites Basic | `assets/sprout_lands/sprites/` | Personagens, cenarios, ferramentas, plantas e animais |
| Sprout Lands UI Basic | `assets/ui/sprout_lands/` | Slots, vida, mochila e novos paineis reais do pack |
| Sprout Lands TileMap 0.2.0 | `addons/sprout_lands_tilemap/` | Base de mapa, exemplo e plugin instalados mas desativados |
| Sprout Lands UI 0.2.0 | `addons/sprout_lands_ui/` | Tema adaptado ao Slimekeepers, plugin desativado |
| Sprout Sorry | `assets/Characters/sprout_sorry/` e `expansion_packs/sprout_sorry_extra/` | Protagonista e animacoes 8-direcoes corrigidas, audio/efeitos acessiveis |

Os caminhos relativos da coluna Destino local de expansion_packs comecam em `assets/`. O pacote Ranch **nao** instala `assets_premium_preview/`: esses arquivos sao demonstracoes Premium, nao incluidos para uso no tier gratuito.

## Controles

- **F7** no menu ou no World: abre a galeria dos 19 packs. **←/→** navegam, **Esc** retorna ao menu.
- **F5** joga no World. Com os assets instalados, visitantes aparecem no mapa e um bau/vaso surgem em relva sem ocupacao.
- **E** perto de bau/vaso: coleta recursos uma so vez por fazenda. O estado usa o ResourceBag ja existente, com os slots e o reset do mundo.
- **F10** no World: opcoes de personagem e HUD; agora a altura da janela e rolavel, e o painel vem do sprite real `settings_menu.png`.
- O menu principal usa o mesmo painel. O Sprout Sorry foi corrigido em orientacoes horizontais e diagonais.

## Licencas: LEIA antes de publicar

Apos examinar os arquivos de licenca incluidos nos ZIPs:

- **Tiny Animals (JedimeisterX / Pixel-Deck.com):** uso pessoal e comercial permitido, sem revenda do pack isolado.
- **Sprout Lands e Sprout Sorry (Cup Nooble):** os Basic ZIPs sao somente nao comerciais por padrao; o usuario informou ter permissao comercial. Confirmar que cobre individualmente TODOS os packs aplicaveis. Credito a Cup Nooble exigido.
- **Sprout plugins (Maaack / Marek Belski):** codigo MIT, mas arte sujeita aos termos de Cup Nooble.
- **SuperRetroRanch Free Tier (Gif):** somente nao comercial, sem redistribuir; previews Premium foram omitidos do instalador.
- **Little Dreamyland Free (Starmixu & Utaskuas):** somente nao comercial, sem redistribuir; credito exigido.
- **PostApocalypse (TheLazyStone):** gratuito para uso nao comercial; uso comercial requer pagamento de pelo menos US$ 2 conforme LICENSE.txt; sem redistribuir o pack.
- **Mana Seed / Gentle Forest / Treasure Chests / Breakable Pots (Seliel the Shaper):** os readmes identificam autor/pack, mas os readmes aqui nao esclarecem todas as permissoes comerciais; confirme os termos do autor antes de comercializar.
- **char free:** o ZIP nao apresentou termos de licenca identificaveis. Nao publicar comercialmente sem verificar a fonte.

Os assets sao instalados **apenas na copia local** e ficam excluidos do `.gitignore`. Nao redistribua esses ZIPs em um repositorio aberto. Para compilar e distribuir um jogo comercial, obtenha autorizacoes adequadas para cada conjunto de arte; instalar nao e uma licenca.

## Limites desta versao

O laboratorio permite **inspecionar** os 19 packs e os objetos basicos no World; isso nao significa que todas as centenas de props, mecanicas de animais, 4 estacoes dinamicas, sistemas de roupa e biomas PostApocalypse tenham sido implementados. Ativacoes profundas ficam para fases por pacote com testes de colisoes e saves. Os arquivos foram preservados em pastas separadas para evitar trocar art de forma incompatível.

## Testes

- `python -m unittest discover -s tools/tests -p 'test_install_all_art_packs.py' -v` verifica importador sem sprites reais.
- `tests/AssetPackExpansionTest.tscn` valida recompensas unicas, mapa opcional, mapeamento Sprout e 19 entradas.
- O CI testa tambem toda a suite Godot headless existente. Para QA visual, teste com os assets reais no Godot local.
