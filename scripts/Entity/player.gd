class_name PlayerEntity extends Object

var state: PlayerState = PlayerState.new()
var controller: PlayerController = PlayerController.new()

var name: String:
	get:
		return state.name
	set(value):
		state.name = value

var team_id: int:
	get:
		return state.team_id
	set(value):
		state.team_id = value

var is_active: bool:
	get:
		return state.is_active
	set(value):
		state.is_active = value

var item_notes: Array[String]:
	get:
		return state.item_notes
	set(value):
		state.item_notes = value

var score: int:
	get:
		return state.score
	set(value):
		state.score = value

var health: int:
	get:
		return state.health
	set(value):
		state.health = value

var defense: int:
	get:
		return state.defense
	set(value):
		state.defense = value

var waitingGroup: Array[Card_Base]:
	get:
		return state.waitingGroup
	set(value):
		state.waitingGroup = value

var hand_cards: Array[Card_Base]:
	get:
		return state.hand_cards
	set(value):
		state.hand_cards = value

var showing_cards: Array[Card_Base]:
	get:
		return state.showing_cards
	set(value):
		state.showing_cards = value

var can_combo: bool:
	get:
		return state.can_combo
	set(value):
		state.can_combo = value

func _init(name_: String, team_id_: int, is_active_: bool) -> void:
	state = PlayerState.new()
	controller = PlayerController.new()
	state.health = 100
	state.defense = 100
	state.name = name_
	state.team_id = team_id_
	state.is_active = is_active_
	state.item_notes = []
	state.score = 0
	state.waitingGroup = []
	state.hand_cards = []
	state.showing_cards = []
	state.can_combo = false

func add_items(value: int) -> void:
	score += max(value, 0)

func process() -> void:
	if controller != null:
		controller.process(self)
