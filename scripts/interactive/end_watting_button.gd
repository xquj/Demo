extends MeshInstance3D


var is_entered: bool
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			if is_entered and global.current_state == global.GameState.WAITING:
				var total_waiting_size: int = 0;
				for player in global.players:
					total_waiting_size += player.waitingGroup.size()
					if !player.can_combo:
						total_waiting_size = -9999
				if total_waiting_size == 0 && global.cube_rot_animation.end_value != 90:
					global.spring_length_animation.set_target(3,200)
					global.spring_length_animation.play(true)
					global.spring_rotX_animation.set_target(0,200)
					global.spring_rotX_animation.play(true)
					global.cube_rot_animation.set_target(90,500)
					global.cube_rot_animation.play(true)

func _on_area_3d_mouse_entered() -> void:
	is_entered = true


func _on_area_3d_mouse_exited() -> void:
	is_entered = false
