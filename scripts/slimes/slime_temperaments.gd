extends RefCounted
## Temperamento selvagem por especie, independente de captura e domesticacao.
## Reacoes sao sempre territoriais/de proximidade, nao afetam fazendas salvas.
const TEMPERAMENTS: Dictionary = {
    "terrinho": "curious",
    "brotinho": "friendly",
    "gota": "territorial",
    "colhita": "shy",
    "polenita": "friendly",
    "compo": "curious",
    "capinito": "curious",
    "raizela": "territorial",
    "carreguim": "friendly",
    "seletim": "shy",
    "lenhoco": "territorial",
    "pedrito": "aggressive",
    "ferrito": "aggressive",
    "pomelo": "friendly",
    "riacho": "shy",
    "funguinho": "shy",
    "brasinha": "aggressive",
    "chefito": "friendly",
    "gelito": "territorial",
    "faisca": "territorial",
    "engrenito": "shy",
    "construlim": "curious",
    "melado": "friendly",
    "fiapo": "shy",
    "alquimita": "curious",
    "ventinho": "curious",
    "lumito": "friendly",
    "curinha": "shy",
    "guardito": "aggressive",
    "noturno": "territorial",
    "prismita": "aggressive",
    "chuvao": "territorial"
}

const NOTICE_DISTANCE := 92.0
const ATTACK_REACH := 27.0
const RANGED_REACH := 58.0
const WINDUP_SECONDS := 0.85
const STRIKE_RECOVERY := 1.1
const ATTACK_COOLDOWN := 6.0
const SOCIAL_CHECK_SECONDS := 0.28
const LOW_RESERVE_OVERRIDE := 35.0


static func for_species(species_id: String) -> Dictionary:
    var temperament: String = str(TEMPERAMENTS.get(species_id, "curious"))
    var ranged: bool = species_id in ["gota", "chuvao", "prismita", "faisca", "brasinha"]
    var reaction: StringName = &"happy"
    match temperament:
        "shy": reaction = &"cansado"
        "curious": reaction = &"blink"
        "territorial": reaction = &"irritado"
        "aggressive": reaction = &"attack_charge"
    var ability: StringName = &"attack"
    if species_id == "gota":
        ability = &"disparar_jato"
    elif species_id == "chuvao":
        ability = &"jato_pressurizado"
    elif species_id == "prismita":
        ability = &"disparar_raio"
    return {
        "temperament": temperament,
        "notice": NOTICE_DISTANCE + (20.0 if temperament == "shy" else 0.0),
        "reach": RANGED_REACH if ranged else ATTACK_REACH,
        "windup": WINDUP_SECONDS,
        "attack_cooldown": ATTACK_COOLDOWN,
        "reaction_animation": reaction,
        "attack_animation": ability,
        "ranged": ranged
    }
