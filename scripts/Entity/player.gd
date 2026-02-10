class_name PlayerEntity extends Object

var name: String
var team_id: int
var is_active: bool
var item_notes: Array[String]
var score: int
var health: int
var defense: int
var inventory: Inventory
var inventory_temporary: Inventory
var waitingGroup: Array[Card_Base] # 待处理卡牌组（等待进入手牌）。
var hand_cards: Array[Card_Base] # 手牌列表。
var showing_cards: Array[Card_Base] # 展示区卡牌列表。
var can_combo: bool

# 构造函数：初始化玩家核心属性。
func _init(name_: String, team_id_: int, is_active_: bool) -> void:
	health = 100
	defense = 100
	inventory = Inventory.new()
	inventory_temporary = Inventory.new(999)
	name = name_
	team_id = team_id_
	is_active = is_active_


func process() -> void:
	pass
