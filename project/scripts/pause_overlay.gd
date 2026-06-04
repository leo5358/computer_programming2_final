extends CanvasLayer

signal resume_requested
signal save_and_menu_requested

const OPTION_RESUME := 0
const OPTION_SAVE_MENU := 1
const BUTTON_CLICK_SFX_PATH := "res://assets/sfx/buttonClick.MP3"
const TITLE_TEXT := "暫停"
const RESUME_TEXT := "繼續遊戲"
const SAVE_MENU_TEXT := "存檔並返回主頁"

var selected_index := OPTION_RESUME
var is_active := false

var shade: ColorRect
var title_label: Label
var resume_label: Label
var save_menu_label: Label
var box: VBoxContainer
var options: VBoxContainer
var button_click_sfx: AudioStreamPlayer

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_setup_button_click_sfx()
	hide_pause()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_ESCAPE:
			_play_button_click_sfx()
			resume_requested.emit()
			get_viewport().set_input_as_handled()
		KEY_UP, KEY_W:
			move_selection(-1)
			get_viewport().set_input_as_handled()
		KEY_DOWN, KEY_S:
			move_selection(1)
			get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			confirm_selection()
			get_viewport().set_input_as_handled()

func show_pause() -> void:
	visible = true
	is_active = true
	selected_index = OPTION_RESUME
	_update_selection()

func hide_pause() -> void:
	visible = false
	is_active = false
	selected_index = OPTION_RESUME
	_update_selection()

func move_selection(direction: int) -> void:
	selected_index = wrapi(selected_index + direction, OPTION_RESUME, OPTION_SAVE_MENU + 1)
	_update_selection()

func select_option(index: int) -> void:
	if not is_active:
		return
	selected_index = clampi(index, OPTION_RESUME, OPTION_SAVE_MENU)
	_update_selection()

func confirm_option(index: int) -> void:
	select_option(index)
	if is_active:
		confirm_selection()

func confirm_selection() -> void:
	_play_button_click_sfx()
	if selected_index == OPTION_RESUME:
		resume_requested.emit()
	else:
		save_and_menu_requested.emit()

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
	if button_click_sfx != null and button_click_sfx.stream != null:
		button_click_sfx.play()

func _build_ui() -> void:
	shade = ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.color = Color(0.01, 0.01, 0.012, 0.68)
	add_child(shade)

	var content := CenterContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	box = VBoxContainer.new()
	box.name = "Box"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	content.add_child(box)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = TITLE_TEXT
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.94, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	box.add_child(title_label)

	options = VBoxContainer.new()
	options.name = "Options"
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 14)
	box.add_child(options)

	resume_label = _make_option_label("ResumeLabel", RESUME_TEXT)
	save_menu_label = _make_option_label("SaveMenuLabel", SAVE_MENU_TEXT)
	options.add_child(resume_label)
	options.add_child(save_menu_label)

func _make_option_label(node_name: String, text_value: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.custom_minimum_size = Vector2(360, 42)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	var option_index := OPTION_RESUME if node_name == "ResumeLabel" else OPTION_SAVE_MENU
	label.mouse_entered.connect(select_option.bind(option_index))
	label.gui_input.connect(_on_option_gui_input.bind(option_index))
	return label

func _on_option_gui_input(event: InputEvent, option_index: int) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		confirm_option(option_index)
		get_viewport().set_input_as_handled()

func _update_selection() -> void:
	if resume_label == null or save_menu_label == null:
		return
	_apply_option_style(resume_label, RESUME_TEXT, selected_index == OPTION_RESUME)
	_apply_option_style(save_menu_label, SAVE_MENU_TEXT, selected_index == OPTION_SAVE_MENU)

func _apply_option_style(label: Label, base_text: String, selected: bool) -> void:
	label.text = "> %s <" % base_text if selected else base_text
	var color := Color(1.0, 0.86, 0.36, 1.0) if selected else Color(0.75, 0.77, 0.80, 1.0)
	label.add_theme_color_override("font_color", color)
