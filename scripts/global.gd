class_name global

enum GameState {
	TO_DEALING,
	DEALING,
	TO_SELECTING,
	SELECTING,
	TO_WAITING,
	WAITING,
	TO_COMBOING,
	COMBOING
}

static var match_state: MatchState = MatchState.new()
static var scene_refs: SceneRefs = SceneRefs.new()

static var selected_group: Array[Card_Base]:
	get:
		return match_state.selected_group
	set(value):
		match_state.selected_group = value

static var discard_group: Array[Card_Base]:
	get:
		return match_state.discard_group
	set(value):
		match_state.discard_group = value

static var players: Array[PlayerEntity]:
	get:
		return match_state.players
	set(value):
		match_state.players = value

static var player_activity: PlayerEntity:
	get:
		return match_state.player_activity
	set(value):
		match_state.player_activity = value

static var local_player: PlayerEntity:
	get:
		return match_state.local_player
	set(value):
		match_state.local_player = value

static var current_play_turn: int:
	get:
		return match_state.current_play_turn
	set(value):
		match_state.current_play_turn = value

static var round: int:
	get:
		return match_state.round
	set(value):
		match_state.round = value

static var game_progress: int:
	get:
		return match_state.game_progress
	set(value):
		match_state.game_progress = value

static var detailed_card: Card_Base:
	get:
		return match_state.detailed_card
	set(value):
		match_state.detailed_card = value

static var current_state: int:
	get:
		return match_state.current_state
	set(value):
		match_state.current_state = value

static var selected_card: Card_Base:
	get:
		return match_state.selected_card
	set(value):
		match_state.selected_card = value

static var cards_number_label: Label3D:
	get:
		return scene_refs.cards_number_label
	set(value):
		scene_refs.cards_number_label = value

static var showing_area_label: Label3D:
	get:
		return scene_refs.showing_area_label
	set(value):
		scene_refs.showing_area_label = value

static var wait_area1_label: Label3D:
	get:
		return scene_refs.wait_area1_label
	set(value):
		scene_refs.wait_area1_label = value

static var wait_area2_label: Label3D:
	get:
		return scene_refs.wait_area2_label
	set(value):
		scene_refs.wait_area2_label = value

static var held_area1_label: Label3D:
	get:
		return scene_refs.held_area1_label
	set(value):
		scene_refs.held_area1_label = value

static var held_area2_label: Label3D:
	get:
		return scene_refs.held_area2_label
	set(value):
		scene_refs.held_area2_label = value

static var discard_pile: Sprite3D:
	get:
		return scene_refs.discard_pile
	set(value):
		scene_refs.discard_pile = value

static var deck: Sprite3D:
	get:
		return scene_refs.deck
	set(value):
		scene_refs.deck = value

static var camera: Camera3D:
	get:
		return scene_refs.camera
	set(value):
		scene_refs.camera = value

static var local_hand_anchor: Node3D:
	get:
		return scene_refs.local_hand_anchor
	set(value):
		scene_refs.local_hand_anchor = value

static var remote_hand_anchor: Node3D:
	get:
		return scene_refs.remote_hand_anchor
	set(value):
		scene_refs.remote_hand_anchor = value

static var local_wait_anchor: Node3D:
	get:
		return scene_refs.local_wait_anchor
	set(value):
		scene_refs.local_wait_anchor = value

static var local_held_anchor: Node3D:
	get:
		return scene_refs.local_held_anchor
	set(value):
		scene_refs.local_held_anchor = value

static var remote_wait_anchor: Node3D:
	get:
		return scene_refs.remote_wait_anchor
	set(value):
		scene_refs.remote_wait_anchor = value

static var remote_held_anchor: Node3D:
	get:
		return scene_refs.remote_held_anchor
	set(value):
		scene_refs.remote_held_anchor = value

static var local_player_node: Node3D:
	get:
		return scene_refs.local_player_node
	set(value):
		scene_refs.local_player_node = value

static var multi_player_node: Node3D:
	get:
		return scene_refs.multi_player_node
	set(value):
		scene_refs.multi_player_node = value

static var cube_desk: MeshInstance3D:
	get:
		return scene_refs.cube_desk
	set(value):
		scene_refs.cube_desk = value

static var camera_controller: CameraController:
	get:
		return scene_refs.camera_controller
	set(value):
		scene_refs.camera_controller = value

static var cube_rot_animation: AnimationUtils:
	get:
		return scene_refs.cube_rot_animation
	set(value):
		scene_refs.cube_rot_animation = value

static var game_sense: GameScene3D:
	get:
		return scene_refs.game_sense
	set(value):
		scene_refs.game_sense = value

static var event_bus: EventBus:
	get:
		return scene_refs.event_bus
	set(value):
		scene_refs.event_bus = value

static var diagnostics_enabled: bool = false

static func reset_runtime_state(preserve_players: bool = false) -> void:
	selected_group = []
	discard_group = []
	if not preserve_players:
		players = []
		local_player = null
	player_activity = null
	current_play_turn = 0
	round = 0
	game_progress = 1
	detailed_card = null
	selected_card = null
	current_state = GameState.DEALING

static func is_transitional_state() -> bool:
	return current_state == GameState.TO_DEALING \
		or current_state == GameState.TO_SELECTING \
		or current_state == GameState.TO_WAITING \
		or current_state == GameState.TO_COMBOING

static func debug_log(message: String) -> void:
	if diagnostics_enabled:
		print("[DEBUG] %s" % message)
