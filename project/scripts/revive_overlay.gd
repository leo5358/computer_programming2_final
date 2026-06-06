extends CanvasLayer

signal revive_requested
signal give_up_requested

class CountdownRingControl:
	extends Control

	var ring_color := Color(0.94, 0.95, 0.98, 0.9)
	var ring_width := 5.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var radius: float = max(0.0, min(size.x, size.y) * 0.5 - ring_width)
		draw_arc(size * 0.5, radius, 0.0, TAU, 72, ring_color, ring_width, true)

const OPTION_REVIVE := 0
const OPTION_GIVE_UP := 1
const BUTTON_CLICK_SFX_PATH := "res://assets/sfx/buttonClick.MP3"

var fade_duration := 3.0
var countdown_duration := 15.0
var display_countdown_seconds := 15

var selected_index := OPTION_REVIVE
var is_active := false

var shade: ColorRect
var content: Control
var countdown_label: Label
var revive_label: Label
var give_up_label: Label
var options: VBoxContainer
var button_click_sfx: AudioStreamPlayer
var countdown_remaining := 0.0
var countdown_started := false
var countdown_resolved := false

func _ready() -> void:
	layer = 34
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_setup_button_click_sfx()
	hide_overlay_immediate()

func _process(delta: float) -> void:
	if not is_active or not countdown_started or countdown_resolved:
		return
	countdown_remaining = max(0.0, countdown_remaining - delta)
	_update_countdown_label()
	if countdown_remaining <= 0.0:
		countdown_resolved = true
		_play_button_click_sfx()
		give_up_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_UP, KEY_W:
			move_selection(-1)
			_mark_input_handled()
		KEY_DOWN, KEY_S:
			move_selection(1)
			_mark_input_handled()
		KEY_ENTER, KEY_KP_ENTER:
			confirm_selection()
			_mark_input_handled()

func show_revive_prompt() -> void:
	visible = true
	is_active = false
	selected_index = OPTION_REVIVE
	countdown_remaining = countdown_duration
	countdown_started = false
	countdown_resolved = false
	_update_selection()
	_update_countdown_label()
	content.modulate.a = 0.0
	shade.color = Color(0.0, 0.0, 0.0, 0.2)
	var tween := create_tween()
	tween.tween_property(shade, "color:a", 0.8, fade_duration)
	await tween.finished
	if not visible:
		return
	is_active = true
	countdown_started = true
	var content_tween := create_tween()
	content_tween.tween_property(content, "modulate:a", 1.0, 0.2)

func hide_overlay_immediate() -> void:
	visible = false
	is_active = false
	countdown_started = false
	countdown_resolved = false
	selected_index = OPTION_REVIVE
	countdown_remaining = countdown_duration
	_update_selection()
	if content != null:
		content.modulate.a = 0.0
	if shade != null:
		shade.color = Color(0.0, 0.0, 0.0, 0.2)

func move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, OPTION_REVIVE, OPTION_GIVE_UP + 1)
	_update_selection()

func select_option(index: int) -> void:
	if not is_active:
		return
	selected_index = clampi(index, OPTION_REVIVE, OPTION_GIVE_UP)
	_update_selection()

func confirm_option(index: int) -> void:
	select_option(index)
	if is_active:
		confirm_selection()

func confirm_selection() -> void:
	if not is_active or countdown_resolved:
		return
	countdown_resolved = true
	_play_button_click_sfx()
	if selected_index == OPTION_REVIVE:
		revive_requested.emit()
	else:
		give_up_requested.emit()

func _build_ui() -> void:
	shade = ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var content_root := Control.new()
	content_root.name = "Content"
	content_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content_root)
	content = content_root

	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.position = Vector2(-180.0, -220.0)
	box.size = Vector2(360.0, 420.0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 22)
	content_root.add_child(box)

	var countdown_group := Control.new()
	countdown_group.name = "CountdownGroup"
	countdown_group.custom_minimum_size = Vector2(220.0, 220.0)
	countdown_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(countdown_group)

	var ring := CountdownRingControl.new()
	ring.name = "CountdownRing"
	ring.set_anchors_preset(Control.PRESET_CENTER)
	ring.position = Vector2(-82.0, -82.0)
	ring.size = Vector2(164.0, 164.0)
	countdown_group.add_child(ring)

	countdown_label = Label.new()
	countdown_label.name = "CountdownLabel"
	countdown_label.set_anchors_preset(Control.PRESET_CENTER)
	countdown_label.position = Vector2(-50.0, -40.0)
	countdown_label.size = Vector2(100.0, 80.0)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 52)
	countdown_label.add_theme_color_override("font_color", Color(0.96, 0.97, 0.99, 1.0))
	countdown_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	countdown_label.add_theme_constant_override("shadow_offset_x", 3)
	countdown_label.add_theme_constant_override("shadow_offset_y", 4)
	countdown_group.add_child(countdown_label)

	options = VBoxContainer.new()
	options.name = "Options"
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 16)
	box.add_child(options)

	revive_label = _make_option_label("ReviveLabel", "復活")
	give_up_label = _make_option_label("GiveUpLabel", "放棄")
	options.add_child(revive_label)
	options.add_child(give_up_label)

func _make_option_label(node_name: String, text_value: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.custom_minimum_size = Vector2(280.0, 42.0)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	var option_index := OPTION_REVIVE if node_name == "ReviveLabel" else OPTION_GIVE_UP
	label.mouse_entered.connect(select_option.bind(option_index))
	label.gui_input.connect(_on_option_gui_input.bind(option_index))
	return label

func _on_option_gui_input(event: InputEvent, option_index: int) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		confirm_option(option_index)
		_mark_input_handled()

func _setup_button_click_sfx() -> void:
	button_click_sfx = get_node_or_null("ButtonClickSfx") as AudioStreamPlayer
	if button_click_sfx == null:
		button_click_sfx = AudioStreamPlayer.new()
		button_click_sfx.name = "ButtonClickSfx"
		add_child(button_click_sfx)
	button_click_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(BUTTON_CLICK_SFX_PATH):
		button_click_sfx.stream = load(BUTTON_CLICK_SFX_PATH)

func _play_button_click_sfx() -> void:
	if button_click_sfx != null and button_click_sfx.stream != null and button_click_sfx.is_inside_tree():
		button_click_sfx.play()

func _mark_input_handled() -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()

func _update_countdown_label() -> void:
	if countdown_label == null:
		return
	if countdown_duration <= 0.0:
		countdown_label.text = "0"
		return
	var scaled_seconds := int(ceili(max(countdown_remaining, 0.0) / countdown_duration * float(display_countdown_seconds)))
	countdown_label.text = str(clampi(scaled_seconds, 0, display_countdown_seconds))

func _update_selection() -> void:
	if revive_label == null or give_up_label == null:
		return
	_apply_option_style(revive_label, "復活", selected_index == OPTION_REVIVE)
	_apply_option_style(give_up_label, "放棄", selected_index == OPTION_GIVE_UP)

func _apply_option_style(label: Label, base_text: String, selected: bool) -> void:
	label.text = "> %s <" % base_text if selected else base_text
	var color := Color(1.0, 0.86, 0.36, 1.0) if selected else Color(0.76, 0.78, 0.82, 1.0)
	label.add_theme_color_override("font_color", color)
