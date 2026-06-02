extends CanvasLayer

signal retry_requested
signal main_menu_requested

const OPTION_RETRY := 0
const OPTION_MAIN_MENU := 1
const TITLE_TEXT := "心音斷絕"
const RETRY_TEXT := "重新挑戰"
const MAIN_MENU_TEXT := "返回主選單"

var selected_index := OPTION_RETRY
var is_active := false

var shade: ColorRect
var title_label: Label
var retry_label: Label
var main_menu_label: Label
var box: VBoxContainer
var options: HBoxContainer

func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	hide_overlay_immediate()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_UP, KEY_W:
			move_selection(-1)
			get_viewport().set_input_as_handled()
		KEY_DOWN, KEY_S:
			move_selection(1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			confirm_selection()
			get_viewport().set_input_as_handled()

func show_death() -> void:
	visible = true
	is_active = true
	selected_index = OPTION_RETRY
	_update_selection()
	if title_label != null:
		title_label.modulate.a = 0.0
	if options != null:
		options.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(options, "modulate:a", 1.0, 0.35).set_delay(0.08)

func hide_overlay_immediate() -> void:
	visible = false
	is_active = false
	selected_index = OPTION_RETRY
	_update_selection()

func move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, OPTION_RETRY, OPTION_MAIN_MENU + 1)
	_update_selection()

func confirm_selection() -> void:
	if selected_index == OPTION_RETRY:
		retry_requested.emit()
	else:
		main_menu_requested.emit()

func _build_ui() -> void:
	shade = ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.02, 0.02, 0.025, 0.84)
	add_child(shade)

	var content := CenterContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	box = VBoxContainer.new()
	box.name = "Box"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 34)
	content.add_child(box)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = TITLE_TEXT
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 76)
	title_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(title_label)

	options = HBoxContainer.new()
	options.name = "Options"
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 60)
	box.add_child(options)

	retry_label = _make_option_label("RetryLabel", RETRY_TEXT)
	main_menu_label = _make_option_label("MainMenuLabel", MAIN_MENU_TEXT)
	options.add_child(retry_label)
	options.add_child(main_menu_label)

func _make_option_label(node_name: String, text_value: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	return label

func _update_selection() -> void:
	if retry_label == null or main_menu_label == null:
		return
	_apply_option_style(retry_label, RETRY_TEXT, selected_index == OPTION_RETRY)
	_apply_option_style(main_menu_label, MAIN_MENU_TEXT, selected_index == OPTION_MAIN_MENU)

func _apply_option_style(label: Label, base_text: String, selected: bool) -> void:
	label.text = "> %s <" % base_text if selected else base_text
	var color := Color(1.0, 0.86, 0.36, 1.0) if selected else Color(0.72, 0.74, 0.78, 1.0)
	label.add_theme_color_override("font_color", color)
