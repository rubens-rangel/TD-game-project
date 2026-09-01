extends RefCounted
class_name StructureCatalog

## Catálogo único de estruturas. Comprar, colocar, mover e desenhar o preview
## devem consultar estes dados em vez de copiar as mesmas constantes.

const PLACEMENT_BASE := "base"
const PLACEMENT_WALKABLE := "walkable"
const PLACEMENT_PATH := "path"

const CURRENCY_COINS := "coins"
const CURRENCY_EMERALDS := "emeralds"

const COST_TOWER := "tower"
const COST_RAW := "raw"
const COST_WALL := "wall"

const DEFS := {
	"tower": {
		"id": "tower",
		"array": "towers",
		"cost_key": "TOWER_COST",
		"unlock_wave_key": "UNLOCK_WAVE_TOWER",
		"max_key": "MAX_TOWERS",
		"size_key": "TOWER_SIZE_GRID",
		"grid_type": 1,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_tower",
		"preview_ok": Color(0.7, 0.9, 0.7, 0.5),
		"preview_ok_border": Color(0.5, 0.8, 0.5),
	},
	"barracks": {
		"id": "barracks",
		"array": "barracks",
		"cost_key": "BARRACKS_COST",
		"unlock_wave_key": "UNLOCK_WAVE_BARRACKS",
		"max_key": "MAX_BARRACKS",
		"size_key": "BARRACKS_SIZE_GRID",
		"grid_type": 3,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_barracks",
		"preview_ok": Color(0.7, 0.9, 0.7, 0.5),
		"preview_ok_border": Color(0.5, 0.8, 0.5),
	},
	"slow_tower": {
		"id": "slow_tower",
		"array": "slow_towers",
		"cost_key": "SLOW_TOWER_COST",
		"unlock_wave_key": "UNLOCK_WAVE_SLOW",
		"max_key": "MAX_SLOW_TOWERS",
		"size_key": "SLOW_TOWER_SIZE_GRID",
		"grid_type": 5,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_slow_tower",
		"preview_ok": Color(0.5, 0.7, 0.9, 0.5),
		"preview_ok_border": Color(0.3, 0.5, 0.7),
	},
	"aoe_tower": {
		"id": "aoe_tower",
		"array": "aoe_towers",
		"cost_key": "AOE_TOWER_COST",
		"unlock_wave_key": "UNLOCK_WAVE_AOE",
		"max_key": "MAX_AOE_TOWERS",
		"size_key": "AOE_TOWER_SIZE_GRID",
		"grid_type": 6,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_aoe_tower",
		"preview_ok": Color(0.9, 0.5, 0.2, 0.5),
		"preview_ok_border": Color(0.7, 0.3, 0.1),
	},
	"sniper_tower": {
		"id": "sniper_tower",
		"array": "sniper_towers",
		"cost_key": "SNIPER_TOWER_COST",
		"unlock_wave_key": "UNLOCK_WAVE_SNIPER",
		"max_key": "MAX_SNIPER_TOWERS",
		"size_key": "SNIPER_TOWER_SIZE_GRID",
		"grid_type": 7,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_sniper_tower",
		"preview_ok": Color(0.3, 0.3, 0.3, 0.5),
		"preview_ok_border": Color(0.1, 0.1, 0.1),
	},
	"boost_tower": {
		"id": "boost_tower",
		"array": "boost_towers",
		"cost_key": "BOOST_TOWER_COST",
		"unlock_wave_key": "UNLOCK_WAVE_BOOST",
		"max_key": "MAX_BOOST_TOWERS",
		"size_key": "BOOST_TOWER_SIZE_GRID",
		"grid_type": 8,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_boost_tower",
		"preview_ok": Color(0.8, 0.8, 0.2, 0.5),
		"preview_ok_border": Color(0.6, 0.6, 0.1),
	},
	"shock_tower": {
		"id": "shock_tower",
		"array": "shock_towers",
		"cost_key": "SHOCK_TOWER_COST",
		"unlock_wave_key": "UNLOCK_WAVE_SHOCK",
		"max_key": "MAX_SHOCK_TOWERS",
		"size_key": "SHOCK_TOWER_SIZE_GRID",
		"grid_type": 9,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_shock_tower",
		"preview_ok": Color(0.5, 0.3, 0.9, 0.5),
		"preview_ok_border": Color(0.4, 0.2, 0.8),
	},
	"anti_air_tower": {
		"id": "anti_air_tower",
		"array": "anti_air_towers",
		"cost_key": "ANTI_AIR_TOWER_COST",
		"unlock_wave_key": "UNLOCK_WAVE_ANTI_AIR",
		"max_key": "MAX_ANTI_AIR_TOWERS",
		"size_key": "ANTI_AIR_TOWER_SIZE_GRID",
		"grid_type": 12,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_TOWER,
		"track_coins": true,
		"track_built": true,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_anti_air_tower",
		"preview_ok": Color(0.2, 0.6, 0.9, 0.5),
		"preview_ok_border": Color(0.1, 0.4, 0.7),
	},
	"healing_station": {
		"id": "healing_station",
		"array": "healing_stations",
		"cost_key": "HEALING_STATION_COST",
		"unlock_wave_key": "UNLOCK_WAVE_HEALING_STATION",
		"max_key": "MAX_HEALING_STATIONS",
		"size_key": "HEALING_STATION_SIZE_GRID",
		"grid_type": 10,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_RAW,
		"track_coins": false,
		"track_built": false,
		"track_wall": false,
		"click_radius": 20.0,
		"texture_var": "tex_healing_station",
		"preview_ok": Color(0.2, 0.8, 0.4, 0.5),
		"preview_ok_border": Color(0.1, 0.6, 0.3),
	},
	"market": {
		"id": "market",
		"array": "markets",
		"cost_key": "MARKET_COST_EMERALDS",
		"unlock_wave_key": "UNLOCK_WAVE_MARKET",
		"max_key": "MAX_MARKETS",
		"size_key": "MARKET_SIZE_GRID",
		"grid_type": 11,
		"placement": PLACEMENT_BASE,
		"currency": CURRENCY_EMERALDS,
		"cost_mode": COST_RAW,
		"track_coins": false,
		"track_built": false,
		"track_wall": false,
		"click_radius": 30.0,
		"texture_var": "tex_market",
		"preview_ok": Color(0.2, 0.8, 0.2, 0.5),
		"preview_ok_border": Color(0.1, 0.6, 0.1),
	},
	"mine": {
		"id": "mine",
		"array": "mines",
		"cost_key": "MINE_COST",
		"unlock_wave_key": "UNLOCK_WAVE_MINE",
		"max_key": "MAX_MINES",
		"size_key": "MINE_SIZE_GRID",
		"grid_type": 0,
		"placement": PLACEMENT_WALKABLE,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_RAW,
		"track_coins": false,
		"track_built": false,
		"track_wall": false,
		"click_radius": 12.0,
		"texture_var": "tex_mine",
		"preview_ok": Color(0.8, 0.7, 0.2, 0.5),
		"preview_ok_border": Color(0.6, 0.5, 0.1),
	},
	"wall": {
		"id": "wall",
		"array": "walls",
		"cost_key": "WALL_COST",
		"unlock_wave_key": "UNLOCK_WAVE_WALL",
		"max_key": "MAX_WALLS",
		"size_key": "WALL_SIZE_GRID",
		"grid_type": 9,
		"placement": PLACEMENT_PATH,
		"currency": CURRENCY_COINS,
		"cost_mode": COST_WALL,
		"track_coins": true,
		"track_built": false,
		"track_wall": true,
		"click_radius": 15.0,
		"texture_var": "tex_wall_structure",
		"preview_ok": Color(0.6, 0.4, 0.2, 0.5),
		"preview_ok_border": Color(0.5, 0.3, 0.2),
	},
}

const DRAG_ORDER := [
	"tower", "slow_tower", "aoe_tower", "sniper_tower", "boost_tower",
	"shock_tower", "anti_air_tower", "mine", "wall", "barracks",
	"healing_station", "market",
]

const CONTEXT_MENU_ORDER := [
	"market", "wall", "tower", "barracks", "sniper_tower", "aoe_tower",
	"anti_air_tower", "shock_tower", "slow_tower", "boost_tower",
]

const GRID_OCCUPANTS := [
	"tower", "barracks", "slow_tower", "aoe_tower", "sniper_tower",
	"anti_air_tower", "boost_tower", "shock_tower", "wall",
	"healing_station", "market",
]

static func get_def(type_id: String) -> Dictionary:
	return DEFS.get(type_id, {})

static func has_type(type_id: String) -> bool:
	return DEFS.has(type_id)

static func find_by_array(array_name: String) -> Dictionary:
	for type_id in DEFS:
		var def: Dictionary = DEFS[type_id]
		if def.get("array", "") == array_name:
			return def
	return {}

static func base_types() -> Array:
	var result: Array = []
	for type_id in DEFS:
		if DEFS[type_id].get("placement", "") == PLACEMENT_BASE:
			result.append(type_id)
	return result
