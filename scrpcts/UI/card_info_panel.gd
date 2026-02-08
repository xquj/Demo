extends Panel

var texture_rect: TextureRect

var skill_label: Label
var skill_type_label: Label
var name_label: Label
var cost_label: Label
var family_label: Label
var family_texture: TextureRect

var close_point: Label
var close_panel: Panel
var info_button: Button
var info_panel: Panel
var min_c_point_size: Vector2
var min_c_panel_size: Vector2
var close_animation: AnimationUtils
var panel_scale_animation: AnimationUtils
var panel_size_animation: VectorAnimationUtils
var is_c_entered: bool
const min_scale: float = 0.73
const min_size: Vector2 = Vector2(432,535)
const max_size: Vector2 = Vector2(832,535)
var original_pos: Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	skill_label = $InfoPanel/Skill
	skill_type_label = $InfoPanel/Skill_Type
	name_label = $InfoPanel/Name
	cost_label = $InfoPanel/Cost
	family_label = $InfoPanel/Family
	family_texture = $InfoPanel/FamilyTexture
	info_panel = $InfoPanel
	original_pos = position
	#箭头图标
	close_point = $Close_Button/point
	min_c_point_size = close_point.scale

	#按钮
	info_button = $Details_Button
	info_button.toggled.connect(func(toggled: bool):_on__button_toggled(toggled))
	close_panel = $Close_Button
	min_c_panel_size = close_panel.scale
	
	#绑定图片
	texture_rect = $Panel/TextureRect
	
	close_animation = AnimationUtils.new(1.0,1.0,100)
	close_animation.play(true)
	
	
	panel_scale_animation = AnimationUtils.new(0,0,0)
	panel_scale_animation.play(true)
	
	panel_size_animation = VectorAnimationUtils.new(min_size,min_size,0)
	panel_size_animation.play(true)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	panel_size_animation.update(delta)
	size = panel_size_animation.value
	pivot_offset.x = size.x / 2
	pivot_offset.y = size.y / 2
	position = Vector2(original_pos.x + (min_size.x - size.x) / 2,original_pos.y + (min_size.y - size.y) / 2)
	if visible:
		panel_scale_animation.update(delta)
		scale.x = panel_scale_animation.value
		scale.y = panel_scale_animation.value
		
		if global.DetailedCard != null:
			texture_rect.texture = global.DetailedCard.texture
			skill_label.text = "技能 : " + global.DetailedCard.skill
			skill_type_label.text = "技能类型 : "
			match global.DetailedCard.skill_type:
				Card_Base.Type.Immediately:
					skill_type_label.text += "即时(一次性)"
				Card_Base.Type.Permanent:
					skill_type_label.text += "永久(随时生效)"
				Card_Base.Type.Initiative:
					skill_type_label.text += "主动(回合末生效)"
			name_label.text = "名称 : " + global.DetailedCard.card_name
			cost_label.text = "召唤所需花费 : " + str(global.DetailedCard.cost)
			family_label.text = "家族 : " + global.DetailedCard.family_name
			family_texture.texture = global.DetailedCard.family_texture
		
		if panel_scale_animation.done && panel_scale_animation.end_value == 0.0:
			global.DetailedCard = null
			visible = false
		
		close_animation.update(delta)
		close_point.scale = Vector2(min_c_point_size.x * close_animation.value,min_c_point_size.y * close_animation.value)
		close_panel.scale = Vector2(min_c_panel_size.x * close_animation.value,min_c_panel_size.y * close_animation.value)
		
		if panel_size_animation.done && panel_size_animation.end_value == max_size:
			info_panel.visible = true
		else:
			info_panel.visible = false
	else:
		panel_scale_animation.value = 0.0
		panel_scale_animation.set_target(min_scale,100)
		panel_scale_animation.play(true)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if is_c_entered:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				close_animation.set_target(1.0,100)
				close_animation.play(true)
				panel_scale_animation.set_target(0.0,50)
				panel_scale_animation.play(true)
				

func _on_close_button_mouse_entered() -> void:
	is_c_entered = true
	close_animation.set_target(1.05,100)
	close_animation.play(true)


func _on_close_button_mouse_exited() -> void:
	is_c_entered = false
	close_animation.set_target(1.0,100)
	close_animation.play(true)
	
func _on__button_toggled(toggled: bool) -> void:
	if toggled:
		panel_size_animation.set_target(max_size,100)
		panel_size_animation.play(true)
	else:
		panel_size_animation.set_target(min_size,100)
		panel_size_animation.play(true)
