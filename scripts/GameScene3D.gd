extends Node3D
class_name GameScene3D

var _turn_system: TurnSystem
var _card_spawn_system: CardSpawnSystem
var _battle_flow: BattleFlow
var _battle_presenter: BattlePresenter
var _scene_layout_system: SceneLayoutSystem
var _scene_binder: SceneBinder
var _signal_bridge: SignalBridge

func _ready() -> void:
	global.game_sense = self
	_scene_binder = SceneBinder.new()
	_scene_binder.bind_global_references(self)
	global.reset_runtime_state(true)
	_turn_system = TurnSystem.new()
	_card_spawn_system = CardSpawnSystem.new(self)
	_battle_flow = BattleFlow.new(self, _turn_system, _card_spawn_system)
	_battle_presenter = BattlePresenter.new()
	_scene_layout_system = SceneLayoutSystem.new()
	_signal_bridge = SignalBridge.new(_battle_flow, global.event_bus)
	_apply_scene_layout()
	_signal_bridge.connect_event_bus()
	_battle_flow.reset_match_state()

func _process(delta: float) -> void:
	_battle_presenter.update_camera_and_animations(delta)
	_battle_presenter.update_hand_count_label()
	_battle_flow.process_formal_state()
	_battle_flow.process_transitional_state()
	_card_spawn_system.update_tick()

func _input(event: InputEvent) -> void:
	if global.camera_controller != null:
		global.camera_controller._input_event(event)

func _on_sell_button_up() -> void:
	_turn_system.sell_selected_card()

func _on_tame_button_up() -> void:
	_turn_system.tame_selected_card()

func _hover(m_x: float, m_y: float, x: float, y: float, x1: float, y1: float) -> bool:
	return m_x >= x and m_x <= x1 and m_y >= y and m_y <= y1

func initialize_card(card: Card_Base) -> void:
	global.selected_group.push_back(card)
	var last_card: Card_Base = global.selected_group.back()
	if last_card.get_parent() == null:
		global.cube_desk.add_child(last_card)

func _apply_scene_layout() -> void:
	_scene_layout_system.apply_default_layout(_scene_binder.create_layout_refs(self), false)

func request_state_change(state: global.GameState) -> bool:
	return _battle_flow.request_state_change(state)

func try_enter_comboing_from_waiting() -> bool:
	return _battle_flow.try_enter_comboing_from_waiting()

func request_waiting_ready(player: PlayerEntity) -> bool:
	return _battle_flow.request_waiting_ready(player)

func request_advance_combo_round(player: PlayerEntity) -> bool:
	return _battle_flow.request_advance_combo_round(player)

func _switch_state(state: global.GameState) -> void:
	request_state_change(state)

func on_selecting_card_committed(card: Card_Base) -> void:
	_turn_system.commit_selecting_card(card)

func on_card_to_held_enter(card: Card_Base) -> void:
	_turn_system.enter_to_held(card)

func on_card_to_held_exit(card: Card_Base) -> void:
	_turn_system.exit_to_held(card)
