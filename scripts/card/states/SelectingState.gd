extends State
class_name SelectingState

var area: Area3D
var is_entered: bool
var start_pos: Vector3

func enter() -> void:
	# 区域初始化：绑定鼠标进入/离开事件。
	for child in card.get_children():
		if child as Area3D:
			area = child
			break
	if area != null:
		area.mouse_entered.connect(func():mouse_entered(true))
		area.mouse_exited.connect(func():mouse_entered(false))
	start_pos = card.global_position

	
func exit() -> void:
	super.exit()
	# 退出选牌状态时，恢复卡牌显示状态并写回归属信息。
	area.visible = false
	card.set_color(card.original_modulate,100)
	
	global.round += 1;
	
	if global.selected_group.has(card):
		global.selected_group.remove_at(global.selected_group.find(card))
		
	if global.player_activity != null:
		card.team_id = global.player_activity.team_id
		card.player = global.player_activity
		card.player.waitingGroup.push_back(card)
		
	card.start_pos = card.global_position
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	super.update(delta)
	if global.current_state == global.GameState.SELECTING:
		area.visible = true

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			if _is_move_finished() and is_entered:
				transition_to(load("res://scripts/card/states/ToWaitState.gd"))

func mouse_entered(entered: bool) -> void:
	if card.state != self or !area.visible: return
	is_entered = entered
	if entered:
		card.set_color(Color(0.588, 0.588, 0.588, 1.0),100)
		_move(Vector3(start_pos.x, start_pos.y + 0.01, start_pos.z),0.1,0,1)
	else:
		card.set_color(card.original_modulate,100)
		_move(Vector3(start_pos.x, start_pos.y, start_pos.z),0.1,0,1)
