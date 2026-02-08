extends Panel


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var round :Label = $Label/Round
	round.text = str(global.game_progress)
	var name :Label = $Name
	name.text = "名称 : "+global.local_player.name
	var name2 :Label = $Panel/Name
	name2.text = "名称 : "+global.local_player.name
	
	var 生命 :ProgressBar = $"Panel/生命/ProgressBar"
	生命.value = global.local_player.health
	var 防御 :ProgressBar = $"Panel/防御/ProgressBar"
	防御.value = global.local_player.defense
	
	var score :Label = $Score
	score.text = "分数 : "+str(global.local_player.score)
