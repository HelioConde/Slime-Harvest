extends RefCounted
## Correcoes de deslocamento foram incorporadas nos PNGs.
## Nao aplicar compensacoes antigas nos quadros ja corrigidos.
static func frame_offset(_appearance: String, _name: StringName, _frame: int) -> Vector2:
	return Vector2.ZERO
