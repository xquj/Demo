extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_button_up() -> void:
	global.players = [LocalPlayer.new("Me",1,false),MultiPlayer.new("Enemy",2,false)]
	global.current_state = global.GameState.DEALING
	global.local_player = global.players[0]
	get_tree().change_scene_to_file("res://node_3d.tscn")
