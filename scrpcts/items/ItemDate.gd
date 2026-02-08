class_name ItemDate extends RefCounted

# 物品基础属性
var item_id: String  # 物品唯一ID
var name: String     # 物品名称
var description: String  # 物品描述
var item_type: String  # 物品类型
var texture: Texture2D  # 物品的2D贴图

# 构造函数
func _init(item_id_: String, name_: String, description_: String, item_type_: String, texture_: Texture2D = null) -> void:
	item_id = item_id_
	name = name_
	description = description_
	item_type = item_type_
	texture = texture_

# 获取物品信息
func get_info() -> Dictionary:
	return {
		"item_id": item_id,
		"name": name,
		"description": description,
		"item_type": item_type,
		"texture": texture
	}
