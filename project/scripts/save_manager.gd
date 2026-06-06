extends Node

const SAVE_PATH := "user://savegame.json"

var current_save_data := {}

func _ready() -> void:
	load_game()

func save_game(map_id: String, position: Vector2, health: float = 120.0) -> void:
	current_save_data = {
		"map_id": map_id,
		"pos_x": position.x,
		"pos_y": position.y,
		"health": health,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		var json_string := JSON.stringify(current_save_data)
		file.store_string(json_string)
		file.close()
		print("Game saved to: ", map_id, " at ", position)
	else:
		push_error("Failed to open save file for writing: ", SAVE_PATH)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
		
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading: ", SAVE_PATH)
		return false
		
	var json_string := file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		current_save_data = json.data
		return true
	else:
		push_error("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
		return false

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_saved_map() -> String:
	return current_save_data.get("map_id", "ab_foothill")

func get_saved_position() -> Vector2:
	return Vector2(
		current_save_data.get("pos_x", 430.0),
		current_save_data.get("pos_y", 408.0)
	)

func get_saved_health() -> float:
	return current_save_data.get("health", 120.0)

func delete_save() -> void:
	current_save_data = {}
	if FileAccess.file_exists(SAVE_PATH):
		var user_dir := DirAccess.open("user://")
		if user_dir != null:
			user_dir.remove("savegame.json")
