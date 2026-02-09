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
var waitingGroup: Array[Card_Base] #代取卡牌
var hand_cards: Array[Card_Base] #手牌
var showing_cards: Array[Card_Base] #展示牌（修正原重复注释）
var can_combo: bool
var hand_fan_center_local: Vector3
var hand_fan_center_initialized: bool

# 构造函数：初始化核心属性（原有代码，无错误）
func _init(name_: String, team_id_: int, is_active_: bool) -> void:
	health = 100
	defense = 100
	inventory = Inventory.new()
	inventory_temporary = Inventory.new(999)
	name = name_
	team_id = team_id_
	is_active = is_active_
	hand_fan_center_local = Vector3.ZERO
	hand_fan_center_initialized = false


func process() -> void:
	pass
