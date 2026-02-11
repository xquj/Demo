extends MeshInstance3D

var is_entered: bool = false

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.is_released():
		return
	if not is_entered or global.current_state != global.GameState.WAITING:
		return

	var total_waiting_size: int = 0
	for player in global.players:
		total_waiting_size += player.waitingGroup.size()
		if not player.can_combo:
			total_waiting_size = -1
			break

	if total_waiting_size == 0 and global.cube_rot_animation.end_value != 90:
		global.game_sense._switch_state(global.GameState.COMBOING)

func _on_area_3d_mouse_entered() -> void:
	is_entered = true

func _on_area_3d_mouse_exited() -> void:
	is_entered = false
