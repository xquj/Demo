extends Node
class_name CardDatabase

var cards: Dictionary = {}

func load_cards() -> void:
	cards.clear()
	var file := FileAccess.open("res://data/cards.json", FileAccess.READ)
	if file == null:
		push_warning("cards.json missing; using empty card database")
		return
	var json := JSON.parse_string(file.get_as_text())
	if typeof(json) != TYPE_ARRAY:
		push_warning("cards.json did not parse to an array")
		return
	for entry in json:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("id"):
			cards[entry["id"]] = entry

func get_card(id: String) -> Dictionary:
	return cards.get(id, {})

func all_cards() -> Array:
	return cards.values()
