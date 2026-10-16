# F1 — reset seguro do mapa (debug/editor)

Pressione F1 enquanto a cena World estiver aberta pelo F5 ou F6. A janela de confirmacao permite Cancelar (Esc) ou Confirmar reset. Nao executa automaticamente.

O reset limpa dados do mapa ATUAL: casa construida, solo arado, arvore/tocos, pedras mineradas, objetos/plantas coletados, drops persistidos. Preserva inventario (counts), calendario, equipamento e outros saves. Depois reinicia a cena World.tscn usando os novos objetos e sprites presentes no projeto. Nao modifica arquivos .tscn nem objetos pintados no editor.

Um backup dos arquivos de progresso anteriores fica em user://slimekeepers_slot_snapshots/slot_X_antes_reset_mapa_f1_... e o caminho fica no indice de saves. Se falhar, ha tentativa de rollback e aviso ao usuario.

Atalho habilitado apenas em compilacoes debug. Testes automatizados usam uma subpasta sandbox, sem tocar na fazenda real.
