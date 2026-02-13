extends State
class_name SelectingState

const TO_WAIT_STATE_SCRIPT: Script = preload("res://scripts/card/states/ToWaitState.gd")

var area: Area3D
var is_entered: bool
var start_pos: Vector3

func enter() -> void:
	for child in card.get_children():
		if child as Area3D:
			area = child
			break
	if area != null:
		area.mouse_entered.connect(func(): mouse_entered(true))
		area.mouse_exited.connect(func(): mouse_entered(false))
	start_pos = card.global_position

func exit() -> void:
	super.exit()
	if area != null:
		area.visible = false
	card.set_color(card.original_modulate, 100)
	if global.game_sense != null:
		global.game_sense.on_selecting_card_committed(card)

func update(delta: float) -> void:
	super.update(delta)
	if area != null and global.current_state == global.GameState.SELECTING:
		area.visible = true

func handle_input(event: InputEvent) -> void:
	super.handle_input(event)
	if event is InputEventMouseButton:
		if event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
			if _is_move_finished() and is_entered:
				transition_to(TO_WAIT_STATE_SCRIPT)

func mouse_entered(entered: bool) -> void:
	if area == null:
		return
	if card.state != self or !area.visible:
		return
	is_entered = entered
	if entered:
		card.set_color(Color(0.588, 0.588, 0.588, 1.0), 100)
		_move(Vector3(start_pos.x, start_pos.y + 0.01, start_pos.z), 0.1, 0, 1)
	else:
		card.set_color(card.original_modulate, 100)
		_move(Vector3(start_pos.x, start_pos.y, start_pos.z), 0.1, 0, 1)
