extends SceneTree

const MAIN_SCENE_PATH: String = "res://scenes/node_3d.tscn"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load(MAIN_SCENE_PATH) as PackedScene
	if packed == null:
		push_error("SmokeCheck: failed to load main scene: %s" % MAIN_SCENE_PATH)
		quit(1)
		return

	var instance: Node = packed.instantiate()
	if instance == null:
		push_error("SmokeCheck: failed to instantiate main scene.")
		quit(1)
		return
	get_root().add_child(instance)

	await process_frame
	await process_frame

	var failures: Array[String] = []
	if global.deck == null:
		failures.push_back("global.deck is null")
	if global.discard_pile == null:
		failures.push_back("global.discard_pile is null")
	if global.camera == null:
		failures.push_back("global.camera is null")
	if global.local_hand_anchor == null:
		failures.push_back("global.local_hand_anchor is null")
	if global.remote_hand_anchor == null:
		failures.push_back("global.remote_hand_anchor is null")

	if failures.size() > 0:
		for failure in failures:
			push_error("SmokeCheck: %s" % failure)
		quit(2)
		return

	print("SmokeCheck: PASS")
	quit(0)
