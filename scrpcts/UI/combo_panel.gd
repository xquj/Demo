extends Panel

var inventoryPanel: Panel
var coinPanel: Panel
var slots: Array[Button] = []
var select_slots: Array[Button] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inventoryPanel = $Use/InventoryPanel
	var nums: int = 0;
	for child in inventoryPanel.get_children():
		if child as Button:
			var button: Button = child
			var sprite: Sprite2D = button.get_child(0)
			sprite.texture = null
			sprite.visible = false
			slots.push_back(button)
			button.toggled.connect(func(toggle: bool): _on_button_toggled(toggle,button))
			nums+=1;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !visible:
		return
	
	var use_button: Button = $Use
	if global.selectedCard != null && global.selectedCard.team_id == global.player_activity.team_id:
		use_button.visible = true
	else:
		use_button.visible = false
	#使用卡牌消耗货币相关部分
	for slot in slots:
		var sprite: Sprite2D = slot.get_child(0)
		var nums :int= slots.find(slot)
		if global.player_activity.inventory.get_item(nums) != null:
			sprite.texture = global.player_activity.inventory.get_item(nums).texture
			sprite.visible = true
		else:
			sprite.visible = false

func _on_end_button_up() -> void: #回合结束按钮
	if global.selectedCard != null:
		global.selectedCard.move_ability = true
		global.selectedCard.elapsed_time = 0;
		global.selectedCard.peak_height = Vector3(0,0,0)
		global.selectedCard = null
	global.player_activity.inventory_temporary.clear()
	global.round += 1;
	visible = false


func _on_use_button_up() -> void:
	var pay_coins: int = 0;
	for slot in select_slots:
		var idx = slots.find(slot)
		match global.player_activity.inventory.get_item(idx).item_id:
			"1":
				pay_coins += 1
			"2":
				pay_coins += 3
			"3":
				pay_coins += 6
	if pay_coins >= global.selectedCard.cost:
		for slot in select_slots:
			var idx = slots.find(slot)
			global.player_activity.inventory.remove_item(idx)
		global.selectedCard.switch_state(Card_Base.States.TO_SHOWING)
		global.selectedCard = null
		global.player_activity.inventory_temporary.clear()
		for slot in slots: 
			slot.toggle_mode = false  #复原支付物品栏格子
			slot.toggle_mode = true


func _on_button_toggled(toggle:bool,slot: Button):
	if select_slots.has(slot):
		if !toggle:
			select_slots.remove_at(select_slots.find(slot))
	else:
		if toggle:
			select_slots.push_back(slot)
		
