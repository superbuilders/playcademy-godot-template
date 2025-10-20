@tool
extends Control
class_name PlaycademyBackendDock

var backend_manager: PlaycademyBackendManager

# UI Elements
var sandbox_status_label: Label
var backend_status_label: Label
var sandbox_url_label: Label
var backend_url_label: Label
var start_button: Button
var stop_button: Button
var restart_button: Button
var auto_start_checkbox: CheckBox

func _init():
	name = "Playcademy"

func setup_with_manager(manager: PlaycademyBackendManager):
	backend_manager = manager
	_create_ui()
	_connect_signals()
	_update_ui()

func _create_ui():
	# Main container with margins
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Dev Servers"
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)
	
	vbox.add_child(HSeparator.new())
	
	# Sandbox section with inline status
	var sandbox_hbox = HBoxContainer.new()
	sandbox_hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	vbox.add_child(sandbox_hbox)
	
	var sandbox_title = Label.new()
	sandbox_title.text = "Sandbox:"
	sandbox_title.add_theme_font_size_override("font_size", 12)
	sandbox_hbox.add_child(sandbox_title)
	
	sandbox_status_label = Label.new()
	sandbox_status_label.text = "Stopped"
	sandbox_status_label.add_theme_color_override("font_color", Color.GRAY)
	sandbox_hbox.add_child(sandbox_status_label)
	
	sandbox_url_label = Label.new()
	sandbox_url_label.text = ""
	sandbox_url_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	sandbox_url_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sandbox_url_label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	vbox.add_child(sandbox_url_label)
	
	# Backend section with inline status
	var backend_hbox = HBoxContainer.new()
	backend_hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	vbox.add_child(backend_hbox)
	
	var backend_title = Label.new()
	backend_title.text = "Backend:"
	backend_title.add_theme_font_size_override("font_size", 12)
	backend_hbox.add_child(backend_title)
	
	backend_status_label = Label.new()
	backend_status_label.text = "Stopped"
	backend_status_label.add_theme_color_override("font_color", Color.GRAY)
	backend_hbox.add_child(backend_status_label)
	
	backend_url_label = Label.new()
	backend_url_label.text = ""
	backend_url_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	backend_url_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	backend_url_label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	vbox.add_child(backend_url_label)
	
	vbox.add_child(HSeparator.new())
	
	# Buttons
	start_button = Button.new()
	start_button.text = "Start Servers"
	start_button.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)
	
	stop_button = Button.new()
	stop_button.text = "Stop Servers"
	stop_button.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	stop_button.pressed.connect(_on_stop_pressed)
	vbox.add_child(stop_button)
	
	restart_button = Button.new()
	restart_button.text = "Restart Servers"
	restart_button.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	restart_button.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_button)
	
	vbox.add_child(HSeparator.new())
	
	# Settings
	auto_start_checkbox = CheckBox.new()
	auto_start_checkbox.text = "Auto-start on project open"
	auto_start_checkbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	auto_start_checkbox.toggled.connect(_on_auto_start_toggled)
	vbox.add_child(auto_start_checkbox)
	
	# Spacer to push everything to top
	var spacer = Control.new()
	spacer.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	vbox.add_child(spacer)

func _connect_signals():
	if backend_manager:
		backend_manager.status_changed.connect(_on_status_changed)
		backend_manager.sandbox_started.connect(_on_sandbox_started)
		backend_manager.backend_started.connect(_on_backend_started)
		backend_manager.servers_stopped.connect(_on_servers_stopped)
		backend_manager.server_failed.connect(_on_server_failed)

func _update_ui():
	if not backend_manager:
		return
	
	var sandbox_status = backend_manager.get_sandbox_status()
	var backend_status = backend_manager.get_backend_status()
	
	# Update sandbox status with color
	if sandbox_status == PlaycademyBackendManager.ServerStatus.RUNNING:
		sandbox_status_label.text = "Running"
		sandbox_status_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	elif sandbox_status == PlaycademyBackendManager.ServerStatus.STARTING:
		sandbox_status_label.text = "Starting..."
		sandbox_status_label.add_theme_color_override("font_color", Color.LIGHT_YELLOW)
	elif sandbox_status == PlaycademyBackendManager.ServerStatus.ERROR:
		sandbox_status_label.text = "Error"
		sandbox_status_label.add_theme_color_override("font_color", Color.ORANGE)
	elif sandbox_status == PlaycademyBackendManager.ServerStatus.STOPPING:
		sandbox_status_label.text = "Stopping..."
		sandbox_status_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		sandbox_status_label.text = "Stopped"
		sandbox_status_label.add_theme_color_override("font_color", Color.GRAY)
	
	# Update backend status with color
	if backend_status == PlaycademyBackendManager.ServerStatus.RUNNING:
		backend_status_label.text = "Running"
		backend_status_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	elif backend_status == PlaycademyBackendManager.ServerStatus.STARTING:
		backend_status_label.text = "Starting..."
		backend_status_label.add_theme_color_override("font_color", Color.LIGHT_YELLOW)
	elif backend_status == PlaycademyBackendManager.ServerStatus.ERROR:
		backend_status_label.text = "Error"
		backend_status_label.add_theme_color_override("font_color", Color.ORANGE)
	elif backend_status == PlaycademyBackendManager.ServerStatus.STOPPING:
		backend_status_label.text = "Stopping..."
		backend_status_label.add_theme_color_override("font_color", Color.GRAY)
	else:
		backend_status_label.text = "Stopped"
		backend_status_label.add_theme_color_override("font_color", Color.GRAY)
	
	# Update URLs
	var sandbox_url = backend_manager.get_sandbox_url()
	if sandbox_url.is_empty():
		sandbox_url_label.text = "Not running"
		sandbox_url_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	else:
		sandbox_url_label.text = sandbox_url
		sandbox_url_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	
	var backend_url = backend_manager.get_backend_url()
	if backend_url.is_empty():
		backend_url_label.text = "Not running"
		backend_url_label.add_theme_color_override("font_color", Color.DIM_GRAY)
	else:
		backend_url_label.text = backend_url
		backend_url_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)
	
	# Update buttons
	var any_running = sandbox_status == PlaycademyBackendManager.ServerStatus.RUNNING or backend_status == PlaycademyBackendManager.ServerStatus.RUNNING
	var any_starting = sandbox_status == PlaycademyBackendManager.ServerStatus.STARTING or backend_status == PlaycademyBackendManager.ServerStatus.STARTING
	var any_stopping = sandbox_status == PlaycademyBackendManager.ServerStatus.STOPPING or backend_status == PlaycademyBackendManager.ServerStatus.STOPPING
	
	start_button.disabled = any_running or any_starting
	stop_button.disabled = not any_running and not any_starting
	restart_button.disabled = any_starting or any_stopping
	
	auto_start_checkbox.button_pressed = backend_manager.is_auto_start_enabled()

func _on_start_pressed():
	if backend_manager:
		backend_manager.start_servers()

func _on_stop_pressed():
	if backend_manager:
		backend_manager.stop_servers()

func _on_restart_pressed():
	if backend_manager:
		backend_manager.restart_servers()

func _on_auto_start_toggled(pressed: bool):
	ProjectSettings.set_setting("playcademy/backend/auto_start", pressed)
	ProjectSettings.save()

func _on_status_changed(status_string: String):
	_update_ui()

func _on_sandbox_started(url: String):
	_update_ui()

func _on_backend_started(url: String):
	_update_ui()

func _on_servers_stopped():
	_update_ui()

func _on_server_failed(server_type: String, error: String):
	_update_ui()
