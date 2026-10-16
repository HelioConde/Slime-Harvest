extends RefCounted
## Mantem os nomes de 28 animacoes do controlador antigo, substituindo apenas os visuais.
## As imagens originais 8x4 (1774x887) estao em assets/Characters/new.
const DIR := "res://assets/Characters/new/"
const SHEETS := {
    "masculino": {
        "idle": "exec-fd8ae2cc-8791-4f79-a2d1-7815068bd828.png",
        "walk": "exec-fd8ae2cc-8791-4f79-a2d1-7815068bd828.png",
        "run": "exec-9749d5d0-c0d0-4042-8181-d35286cf460a.png",
        "axe": "exec-9e81e999-3511-4520-adeb-7f2c2744fef0.png",
        "pick": "exec-0eea2ccf-743f-492f-b773-5f51e8478aa3.png",
        "hoe": "exec-486b5e99-6122-4cf1-bf8e-af6e99caa514.png",
        "watering": "exec-17e6c232-eef2-4436-bcb9-5927d8ab4d3e.png"
    },
    "feminino": {
        "idle": "exec-3436f4e7-4b70-4556-bd52-8ba00adae31c.png",
        "walk": "exec-af55c5be-081c-44df-8fe1-617ca0bc67e8.png",
        "run": "exec-64bcc504-e427-4d69-a3d6-625271ed496f.png",
        "axe": "exec-98e6b770-ea96-4040-a85e-078447aa6e4b.png",
        "pick": "exec-1ec4a3f7-0f7c-4cf5-847c-f81bf22b8b2b.png",
        "hoe": "exec-42584540-eb7f-40f5-90c3-6f5e7e87afb4.png",
        "watering": "exec-48bd9d22-2b51-4ae2-8147-97caba2e3cb3.png"
    }
}
const DIRECTIONS := ["down", "up", "right", "left"]
const ACTIONS := ["idle", "walk", "run", "axe", "pick", "hoe", "watering"]


static func apply(sprite: AnimatedSprite2D, appearance: String) -> bool:
    if sprite == null:
        return false
    var gender: String = appearance if SHEETS.has(appearance) else "masculino"
    var selected: Dictionary = SHEETS[gender]
    var loaded: Dictionary = {}
    for action in ACTIONS:
        var path: String = DIR + String(selected[action])
        if not ResourceLoader.exists(path):
            push_warning("PlayerSkins: spritesheet ausente: " + path)
            return false
        var texture := load(path) as Texture2D
        if texture == null:
            return false
        loaded[action] = texture
    var result := SpriteFrames.new()
    for action in ACTIONS:
        var tex: Texture2D = loaded[action]
        for row in range(4):
            var animation_name: StringName = StringName(action + "_" + DIRECTIONS[row])
            result.add_animation(animation_name)
            result.set_animation_loop(animation_name, action in ["idle", "walk", "run"])
            result.set_animation_speed(animation_name, 5.0 if action == "idle" else (12.0 if action == "run" else (8.0 if action == "walk" else 8.0)))
            var frame_total: int = 1 if action == "idle" and gender == "masculino" else 8
            for column in range(frame_total):
                var x0: int = roundi(float(column) * float(tex.get_width()) / 8.0)
                var x1: int = roundi(float(column + 1) * float(tex.get_width()) / 8.0)
                var y0: int = roundi(float(row) * float(tex.get_height()) / 4.0)
                var y1: int = roundi(float(row + 1) * float(tex.get_height()) / 4.0)
                var frame := AtlasTexture.new()
                frame.atlas = tex
                frame.region = Rect2(x0, y0, x1 - x0, y1 - y0)
                result.add_frame(animation_name, frame)
    sprite.stop()
    sprite.sprite_frames = result
    sprite.animation = &"idle_down"
    sprite.scale = Vector2(0.25, 0.25)
    sprite.position = Vector2(0, -27)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.play(&"idle_down")
    return true
