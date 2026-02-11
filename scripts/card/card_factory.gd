extends RefCounted
class_name CardFactory

const CARD_TEMPLATE_PATH: String = "res://scenes/card/card_template.tscn"
const CARD_DATA_PATH: String = "res://data/cards/cards.json"

var _card_template: PackedScene = load(CARD_TEMPLATE_PATH)
var _card_defs: Array[Dictionary] = []

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
	card.visible = true
	card.apply_data(card_def)
	return card

func _load_card_defs() -> void:
	_card_defs.clear()
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
		if item is Dictionary and not str(item.get("id", "")).is_empty():
			_card_defs.push_back(item)

func _get_card_def(card_id: String) -> Dictionary:
	for item in _card_defs:
		if str(item.get("id", "")) == card_id:
			return item
	return {}
