extends RefCounted
class_name CardFactory

const CARD_TEMPLATE_PATH: String = "res://scenes/card/card_template.tscn"
const CARD_DATA_PATH: String = "res://data/cards/cards.json"

var _card_template: PackedScene = load(CARD_TEMPLATE_PATH)
var _card_defs: Array[Dictionary] = []
var _card_script_cache: Dictionary = {}

func _init() -> void:
	_load_card_defs()

func get_cards_count() -> int:
	return _card_defs.size()

func get_card_id_by_index(index: int) -> String:
	if _card_defs.is_empty():
		return ""
	return str(_card_defs[index % _card_defs.size()].get("id", ""))

func create_card_by_index(index: int) -> Card_Base:
	if _card_defs.is_empty():
		return null
	return create_card_by_id(get_card_id_by_index(index))

func create_card_by_id(card_id: String) -> Card_Base:
	var card_def: Dictionary = _get_card_def(card_id)
	if card_def.is_empty() or _card_template == null:
		return null

	var card: Card_Base = _card_template.instantiate()
	_bind_card_script(card, card_def)
	card.visible = true
	card.apply_data(card_def)
	return card

func _bind_card_script(card: Card_Base, card_def: Dictionary) -> void:
	if card == null:
		return

	var card_script_path: String = str(card_def.get("card_script", ""))
	if card_script_path.is_empty():
		return

	var script_resource: Script = _get_cached_card_script(card_script_path)
	if script_resource == null:
		return

	if not script_resource.instance_has(card):
		push_warning("CardFactory: card script does not inherit current card type: %s" % card_script_path)
		return

	card.set_script(script_resource)

func _get_cached_card_script(card_script_path: String) -> Script:
	if _card_script_cache.has(card_script_path):
		return _card_script_cache[card_script_path]

	var script_resource: Script = load(card_script_path)
	if script_resource == null:
		push_warning("CardFactory: card script not found: %s" % card_script_path)
		return null

	if not script_resource.can_instantiate():
		push_warning("CardFactory: card script cannot instantiate: %s" % card_script_path)
		return null

	_card_script_cache[card_script_path] = script_resource
	return script_resource

func _load_card_defs() -> void:
	_card_defs.clear()
	_card_script_cache.clear()
	if not FileAccess.file_exists(CARD_DATA_PATH):
		push_warning("CardFactory: card data file not found: %s" % CARD_DATA_PATH)
		return

	var file: FileAccess = FileAccess.open(CARD_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("CardFactory: failed to open card data file")
		return

	var parse_result: Variant = JSON.parse_string(file.get_as_text())
	if parse_result == null or not (parse_result is Array):
		push_warning("CardFactory: invalid card data json")
		return

	for item in parse_result:
		if not (item is Dictionary):
			push_warning("CardFactory: invalid card entry type, expected Dictionary")
			continue

		var card_def: Dictionary = _normalize_card_def(item)
		if card_def.is_empty():
			continue
		_card_defs.push_back(card_def)

func _normalize_card_def(card_def: Dictionary) -> Dictionary:
	var normalized: Dictionary = card_def.duplicate(true)
	var card_id: String = str(normalized.get("id", "")).strip_edges()
	if card_id.is_empty():
		push_warning("CardFactory: skip card entry without id")
		return {}
	normalized["id"] = card_id

	if not normalized.has("name"):
		normalized["name"] = card_id
	if not normalized.has("keywords") or not (normalized["keywords"] is Array):
		normalized["keywords"] = []

	var card_script_path: String = str(normalized.get("card_script", "")).strip_edges()
	if not card_script_path.is_empty() and not card_script_path.begins_with("res://"):
		push_warning("CardFactory: invalid card_script path for '%s': %s" % [card_id, card_script_path])
		card_script_path = ""
	normalized["card_script"] = card_script_path
	return normalized

func _get_card_def(card_id: String) -> Dictionary:
	for item in _card_defs:
		if str(item.get("id", "")) == card_id:
			return item
	return {}
