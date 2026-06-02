extends Node2D

signal option_confirmed(option_index: int, option_name: String)

const MAIN_SCENE_PATH := "res://scenes/Main.tscn"
const NEW_GAME_DELAY := 0.5
const FADE_DURATION := 0.45
const MENU_NODE_NAMES := [&"menu_continue", &"menu_new_game", &"menu_quit"]
const MENU_OPTION_NAMES := ["continue", "new_game", "quit"]
const SELECTOR_POSITION_OFFSETS := [
	Vector2.ZERO,
	Vector2(0, -5),
	Vector2(0, -4),
]
const PRESS_SCALE := Vector2(0.94, 0.9)
const PRESS_DURATION := 0.06

@onready var menu_selector: Sprite2D = $menu_selector
@onready var menu_selector_glow: Sprite2D = $menu_selector_glow
@onready var fade_rect: ColorRect = $FadeLayer/FadeRect
@onready var start_bgm: AudioStreamPlayer = $StartPageBgm

var _menu_nodes: Array[Sprite2D] = []
var _selector_offset := Vector2.ZERO
var _selector_glow_offset := Vector2.ZERO
var _selected_index := -1
var _selector_base_scale := Vector2.ONE
var _selector_glow_base_scale := Vector2.ONE
var _press_tween: Tween
var _is_confirming := false


func _ready() -> void:
	for node_name in MENU_NODE_NAMES:
		_menu_nodes.append(get_node(NodePath(node_name)) as Sprite2D)

	_selector_offset = menu_selector.position - _menu_nodes[0].position
	_selector_glow_offset = menu_selector_glow.position - _menu_nodes[0].position
	_selector_base_scale = menu_selector.scale
	_selector_glow_base_scale = menu_selector_glow.scale
	menu_selector.visible = false
	menu_selector_glow.visible = false
	fade_rect.visible = false
	fade_rect.color = Color(0, 0, 0, 0)
	if start_bgm.stream != null and "loop" in start_bgm.stream:
		start_bgm.stream.loop = true
	_setup_mouse_hit_areas()


func _unhandled_input(event: InputEvent) -> void:
	if _is_confirming:
		return

	if _is_menu_up(event):
		_move_selection(-1)
		_mark_input_handled()
		return

	if _is_menu_down(event):
		_move_selection(1)
		_mark_input_handled()
		return

	if _is_menu_confirm(event):
		_mark_input_handled()
		_confirm_selection()


func _move_selection(direction: int) -> void:
	if _selected_index < 0:
		_set_selection(0 if direction >= 0 else _menu_nodes.size() - 1)
	else:
		_set_selection(wrapi(_selected_index + direction, 0, _menu_nodes.size()))


func _set_selection(index: int) -> void:
	_selected_index = clampi(index, 0, _menu_nodes.size() - 1)
	menu_selector.visible = true
	menu_selector_glow.visible = true
	_apply_selection()


func _apply_selection() -> void:
	var target := _menu_nodes[_selected_index].position
	var selector_adjust: Vector2 = SELECTOR_POSITION_OFFSETS[_selected_index]
	menu_selector.position = target + _selector_offset + selector_adjust
	menu_selector_glow.position = target + _selector_glow_offset + selector_adjust


func _confirm_selection() -> void:
	if _is_confirming or _selected_index < 0:
		return

	_play_confirm_press()
	var option_name: String = MENU_OPTION_NAMES[_selected_index]
	option_confirmed.emit(_selected_index, option_name)
	_handle_menu_option(option_name)


func get_main_scene_path() -> String:
	return MAIN_SCENE_PATH


func _handle_menu_option(option_name: String) -> void:
	match option_name:
		"continue":
			if has_node("/root/SaveManager") and get_node("/root/SaveManager").has_save():
				_is_confirming = true
				get_tree().set_meta("load_from_save", true)
				_play_new_game_transition()
		"new_game":
			_start_new_game()
		"quit":
			_quit_game()
		_:
			pass


func _start_new_game() -> void:
	_clear_saved_game()
	if get_tree().has_meta("load_from_save"):
		get_tree().remove_meta("load_from_save")
	_is_confirming = true
	call_deferred("_play_new_game_transition")


func _play_new_game_transition() -> void:
	await get_tree().create_timer(NEW_GAME_DELAY).timeout
	await _fade_to(1.0)
	get_tree().set_meta("fade_in_from_start_page", true)
	_change_to_main_scene()


func _change_to_main_scene() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _clear_saved_game() -> void:
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		if save_manager.has_method("delete_save"):
			save_manager.delete_save()


func _quit_game() -> void:
	_is_confirming = true
	call_deferred("_quit_tree")


func _quit_tree() -> void:
	get_tree().quit()


func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _setup_mouse_hit_areas() -> void:
	for index in _menu_nodes.size():
		var menu_node: Sprite2D = _menu_nodes[index]
		var hit_area := Area2D.new()
		hit_area.name = "%s_mouse_area" % MENU_NODE_NAMES[index]
		hit_area.input_pickable = true
		hit_area.mouse_entered.connect(_on_menu_mouse_entered.bind(index))
		hit_area.mouse_exited.connect(_on_menu_mouse_exited.bind(index))
		hit_area.input_event.connect(_on_menu_input_event.bind(index))
		menu_node.add_child(hit_area)

		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		var texture_size := Vector2(240, 96)
		if menu_node.texture != null:
			texture_size = menu_node.texture.get_size()
		rectangle.size = texture_size
		shape.shape = rectangle
		hit_area.add_child(shape)


func _on_menu_mouse_entered(index: int) -> void:
	if _is_confirming:
		return
	_set_selection(index)


func _on_menu_mouse_exited(index: int) -> void:
	if _is_confirming or _selected_index != index:
		return
	_selected_index = -1
	menu_selector.visible = false
	menu_selector_glow.visible = false


func _on_menu_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, index: int) -> void:
	if _is_confirming:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_set_selection(index)
		_mark_input_handled()
		_confirm_selection()


func _fade_to(alpha: float) -> void:
	fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", alpha, FADE_DURATION)
	await tween.finished


func _play_confirm_press() -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()

	menu_selector.scale = _selector_base_scale
	menu_selector_glow.scale = _selector_glow_base_scale

	_press_tween = create_tween()
	_press_tween.tween_property(menu_selector, "scale", _selector_base_scale * PRESS_SCALE, PRESS_DURATION)
	_press_tween.parallel().tween_property(menu_selector_glow, "scale", _selector_glow_base_scale * PRESS_SCALE, PRESS_DURATION)
	_press_tween.tween_property(menu_selector, "scale", _selector_base_scale, PRESS_DURATION)
	_press_tween.parallel().tween_property(menu_selector_glow, "scale", _selector_glow_base_scale, PRESS_DURATION)


func _is_menu_up(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_up") or _is_key_pressed(event, [KEY_W, KEY_UP])


func _is_menu_down(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_down") or _is_key_pressed(event, [KEY_S, KEY_DOWN])


func _is_menu_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_accept") or _is_key_pressed(event, [KEY_ENTER, KEY_KP_ENTER])


func _is_key_pressed(event: InputEvent, keycodes: Array[int]) -> bool:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false

	return key_event.physical_keycode in keycodes
