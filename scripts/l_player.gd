extends CharacterBody3D


const SPEED = 1.0
const JUMP_VELOCITY = 4.5
var is_clicked: bool = false

var mouseX: float = -999
var mouseZ: float = -999
var deltaX: float
var deltaZ: float

func _physics_process(delta: float) -> void:
	velocity.x = -deltaX * 0.15
	velocity.z = -deltaZ * 0.15
	deltaX = 0
	deltaZ = 0
	#move_and_slide()	
			
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_MIDDLE:
			is_clicked = true
		if event.is_released():
			mouseX = -999
			mouseZ = -999
			deltaX = 0
			deltaZ = 0
			is_clicked = false
	elif event is InputEventMouseMotion:
		if is_clicked:
			if mouseX != -999 and mouseZ != -999:
				deltaX = event.position.x - mouseX
				deltaZ = event.position.y - mouseZ
			mouseX = event.position.x
			mouseZ = event.position.y
