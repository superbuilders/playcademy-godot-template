@tool
extends Node
class_name PlaycademyBackendManager

signal sandbox_started(url: String)
signal backend_started(url: String)
signal servers_stopped()
signal server_failed(server_type: String, error: String)
signal status_changed(status: String)

enum ServerStatus {
	STOPPED,
	STARTING,
	RUNNING,
	STOPPING,
	ERROR
}

var sandbox_status: ServerStatus = ServerStatus.STOPPED
var backend_status: ServerStatus = ServerStatus.STOPPED
var sandbox_url: String = ""
var backend_url: String = ""
var sandbox_port: int = 4321
var backend_port: int = 8788
var sandbox_process: int = -1
var backend_process: int = -1

# Project settings keys
const SETTING_AUTO_START = "playcademy/backend/auto_start"
const SETTING_SANDBOX_PORT = "playcademy/backend/sandbox_port"
const SETTING_BACKEND_PORT = "playcademy/backend/backend_port"
const SETTING_VERBOSE = "playcademy/backend/verbose"

func _ready():
	_ensure_project_settings()

func _ensure_project_settings():
	if not ProjectSettings.has_setting(SETTING_AUTO_START):
		ProjectSettings.set_setting(SETTING_AUTO_START, true)
	
	if not ProjectSettings.has_setting(SETTING_SANDBOX_PORT):
		ProjectSettings.set_setting(SETTING_SANDBOX_PORT, 4321)
	
	if not ProjectSettings.has_setting(SETTING_BACKEND_PORT):
		ProjectSettings.set_setting(SETTING_BACKEND_PORT, 8788)
	
	if not ProjectSettings.has_setting(SETTING_VERBOSE):
		ProjectSettings.set_setting(SETTING_VERBOSE, false)
	
	ProjectSettings.save()

func is_auto_start_enabled() -> bool:
	return ProjectSettings.get_setting(SETTING_AUTO_START, true)

func get_sandbox_port() -> int:
	return ProjectSettings.get_setting(SETTING_SANDBOX_PORT, 4321)

func get_backend_port() -> int:
	return ProjectSettings.get_setting(SETTING_BACKEND_PORT, 8788)

func is_verbose_enabled() -> bool:
	return ProjectSettings.get_setting(SETTING_VERBOSE, false)

func auto_start_if_enabled():
	if is_auto_start_enabled():
		start_servers(true)  # Silent mode - don't show errors on auto-start failure

func ensure_servers_running():
	if sandbox_status != ServerStatus.RUNNING:
		start_servers(false)

func start_servers(silent: bool = false):
	start_sandbox(silent)
	
	# Check if playcademy.config.js or .json exists
	if _has_backend_config():
		start_backend(silent)

func _has_backend_config() -> bool:
	var project_root = ProjectSettings.globalize_path("res://")
	var config_js = project_root + "/playcademy.config.js"
	var config_json = project_root + "/playcademy.config.json"
	return FileAccess.file_exists(config_js) or FileAccess.file_exists(config_json)

func start_sandbox(silent: bool = false):
	if sandbox_status == ServerStatus.RUNNING or sandbox_status == ServerStatus.STARTING:
		return
	
	var port = get_sandbox_port()
	var verbose = is_verbose_enabled()
	
	var runtime_info = _find_js_runtime()
	if runtime_info.is_empty():
		if not silent:
			_handle_error("sandbox", "Neither npm nor bun found. Please install Node.js (npm) or Bun:\n• npm: https://nodejs.org\n• bun: curl -fsSL https://bun.sh/install | bash")
		return
	
	var runtime_path = runtime_info["path"]
	var runtime_type = runtime_info["type"]
	
	sandbox_status = ServerStatus.STARTING
	emit_signal("status_changed", get_status_string())
	
	var args = []
	if runtime_type == "npm":
		args = ["npx", "--yes", "@playcademy/sandbox", "--port", str(port)]
	else:
		args = ["x", "@playcademy/sandbox", "--port", str(port)]
	
	if verbose:
		args.append("--verbose")
	
	var project_name = ProjectSettings.get_setting("application/config/name", "godot-game")
	var project_slug = project_name.to_lower().replace(" ", "-")
	args.append_array(["--project-name", project_name])
	args.append_array(["--project-slug", project_slug])
	
	sandbox_process = OS.create_process(runtime_path, args)
	
	if sandbox_process == -1:
		sandbox_status = ServerStatus.STOPPED
		if not silent:
			var install_cmd = "npm install -g @playcademy/sandbox" if runtime_type == "npm" else "bun add -g @playcademy/sandbox"
			_handle_error("sandbox", "Failed to start sandbox. Try: " + install_cmd)
		return
	
	var command = "%s %s" % [runtime_type, "@playcademy/sandbox --port " + str(port)]
	print("[PlaycademyBackend] Starting sandbox (PID %d): %s" % [sandbox_process, command])
	
	# Start checking registry (retry for 5 seconds)
	_check_server_registry("sandbox", 0, silent)

func start_backend(silent: bool = false):
	if backend_status == ServerStatus.RUNNING or backend_status == ServerStatus.STARTING:
		return
	
	var port = get_backend_port()
	var verbose = is_verbose_enabled()
	
	var runtime_info = _find_js_runtime()
	if runtime_info.is_empty():
		if not silent:
			_handle_error("backend", "Neither npm nor bun found")
		return
	
	var runtime_path = runtime_info["path"]
	var runtime_type = runtime_info["type"]
	
	backend_status = ServerStatus.STARTING
	emit_signal("status_changed", get_status_string())
	
	var args = []
	if runtime_type == "npm":
		args = ["npx", "--yes", "playcademy", "dev", "--port", str(port)]
	else:
		args = ["x", "playcademy", "dev", "--port", str(port)]
	
	if verbose:
		args.append("--verbose")
	
	backend_process = OS.create_process(runtime_path, args)
	
	if backend_process == -1:
		backend_status = ServerStatus.STOPPED
		if not silent:
			_handle_error("backend", "Failed to start backend server")
		return
	
	var command = "%s %s" % [runtime_type, "playcademy dev --port " + str(port)]
	print("[PlaycademyBackend] Starting backend (PID %d): %s" % [backend_process, command])
	
	# Start checking registry
	_check_server_registry("backend", 0, silent)

func stop_servers():
	stop_sandbox()
	stop_backend()

func stop_sandbox():
	if sandbox_status == ServerStatus.STOPPED or sandbox_status == ServerStatus.STOPPING:
		return
	
	sandbox_status = ServerStatus.STOPPING
	emit_signal("status_changed", get_status_string())
	
	var pid_to_cleanup = sandbox_process
	
	if sandbox_process != -1:
		# Try to send SIGINT for graceful shutdown (Unix only)
		if OS.get_name() != "Windows":
			var output = []
			OS.execute("kill", ["-2", str(sandbox_process)], output)
			# Wait briefly for cleanup handler to run
			await get_tree().create_timer(0.2).timeout
		
		# Kill process if still alive (or on Windows)
		OS.kill(sandbox_process)
		sandbox_process = -1
	
	# Manually clean up registry (in case cleanup handler didn't run)
	if pid_to_cleanup != -1:
		_cleanup_registry_entry_by_pid("sandbox", pid_to_cleanup)
	
	sandbox_url = ""
	sandbox_status = ServerStatus.STOPPED
	emit_signal("status_changed", get_status_string())

func stop_backend():
	if backend_status == ServerStatus.STOPPED or backend_status == ServerStatus.STOPPING:
		return
	
	backend_status = ServerStatus.STOPPING
	emit_signal("status_changed", get_status_string())
	
	var pid_to_cleanup = backend_process
	
	if backend_process != -1:
		# Try to send SIGINT for graceful shutdown (Unix only)
		if OS.get_name() != "Windows":
			var output = []
			OS.execute("kill", ["-2", str(backend_process)], output)
			# Wait briefly for cleanup handler to run
			await get_tree().create_timer(0.2).timeout
		
		# Kill process if still alive (or on Windows)
		OS.kill(backend_process)
		backend_process = -1
	
	# Manually clean up registry (in case cleanup handler didn't run)
	if pid_to_cleanup != -1:
		_cleanup_registry_entry_by_pid("backend", pid_to_cleanup)
	
	backend_url = ""
	backend_status = ServerStatus.STOPPED
	emit_signal("status_changed", get_status_string())

func restart_servers():
	stop_servers()
	await get_tree().create_timer(1.0).timeout
	start_servers()

func get_sandbox_status() -> ServerStatus:
	return sandbox_status

func get_backend_status() -> ServerStatus:
	return backend_status

func get_status_string() -> String:
	var parts = []
	
	# Only show non-stopped statuses
	if sandbox_status == ServerStatus.RUNNING:
		parts.append("Sandbox: Running")
	elif sandbox_status == ServerStatus.STARTING:
		parts.append("Sandbox: Starting...")
	elif sandbox_status == ServerStatus.ERROR:
		parts.append("Sandbox: Error")
	elif sandbox_status == ServerStatus.STOPPING:
		parts.append("Sandbox: Stopping...")
	
	if backend_status == ServerStatus.RUNNING:
		parts.append("Backend: Running")
	elif backend_status == ServerStatus.STARTING:
		parts.append("Backend: Starting...")
	elif backend_status == ServerStatus.ERROR:
		parts.append("Backend: Error")
	elif backend_status == ServerStatus.STOPPING:
		parts.append("Backend: Stopping...")
	
	if parts.is_empty():
		return "Stopped"
	
	return " | ".join(parts)

func get_sandbox_url() -> String:
	return sandbox_url

func get_backend_url() -> String:
	return backend_url

func _handle_error(server_type: String, error_message: String):
	print("[PlaycademyBackend] %s error: %s" % [server_type, error_message])
	
	if server_type == "sandbox":
		sandbox_status = ServerStatus.ERROR
	else:
		backend_status = ServerStatus.ERROR
	
	emit_signal("server_failed", server_type, error_message)
	emit_signal("status_changed", get_status_string())

# Check server registry with retry logic (retry every 500ms for 5 seconds = 10 attempts)
var _retry_counts = {"sandbox": 0, "backend": 0}
const MAX_RETRIES = 10
const RETRY_INTERVAL = 0.5

func _check_server_registry(server_type: String, attempt: int, silent: bool = false):
	if attempt >= MAX_RETRIES:
		if server_type == "sandbox":
			sandbox_status = ServerStatus.STOPPED
		else:
			backend_status = ServerStatus.STOPPED
		
		if not silent:
			_handle_error(server_type, "Server not found in registry after 5 seconds")
		emit_signal("status_changed", get_status_string())
		return
	
	var home = OS.get_environment("HOME")
	var registry_path = home + "/.playcademy/.proc"
	var file = FileAccess.open(registry_path, FileAccess.READ)
	
	if not file:
		# Registry doesn't exist yet, retry silently
		await get_tree().create_timer(RETRY_INTERVAL).timeout
		_check_server_registry(server_type, attempt + 1, silent)
		return
	
	var registry_text = file.get_as_text()
	file.close()
	
	var json_result = JSON.parse_string(registry_text)
	if json_result == null:
		# Failed to parse, retry silently
		await get_tree().create_timer(RETRY_INTERVAL).timeout
		_check_server_registry(server_type, attempt + 1, silent)
		return
	
	var registry = json_result
	var my_project = ProjectSettings.globalize_path("res://").rstrip("/")
	
	# Find server for this project
	for key in registry:
		if key.begins_with(server_type + "-"):
			var server = registry[key]
			if server.projectRoot == my_project:
				if server_type == "sandbox":
					sandbox_port = server.port
					sandbox_url = server.url
					sandbox_status = ServerStatus.RUNNING
					emit_signal("sandbox_started", sandbox_url)
					print("[PlaycademyBackend] ✓ Sandbox: %s" % sandbox_url)
				else:
					backend_port = server.port
					backend_url = server.url
					backend_status = ServerStatus.RUNNING
					emit_signal("backend_started", backend_url)
					print("[PlaycademyBackend] ✓ Backend: %s" % backend_url)
				
				emit_signal("status_changed", get_status_string())
				return
	
	# Not found yet, retry silently
	await get_tree().create_timer(RETRY_INTERVAL).timeout
	_check_server_registry(server_type, attempt + 1, silent)

func _find_js_runtime() -> Dictionary:
	var runtimes = [
		{"type": "bun", "cmd": "bun"},
		{"type": "npm", "cmd": "npm"}
	]
	
	for runtime in runtimes:
		var paths = _get_runtime_paths(runtime.cmd)
		for path in paths:
			if _test_runtime_executable(path):
				return {"type": runtime.type, "path": path}
	
	return {}

func _get_runtime_paths(cmd: String) -> Array:
	var possible_paths = []
	
	if OS.get_name() == "macOS" or OS.get_name() == "Linux":
		var home = OS.get_environment("HOME")
		if cmd == "npm":
			possible_paths.append_array([
				"/usr/local/bin/npm",
				"/opt/homebrew/bin/npm",
				"/usr/bin/npm",
				home + "/.nvm/versions/node/*/bin/npm"
			])
		else:  # bun
			possible_paths.append_array([
				"/usr/local/bin/bun",
				"/opt/homebrew/bin/bun",
				"/usr/bin/bun",
				home + "/.bun/bin/bun"
			])
	elif OS.get_name() == "Windows":
		var username = OS.get_environment("USERNAME")
		if cmd == "npm":
			possible_paths.append_array([
				"C:\\Program Files\\nodejs\\npm.cmd",
				"C:\\Users\\" + username + "\\AppData\\Roaming\\npm\\npm.cmd",
				"npm.cmd"
			])
		else:  # bun
			possible_paths.append_array([
				"C:\\Users\\" + username + "\\.bun\\bin\\bun.exe",
				"bun.exe"
			])
	
	possible_paths.append(cmd)
	return possible_paths

func _test_runtime_executable(path: String) -> bool:
	var output = []
	var exit_code = OS.execute(path, ["--version"], output)
	return exit_code == 0

func _cleanup_registry_entry_by_pid(server_type: String, pid: int):
	"""Manually remove a server from the registry by PID"""
	var home = OS.get_environment("HOME")
	var registry_path = home + "/.playcademy/.proc"
	var file = FileAccess.open(registry_path, FileAccess.READ)
	
	if not file:
		return  # Nothing to clean up
	
	var registry_text = file.get_as_text()
	file.close()
	
	var json_result = JSON.parse_string(registry_text)
	if json_result == null:
		return
	
	var registry = json_result
	var keys_to_remove = []
	
	# Find entries matching this PID
	for key in registry:
		if key.begins_with(server_type + "-"):
			var server = registry[key]
			if server.pid == pid:
				keys_to_remove.append(key)
	
	# Remove entries
	for key in keys_to_remove:
		registry.erase(key)
	
	# Write back
	if keys_to_remove.size() > 0:
		var write_file = FileAccess.open(registry_path, FileAccess.WRITE)
		if write_file:
			write_file.store_string(JSON.stringify(registry, "\t"))
			write_file.close()
			print("[PlaycademyBackend] Cleaned up %d %s entries from registry" % [keys_to_remove.size(), server_type])

func _exit_tree():
	stop_servers()
