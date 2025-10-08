extends Control

# --- UI Element Node References ---
# These will be assigned in _ready() after the UI is programmatically created by UISetup.gd.
var sdk_status_label: Label
var user_info_label: Label
var inventory_label: Label
var level_info_label: Label
var api_result_label: Label

var get_user_button: Button
var get_inventory_button: Button
var get_level_button: Button
var add_xp_button: Button
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
const XP_GRANT_AMOUNT = 100

# Defines feature tiers that can be "unlocked" by spending the primary currency.
# 'label_node_name_in_setup' corresponds to the Node.name given to tier labels in UISetup.gd.
const FEATURE_TIERS = [
	{"name": "Bronze Tier Access", "cost": 50, "label_node_name_in_setup": "FeatureBronzeLabel"},
	{"name": "Silver Tier Access", "cost": 500, "label_node_name_in_setup": "FeatureSilverLabel"},
	{"name": "Gold Tier Access", "cost": 1000, "label_node_name_in_setup": "FeatureGoldLabel"}
]

# --- State Variables ---
var _primary_currency_uuid: String = ""   # UUID of the primary currency item, fetched from inventory.
var _primary_currency_balance: int = 0  # Current balance of the primary currency.
var _feature_tier_labels: Dictionary = {} # Stores references to the dynamically created tier labels for UI updates.
var _current_level: int = 1
var _current_xp: int = 0
var _xp_to_next_level: int = 50

func _ready():
	# UISetup.gd is responsible for programmatically creating the UI elements for this scene.
	var config_for_ui = {
		"currency_grant_amount": CURRENCY_GRANT_AMOUNT,
		"currency_remove_amount": CURRENCY_REMOVE_AMOUNT,
		"xp_grant_amount": XP_GRANT_AMOUNT,
		"feature_tiers": FEATURE_TIERS
	}
	var ui_elements = UISetup.setup_scene_ui(self, config_for_ui)
	
	# Assign all UI element references from the dictionary returned by UISetup.
	sdk_status_label = ui_elements.sdk_status_label
	user_info_label = ui_elements.user_info_label
	inventory_label = ui_elements.inventory_label
	level_info_label = ui_elements.level_info_label
	api_result_label = ui_elements.api_result_label
	get_user_button = ui_elements.get_user_button
	get_inventory_button = ui_elements.get_inventory_button
	get_level_button = ui_elements.get_level_button
	add_xp_button = ui_elements.add_xp_button
	grant_item_button = ui_elements.grant_item_button
	remove_item_button = ui_elements.remove_item_button
	exit_button = ui_elements.exit_button
	call_backend_button = ui_elements.call_backend_button
	status_indicator_node = ui_elements.status_indicator
	
	if ui_elements.has("feature_tier_labels"):
		_feature_tier_labels = ui_elements.feature_tier_labels

	# Critical check: Ensure all necessary UI elements were successfully created and assigned.
	if not (sdk_status_label and user_info_label and inventory_label and level_info_label and api_result_label and
			get_user_button and get_inventory_button and get_level_button and add_xp_button and grant_item_button and remove_item_button and exit_button and call_backend_button and status_indicator_node and not _feature_tier_labels.is_empty()):
		printerr("[Playcademy Godot Template] CRITICAL: Not all UI elements, including feature tier labels, could be found after setup. Check UISetup.gd and Main.gd scripts.")
		return 

	# NOTE: The Playcademy SDK works in both web and local development environments
	# In local development, it connects to the sandbox server automatically

	inventory_label.text = "Currency: ---"
	level_info_label.text = "Level: --- | XP: --- | To Next: ---"
	remove_item_button.disabled = true 
	grant_item_button.disabled = true 
	get_level_button.disabled = true
	add_xp_button.disabled = true
	_update_feature_tier_display() # Initial update for feature tier statuses.

	_update_sdk_status_display() # Reflect current SDK status (e.g., "Initializing...").
	
	# Show helpful info for local development
	if not OS.has_feature("web"):
		api_result_label.text = "API Result: Local development mode - ensure sandbox is running!"

	# Connect to global Playcademy SDK signals.
	# PlaycademySdk is an Autoload script that manages JavaScript SDK communication.
	if PlaycademySdk:
		PlaycademySdk.sdk_ready.connect(_on_sdk_ready)
		PlaycademySdk.sdk_initialization_failed.connect(_on_sdk_init_failed)
	else:
		sdk_status_label.text = "SDK Status: PlaycademySdk Autoload NOT FOUND!"
		_disable_buttons() # SDK is unavailable, so disable interactive elements.

	# Connect UI button press events to their respective handler functions.
	get_user_button.pressed.connect(_on_get_user_button_pressed)
	get_inventory_button.pressed.connect(_on_get_inventory_button_pressed)
	get_level_button.pressed.connect(_on_get_level_button_pressed)
	add_xp_button.pressed.connect(_on_add_xp_button_pressed)
	grant_item_button.pressed.connect(_on_grant_item_button_pressed)
	remove_item_button.pressed.connect(_on_remove_item_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	call_backend_button.pressed.connect(_on_call_backend_button_pressed)

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
		var mode = "Web" if OS.has_feature("web") else "Local Development"
		sdk_status_label.text = "SDK Status: Ready! (%s Mode)" % mode
		_enable_buttons()
		_set_status_indicator_color(Color("#4CAF50")) # Green
	else:
		var mode = "Web" if OS.has_feature("web") else "Local Development"
		sdk_status_label.text = "SDK Status: Initializing... (%s Mode)" % mode
		_disable_buttons()
		_set_status_indicator_color(Color("#FFC107")) # Amber
		
func _disable_buttons():
	get_user_button.disabled = true
	get_inventory_button.disabled = true
	get_level_button.disabled = true
	add_xp_button.disabled = true
	grant_item_button.disabled = true
	remove_item_button.disabled = true
	exit_button.disabled = true
	call_backend_button.disabled = true

func _enable_buttons():
	get_user_button.disabled = false
	get_inventory_button.disabled = false
	get_level_button.disabled = false
	add_xp_button.disabled = false
	grant_item_button.disabled = false
	exit_button.disabled = false
	call_backend_button.disabled = false

# --- SDK Initialization Signal Handlers ---

# Called when the Playcademy SDK has successfully initialized.
func _on_sdk_ready():
	var mode = "web" if OS.has_feature("web") else "local development"
	print("[Playcademy Godot Template] Playcademy SDK is Ready in %s mode!" % mode)
	
	# Connect inventory signals
	PlaycademySdk.inventory.get_all_succeeded.connect(_on_get_inventory_succeeded)
	PlaycademySdk.inventory.get_all_failed.connect(_on_get_inventory_failed)
	PlaycademySdk.inventory.add_succeeded.connect(_on_add_item_succeeded)
	PlaycademySdk.inventory.add_failed.connect(_on_add_item_failed)
	PlaycademySdk.inventory.remove_succeeded.connect(_on_remove_item_succeeded)
	PlaycademySdk.inventory.remove_failed.connect(_on_remove_item_failed)
	PlaycademySdk.inventory.changed.connect(_on_inventory_changed_event)
	
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
	
	# Connect level signals
	PlaycademySdk.levels.get_succeeded.connect(_on_get_level_succeeded)
	PlaycademySdk.levels.get_failed.connect(_on_get_level_failed)
	PlaycademySdk.levels.progress_succeeded.connect(_on_get_level_progress_succeeded)
	PlaycademySdk.levels.progress_failed.connect(_on_get_level_progress_failed)
	PlaycademySdk.levels.add_xp_succeeded.connect(_on_add_xp_succeeded)
	PlaycademySdk.levels.add_xp_failed.connect(_on_add_xp_failed)
	
	# Connect level system events
	PlaycademySdk.levels.level_up.connect(_on_level_up_event)
	PlaycademySdk.levels.xp_gained.connect(_on_xp_gained_event)
	
	# Connect backend signals
	PlaycademySdk.backend.request_succeeded.connect(_on_backend_request_succeeded)
	PlaycademySdk.backend.request_failed.connect(_on_backend_request_failed)
	
	_update_sdk_status_display()
	api_result_label.text = "API Result: SDK Ready (%s mode)! Fetching initial data..." % mode
	# Automatically fetch the player's inventory and level once the SDK is ready.
	PlaycademySdk.inventory.get_all()
	PlaycademySdk.levels.progress()

# Called if the Playcademy SDK fails to initialize.
func _on_sdk_init_failed(error_message: String):
	printerr("[Playcademy Godot Template] Playcademy SDK Initialization Failed: ", error_message)
	
	var mode = "Web" if OS.has_feature("web") else "Local Development"
	
	# Handle specific error cases
	if error_message == "NOT_WEB_BUILD":
		sdk_status_label.text = "SDK Status: Local sandbox not available (%s Mode)" % mode
		api_result_label.text = "API Result: Local sandbox not running. Check the Sandbox dock panel."
		_set_status_indicator_color(Color("#FF9800")) # Orange - indicates fixable issue
	else:
		sdk_status_label.text = "SDK Status: FAILED - %s (%s Mode)" % [error_message, mode]
		api_result_label.text = "API Result: SDK Init FAILED! Check console."
		_set_status_indicator_color(Color("#F44336")) # Red - indicates error
	
	_disable_buttons()


# --- Button Press Handlers ---

func _on_get_user_button_pressed():
	api_result_label.text = "API Result: Fetching user..."
	# This call is asynchronous. The actual user data will be delivered via the
	# 'profile_received' signal (connected in _ready) to the '_on_get_me_succeeded' function,
	# or 'profile_fetch_failed' to '_on_get_me_failed'.
	PlaycademySdk.users.me()

func _on_get_inventory_button_pressed():
	api_result_label.text = "API Result: Fetching inventory..."
	# This call is asynchronous. The actual inventory data will be delivered via the
	# 'get_all_succeeded' signal (connected in _ready) to the '_on_get_inventory_succeeded' function.
	PlaycademySdk.inventory.get_all()

func _on_get_level_button_pressed():
	api_result_label.text = "API Result: Fetching level progress..."
	PlaycademySdk.levels.progress()

func _on_add_xp_button_pressed():
	api_result_label.text = "API Result: Adding %d XP..." % XP_GRANT_AMOUNT
	PlaycademySdk.levels.add_xp(XP_GRANT_AMOUNT)

func _on_grant_item_button_pressed():
	api_result_label.text = "API Result: Granting %s credits..." % CURRENCY_GRANT_AMOUNT
	PlaycademySdk.credits.add(CURRENCY_GRANT_AMOUNT)

func _on_remove_item_button_pressed():
	if _primary_currency_balance < CURRENCY_REMOVE_AMOUNT:
		api_result_label.text = "API Result: Not enough credits to remove."
		return
	
	api_result_label.text = "API Result: Removing %s credits..." % CURRENCY_REMOVE_AMOUNT
	PlaycademySdk.credits.spend(CURRENCY_REMOVE_AMOUNT)

func _on_exit_button_pressed():
	api_result_label.text = "API Result: Attempting to exit game..."
	PlaycademySdk.runtime.exit()

func _on_call_backend_button_pressed():
	api_result_label.text = "API Result: Calling custom backend route..."
	# Example: Call a custom backend route
	# This demonstrates calling /api/hello with POST method and some data
	PlaycademySdk.backend.request("/hello", "POST", {
		"exampleData": "Hello from Godot!",
		"timestamp": Time.get_unix_time_from_system()
	})


# --- Backend API Signal Handlers ---

func _on_backend_request_succeeded(response_data):
	print("[Playcademy Godot Template] Backend request succeeded: ", response_data)
	api_result_label.text = "API Result: Backend call succeeded! Response: %s" % JSON.stringify(response_data)

func _on_backend_request_failed(error_message: String):
	printerr("[Playcademy Godot Template] Backend request failed: ", error_message)
	api_result_label.text = "API Result: Backend call FAILED - %s" % error_message


# --- UserAPI Signal Handlers ---

# Handles successful retrieval of user profile data.
func _on_get_me_succeeded(user_data):
	print("[Playcademy Godot Template] User profile received: ", user_data)
	var user_display_representation := "N/A"
	var user_id_str := "N/A"

	if user_data == null:
		user_info_label.text = "User Info: Profile data is null."
		api_result_label.text = "API Result: User data null."
		return

	if not user_data is Dictionary:
		printerr("[Playcademy Godot Template] Unexpected user_data type: ", typeof(user_data))
		user_info_label.text = "User Info: Unexpected data format."
		api_result_label.text = "API Result: User data format error."
		return
	
	var user_id = user_data.get("id")
	var username = user_data.get("username")
	var name = user_data.get("name")
	var email = user_data.get("email")

	if user_id != null:
		user_id_str = str(user_id)
	
	if username != null and not str(username).is_empty():
		user_display_representation = str(username)
	elif name != null and not str(name).is_empty():
		user_display_representation = str(name)
	elif email != null and not str(email).is_empty():
		user_display_representation = str(email)

	# Fallback display if specific name fields are missing.
	if user_display_representation == "N/A" and user_id_str != "N/A":
		user_display_representation = "User (ID: %s)" % user_id_str
	elif user_display_representation == "N/A" and user_id_str == "N/A":
		user_info_label.text = "User Info: Received incomplete or unidentifiable data."
		api_result_label.text = "API Result: User data incomplete."
		return

	user_info_label.text = "User: %s (ID: %s)" % [user_display_representation, user_id_str]
	api_result_label.text = "API Result: User fetched successfully."

func _on_get_me_failed(error_message: String):
	printerr("[Playcademy Godot Template] Get User Failed: ", error_message)
	user_info_label.text = "User fetch failed: %s" % error_message
	api_result_label.text = "API Result: Get User FAILED."


# --- LevelsAPI Signal Handlers ---

func _on_get_level_succeeded(level_data):
	print("[Playcademy Godot Template] Level data received: ", level_data)
	if level_data != null and level_data is Dictionary:
		_current_level = level_data.get("currentLevel", 1)
		_current_xp = level_data.get("currentXp", 0)
		_update_level_display()
		api_result_label.text = "API Result: Level data fetched successfully."
	else:
		level_info_label.text = "Level: Error - Invalid data"
		api_result_label.text = "API Result: Level data invalid."

func _on_get_level_failed(error_message: String):
	printerr("[Playcademy Godot Template] Get Level Failed: ", error_message)
	level_info_label.text = "Level fetch failed: %s" % error_message
	api_result_label.text = "API Result: Get Level FAILED."

func _on_get_level_progress_succeeded(progress_data):
	print("[Playcademy Godot Template] Level progress received: ", progress_data)
	if progress_data != null and progress_data is Dictionary:
		_current_level = progress_data.get("level", 1)
		_current_xp = progress_data.get("currentXp", 0)
		_xp_to_next_level = progress_data.get("xpToNextLevel", 50)
		_update_level_display()
		api_result_label.text = "API Result: Level progress fetched successfully."
	else:
		level_info_label.text = "Level: Error - Invalid progress data"
		api_result_label.text = "API Result: Level progress data invalid."

func _on_get_level_progress_failed(error_message: String):
	printerr("[Playcademy Godot Template] Get Level Progress Failed: ", error_message)
	level_info_label.text = "Level progress fetch failed: %s" % error_message
	api_result_label.text = "API Result: Get Level Progress FAILED."

func _on_add_xp_succeeded(result_data):
	print("[Playcademy Godot Template] Add XP succeeded: ", result_data)
	if result_data != null and result_data is Dictionary:
		var leveled_up = result_data.get("leveledUp", false)
		var new_level = result_data.get("newLevel", _current_level)
		var credits_awarded = result_data.get("creditsAwarded", 0)
		
		if leveled_up:
			api_result_label.text = "API Result: 🎉 LEVEL UP! Level %d → %d (+%d credits)" % [_current_level, new_level, credits_awarded]
		else:
			api_result_label.text = "API Result: XP added successfully!"
		
		# Refresh level progress to get updated values
		PlaycademySdk.levels.progress()
		
		# If credits were awarded, refresh inventory too
		if credits_awarded > 0:
			PlaycademySdk.inventory.get_all()
	else:
		api_result_label.text = "API Result: XP added but invalid response data."

func _on_add_xp_failed(error_message: String):
	printerr("[Playcademy Godot Template] Add XP Failed: ", error_message)
	api_result_label.text = "API Result: Add XP FAILED - %s" % error_message

# Level system event handlers
func _on_level_up_event(old_level: int, new_level: int, credits_awarded: int):
	print("[Playcademy Godot Template] 🎉 LEVEL UP EVENT! %d → %d (Earned %d credits)" % [old_level, new_level, credits_awarded])
	# This could trigger special effects, sounds, animations, etc.

func _on_xp_gained_event(amount: int, total_xp: int, leveled_up: bool):
	print("[Playcademy Godot Template] XP Gained Event: +%d XP (Total: %d, Leveled Up: %s)" % [amount, total_xp, leveled_up])
	# This could trigger XP bar animations, floating text, etc.

func _update_level_display():
	level_info_label.text = "Level: %d | XP: %d | To Next: %d" % [_current_level, _current_xp, _xp_to_next_level]


# --- InventoryAPI Signal Handlers ---

# Handles successful retrieval of the player's inventory.
func _on_get_inventory_succeeded(inventory_data: Array):
	print("[Playcademy Godot Template] Inventory received. Count: %d" % inventory_data.size())
	var processed_count := 0
	_primary_currency_uuid = "" 
	_primary_currency_balance = 0

	if inventory_data.is_empty():
		inventory_label.text = "Currency: 0 (No items)"
		api_result_label.text = "API Result: Inventory is empty."
		grant_item_button.disabled = _primary_currency_uuid.is_empty()
		remove_item_button.disabled = true
		_update_feature_tier_display()
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
		inventory_label.text = "Currency: 0 (Demo currency item not found)"
		printerr("[Playcademy Godot Template] Primary currency '%s' not found in inventory." % PRIMARY_CURRENCY_SLUG)
	else:
		inventory_label.text = "Currency: %d" % _primary_currency_balance

	# Credits API handles finding the item, so we can always enable grant
	grant_item_button.disabled = false
	remove_item_button.disabled = (_primary_currency_balance < CURRENCY_REMOVE_AMOUNT)
	
	api_result_label.text = "API Result: Inventory fetched successfully. %d item(s)." % processed_count
	_update_feature_tier_display()
	
func _on_get_inventory_failed(error_message: String):
	printerr("[Playcademy Godot Template] Get Inventory Failed. Error: ", error_message)
	inventory_label.text = "Inventory: Failed to fetch - %s" % error_message
	api_result_label.text = "API Result: Get Inventory FAILED."

func _on_add_item_succeeded(response_data):
	print("[Playcademy Godot Template] Add Item Succeeded. Response: ", response_data)
	api_result_label.text = "API Result: Item '%s' granted!" % PRIMARY_CURRENCY_SLUG
	# The 'changed' signal from InventoryAPI should automatically trigger a re-fetch via _on_inventory_changed_event.

func _on_add_item_failed(error_message: String):
	printerr("[Playcademy Godot Template] Add Item Failed for '%s'. Error: %s" % [PRIMARY_CURRENCY_SLUG, error_message])
	api_result_label.text = "API Result: Grant Item FAILED - %s" % error_message

func _on_remove_item_succeeded(response_data):
	print("[Playcademy Godot Template] Remove Item Succeeded. Response: ", response_data)
	api_result_label.text = "API Result: Item '%s' removed!" % PRIMARY_CURRENCY_SLUG
	# The 'changed' signal from InventoryAPI should automatically trigger a re-fetch.

func _on_remove_item_failed(error_message: String):
	printerr("[Playcademy Godot Template] Remove Item Failed for '%s'. Error: %s" % [PRIMARY_CURRENCY_SLUG, error_message])
	api_result_label.text = "API Result: Remove Item FAILED - %s" % error_message

# Handles the generic 'changed' signal from the InventoryAPI.
# This signal indicates that the inventory has been modified (e.g., by adding or spending items).
func _on_inventory_changed_event(change_data): 
	print("[Playcademy Godot Template] Inventory 'changed' signal received. Data: ", change_data)
	api_result_label.text = "API Result: Inventory changed. Re-fetching..."
	# Best practice: re-fetch the full inventory to ensure UI consistency.
	PlaycademySdk.inventory.get_all()


func _on_credits_balance_succeeded(balance: int):
	print("[Playcademy Godot Template] Credits balance: ", balance)
	_primary_currency_balance = balance
	inventory_label.text = "Currency: %d" % balance
	_update_feature_tier_display()
	api_result_label.text = "API Result: Credits balance fetched successfully."

func _on_credits_balance_failed(error_message: String):
	printerr("[Playcademy Godot Template] Credits balance failed: ", error_message)
	api_result_label.text = "API Result: Credits balance FAILED - %s" % error_message

func _on_credits_add_succeeded(new_balance: int):
	print("[Playcademy Godot Template] Credits added successfully. New balance: ", new_balance)
	_primary_currency_balance = new_balance
	inventory_label.text = "Currency: %d" % new_balance
	_update_feature_tier_display()
	remove_item_button.disabled = (_primary_currency_balance < CURRENCY_REMOVE_AMOUNT)
	api_result_label.text = "API Result: %d credits granted! New balance: %d" % [CURRENCY_GRANT_AMOUNT, new_balance]

func _on_credits_add_failed(error_message: String):
	printerr("[Playcademy Godot Template] Credits add failed: ", error_message)
	api_result_label.text = "API Result: Grant credits FAILED - %s" % error_message

func _on_credits_spend_succeeded(new_balance: int):
	print("[Playcademy Godot Template] Credits spent successfully. New balance: ", new_balance)
	_primary_currency_balance = new_balance
	inventory_label.text = "Currency: %d" % new_balance
	_update_feature_tier_display()
	remove_item_button.disabled = (_primary_currency_balance < CURRENCY_REMOVE_AMOUNT)
	api_result_label.text = "API Result: %d credits removed! New balance: %d" % [CURRENCY_REMOVE_AMOUNT, new_balance]

func _on_credits_spend_failed(error_message: String):
	printerr("[Playcademy Godot Template] Credits spend failed: ", error_message)
	api_result_label.text = "API Result: Remove credits FAILED - %s" % error_message 

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

func _update_feature_tier_display():
	for tier_info in FEATURE_TIERS:
		var label_node_name = tier_info.label_node_name_in_setup
		if _feature_tier_labels.has(label_node_name):
			var label: Label = _feature_tier_labels[label_node_name]
			if _primary_currency_balance >= tier_info.cost:
				label.text = "%s: Unlocked!" % tier_info.name
				label.add_theme_color_override("font_color", Color("#A5D6A7")) # Light green
			else:
				label.text = "%s: Locked (Requires %s Credits)" % [tier_info.name, tier_info.cost]
				label.add_theme_color_override("font_color", Color("#FFCDD2")) # Light red
		else:
			printerr("[Playcademy Godot Template] Feature tier label node not found: ", label_node_name)
