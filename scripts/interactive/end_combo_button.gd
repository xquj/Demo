extends MeshInstance3D

var is_entered: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if is_entered and global.current_state == global.GameState.COMBOING and global.event_bus != null:
				global.event_bus.end_combo_requested.emit()

func _on_area_3d_mouse_entered() -> void:
	is_entered = true

func _on_area_3d_mouse_exited() -> void:
	is_entered = false
