class_name Coin3 extends ItemData

# 构造函数
func _init() -> void:
	# 设置货币属性
	var item_id_ = "3"
	var name_ = "Coin 3"
	var description_ = "A level 3 currency item"
	var item_type_ = "currency"
	var texture_: Texture2D = load("res://textrue/coin/coin3.png")
	# 调用父类构造函数
	super(item_id_, name_, description_, item_type_, texture_)
