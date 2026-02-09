extends State
class_name ToHeldState

func enter() -> void:
	super.enter()
	if card.player.waitingGroup.has(card):
		card.player.waitingGroup.remove_at(card.player.waitingGroup.find(card))
		card.player.hand_cards.push_back(card)
	#位置初始化
	var idx = card.player.hand_cards.find(card) + 1
	
	var target_pos = Vector3(global.HELD_Area2_Label.global_position.x + 0.25 + idx * 0.2,global.HELD_Area2_Label.global_position.y + 0.01,global.HELD_Area2_Label.global_position.z)
		
	if card.team_id == global.local_player.team_id:
		target_pos = Vector3(global.camera.global_position.x - 0.3 + idx * 0.2,global.camera.global_position.y - 0.5,global.camera.global_position.z - 0.15)
		card.reparent(global.camera)
		
	var target_rot = Vector3(card.rotation.x + deg_to_rad(45),card.rotation.y,card.rotation.z)
	
	_move_with_control_rotation(target_pos,
	Vector3((card.start_pos.x + target_pos.x) / 2,target_pos.y + 0.2,(card.start_pos.z + target_pos.z) / 2),target_rot,0.2)
	
func exit() -> void:
	super.exit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	super.update(delta)
	#if _is_move_finished():
		#transition_to(load("res://scripts/card/states/HeldState.gd"))


func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
