class_name global

static var selected_group: Array[Card_Base] = [] # 选择卡牌组
static var discard_group: Array[Card_Base] = [] # 丢弃的卡牌组
static var players: Array[PlayerEntity] = [] # 玩家列表
static var player_activity: PlayerEntity = null # 活跃玩家
static var local_player: PlayerEntity = null # 本地玩家
static var current_play_turn: int = 0 # 玩家出牌回合数 第(current_play_turn % 玩家数)位出牌
static var round: int = 0 # 回合数
static var game_progress: int = 1 # 游戏进度 n/10
static var detailed_card: Card_Base = null # 详细介绍的卡牌(用于 card_info_panel.gd)
static var current_state: global.GameState = GameState.DEALING # 默认初始状态为发牌
static var selected_card: Card_Base = null # 选择的卡牌
static var cards_number_label: Label3D # 卡牌信息面板
static var showing_area_label: Label3D # 展示区域字体
static var wait_area1_label: Label3D # 区域字体
static var wait_area2_label: Label3D # 区域字体
static var held_area1_label: Label3D # 区域字体
static var held_area2_label: Label3D # 区域字体
static var discard_pile: Sprite3D # 弃牌堆(实体)
static var deck: Sprite3D # 牌堆(实体)
static var camera: Camera3D
static var multi_player_node: CharacterBody3D
static var cube_desk: MeshInstance3D
static var camera_controller: CameraController
static var cube_rot_animation: AnimationUtils = AnimationUtils.new(0, 0, 0)
static var game_sense: GameScene3D

# 状态枚举（必须前置声明，放在 current_state 变量之前）
enum GameState {
	TO_DEALING, # (过渡态)
	DEALING, # 发牌状态
	TO_SELECTING, # (过渡态)
	SELECTING, # 选牌状态
	TO_WAITING, # (过渡态)
	WAITING, # 等待状态
	TO_COMBOING, # (过渡态)
	COMBOING # 连招状态
}

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
