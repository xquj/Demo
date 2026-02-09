extends State
class_name DealingState

func enter() -> void:
	super.enter()
	var idx = global.selectGroup.find(card) + 1
	var target_pos = Vector3(global.Deck.global_position.x + 0.2 + idx * 0.3,global.Deck.global_position.y - 0.05,global.Deck.global_position.z)
	_move_with_control_rotation(target_pos,
	Vector3((card.start_pos.x + target_pos.x) / 2,target_pos.y + 0.8,(card.start_pos.z + target_pos.z) / 2),
	Vector3(Vector3(deg_to_rad(-90),deg_to_rad(0),deg_to_rad(0))),0.5)
	
func exit() -> void:
	super.exit()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func update(delta: float) -> void:
	super.update(delta)
	if _is_move_finished():
		transition_to(load("res://scripts/card/states/SelectingState.gd"))

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
