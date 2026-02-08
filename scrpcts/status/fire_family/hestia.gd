extends Card_Fire


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready() # Replace with function body.
	card_name = "赫斯提亚"
	skill = "你可以多保留两枚货币"
	skill_type = Type.Permanent
	cost = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)

func take_effect() -> void:
	for player in global.players:
		if player.team_id != team_id:
			player.health -= 50
			if player.health < 0:
				player.health = 0
