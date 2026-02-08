extends Panel

var coin1: Label
var coin2: Label
var coin3: Label
var coin_slots: Array[Button] = []
var point: Label
var min_point_size: Vector2
var max_point_size: Vector2
var min_width: float
var max_width: float
var original_x: float
var animation_x: AnimationUtils
var animation_y: AnimationUtils
var animation_fold: AnimationUtils
var is_entered: bool
var is_folded: bool
var inventoryPanel: Panel
var coinPanel: Panel
var slots: Array[Button] = []
var select_slot: Button = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	inventoryPanel = $InventoryPanel
	var nums: int = 0;
	for child in inventoryPanel.get_children():
		if child as Button:
			var button: Button = child
			var sprite: Sprite2D = button.get_child(0)
			if global.local_player.inventory.get_item(nums) != null:
				sprite.texture = global.local_player.inventory.get_item(nums).texture
				sprite.visible = true
			else:
				sprite.visible = false
			slots.push_back(button)
			button.button_down.connect(func(): _on_button_toggled(button))
			nums+=1;
#######################################################################################
	coinPanel = $CoinPanel
	for child in coinPanel.get_children():
		if child as Button:
			var button: Button = child
			coin_slots.push_back(button)
			button.button_up.connect(func(): _on_coin_button_up(button))
########################################################################################
	coin1 = $CoinPanel/Coin1_Slot/Coin1/Label
	coin2 = $CoinPanel/Coin2_Slot/Coin2/Label
	coin3 = $CoinPanel/Coin3_Slot/Coin3/Label
	point = $Panel/point# Replace with function body.
	min_point_size = point.scale
	max_point_size = Vector2(point.scale.x * 1.2,point.scale.y * 1.2)
	animation_x = AnimationUtils.new(min_point_size.x,min_point_size.x,100)
	animation_x.play(true)
	animation_y = AnimationUtils.new(min_point_size.y,min_point_size.y,100)
	animation_y.play(true)
	animation_fold = AnimationUtils.new(0.0,0.0,100)
	animation_fold.play(true)
	min_width = size.x
	max_width = min_width * 6
	original_x = position.x
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	animation_x.update(delta)
	animation_y.update(delta)
	animation_fold.update(delta)
	point.scale.x = animation_x.value
	point.scale.y = animation_y.value
	point.rotation = deg_to_rad(animation_fold.value * 180)
	size.x = min_width + max_width * animation_fold.value
	position.x = original_x - max_width * animation_fold.value
	coin1.text = "X  " + str(global.local_player.inventory_temporary.get_item_count("1"))
	coin2.text = "X  " + str(global.local_player.inventory_temporary.get_item_count("2"))
	coin3.text = "X  " + str(global.local_player.inventory_temporary.get_item_count("3"))
	for slot in slots:
		var sprite: Sprite2D = slot.get_child(0)
		var nums :int= slots.find(slot)
		if global.local_player.inventory.get_item(nums) != null:
			sprite.texture = global.local_player.inventory.get_item(nums).texture
			sprite.visible = true
		else:
			sprite.visible = false
			
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if is_entered:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				is_folded = !is_folded
				if is_folded:
					animation_fold.set_target(1.0,100)
					animation_fold.play(true)
				else:
					animation_fold.set_target(0.0,100)
					animation_fold.play(true)
					
				animation_x.set_target(min_point_size.x,100)
				animation_x.play(true)
				animation_y.set_target(min_point_size.y,100)
				animation_y.play(true)

func _on_panel_mouse_entered() -> void:
	is_entered = true
	animation_x.set_target(max_point_size.x,100)
	animation_x.play(true)
	animation_y.set_target(max_point_size.y,100)
	animation_y.play(true)


func _on_panel_mouse_exited() -> void:
	is_entered = false
	animation_x.set_target(min_point_size.x,100)
	animation_x.play(true)
	animation_y.set_target(min_point_size.y,100)
	animation_y.play(true)


func _on_button_toggled(slot: Button):
	if select_slot != slot:
		if select_slot != null:
			select_slot.toggle_mode = false
		select_slot = slot
		select_slot.toggle_mode = true
	else:
		select_slot = null
		
func _on_coin_button_up(slot: Button):
	if select_slot == null : return
	var slot_id :int = slots.find(select_slot)
	
	if slot.name.contains("Coin1") && global.local_player.inventory_temporary.remove_item(global.local_player.inventory_temporary.get_item_index("1")):
		if !(global.local_player.inventory.get_item(slot_id) as AirItem):
			global.local_player.inventory_temporary.add_item_(global.local_player.inventory.get_item(slot_id))
		global.local_player.inventory.add_item(Coin1.new(),slot_id)
	elif slot.name.contains("Coin2") && global.local_player.inventory_temporary.remove_item(global.local_player.inventory_temporary.get_item_index("2")):
		if !(global.local_player.inventory.get_item(slot_id) as AirItem):
			global.local_player.inventory_temporary.add_item_(global.local_player.inventory.get_item(slot_id))
		global.local_player.inventory.add_item(Coin2.new(),slot_id)
	elif slot.name.contains("Coin3") && global.local_player.inventory_temporary.remove_item(global.local_player.inventory_temporary.get_item_index("3")):
		if !(global.local_player.inventory.get_item(slot_id) as AirItem):
			global.local_player.inventory_temporary.add_item_(global.local_player.inventory.get_item(slot_id))
		global.local_player.inventory.add_item(Coin3.new(),slot_id)
	select_slot.toggle_mode = false
	select_slot = null
