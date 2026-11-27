@tool
extends EditorPlugin

## Exposes the GDQuest GDScript Formatter's format action as a Godot
## editor shortcut so GodotVim can call it from a mapping.

const SHORTCUT_PATH := "godotvim/gdscript_format"
const FORMATTER_PATH_SETTING := "gdquest_gdscript_formatter/formatter_path"

var _shortcut: Shortcut


func _enter_tree() -> void:
	_register_shortcut()
	call_deferred("_ensure_formatter_path")


func _exit_tree() -> void:
	var settings := EditorInterface.get_editor_settings()
	if settings != null:
		settings.remove_shortcut(SHORTCUT_PATH)


func _shortcut_input(event: InputEvent) -> void:
	if event is InputEventShortcut and _shortcut != null and event.shortcut == _shortcut:
		_format_current_script()
		get_viewport().set_input_as_handled()


func _register_shortcut() -> void:
	var settings := EditorInterface.get_editor_settings()
	if settings == null:
		return

	_shortcut = Shortcut.new()
	var event := InputEventKey.new()
	event.keycode = KEY_I
	event.ctrl_pressed = true
	event.alt_pressed = true
	event.pressed = true
	_shortcut.events = [event]

	settings.add_shortcut(SHORTCUT_PATH, _shortcut)


func _ensure_formatter_path() -> void:
	var settings := EditorInterface.get_editor_settings()
	if settings == null:
		return

	var current = settings.get_setting(FORMATTER_PATH_SETTING)
	if current != null and not String(current).is_empty():
		return

	var binary_path := EditorInterface.get_editor_paths().get_cache_dir()
	binary_path = binary_path.path_join("gdquest").path_join("gdscript-formatter")
	if FileAccess.file_exists(binary_path):
		settings.set_setting(FORMATTER_PATH_SETTING, binary_path)


func _format_current_script() -> void:
	var formatter := _find_formatter(get_tree().root)
	if formatter == null:
		push_warning("GodotVim Formatter Bridge: GDQuest GDScript Formatter is not enabled.")
		return

	if not formatter.call("format_current_script"):
		push_warning("GodotVim Formatter Bridge: could not format the current script.")


func _find_formatter(node: Node) -> Node:
	if node.has_method("format_current_script"):
		return node

	for child in node.get_children():
		var found := _find_formatter(child)
		if found != null:
			return found

	return null
