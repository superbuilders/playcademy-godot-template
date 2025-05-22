class_name UsersAPI extends RefCounted

signal profile_received(profile_data)
signal profile_fetch_failed(error_message)

var _main_client: JavaScriptObject
var _resolve_cb_js: JavaScriptObject = null
var _reject_cb_js: JavaScriptObject = null

func _init(client_js_object: JavaScriptObject):
	_main_client = client_js_object
	print("[UsersAPI] Initialized with client.")

func me():
	if _main_client == null:
		printerr("[UsersAPI] Main client not set. Cannot call me().")
		emit_signal("profile_fetch_failed", "MAIN_CLIENT_NULL")
		return

	if not ('users' in _main_client and _main_client.users is JavaScriptObject and 'me' in _main_client.users):
		printerr("[UsersAPI] client.users.me() path not found on JavaScriptObject.")
		emit_signal("profile_fetch_failed", "METHOD_PATH_INVALID")
		return

	print("[UsersAPI] Calling _main_client.users.me()...")
	var promise = _main_client.users.me()

	if not promise is JavaScriptObject:
		printerr("[UsersAPI] _main_client.users.me() did not return a JavaScriptObject (expected Promise).")
		emit_signal("profile_fetch_failed", "NOT_A_PROMISE")
		return

	var on_resolve_cb = Callable(self, "_on_profile_resolved").bind()
	var on_reject_cb = Callable(self, "_on_profile_rejected").bind()

	# Store JS callbacks in member variables to keep them alive
	_resolve_cb_js = JavaScriptBridge.create_callback(on_resolve_cb)
	_reject_cb_js = JavaScriptBridge.create_callback(on_reject_cb)

	promise.then(_resolve_cb_js, _reject_cb_js)
	print("[UsersAPI] .then() called on users.me() promise.")

func _on_profile_resolved(args: Array):
	print("[UsersAPI] User profile promise resolved. Args: ", args)
	if args.size() > 0:
		emit_signal("profile_received", args[0])
	else:
		emit_signal("profile_fetch_failed", "PROFILE_RESOLVED_NO_DATA")

	# Optional: clear stored callbacks now that promise resolved
	_resolve_cb_js = null
	_reject_cb_js = null

func _on_profile_rejected(args: Array):
	print("[UsersAPI] User profile promise rejected. Args: ", args)
	var error_msg = "PROFILE_REJECTED_UNKNOWN"
	if args.size() > 0:
		error_msg = str(args[0])
	emit_signal("profile_fetch_failed", error_msg)

	# Clear stored callbacks
	_resolve_cb_js = null
	_reject_cb_js = null 