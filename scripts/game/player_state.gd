extends RefCounted
class_name PlayerState

var name: String
var is_player: bool
var deck: Array[Dictionary] = []
var hand: Array[Card3D] = []
var board: Array[Card3D] = []
var bones: int = 0

func _init(name_: String, is_player_: bool) -> void:
	name = name_
	is_player = is_player_
