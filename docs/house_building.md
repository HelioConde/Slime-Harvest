# Construção da casa — modo de teste

Execute a cena do mundo que contém HouseBuilder. Pressione **B** para abrir ou fechar a construção; **Esc** também fecha. O jogador fica parado enquanto pinta.

- O teste disponibiliza **25 materiais**, sem loja ou compra.
- O primeiro clique esquerdo inicia a casa no solo livre escolhido.
- Clique ou arraste com o esquerdo para expandir. Cada célula nova custa **1 material**; pintar a mesma célula novamente não cobra.
- As novas células devem tocar um lado da casa. Não é permitido construir partes separadas.
- Clique ou arraste com o direito para remover uma célula e receber **1 material** de volta. Remover uma conexão que separaria a casa é bloqueado.
- **Desfazer** restaura a última alteração e recalcula os materiais.
- **Salvar** e **Carregar** guardam a área construída em `user://house_terrain_test.json`. A casa antiga do construtor anterior não é importada.

O telhado usa Terrain com conexão pelos lados e 16 combinações de vizinhos. As paredes da fachada são recalculadas nas bordas inferiores. O custo é pela área pintada: a fachada automática não cobra materiais adicionais. O espaço da área e da fachada deve estar livre, com solo e sem colisões.

Os sprites disponíveis têm nove peças de borda; combinações estreitas, isoladas e recortes reutilizam essas peças. Para acabamento perfeito em todos os formatos, ainda serão necessárias peças específicas para os recortes. Portas, interior e compra de materiais ficam para uma próxima etapa.

No Inspector de HouseBuilder, `material_limit` tem valor padrão 25. Os caminhos de Player e da camada de solo precisam apontar para os nós da sua cena.

Validação desta alteração: o script passou pelo parser GDScript. A execução e a aparência devem ser conferidas no Godot.
