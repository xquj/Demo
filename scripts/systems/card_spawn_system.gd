extends RefCounted
class_name CardSpawnSystem

const DEAL_INTERVAL: int = 30

var game_scene: GameScene3D
var tick: int = 0
var card_factory: CardFactory = CardFactory.new()

func _init(game_scene_: GameScene3D) -> void:
	game_scene = game_scene_

func update_tick() -> void:
	tick += 1

func spawn_next_card_if_due() -> void:
	if tick % DEAL_INTERVAL != 0:
		return
	var cards_count: int = card_factory.get_cards_count()
	if cards_count == 0:
		return
	var card_index: int = (tick / DEAL_INTERVAL) % cards_count
	var card: Card_Base = card_factory.create_card_by_index(card_index)
	if card == null:
		return
	game_scene.initialize_card(card)
