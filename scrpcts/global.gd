
class_name global
static var selectGroup: Array[Card_Base]  #选择卡牌组
static var discardGroup: Array[Card_Base] #丢弃的卡牌组
static var players: Array[PlayerEntity] #玩家列表
static var player_activity: PlayerEntity; #活跃玩家
static var local_player: PlayerEntity #本地玩家
static var current_play_turn: int #玩家出牌回合数 第(current_play_turn % 玩家数)位出牌
static var round: int #回合数
static var game_progress: int #游戏进度 n/10
static var DetailedCard: Card_Base #详细介绍的卡牌(用于 card_info_panel.gd)
static var current_state: global.GameState # 默认初始状态为发牌
static var selectedCard: Card_Base #选择的卡牌
static var Tame_Panel :Panel #捕猎/售卖 卡牌面板
static var RoundEnd_Panel :Panel #回合末结束面板
static var Combo_Panel :Panel #回合 卡牌面板
static var Card_Info_Panel :Panel #卡牌信息面板
static var Cards_Number_Label :Label3D #卡牌信息面板
static var Showing_Area_Label :Label3D #展示区域字体
static var WAIT_Area1_Label :Label3D #区域字体
static var WAIT_Area2_Label :Label3D #区域字体
static var HELD_Area1_Label :Label3D #区域字体
static var HELD_Area2_Label :Label3D #区域字体
static var discardPile :Sprite3D #弃牌堆(实体)
static var Deck :Sprite3D #牌堆(实体)
static var camera: Camera3D
static var Cube_Desk: MeshInstance3D
static var spring_length_animation: AnimationUtils = AnimationUtils.new(0,0,0)
static var spring_rotX_animation: AnimationUtils = AnimationUtils.new(0,0,0)
# 状态枚举（必须前置声明，放在current_state变量之前）
enum GameState {
	DEALING,   # 发牌状态
	SELECTING, # 选牌状态
	WAITING,   # 等待状态
	COMBOING,  # 连招状态
	END        # 回合末状态
}
