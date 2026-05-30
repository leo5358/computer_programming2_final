extends Node2D

signal option_confirmed(option_index: int, option_name: String)

const MAIN_SCENE_PATH := "res://scenes/Main.tscn"
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

var _menu_nodes: Array[Sprite2D] = []
var _selector_offset := Vector2.ZERO
var _selector_glow_offset := Vector2.ZERO
var _selected_index := 0
var _selector_base_scale := Vector2.ONE
var _selector_glow_base_scale := Vector2.ONE
var _press_tween: Tween


func _ready() -> void:
	for node_name in MENU_NODE_NAMES:
		_menu_nodes.append(get_node(NodePath(node_name)) as Sprite2D)

	_selector_offset = menu_selector.position - _menu_nodes[0].position
	_selector_glow_offset = menu_selector_glow.position - _menu_nodes[0].position
	_selector_base_scale = menu_selector.scale
	_selector_glow_base_scale = menu_selector_glow.scale
	_apply_selection()


func _unhandled_input(event: InputEvent) -> void:
	if _is_menu_up(event):
		_move_selection(-1)
		get_viewport().set_input_as_handled()
		return

	if _is_menu_down(event):
		_move_selection(1)
		get_viewport().set_input_as_handled()
		return

	if _is_menu_confirm(event):
		_confirm_selection()
		get_viewport().set_input_as_handled()


func _move_selection(direction: int) -> void:
	_selected_index = wrapi(_selected_index + direction, 0, _menu_nodes.size())
	_apply_selection()


func _apply_selection() -> void:
	var target := _menu_nodes[_selected_index].position
	var selector_adjust: Vector2 = SELECTOR_POSITION_OFFSETS[_selected_index]
	menu_selector.position = target + _selector_offset + selector_adjust
	menu_selector_glow.position = target + _selector_glow_offset + selector_adjust


func _confirm_selection() -> void:
	_play_confirm_press()
	var option_name: String = MENU_OPTION_NAMES[_selected_index]
	option_confirmed.emit(_selected_index, option_name)
	_handle_menu_option(option_name)


func get_main_scene_path() -> String:
	return MAIN_SCENE_PATH


func _handle_menu_option(option_name: String) -> void:
	match option_name:
		"new_game":
			get_tree().change_scene_to_file(MAIN_SCENE_PATH)
		"quit":
			get_tree().quit()
		_:
			pass


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
