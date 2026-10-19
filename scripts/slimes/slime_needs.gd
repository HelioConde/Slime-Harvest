extends RefCounted
## Ecologia dos slimes selvagens: cada especie busca um recurso do bioma.
## Nao modifica sprites, trabalho em fazendas, inventario ou slots.
const PROFILE: Dictionary = {
	"terrinho": {"need": "soil", "absorb": "cavar"},
	"brotinho": {"need": "plants", "absorb": "absorver_sementes"},
	"gota": {"need": "water", "absorb": "absorver_agua"},
	"colhita": {"need": "plants", "absorb": "recolher_colheita"},
	"polenita": {"need": "flowers", "absorb": "visitar_flores"},
	"compo": {"need": "soil", "absorb": "misturar_composto"},
	"capinito": {"need": "grass", "absorb": "agarrar_erva_daninha"},
	"raizela": {"need": "trees", "absorb": "espalhar_raizes"},
	"carreguim": {"need": "wood", "absorb": "descansar"},
	"seletim": {"need": "wood", "absorb": "analisar_item"},
	"lenhoco": {"need": "trees", "absorb": "recolher_galhos"},
	"pedrito": {"need": "rocks", "absorb": "sacudir_cascalho"},
	"ferrito": {"need": "rocks", "absorb": "atrair_fragmentos"},
	"pomelo": {"need": "trees", "absorb": "inspecionar_arvore"},
	"riacho": {"need": "water", "absorb": "mergulhar"},
	"funguinho": {"need": "mushrooms", "absorb": "espalhar_esporos"},
	"brasinha": {"need": "sun", "absorb": "acender_chama"},
	"chefito": {"need": "mushrooms", "absorb": "experimentar_comida"},
	"gelito": {"need": "shade", "absorb": "cristalizar"},
	"faisca": {"need": "sun", "absorb": "acumular_carga"},
	"engrenito": {"need": "rocks", "absorb": "martelar"},
	"construlim": {"need": "wood", "absorb": "carregar_tijolos"},
	"melado": {"need": "flowers", "absorb": "alimentar_se"},
	"fiapo": {"need": "grass", "absorb": "produzir_fibra"},
	"alquimita": {"need": "mushrooms", "absorb": "analisar_ingredientes"},
	"ventinho": {"need": "open_air", "absorb": "girar"},
	"lumito": {"need": "sun", "absorb": "pulsar_luz"},
	"curinha": {"need": "flowers", "absorb": "curar"},
	"guardito": {"need": "open_air", "absorb": "vigiar"},
	"noturno": {"need": "shade", "absorb": "esconder_se_em_sombras"},
	"prismita": {"need": "rocks", "absorb": "localizar_deposito"},
	"chuvao": {"need": "water", "absorb": "acumular_chuva"}
}

## Os intervalos sao segundos reais com o mundo rodando, nao dias de calendario.
const DEFAULT_SEARCH_INTERVAL := 16.0
const START_RESERVE := 82.0
const SEEK_BELOW := 67.0
const REFILL_TO := 100.0
const EXHAUSTION_SECONDS := 90.0
const ABSORB_SECONDS := 2.3


static func for_species(species_id: String) -> Dictionary:
	var data: Dictionary = PROFILE.get(species_id, {"need": "grass", "absorb": "happy"})
	var result: Dictionary = data.duplicate()
	result["search_interval"] = DEFAULT_SEARCH_INTERVAL
	result["drain_per_second"] = 0.18 if result["need"] == "water" else 0.11
	result["absorb_seconds"] = ABSORB_SECONDS
	return result
