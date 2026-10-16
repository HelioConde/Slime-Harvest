extends RefCounted
## Compensacoes medidas nas folhas originais para impedir que o corpo deslize na celula.
## Nao modifica a posicao fisica do CharacterBody2D nem a hitbox.
const DIRECTION_NAMES := ["down", "up", "right", "left"]
const IDLE_PING_PONG := [0, 1, 2, 3, 4, 5, 6, 7, 6, 5, 4, 3, 2, 1]
const X_ALIGN := {
	"masculino": {
		"walk": [[-8,-5,-6,-2,2,8,7,14],[-8,-6,-4,-1,1,6,8,15],[-6,-8,-4,-4,4,6,6,14],[-8,-3,-5,-2,2,6,8,14]],
		"run": [[-6,-4,-2,-2,4,2,6,6],[6,-5,-4,-1,-3,1,2,9],[2,6,-4,-8,-6,0,0,6],[1,-4,-5,-4,-1,10,12,10]]
	},
	"feminino": {
		"idle": [[-18,-12,-6,-2,2,8,10,16],[-16,-10,-6,-2,2,9,11,17],[-15,-10,-7,-2,2,7,10,15],[-14,-9,-4,-2,2,6,9,14]],
		"walk": [[-10,-8,-4,-2,2,4,6,14],[-13,-8,-4,-2,2,6,7,11],[-10,-10,0,0,2,0,6,12],[-8,-5,-3,-2,4,4,2,11]],
		"run": [[-4,0,2,2,0,-2,0,0],[2,2,-2,2,-2,-2,-2,2],[4,4,0,0,-2,2,-2,0],[-2,-2,0,2,4,-2,0,6]]
	}
}
## Diferencas de altura das poses de lado: nivelar os pes em relacao a frente.
const Y_ALIGN := {"masculino": [0,2,2,14], "feminino": [0,4,5,15]}


static func frame_offset(appearance: String, name: StringName, frame: int) -> Vector2:
	var gender: String = appearance if X_ALIGN.has(appearance) else "masculino"
	var full: String = String(name)
	var direction_name: String = full.get_slice("_", full.get_slice_count("_") - 1)
	var row: int = DIRECTION_NAMES.find(direction_name)
	if row < 0:
		return Vector2.ZERO
	var action: String = full.trim_suffix("_" + direction_name)
	var horizontal := 0.0
	var group: Dictionary = X_ALIGN[gender]
	if group.has(action):
		var offsets: Array = group[action][row]
		var index: int = frame
		if action == "idle" and gender == "feminino":
			index = IDLE_PING_PONG[clampi(frame, 0, IDLE_PING_PONG.size() - 1)]
		index = clampi(index, 0, offsets.size() - 1)
		var intensity := 0.7 if action == "run" else 1.0
		horizontal = float(offsets[index]) * intensity
	var vertical: float = float(Y_ALIGN[gender][row])
	return Vector2(horizontal, vertical)
