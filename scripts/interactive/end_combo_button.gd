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
			if is_entered and global.current_state == global.GameState.COMBOING:
				global.round += 1;

func _on_area_3d_mouse_entered() -> void:
	is_entered = true


func _on_area_3d_mouse_exited() -> void:
	is_entered = false
