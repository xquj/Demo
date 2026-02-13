extends State
class_name DealingState

const SELECTING_STATE_SCRIPT: Script = preload("res://scripts/card/states/SelectingState.gd")

func enter() -> void:
	super.enter()
	var idx = global.selected_group.find(card) + 1
	var target_pos = Vector3(global.deck.global_position.x + 0.2 + idx * 0.3,global.deck.global_position.y - 0.05,global.deck.global_position.z)
	_move_with_control_rotation(target_pos,
	Vector3((card.start_pos.x + target_pos.x) / 2,target_pos.y + 0.8,(card.start_pos.z + target_pos.z) / 2),
	Vector3(Vector3(deg_to_rad(-90),deg_to_rad(0),deg_to_rad(0))),0.5)

func exit() -> void:
	super.exit()

func update(delta: float) -> void:
	super.update(delta)
	if _is_move_finished():
		transition_to(SELECTING_STATE_SCRIPT)

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
