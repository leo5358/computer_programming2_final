extends Node

## 全域遊戲設定（AutoLoad 單例）
## 負責難度選項的讀取、儲存與即時通知

signal difficulty_changed(is_easy: bool)

const SETTINGS_PATH := "user://settings.json"

## true = 簡單（顯示攻擊提示），false = 困難（隱藏攻擊提示）
var is_easy_mode := true:
	set(value):
		if is_easy_mode == value:
			return
		is_easy_mode = value
		difficulty_changed.emit(is_easy_mode)
		_save_settings()

func _ready() -> void:
	_load_settings()

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		is_easy_mode = true
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_string) == OK and json.data is Dictionary:
		is_easy_mode = bool(json.data.get("is_easy_mode", true))

func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"is_easy_mode": is_easy_mode}))
	file.close()
