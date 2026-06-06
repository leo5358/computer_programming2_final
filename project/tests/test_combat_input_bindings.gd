extends SceneTree

func _initialize() -> void:
	_assert_key_binding("attack", KEY_J)
	_assert_mouse_binding("attack", MOUSE_BUTTON_LEFT)
	_assert_key_binding("block", KEY_K)
	_assert_mouse_binding("block", MOUSE_BUTTON_RIGHT)
	_assert_key_binding("dash", KEY_L)
	_assert_key_binding("perfect_dodge_shift", KEY_SHIFT)
	_assert_no_key_binding("dash", KEY_SHIFT)
	quit(0)

func _assert_key_binding(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		push_error("InputMap should include %s" % action_name)
		quit(1)
		return
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return
	push_error("InputMap action %s should include keycode %d" % [action_name, keycode])
	quit(1)

func _assert_mouse_binding(action_name: String, button_index: int) -> void:
	if not InputMap.has_action(action_name):
		push_error("InputMap should include %s" % action_name)
		quit(1)
		return
	for event in InputMap.action_get_events(action_name):
		if event is InputEventMouseButton and event.button_index == button_index:
			return
	push_error("InputMap action %s should include mouse button %d" % [action_name, button_index])
	quit(1)

func _assert_no_key_binding(action_name: String, keycode: int) -> void:
	if not InputMap.has_action(action_name):
		push_error("InputMap should include %s" % action_name)
		quit(1)
		return
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			push_error("InputMap action %s should not include keycode %d" % [action_name, keycode])
			quit(1)
			return
