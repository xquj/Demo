class_name Coin2 extends ItemDate

# 构造函数
func _init() -> void:
	# 设置货币属性
	var item_id_ = "2"
	var name_ = "Coin 2"
	var description_ = "A level 2 currency item"
	var item_type_ = "currency"
	var texture_: Texture2D = load("res://textrue/coin/coin2.png")
	# 调用父类构造函数
	super(item_id_, name_, description_, item_type_, texture_)
