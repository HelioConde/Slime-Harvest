# Espaços de salvamento: três fazendas independentes

Novo jogo permite criar uma fazenda em um espaço livre ou substituir a fazenda ativa. A substituição exige uma confirmação adicional. O sistema guarda um backup anterior em user://slimekeepers_slot_snapshots/ antes de limpar dados.

Os seis arquivos legados são preservados na migração: calendário, recursos/drops, árvores, casa, solo e equipamento. O espaço ativo usa user://; os outros espaços usam snapshots isolados e são recarregados antes de entrar no mundo.

Os testes usam diretórios test_slimekeepers_slots_* exclusivos e não modificam o save real. O tempo jogado ainda não é medido; não mostramos valores inventados.

Multiplayer continua desativado, separado dos saves locais.

Criado por Hélio Conde.
