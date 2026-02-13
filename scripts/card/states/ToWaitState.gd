extends State
class_name ToWaitState

const WAITING_STATE_SCRIPT: Script = preload("res://scripts/card/states/WaitingState.gd")

func enter() -> void:
	super.enter()
	var idx := card.player.waitingGroup.find(card) + 1
	var target_pos := Vector3(global.wait_area1_label.global_position.x + 0.25 + idx * 0.3, global.wait_area1_label.global_position.y + 0.01, global.wait_area1_label.global_position.z)
	if card.team_id != global.local_player.team_id:
		target_pos = Vector3(global.wait_area2_label.global_position.x + 0.25 + idx * 0.3, global.wait_area2_label.global_position.y + 0.01, global.wait_area2_label.global_position.z)
	_move_with_control(target_pos, Vector3((card.start_pos.x + target_pos.x) / 2, target_pos.y + 0.2, (card.start_pos.z + target_pos.z) / 2), 0.2)

func exit() -> void:
	super.exit()

func update(delta: float) -> void:
	super.update(delta)
	if _is_move_finished():
		transition_to(WAITING_STATE_SCRIPT)

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
