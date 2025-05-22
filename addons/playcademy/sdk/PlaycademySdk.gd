extends Node

# Main SDK Signals
signal sdk_ready
signal sdk_initialization_failed(error_message)

var playcademy_client: JavaScriptObject = null
var is_sdk_initialized := false

# --- Public Sub-APIs ---
var users: UsersAPI
var runtime: RuntimeAPI
var inventory: InventoryAPI

# --- Main PlaycademySDK Methods ---
func _ready():
	print("[PlaycademySDK.gd] SDK Node Initializing...")

	if not OS.has_feature("web"):
		print("[PlaycademySDK.gd] Not a web build. SDK will not function.")
		emit_signal("sdk_initialization_failed", "NOT_WEB_BUILD")
		return

	var js_window = JavaScriptBridge.get_interface("window")
	if js_window == null:
		print("[PlaycademySDK.gd] Failed to get JS window object.")
		emit_signal("sdk_initialization_failed", "NO_JS_WINDOW")
		return

	var sdk_init_cb = Callable(self, "_on_sdk_initialized_from_js").bind()
	js_window.godotPlaycademySDKInitializedCallback = JavaScriptBridge.create_callback(sdk_init_cb)
	print("[PlaycademySDK.gd] JS callback 'godotPlaycademySDKInitializedCallback' registered.")

	var sdk_fail_cb = Callable(self, "_on_sdk_initialization_failed_from_js").bind()
	js_window.godotPlaycademySDKInitializationFailedCallback = JavaScriptBridge.create_callback(sdk_fail_cb)
	print("[PlaycademySDK.gd] JS failure callback 'godotPlaycademySDKInitializationFailedCallback' registered.")
	
	var js_sdk_ready_flag = js_window.isPlaycademyReady
	if js_sdk_ready_flag == true:
		var client_from_js_direct = js_window.playcademyClient
		if client_from_js_direct is JavaScriptObject:
			_on_sdk_initialized_from_js([client_from_js_direct])
		else:
			_on_sdk_initialization_failed_from_js(["Playcademy is ready but client is invalid (direct check)"])
	else:
		print("[PlaycademySDK.gd] SDK not yet ready. Waiting for JS callback.")


func _on_sdk_initialized_from_js(args_array: Array):
	if is_sdk_initialized:
		return

	if args_array.size() > 0 and args_array[0] is JavaScriptObject:
		playcademy_client = args_array[0]
		is_sdk_initialized = true
		
		users = UsersAPI.new(playcademy_client)
		if users == null:
			printerr("[PlaycademySDK.gd] CRITICAL: UsersAPI failed to instantiate!")
			_on_sdk_initialization_failed_from_js(["UsersAPI_INSTANTIATION_FAILED"])
			return

		runtime = RuntimeAPI.new(playcademy_client)
		if runtime == null:
			printerr("[PlaycademySDK.gd] CRITICAL: RuntimeAPI failed to instantiate!")
			_on_sdk_initialization_failed_from_js(["RuntimeAPI_INSTANTIATION_FAILED"])
			return

		inventory = InventoryAPI.new(playcademy_client)
		if inventory == null:
			printerr("[PlaycademySDK.gd] CRITICAL: InventoryAPI failed to instantiate!")
			_on_sdk_initialization_failed_from_js(["InventoryAPI_INSTANTIATION_FAILED"])
			return

		print("[PlaycademySDK.gd] Main Client assigned. Sub-APIs (Users, Runtime, Inventory) instantiated.")
		emit_signal("sdk_ready")
		test_sdk_ping()
	else:
		var error_msg = "SDK init callback: Invalid or no client argument."
		if args_array.size() > 0:
			error_msg = "SDK init callback: Argument was not a JavaScriptObject. Type: %s" % typeof(args_array[0])
		else:
			error_msg = "SDK init callback: No arguments received from JS."
		print("[PlaycademySDK.gd] ERROR: %s" % error_msg)
		_on_sdk_initialization_failed_from_js([error_msg])


func _on_sdk_initialization_failed_from_js(args_array: Array):
	if is_sdk_initialized: return 

	var error_message = "SDK_INIT_FAILED_UNKNOWN"
	if args_array.size() > 0:
		error_message = str(args_array[0])
	print("[PlaycademySDK.gd] SDK Initialization FAILED. Error: ", error_message)
	emit_signal("sdk_initialization_failed", error_message)
	_cleanup_js_callbacks()


func is_ready() -> bool:
	return is_sdk_initialized

func get_client_js_object() -> JavaScriptObject:
	if not is_ready():
		printerr("[PlaycademySDK] SDK not ready. Cannot get client JSObject.")
	return playcademy_client

func ping() -> String:
	if not is_ready() or playcademy_client == null:
		printerr("[PlaycademySDK] Cannot ping: SDK not ready or client null.")
		return "ERROR: SDK_NOT_READY"
	
	print("[PlaycademySDK] GDScript wrapper calling client.ping()...")
	var result = playcademy_client.ping()
	print("[PlaycademySDK] Ping direct result from JS: ", result)
	return str(result)

func test_sdk_ping():
	if not is_ready() or playcademy_client == null:
		print("[PlaycademySDK] test_sdk_ping (auto): SDK not ready or client null.")
		return
	var ping_result = ping()
	print("[PlaycademySDK] Auto-Ping result (via wrapper): ", ping_result)


func _cleanup_js_callbacks():
	print("[PlaycademySDK.gd] Cleaning up JS callbacks from window object...")
	var js_window = JavaScriptBridge.get_interface("window")
	if js_window != null:
		if 'godotPlaycademySDKInitializedCallback' in js_window:
			js_window.godotPlaycademySDKInitializedCallback = null
		if 'godotPlaycademySDKInitializationFailedCallback' in js_window:
			js_window.godotPlaycademySDKInitializationFailedCallback = null

func _exit_tree():
	_cleanup_js_callbacks()

# Example callback function if needed later
# func _on_js_event(args_array):
# 	 print("[PlaycademySDK.gd] Received event from JS: ", args_array) 
