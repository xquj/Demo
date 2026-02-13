extends Node2D

const BATTLE_SCENE_PATH: String = "res://scenes/node_3d.tscn"

func _on_button_button_up() -> void:
	global.reset_runtime_state()
	global.players = [LocalPlayer.new("Me", 1, false), MultiPlayer.new("Enemy", 2, false)]
	global.local_player = global.players[0]
	global.current_state = global.GameState.DEALING
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
