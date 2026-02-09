extends State
class_name ToWaitState

func enter() -> void:
	super.enter()
	#位置初始化
	var idx = card.player.waitingGroup.find(card) + 1
	var target_pos = Vector3(global.WAIT_Area1_Label.global_position.x + 0.25 + idx * 0.3,global.WAIT_Area1_Label.global_position.y + 0.01,global.WAIT_Area1_Label.global_position.z)
	if card.team_id != global.local_player.team_id:
		target_pos = Vector3(global.WAIT_Area2_Label.global_position.x + 0.25 + idx * 0.3,global.WAIT_Area2_Label.global_position.y + 0.01,global.WAIT_Area2_Label.global_position.z)
	_move_with_control(target_pos,
	Vector3((card.start_pos.x + target_pos.x) / 2,target_pos.y + 0.2,(card.start_pos.z + target_pos.z) / 2),0.2)
	
func exit() -> void:
	super.exit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	super.update(delta)
	if _is_move_finished():
		transition_to(load("res://scripts/card/states/WaittingState.gd"))


func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
