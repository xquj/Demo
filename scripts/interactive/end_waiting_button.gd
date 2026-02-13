extends MeshInstance3D

var is_entered: bool = false

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.is_released():
		return
	if not is_entered or global.current_state != global.GameState.WAITING:
		return
	if global.event_bus != null:
		global.event_bus.end_waiting_requested.emit()

func _on_area_3d_mouse_entered() -> void:
	is_entered = true

func _on_area_3d_mouse_exited() -> void:
	is_entered = false
