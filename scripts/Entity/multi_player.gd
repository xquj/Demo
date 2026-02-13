class_name MultiPlayer extends PlayerEntity

func _init(name_: String, team_id_: int, is_active_: bool) -> void:
	super._init(name_, team_id_, is_active_)
	controller = SimpleAiController.new(SimpleAiController.Mode.BALANCED)

func process() -> void:
	super.process()
