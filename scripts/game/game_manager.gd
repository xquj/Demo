extends Node3D
class_name GameManager

const LANE_COUNT := 4
const SCALE_THRESHOLD := 10

class PlayerState:
	var name: String
	var is_player: bool
	var deck: Array[Dictionary] = []
	var hand: Array[Card3D] = []
	var board: Array[Card3D] = []
	var bones: int = 0

	func _init(name_: String, is_player_: bool) -> void:
		name = name_
		is_player = is_player_

@export var card_scene: PackedScene

@onready var player_hand_anchor: Node3D = $PlayerHand
@onready var enemy_hand_anchor: Node3D = $EnemyHand
@onready var player_slots_root: Node3D = $Board/PlayerSlots
@onready var enemy_slots_root: Node3D = $Board/EnemySlots
@onready var scale_anchor: Node3D = $ScaleAnchor
@onready var ui_phase_label: Label = $UI/Root/PhaseLabel
@onready var ui_turn_label: Label = $UI/Root/TurnLabel
@onready var ui_scale_bar: ProgressBar = $UI/Root/ScaleBar
@onready var ui_scale_label: Label = $UI/Root/ScaleLabel
@onready var ui_bones_label: Label = $UI/Root/BonesLabel
@onready var ui_end_turn: Button = $UI/Root/EndTurnButton
@onready var ui_inspect_panel: Panel = $UI/Root/InspectPanel
@onready var ui_inspect_label: Label = $UI/Root/InspectPanel/InspectLabel
@onready var camera_fsm: CameraFSM = $CameraRig

var card_db := CardDatabase.new()

var player_state := PlayerState.new("Rook", true)
var enemy_state := PlayerState.new("Lumen", false)

var active_player = null
var inactive_player = null
var phase := "draw"
var scale_value := 0
var selected_card: Card3D = null

func _ready() -> void:
	if card_scene == null:
		push_error("GameManager requires a card_scene to be assigned.")
		return
	if player_slots_root == null or enemy_slots_root == null:
		push_error("GameManager missing board slot roots.")
		return
	if player_hand_anchor == null or enemy_hand_anchor == null:
		push_error("GameManager missing hand anchors.")
		return
	if camera_fsm == null:
		push_warning("CameraRig missing; continuing without camera transitions.")
	card_db.load_cards()
	player_state.board = [null, null, null, null] as Array[Card3D]
	enemy_state.board = [null, null, null, null] as Array[Card3D]
	_setup_slots()
	_setup_ui()
	_build_decks()
	_draw_starting_hands()
	start_turn(player_state)

func _setup_slots() -> void:
	for slot in player_slots_root.get_children():
		if slot is BoardSlot:
			slot.slot_clicked.connect(_on_slot_clicked)
			slot.hover_changed.connect(_on_slot_hover)
	for slot in enemy_slots_root.get_children():
		if slot is BoardSlot:
			slot.slot_clicked.connect(_on_slot_clicked)
			slot.hover_changed.connect(_on_slot_hover)

func _setup_ui() -> void:
	if ui_end_turn != null:
		ui_end_turn.pressed.connect(_on_end_turn_pressed)
	if ui_inspect_panel != null:
		ui_inspect_panel.visible = false
	_update_ui()

func _build_decks() -> void:
	var card_entries := card_db.all_cards()
	player_state.deck = card_entries.duplicate() as Array[Dictionary]
	enemy_state.deck = card_entries.duplicate() as Array[Dictionary]
	player_state.deck.shuffle()
	enemy_state.deck.shuffle()

func _draw_starting_hands() -> void:
	for i in range(4):
		draw_card(player_state)
		draw_card(enemy_state)

func start_turn(player) -> void:
	active_player = player
	inactive_player = enemy_state if player == player_state else player_state
	phase = "draw"
	if camera_fsm != null:
		camera_fsm.go_to_state(CameraFSM.CameraState.TURN_PULLBACK)
	_update_ui()
	_on_turn_start()

func _on_turn_start() -> void:
	phase = "draw"
	draw_card(active_player)
	_trigger_abilities("on_turn_start", active_player)
	phase = "play"
	if camera_fsm != null:
		camera_fsm.go_to_state(CameraFSM.CameraState.PUSH_IN)
	if not active_player.is_player:
		_run_enemy_turn()
	_update_ui()

func draw_card(player) -> void:
	if player.deck.is_empty():
		return
	var entry = player.deck.pop_back()
	var card := _spawn_card(entry, player)
	player.hand.append(card)
	_update_hand_positions(player)

func _spawn_card(card_data: Dictionary, owner) -> Card3D:
	var card: Card3D = card_scene.instantiate()
	card.setup(card_data, owner, self)
	card.card_clicked.connect(_on_card_clicked)
	card.hover_changed.connect(_on_card_hover)
	add_child(card)
	return card

func _update_hand_positions(player) -> void:
	var hand := player.hand
	var anchor := player_hand_anchor if player.is_player else enemy_hand_anchor
	var spread := 0.7
	for i in range(hand.size()):
		var card: Card3D = hand[i]
		card.zone = "hand"
		card.global_position = anchor.global_position + Vector3((i - (hand.size() - 1) / 2.0) * spread, 0.0, 0.0)
		card.base_position = card.global_position
		card.rotation = Vector3(deg_to_rad(-90), 0, deg_to_rad(180 if not player.is_player else 0))

func _update_board_positions(player) -> void:
	var slots_root := player_slots_root if player.is_player else enemy_slots_root
	for slot in slots_root.get_children():
		if slot is BoardSlot:
			var card: Card3D = player.board[slot.lane_index]
			if card != null:
				card.zone = "board"
				card.lane_index = slot.lane_index
				card.global_position = slot.global_position + Vector3(0, 0.02, 0)
				card.base_position = card.global_position
				card.rotation = Vector3(deg_to_rad(-90), 0, deg_to_rad(180 if not player.is_player else 0))

func _on_card_clicked(card: Card3D) -> void:
	if phase != "play" or not active_player.is_player:
		return
	if card.owner != active_player:
		return
	if card.is_spell():
		_play_spell(card)
		return
	selected_card = card
	_highlight_slots(true)
	if camera_fsm != null:
		camera_fsm.go_to_state(CameraFSM.CameraState.CARD_CLOSEUP)

func _on_card_hover(card: Card3D, hovered: bool) -> void:
	if hovered:
		if ui_inspect_panel != null:
			ui_inspect_panel.visible = true
		if ui_inspect_label != null:
			ui_inspect_label.text = _format_card_description(card)
		if card.zone == "hand":
			if camera_fsm != null:
				camera_fsm.go_to_state(CameraFSM.CameraState.CARD_CLOSEUP)
	else:
		if ui_inspect_panel != null:
			ui_inspect_panel.visible = false
		if phase == "play":
			if camera_fsm != null:
				camera_fsm.go_to_state(CameraFSM.CameraState.PUSH_IN)

func _format_card_description(card: Card3D) -> String:
	var sigils := ", ".join(card.data.get("sigils", []))
	if sigils == "":
		sigils = "None"
	return "%s\nCost: %s %s\nSigils: %s\n%s" % [
		card.data.get("name", ""),
		card.data.get("cost", 0),
		card.data.get("cost_type", ""),
		sigils,
		card.data.get("description", "")
	]

func _on_slot_clicked(slot: BoardSlot) -> void:
	if selected_card == null:
		return
	if not slot.is_player_slot:
		return
	if active_player.board[slot.lane_index] != null:
		return
	_play_unit_to_slot(selected_card, slot)

func _on_slot_hover(_slot: BoardSlot, _hovered: bool) -> void:
	pass

func _play_unit_to_slot(card: Card3D, slot: BoardSlot) -> void:
	if not _can_afford(card, active_player):
		spawn_floating_text("Need more cost", slot.global_position)
		return
	_apply_cost(card, active_player)
	active_player.hand.erase(card)
	active_player.board[slot.lane_index] = card
	_trigger_abilities("on_play", card)
	selected_card = null
	_highlight_slots(false)
	_update_hand_positions(active_player)
	_update_board_positions(active_player)
	_update_ui()

func _play_spell(card: Card3D) -> void:
	if not _can_afford(card, active_player):
		spawn_floating_text("Need more cost", card.global_position)
		return
	_apply_cost(card, active_player)
	active_player.hand.erase(card)
	_execute_spell(card)
	card.queue_free()
	_update_hand_positions(active_player)
	_update_ui()

func _can_afford(card: Card3D, player) -> bool:
	var cost_type := str(card.data.get("cost_type", ""))
	var cost_value := int(card.data.get("cost", 0))
	if cost_type == "blood":
		return _count_units(player) >= cost_value
	if cost_type == "bone":
		return player.bones >= cost_value
	return true

func _apply_cost(card: Card3D, player) -> void:
	var cost_type := str(card.data.get("cost_type", ""))
	var cost_value := int(card.data.get("cost", 0))
	if cost_type == "blood":
		_sacrifice_units(player, cost_value)
	elif cost_type == "bone":
		player.bones = max(player.bones - cost_value, 0)

func _sacrifice_units(player, count: int) -> void:
	var sacrificed := 0
	for i in range(LANE_COUNT):
		var card: Card3D = player.board[i]
		if card != null:
			_handle_death(card, player)
			player.board[i] = null
			sacrificed += 1
			if sacrificed >= count:
				break
	_update_board_positions(player)

func _count_units(player) -> int:
	var count := 0
	for card in player.board:
		if card != null:
			count += 1
	return count

func _execute_spell(card: Card3D) -> void:
	var effect := str(card.data.get("effect", ""))
	var value := int(card.data.get("effect_value", 0))
	match effect:
		"gain_bones":
			active_player.bones += value
			spawn_floating_text("+" + str(value) + " bones", player_hand_anchor.global_position)
		"draw":
			for i in range(value):
				draw_card(active_player)
		"direct_damage":
			apply_scale_damage(active_player, value, true)
		"heal_scale":
			apply_scale_damage(active_player, value, true)
		"buff_random":
			_buff_random_unit(active_player, value)
		"summon_token":
			_spawn_token_in_empty_lane(active_player)

func _buff_random_unit(player, amount: int) -> void:
	var candidates := []
	for card in player.board:
		if card != null:
			candidates.append(card)
	if candidates.is_empty():
		return
	var choice: Card3D = candidates.pick_random()
	choice.max_health += amount
	choice.heal(amount)
	spawn_floating_text("+" + str(amount), choice.global_position)

func _spawn_token_in_empty_lane(player) -> void:
	for i in range(LANE_COUNT):
		if player.board[i] == null:
			var token := _spawn_card({
				"id": "token",
				"name": "Echo",
				"type": "unit",
				"cost_type": "bone",
				"cost": 0,
				"attack": 1,
				"health": 1,
				"sigils": [],
				"description": "A fleeting spirit.",
				"art": "res://assets/svg/cards/grave_recall.svg"
			}, player)
			player.board[i] = token
			_update_board_positions(player)
			return

func _trigger_abilities(event_name: String, card_or_player) -> void:
	if event_name == "on_turn_start":
		for card in card_or_player.board:
			if card != null:
				_call_card_abilities(card, event_name, {"manager": self})
		return
	if card_or_player is Card3D:
		_call_card_abilities(card_or_player, event_name, {"manager": self})

func _call_card_abilities(card: Card3D, event_name: String, ctx: Dictionary) -> void:
	for sigil in card.data.get("sigils", []):
		var ability := AbilityLibrary.get_ability(sigil)
		if ability.has(event_name):
			var callable: Callable = ability[event_name]
			ctx["card"] = card
			callable.call(card, ctx)

func _on_end_turn_pressed() -> void:
	if phase == "play" and active_player.is_player:
		_end_turn()

func _end_turn() -> void:
	phase = "combat"
	if camera_fsm != null:
		camera_fsm.go_to_state(CameraFSM.CameraState.SCALE_FOCUS)
	_resolve_combat()
	phase = "end"
	if _check_win():
		return
	if camera_fsm != null:
		camera_fsm.go_to_state(CameraFSM.CameraState.BASE)
	start_turn(inactive_player)

func _resolve_combat() -> void:
	_attack_with_side(player_state, enemy_state)
	_attack_with_side(enemy_state, player_state)

func _attack_with_side(attacker, defender) -> void:
	for i in range(LANE_COUNT):
		var atk_card: Card3D = attacker.board[i]
		if atk_card == null:
			continue
		var def_card: Card3D = defender.board[i]
		var ctx := {"manager": self, "target": def_card}
		_call_card_abilities(atk_card, "on_attack", ctx)
		if def_card != null:
			def_card.take_damage(atk_card.attack)
			_call_card_abilities(atk_card, "on_hit", {"manager": self, "target": def_card})
			if def_card.health <= 0:
				_handle_death(def_card, defender)
				defender.board[i] = null
		else:
			apply_scale_damage(attacker, atk_card.attack, false)
			_call_card_abilities(atk_card, "on_hit", {"manager": self, "target": null})
	_update_board_positions(attacker)
	_update_board_positions(defender)

func _handle_death(card: Card3D, owner) -> void:
	if card == null:
		return
	owner.bones += 1
	_call_card_abilities(card, "on_death", {"manager": self})
	spawn_floating_text("+1 bone", card.global_position)
	card.queue_free()

func apply_scale_damage(attacker, amount: int, is_spell: bool) -> void:
	if attacker == player_state:
		scale_value += amount
	else:
		scale_value -= amount
	scale_value = clamp(scale_value, -SCALE_THRESHOLD, SCALE_THRESHOLD)
	if camera_fsm != null:
		camera_fsm.go_to_state(CameraFSM.CameraState.DAMAGE_TILT)
	_update_ui()

func spawn_rattle_token(dead_card: Card3D) -> void:
	var owner = dead_card.owner
	var lane = dead_card.lane_index
	if owner.board[lane] != null:
		return
	var token := _spawn_card({
		"id": "cinderling",
		"name": "Cinderling",
		"type": "unit",
		"cost_type": "bone",
		"cost": 0,
		"attack": 1,
		"health": 1,
		"sigils": [],
		"description": "Born from embers.",
		"art": "res://assets/svg/cards/ash_hound.svg"
	}, owner)
	owner.board[lane] = token
	_update_board_positions(owner)

func spawn_floating_text(text: String, pos: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.position = pos
	add_child(label)
	var tween := create_tween()
	label.modulate = Color(1, 1, 1, 1)
	tween.tween_property(label, "position", pos + Vector3(0, 0.3, 0), 0.8)
	tween.parallel().tween_property(label, "modulate", Color(1, 1, 1, 0), 0.8)
	tween.finished.connect(func(): label.queue_free())

func _highlight_slots(active: bool) -> void:
	for slot in player_slots_root.get_children():
		if slot is BoardSlot:
			slot.set_highlight(active and active_player.board[slot.lane_index] == null)

func _update_ui() -> void:
	if ui_phase_label != null:
		ui_phase_label.text = "Phase: %s" % phase.capitalize()
	if ui_turn_label != null:
		ui_turn_label.text = "Turn: %s" % (active_player.name if active_player != null else "--")
	if ui_scale_bar != null:
		ui_scale_bar.value = scale_value
	if ui_scale_label != null:
		ui_scale_label.text = "Balance: %d" % scale_value
	if ui_bones_label != null:
		ui_bones_label.text = "Bones: %d" % player_state.bones

func _check_win() -> bool:
	if scale_value >= SCALE_THRESHOLD:
		if ui_phase_label != null:
			ui_phase_label.text = "Victory!"
		phase = "finished"
		if ui_end_turn != null:
			ui_end_turn.disabled = true
		return true
	elif scale_value <= -SCALE_THRESHOLD:
		if ui_phase_label != null:
			ui_phase_label.text = "Defeat!"
		phase = "finished"
		if ui_end_turn != null:
			ui_end_turn.disabled = true
		return true
	return false

func _run_enemy_turn() -> void:
	await get_tree().create_timer(0.6).timeout
	var playable := true
	while playable:
		playable = false
		for card in enemy_state.hand.duplicate():
			if card.is_spell() and _can_afford(card, enemy_state):
				_play_enemy_spell(card)
				playable = true
				break
			if not card.is_spell() and _can_afford(card, enemy_state):
				var slot := _find_enemy_slot()
				if slot >= 0:
					_play_enemy_unit(card, slot)
					playable = true
					break
		await get_tree().create_timer(0.4).timeout
	_end_turn()

func _play_enemy_unit(card: Card3D, lane_index: int) -> void:
	_apply_cost(card, enemy_state)
	enemy_state.hand.erase(card)
	enemy_state.board[lane_index] = card
	_trigger_abilities("on_play", card)
	_update_hand_positions(enemy_state)
	_update_board_positions(enemy_state)

func _play_enemy_spell(card: Card3D) -> void:
	_apply_cost(card, enemy_state)
	enemy_state.hand.erase(card)
	_execute_spell(card)
	card.queue_free()
	_update_hand_positions(enemy_state)

func _find_enemy_slot() -> int:
	for i in range(LANE_COUNT):
		if enemy_state.board[i] == null:
			return i
	return -1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		selected_card = null
		_highlight_slots(false)
		if camera_fsm != null:
			camera_fsm.go_to_state(CameraFSM.CameraState.PUSH_IN)
