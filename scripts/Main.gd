extends Control

# --- UI Element Node References ---
# These will be assigned in _ready() after the UI is programmatically created by UISetup.gd.
var sdk_status_label: Label
var user_info_label: Label
var inventory_label: Label
var api_result_label: Label

var view_user_details_button: Button
var user_details_modal: ColorRect
var user_details_content: Label
var user_details_close_button: Button
var get_inventory_button: Button
var grant_item_button: Button
var remove_item_button: Button
var exit_button: Button
var call_backend_button: Button
var status_indicator_node: Panel

# --- Constants for this template ---
# Defines the internal name of the primary currency item used in this demo.
const PRIMARY_CURRENCY_SLUG = "PLAYCADEMY_CREDITS"
const CURRENCY_GRANT_AMOUNT = 50
const CURRENCY_REMOVE_AMOUNT = 50

# --- State Variables ---
var _primary_currency_uuid: String = ""   # UUID of the primary currency item, fetched from inventory.
var _primary_currency_balance: int = 0  # Current balance of the primary currency.
var _user_data: Dictionary = {}  # Cached user data for modal display

# --- Timeback UI References ---
var timeback_role_label: Label
var timeback_enrollments_container: VBoxContainer
var timeback_refresh_button: Button

func _ready():
	# UISetup.gd is responsible for programmatically creating the UI elements for this scene.
	var config_for_ui = {
		"currency_grant_amount": CURRENCY_GRANT_AMOUNT,
		"currency_remove_amount": CURRENCY_REMOVE_AMOUNT,
	}
	var ui_elements = UISetup.setup_scene_ui(self, config_for_ui)
	
	# Assign all UI element references from the dictionary returned by UISetup.
	sdk_status_label = ui_elements.sdk_status_label
	user_info_label = ui_elements.user_info_label
	view_user_details_button = ui_elements.view_user_details_button
	user_details_modal = ui_elements.user_details_modal
	user_details_content = ui_elements.user_details_content
	user_details_close_button = ui_elements.user_details_close_button
	inventory_label = ui_elements.inventory_label
	api_result_label = ui_elements.api_result_label
	get_inventory_button = ui_elements.get_inventory_button
	grant_item_button = ui_elements.grant_item_button
	remove_item_button = ui_elements.remove_item_button
	exit_button = ui_elements.exit_button
	call_backend_button = ui_elements.call_backend_button
	status_indicator_node = ui_elements.status_indicator
	
	# Timeback UI elements
	timeback_role_label = ui_elements.timeback_role_label
	timeback_enrollments_container = ui_elements.timeback_enrollments_container
	timeback_refresh_button = ui_elements.timeback_refresh_button

	# Critical check: Ensure all necessary UI elements were successfully created and assigned.
	if not (sdk_status_label and user_info_label and view_user_details_button and 
			user_details_modal and user_details_content and user_details_close_button and
			inventory_label and api_result_label and get_inventory_button and 
			grant_item_button and remove_item_button and exit_button and call_backend_button and 
			status_indicator_node and timeback_role_label and timeback_enrollments_container and 
			timeback_refresh_button):
		printerr("[Playcademy Godot Template] CRITICAL: Not all UI elements could be found after setup. Check UISetup.gd and Main.gd scripts.")
		return 

	# NOTE: The Playcademy SDK works in both web and local development environments
	# In local development, it connects to the sandbox server automatically

	inventory_label.text = "---"
	remove_item_button.disabled = true 
	grant_item_button.disabled = true

	_update_sdk_status_display() # Reflect current SDK status (e.g., "Initializing...").
	
	# Show helpful info for local development
	if not OS.has_feature("web"):
		api_result_label.text = "Local development mode - ensure sandbox is running"

	# Connect to global Playcademy SDK signals.
	# PlaycademySdk is an Autoload script that manages JavaScript SDK communication.
	if PlaycademySdk:
		PlaycademySdk.sdk_ready.connect(_on_sdk_ready)
		PlaycademySdk.sdk_initialization_failed.connect(_on_sdk_init_failed)
	else:
		sdk_status_label.text = "SDK Status: PlaycademySdk Autoload NOT FOUND!"
		_disable_buttons() # SDK is unavailable, so disable interactive elements.

	# Connect UI button press events to their respective handler functions.
	view_user_details_button.pressed.connect(_on_view_user_details_pressed)
	user_details_close_button.pressed.connect(_on_close_user_details_pressed)
	get_inventory_button.pressed.connect(_on_get_inventory_button_pressed)
	grant_item_button.pressed.connect(_on_grant_item_button_pressed)
	remove_item_button.pressed.connect(_on_remove_item_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	call_backend_button.pressed.connect(_on_call_backend_button_pressed)
	timeback_refresh_button.pressed.connect(_on_timeback_refresh_pressed)

	# Edge case: If the Playcademy SDK was already initialized *before* this scene's _ready()
	# function executed, the `sdk_ready` signal might have been missed.
	# This manual call to `_on_sdk_ready()` ensures that initial data fetches 
	# (like inventory) and UI updates still occur if the SDK is already good to go.
	if PlaycademySdk and PlaycademySdk.is_ready():
		_on_sdk_ready()

# Helper to set the background color of the SDK status indicator panel.
func _set_status_indicator_color(color: Color):
	if status_indicator_node:
		var style_box = status_indicator_node.get_theme_stylebox("panel", "Panel")
		if style_box:
			var new_style = style_box.duplicate() if style_box else StyleBoxFlat.new()
			new_style.bg_color = color
			status_indicator_node.add_theme_stylebox_override("panel", new_style)
		else:
			printerr("[Playcademy Godot Template] Status indicator node does not have a 'panel' StyleBox of type 'Panel'. Cannot set color.")

# Updates the UI elements that display the SDK's current initialization status.
func _update_sdk_status_display():
	if PlaycademySdk and PlaycademySdk.is_ready():
		var mode = "WEB" if OS.has_feature("web") else "LOCAL"
		sdk_status_label.text = "READY • %s" % mode
		_enable_buttons()
		_set_status_indicator_color(Color("#00ff88")) # Green
	else:
		var mode = "WEB" if OS.has_feature("web") else "LOCAL"
		sdk_status_label.text = "INITIALIZING • %s" % mode
		_disable_buttons()
		_set_status_indicator_color(Color("#ffd700")) # Gold
		
func _disable_buttons():
	view_user_details_button.disabled = true
	get_inventory_button.disabled = true
	grant_item_button.disabled = true
	remove_item_button.disabled = true
	exit_button.disabled = true
	call_backend_button.disabled = true
	timeback_refresh_button.disabled = true

func _enable_buttons():
	view_user_details_button.disabled = false
	get_inventory_button.disabled = false
	grant_item_button.disabled = false
	exit_button.disabled = false
	call_backend_button.disabled = false
	timeback_refresh_button.disabled = false

# --- SDK Initialization Signal Handlers ---

# Called when the Playcademy SDK has successfully initialized.
func _on_sdk_ready():
	var mode = "web" if OS.has_feature("web") else "local development"
	print("[Playcademy Godot Template] Playcademy SDK is Ready in %s mode!" % mode)
	
	# Connect inventory signals
	PlaycademySdk.users.inventory_get_all_succeeded.connect(_on_get_inventory_succeeded)
	PlaycademySdk.users.inventory_get_all_failed.connect(_on_get_inventory_failed)
	PlaycademySdk.users.inventory_add_succeeded.connect(_on_add_item_succeeded)
	PlaycademySdk.users.inventory_add_failed.connect(_on_add_item_failed)
	PlaycademySdk.users.inventory_remove_succeeded.connect(_on_remove_item_succeeded)
	PlaycademySdk.users.inventory_remove_failed.connect(_on_remove_item_failed)
	PlaycademySdk.users.inventory_changed.connect(_on_inventory_changed_event)
	
	# Connect credits signals
	PlaycademySdk.credits.balance_succeeded.connect(_on_credits_balance_succeeded)
	PlaycademySdk.credits.balance_failed.connect(_on_credits_balance_failed)
	PlaycademySdk.credits.add_succeeded.connect(_on_credits_add_succeeded)
	PlaycademySdk.credits.add_failed.connect(_on_credits_add_failed)
	PlaycademySdk.credits.spend_succeeded.connect(_on_credits_spend_succeeded)
	PlaycademySdk.credits.spend_failed.connect(_on_credits_spend_failed)
	
	# Connect user signals
	PlaycademySdk.users.profile_received.connect(_on_get_me_succeeded)
	PlaycademySdk.users.profile_fetch_failed.connect(_on_get_me_failed)
	
	
	# Connect backend signals
	PlaycademySdk.backend.request_succeeded.connect(_on_backend_request_succeeded)
	PlaycademySdk.backend.request_failed.connect(_on_backend_request_failed)
	
	# Connect Timeback signals (for local development)
	if PlaycademySdk.timeback.has_signal("user_context_received"):
		PlaycademySdk.timeback.user_context_received.connect(_on_timeback_context_received)
	if PlaycademySdk.timeback.has_signal("user_context_failed"):
		PlaycademySdk.timeback.user_context_failed.connect(_on_timeback_context_failed)
	
	_update_sdk_status_display()
	api_result_label.text = "SDK ready! Fetching initial data..."
	# Automatically fetch initial data
	PlaycademySdk.users.me()
	PlaycademySdk.users.inventory_get_all()
	# Update Timeback display with current data
	_update_timeback_display()

# Called if the Playcademy SDK fails to initialize.
func _on_sdk_init_failed(error_message: String):
	printerr("[Playcademy Godot Template] Playcademy SDK Initialization Failed: ", error_message)
	
	var mode = "WEB" if OS.has_feature("web") else "LOCAL"
	
	# Handle specific error cases
	if error_message == "NOT_WEB_BUILD":
		sdk_status_label.text = "SANDBOX OFFLINE • %s" % mode
		api_result_label.text = "Local sandbox not running - check the Sandbox dock panel"
		_set_status_indicator_color(Color("#ff9800")) # Orange - indicates fixable issue
	else:
		sdk_status_label.text = "ERROR • %s" % mode
		api_result_label.text = "SDK initialization failed: %s" % error_message
		_set_status_indicator_color(Color("#ff3366")) # Red - indicates error
	
	_disable_buttons()


# --- Button Press Handlers ---

func _on_get_inventory_button_pressed():
	api_result_label.text = "Fetching inventory..."
	# This call is asynchronous. The actual inventory data will be delivered via the
	# 'get_all_succeeded' signal (connected in _ready) to the '_on_get_inventory_succeeded' function.
	PlaycademySdk.users.inventory_get_all()

func _on_grant_item_button_pressed():
	api_result_label.text = "Granting %d credits..." % CURRENCY_GRANT_AMOUNT
	PlaycademySdk.credits.add(CURRENCY_GRANT_AMOUNT)

func _on_remove_item_button_pressed():
	if _primary_currency_balance < CURRENCY_REMOVE_AMOUNT:
		api_result_label.text = "Insufficient credits"
		return
	
	api_result_label.text = "Spending %d credits..." % CURRENCY_REMOVE_AMOUNT
	PlaycademySdk.credits.spend(CURRENCY_REMOVE_AMOUNT)

func _on_exit_button_pressed():
	api_result_label.text = "Exiting game..."
	PlaycademySdk.runtime.exit()

func _on_call_backend_button_pressed():
	api_result_label.text = "Calling backend API..."
	# Example: Call a custom backend route
	# This demonstrates calling /api/sample/custom with POST method and some data
	PlaycademySdk.backend.request("/sample/custom", "POST", {
		"exampleData": "Hello from Godot!",
		"timestamp": Time.get_unix_time_from_system()
	})


# --- Backend API Signal Handlers ---

func _on_backend_request_succeeded(response_data):
	print("[Playcademy Godot Template] Backend request succeeded: ", response_data)
	api_result_label.text = "Backend response: %s" % JSON.stringify(response_data)

func _on_backend_request_failed(error_message: String):
	printerr("[Playcademy Godot Template] Backend request failed: ", error_message)
	api_result_label.text = "Backend error: %s" % error_message


# --- UserAPI Signal Handlers ---

# Handles successful retrieval of user profile data.
func _on_get_me_succeeded(user_data):
	print("[Playcademy Godot Template] User profile received: ", user_data)
	var user_display_representation := "Unknown"

	if user_data == null:
		user_info_label.text = "Unavailable"
		_user_data = {}
		return

	if not user_data is Dictionary:
		printerr("[Playcademy Godot Template] Unexpected user_data type: ", typeof(user_data))
		user_info_label.text = "Data error"
		_user_data = {}
		return
	
	# Cache for modal
	_user_data = user_data
	
	var username = user_data.get("username")
	var name_field = user_data.get("name")
	var email = user_data.get("email")
	
	if username != null and not str(username).is_empty():
		user_display_representation = str(username)
	elif name_field != null and not str(name_field).is_empty():
		user_display_representation = str(name_field)
	elif email != null and not str(email).is_empty():
		user_display_representation = str(email)

	user_info_label.text = user_display_representation

func _on_get_me_failed(error_message: String):
	printerr("[Playcademy Godot Template] Get User Failed: ", error_message)
	user_info_label.text = "Failed to load"
	_user_data = {}

func _on_view_user_details_pressed():
	if _user_data.is_empty():
		user_details_content.text = "No user data available"
	else:
		user_details_content.text = JSON.stringify(_user_data, "  ")
	user_details_modal.visible = true

func _on_close_user_details_pressed():
	user_details_modal.visible = false


# --- LevelsAPI Signal Handlers (REMOVED - Platform-only feature) ---
# The levels namespace was removed as it's a platform-wide feature (overworld avatars).
# For game-specific progression, implement your own system using custom backend routes.


# --- InventoryAPI Signal Handlers ---

# Handles successful retrieval of the player's inventory.
func _on_get_inventory_succeeded(inventory_data: Array):
	print("[Playcademy Godot Template] Inventory received. Count: %d" % inventory_data.size())
	var processed_count := 0
	_primary_currency_uuid = "" 
	_primary_currency_balance = 0

	if inventory_data.is_empty():
		inventory_label.text = "0"
		api_result_label.text = "Inventory is empty"
		grant_item_button.disabled = _primary_currency_uuid.is_empty()
		remove_item_button.disabled = true
		return

	for item_entry_dict in inventory_data:
		var extracted_info = _extract_detailed_item_info(item_entry_dict)
		if not extracted_info.is_empty():
			processed_count += 1
			if extracted_info.slug == PRIMARY_CURRENCY_SLUG:
				_primary_currency_uuid = extracted_info.id
				_primary_currency_balance = extracted_info.quantity
				print("[Playcademy Godot Template] Found primary currency '%s': UUID=%s, Balance=%d" % [PRIMARY_CURRENCY_SLUG, _primary_currency_uuid, _primary_currency_balance])

	if _primary_currency_uuid.is_empty():
		inventory_label.text = "0"
		printerr("[Playcademy Godot Template] Primary currency '%s' not found in inventory." % PRIMARY_CURRENCY_SLUG)
	else:
		inventory_label.text = "%d" % _primary_currency_balance

	# Credits API handles finding the item, so we can always enable grant
	grant_item_button.disabled = false
	remove_item_button.disabled = (_primary_currency_balance < CURRENCY_REMOVE_AMOUNT)
	
	api_result_label.text = "Inventory loaded (%d items)" % processed_count
	
func _on_get_inventory_failed(error_message: String):
	printerr("[Playcademy Godot Template] Get Inventory Failed. Error: ", error_message)
	inventory_label.text = "---"
	api_result_label.text = "Inventory fetch error: %s" % error_message

func _on_add_item_succeeded(response_data):
	print("[Playcademy Godot Template] Add Item Succeeded. Response: ", response_data)
	api_result_label.text = "Credits granted!"
	# The 'changed' signal from InventoryAPI should automatically trigger a re-fetch via _on_inventory_changed_event.

func _on_add_item_failed(error_message: String):
	printerr("[Playcademy Godot Template] Add Item Failed for '%s'. Error: %s" % [PRIMARY_CURRENCY_SLUG, error_message])
	api_result_label.text = "Grant failed: %s" % error_message

func _on_remove_item_succeeded(response_data):
	print("[Playcademy Godot Template] Remove Item Succeeded. Response: ", response_data)
	api_result_label.text = "Credits spent!"
	# The 'changed' signal from InventoryAPI should automatically trigger a re-fetch.

func _on_remove_item_failed(error_message: String):
	printerr("[Playcademy Godot Template] Remove Item Failed for '%s'. Error: %s" % [PRIMARY_CURRENCY_SLUG, error_message])
	api_result_label.text = "Spend failed: %s" % error_message

# Handles the generic 'changed' signal from the InventoryAPI.
# This signal indicates that the inventory has been modified (e.g., by adding or spending items).
func _on_inventory_changed_event(change_data): 
	print("[Playcademy Godot Template] Inventory 'changed' signal received. Data: ", change_data)
	api_result_label.text = "Inventory updated, refreshing..."
	# Best practice: re-fetch the full inventory to ensure UI consistency.
	PlaycademySdk.users.inventory_get_all()


func _on_credits_balance_succeeded(balance: int):
	print("[Playcademy Godot Template] Credits balance: ", balance)
	_primary_currency_balance = balance
	inventory_label.text = "%d" % balance
	api_result_label.text = "Balance: %d credits" % balance

func _on_credits_balance_failed(error_message: String):
	printerr("[Playcademy Godot Template] Credits balance failed: ", error_message)
	api_result_label.text = "Balance fetch error: %s" % error_message

func _on_credits_add_succeeded(new_balance: int):
	print("[Playcademy Godot Template] Credits added successfully. New balance: ", new_balance)
	_primary_currency_balance = new_balance
	inventory_label.text = "%d" % new_balance
	remove_item_button.disabled = (_primary_currency_balance < CURRENCY_REMOVE_AMOUNT)
	api_result_label.text = "+%d credits → Balance: %d" % [CURRENCY_GRANT_AMOUNT, new_balance]

func _on_credits_add_failed(error_message: String):
	printerr("[Playcademy Godot Template] Credits add failed: ", error_message)
	api_result_label.text = "Grant error: %s" % error_message

func _on_credits_spend_succeeded(new_balance: int):
	print("[Playcademy Godot Template] Credits spent successfully. New balance: ", new_balance)
	_primary_currency_balance = new_balance
	inventory_label.text = "%d" % new_balance
	remove_item_button.disabled = (_primary_currency_balance < CURRENCY_REMOVE_AMOUNT)
	api_result_label.text = "-%d credits → Balance: %d" % [CURRENCY_REMOVE_AMOUNT, new_balance]

func _on_credits_spend_failed(error_message: String):
	printerr("[Playcademy Godot Template] Credits spend failed: ", error_message)
	api_result_label.text = "Spend error: %s" % error_message 

# This function processes a single inventory item entry
func _extract_detailed_item_info(item_data_dict: Dictionary) -> Dictionary:
	# Initialize with default values.
	var extracted_info = {
		"id": "N/A",
		"name": "Unknown Item",
		"slug": "N/A",
		"quantity": 0
	}

	if item_data_dict == null or not item_data_dict is Dictionary:
		printerr("[Playcademy Godot Template] _extract_detailed_item_info received null or non-Dictionary: ", item_data_dict)
		return {} 

	var int_quantity = item_data_dict.get("quantity", 0)
	if int_quantity == null:
		printerr("[Playcademy Godot Template] CRITICAL: 'quantity' key missing from item_data_dict from InventoryAPI. This is a bug. Dict: ", item_data_dict)
		int_quantity = 0

	extracted_info.quantity = int_quantity

	var item_details = item_data_dict.get("item")

	if item_details == null:
		printerr("[Playcademy Godot Template] Item details are null for an inventory entry. Quantity: %d. Dict: %s" % [int_quantity, item_data_dict])
		return extracted_info 
	
	if not item_details is Dictionary:
		printerr("[Playcademy Godot Template] Unexpected item_details type: ", typeof(item_details))
		return extracted_info
	
	var item_id = item_details.get("id")
	var item_name = item_details.get("name")
	var slug = item_details.get("slug")
		
	if item_id != null:
		extracted_info.id = str(item_id)

	var display_name = "Unknown Item (ID: %s)" % extracted_info.id
	if item_name != null and not str(item_name).is_empty():
		display_name = str(item_name)
	elif slug != null and not str(slug).is_empty():
		display_name = str(slug)
	
	extracted_info.name = display_name

	if slug != null:
		extracted_info.slug = str(slug)
	
	return extracted_info

# --- Timeback Functions ---

func _on_timeback_refresh_pressed():
	api_result_label.text = "Refreshing Timeback data..."
	if PlaycademySdk.timeback.has_method("fetch_user_context"):
		PlaycademySdk.timeback.fetch_user_context()
	else:
		_update_timeback_display()
		api_result_label.text = "Timeback data refreshed"

func _on_timeback_context_received(_data: Dictionary):
	print("[Playcademy Godot Template] Timeback context received: ", _data)
	_update_timeback_display()
	api_result_label.text = "Timeback data loaded"

func _on_timeback_context_failed(error_message: String):
	printerr("[Playcademy Godot Template] Timeback context failed: ", error_message)
	api_result_label.text = "Timeback error: %s" % error_message

func _update_timeback_display():
	# Get role and enrollments from SDK (these are properties, not methods)
	var role = PlaycademySdk.timeback.role if PlaycademySdk.timeback else "student"
	var enrollments: Array = PlaycademySdk.timeback.enrollments if PlaycademySdk.timeback else []
	
	# Capitalize first letter for display
	timeback_role_label.text = role.capitalize()
	
	# Clear existing enrollment items
	for child in timeback_enrollments_container.get_children():
		child.queue_free()
	
	if enrollments.is_empty():
		var no_enrollments = Label.new()
		no_enrollments.text = "No enrollments"
		no_enrollments.add_theme_font_size_override("font_size", 12)
		no_enrollments.add_theme_color_override("font_color", Color("#484f58"))
		timeback_enrollments_container.add_child(no_enrollments)
	else:
		for enrollment in enrollments:
			var enrollment_label = Label.new()
			var subject = enrollment.get("subject", "Unknown")
			var grade = enrollment.get("grade", "?")
			enrollment_label.text = "%s - Grade %s" % [subject, grade]
			enrollment_label.add_theme_font_size_override("font_size", 13)
			enrollment_label.add_theme_color_override("font_color", Color("#f0f6fc"))
			timeback_enrollments_container.add_child(enrollment_label)
