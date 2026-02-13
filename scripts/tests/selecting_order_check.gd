extends SceneTree

const MAIN_SCENE_PATH: String = "res://scenes/node_3d.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	global.reset_runtime_state()
	global.players = [
		LocalPlayer.new("A", 1, false),
		MultiPlayer.new("B", 2, false)
	]
	global.local_player = global.players[0]
	global.game_progress = 1
	global.current_state = global.GameState.SELECTING

	var packed: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("SelectingOrderCheck: failed to load main scene.")
		quit(1)
		return
	get_root().add_child(packed.instantiate())
	await process_frame
	await process_frame

	var expected_round1: Array[int] = [1, 2, 2, 1]
	var expected_round2: Array[int] = [2, 1, 1, 2]
	var expected_round3: Array[int] = [1, 2, 2, 1]
	var observed_round1: Array[int] = await _collect_order_for_current_progress()
	if observed_round1 != expected_round1:
		push_error("SelectingOrderCheck: round1 expected=%s observed=%s" % [str(expected_round1), str(observed_round1)])
		quit(3)
		return

	global.game_progress = 2
	var observed_round2: Array[int] = await _collect_order_for_current_progress()
	if observed_round2 != expected_round2:
		push_error("SelectingOrderCheck: round2 expected=%s observed=%s" % [str(expected_round2), str(observed_round2)])
		quit(4)
		return

	global.game_progress = 3
	var observed_round3: Array[int] = await _collect_order_for_current_progress()
	if observed_round3 != expected_round3:
		push_error("SelectingOrderCheck: round3 expected=%s observed=%s" % [str(expected_round3), str(observed_round3)])
		quit(5)
		return

	print(
		"SelectingOrderCheck: PASS r1=%s r2=%s r3=%s" % [
			str(observed_round1),
			str(observed_round2),
			str(observed_round3)
		]
	)
	quit(0)

func _collect_order_for_current_progress() -> Array[int]:
	var observed: Array[int] = []
	for remaining in [4, 3, 2, 1]:
		global.selected_group = _make_cards(remaining)
		await process_frame
		await process_frame
		if global.player_activity == null:
			return []
		observed.push_back(global.player_activity.team_id)
	return observed

func _make_cards(count: int) -> Array[Card_Base]:
	var cards: Array[Card_Base] = []
	var factory: CardFactory = CardFactory.new()
	for i in range(count):
		var card: Card_Base = factory.create_card_by_index(i)
		if card != null:
			cards.push_back(card)
	return cards
