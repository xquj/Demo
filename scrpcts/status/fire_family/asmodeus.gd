extends Card_Fire


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready() # Replace with function body.
	card_name = "熔岩巨人"
	skill = "你的区域中每有一张火焰卡牌，获得一点【货币1】"
	skill_type = Type.Immediately
	cost = 3


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
