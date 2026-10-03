# Estrutura do projeto

- `assets/sprites/player/`
- `assets/sprites/slimes/`
- `assets/sprites/crops/`
- `assets/sprites/npcs/`
- `assets/tilesets/`
- `assets/ui/`
- `assets/audio/music/`
- `assets/audio/sfx/`
- `assets/fonts/`
- `scenes/world/`
- `scenes/player/`
- `scenes/slimes/`
- `scenes/farming/`
- `scenes/ui/`
- `scripts/core/`
- `scripts/player/`
- `scripts/slimes/`
- `scripts/farming/`
- `scripts/ui/`
- `data/crops/`
- `data/slimes/`
- `data/items/`
- `tests/`
- `tools/`

## Convenções

- Arte em assets; lógica em scripts; composição visual em scenes; definições em data.
- Documentar origem e licença de assets externos antes de adicioná-los.
- Não adicionar arquivos do GameSlime antigo sem instrução explícita.
- Definir engine e versão antes de criar configurações ou código dependentes delas.
- Builds e saves locais não devem entrar no repositório.
