extends TileMapLayer
## Mock exclusivamente para o teste de cultivo, sem editar o World real.
var allowed: Dictionary = {}

func is_tilled(cell: Vector2i) -> bool:
	return allowed.has(cell)
