extends Card_Wyrm


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready() 
	card_name = "燃烧颅骨"
	skill = "弃置一张你的火焰牌，然后获得一点【货币1】"
	skill_type = Type.Initiative
	cost = 3

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
