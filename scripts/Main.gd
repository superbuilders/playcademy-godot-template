extends Control

# --- UI Element Node References ---
# These will be assigned in _ready() after the UI is programmatically created by UISetup.gd.
var sdk_status_label: Label
var user_info_label: Label
var inventory_label: Label
var api_result_label: Label

var get_user_button: Button
var get_inventory_button: Button
var grant_item_button: Button
var spend_item_button: Button
var exit_button: Button
var status_indicator_node: Panel

# --- Constants for this template ---
# Defines the internal name of the primary currency item used in this demo.
const PRIMARY_CURRENCY_INTERNAL_NAME = "PLAYCADEMY_CREDITS"
const CURRENCY_GRANT_AMOUNT = 50
const CURRENCY_SPEND_AMOUNT = 50

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

func _ready():
	# UISetup.gd is responsible for programmatically creating the UI elements for this scene.
	var config_for_ui = {
		"currency_grant_amount": CURRENCY_GRANT_AMOUNT,
		"currency_spend_amount": CURRENCY_SPEND_AMOUNT,
		"feature_tiers": FEATURE_TIERS
	}
	var ui_elements = UISetup.setup_scene_ui(self, config_for_ui)
	
	# Assign all UI element references from the dictionary returned by UISetup.
	sdk_status_label = ui_elements.sdk_status_label
	user_info_label = ui_elements.user_info_label
	inventory_label = ui_elements.inventory_label
	api_result_label = ui_elements.api_result_label
	get_user_button = ui_elements.get_user_button
	get_inventory_button = ui_elements.get_inventory_button
	grant_item_button = ui_elements.grant_item_button
	spend_item_button = ui_elements.spend_item_button
	exit_button = ui_elements.exit_button
	status_indicator_node = ui_elements.status_indicator
	
	if ui_elements.has("feature_tier_labels"):
		_feature_tier_labels = ui_elements.feature_tier_labels

	# Critical check: Ensure all necessary UI elements were successfully created and assigned.
	if not (sdk_status_label and user_info_label and inventory_label and api_result_label and
			get_user_button and get_inventory_button and grant_item_button and spend_item_button and exit_button and status_indicator_node and not _feature_tier_labels.is_empty()):
		printerr("[Playcademy Godot Template] CRITICAL: Not all UI elements, including feature tier labels, could be found after setup. Check UISetup.gd and Main.gd scripts.")
		return 

	# NOTE: If not running in a web environment, the Playcademy SDK will not initialize.
	if not OS.has_feature("web"):
		_update_sdk_status_display()
		_disable_buttons() 
		printerr("[Playcademy Godot Template] Not a web build. SDK functionality will be unavailable.")
		return

	inventory_label.text = "Currency: ---"
	spend_item_button.disabled = true 
	grant_item_button.disabled = true 
	_update_feature_tier_display() # Initial update for feature tier statuses.

	_update_sdk_status_display() # Reflect current SDK status (e.g., "Initializing...").

	# Connect to global Playcademy SDK signals.
	# PlaycademySdk is an Autoload script that manages JavaScript SDK communication.
	if PlaycademySdk:
		PlaycademySdk.sdk_ready.connect(_on_sdk_ready)
		PlaycademySdk.sdk_initialization_failed.connect(_on_sdk_init_failed)

		PlaycademySdk.inventory.get_all_succeeded.connect(_on_get_inventory_succeeded)
		PlaycademySdk.inventory.get_all_failed.connect(_on_get_inventory_failed)
		PlaycademySdk.inventory.add_succeeded.connect(_on_add_item_succeeded)
		PlaycademySdk.inventory.add_failed.connect(_on_add_item_failed)
		PlaycademySdk.inventory.spend_succeeded.connect(_on_spend_item_succeeded)
		PlaycademySdk.inventory.spend_failed.connect(_on_spend_item_failed)
		PlaycademySdk.inventory.changed.connect(_on_inventory_changed_event)
		
		PlaycademySdk.users.profile_received.connect(_on_get_me_succeeded)
		PlaycademySdk.users.profile_fetch_failed.connect(_on_get_me_failed)
	else:
		sdk_status_label.text = "SDK Status: PlaycademySdk Autoload NOT FOUND!"
		_disable_buttons() # SDK is unavailable, so disable interactive elements.

	# Connect UI button press events to their respective handler functions.
	get_user_button.pressed.connect(_on_get_user_button_pressed)
	get_inventory_button.pressed.connect(_on_get_inventory_button_pressed)
	grant_item_button.pressed.connect(_on_grant_item_button_pressed)
	spend_item_button.pressed.connect(_on_spend_item_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

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
	# Handle non-web environment first
	if not OS.has_feature("web"):
		sdk_status_label.text = "SDK Status: Requires Web Environment"
		_disable_buttons()
		_set_status_indicator_color(Color("#F44336")) # Red, indicating non-functional
		# Ensure API result label also reflects this state clearly
		api_result_label.text = "API Result: SDK is non-functional outside of a web browser environment."
		return

	if PlaycademySdk and PlaycademySdk.is_ready():
		sdk_status_label.text = "SDK Status: Initialized and Ready!"
		_enable_buttons()
		_set_status_indicator_color(Color("#4CAF50")) # Green
	else:
		sdk_status_label.text = "SDK Status: Not Ready / Initializing..."
		_disable_buttons()
		_set_status_indicator_color(Color("#FFC107")) # Amber
		
func _disable_buttons():
	get_user_button.disabled = true
	get_inventory_button.disabled = true
	grant_item_button.disabled = true
	spend_item_button.disabled = true

func _enable_buttons():
	get_user_button.disabled = false
	get_inventory_button.disabled = false
	exit_button.disabled = false

# --- SDK Initialization Signal Handlers ---

# Called when the Playcademy SDK has successfully initialized.
func _on_sdk_ready():
	print("[Playcademy Godot Template] Playcademy SDK is Ready!")
	_update_sdk_status_display()
	api_result_label.text = "API Result: SDK Ready! Fetching initial inventory..."
	# Automatically fetch the player's inventory once the SDK is ready.
	# This call is asynchronous. The actual inventory data will be delivered via the
	# 'get_all_succeeded' signal (connected in _ready) to the '_on_get_inventory_succeeded' function.
	PlaycademySdk.inventory.get_all()

# Called if the Playcademy SDK fails to initialize.
func _on_sdk_init_failed(error_message: String):
	printerr("[Playcademy Godot Template] Playcademy SDK Initialization Failed: ", error_message)
	# _update_sdk_status_display will be called. If it's a NOT_WEB_BUILD error,
	# it will correctly show "Requires Web Environment".
	# Otherwise, it shows the specific initialization error.
	_update_sdk_status_display()
	if error_message != "NOT_WEB_BUILD": # Avoid overwriting the more specific message from _update_sdk_status_display
		sdk_status_label.text = "SDK Status: FAILED - %s" % error_message
		api_result_label.text = "API Result: SDK Init FAILED! Check console."


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

func _on_grant_item_button_pressed():
	if _primary_currency_uuid.is_empty():
		api_result_label.text = "API Result: Primary currency UUID not known. Fetch inventory first."
		return
	
	api_result_label.text = "API Result: Granting %s credits..." % CURRENCY_GRANT_AMOUNT
	PlaycademySdk.inventory.add(_primary_currency_uuid, CURRENCY_GRANT_AMOUNT)

func _on_spend_item_button_pressed():
	if _primary_currency_uuid.is_empty():
		api_result_label.text = "API Result: Primary currency UUID not known. Fetch inventory first."
		return

	if _primary_currency_balance < CURRENCY_SPEND_AMOUNT:
		api_result_label.text = "API Result: Not enough credits to spend."
		return
	
	api_result_label.text = "API Result: Spending %s credits..." % CURRENCY_SPEND_AMOUNT
	PlaycademySdk.inventory.spend(_primary_currency_uuid, CURRENCY_SPEND_AMOUNT)

func _on_exit_button_pressed():
	api_result_label.text = "API Result: Attempting to exit game..."
	PlaycademySdk.runtime.exit()


# --- UserAPI Signal Handlers ---

# Handles successful retrieval of user profile data.
func _on_get_me_succeeded(user_data: JavaScriptObject):
	print("[Playcademy Godot Template] User profile received: ", user_data)
	var user_display_representation := "N/A"
	var user_id_str := "N/A"

	if user_data == null:
		user_info_label.text = "User Info: Profile data is null."
		api_result_label.text = "API Result: User data null."
		return

	if user_data.id != null:
		user_id_str = str(user_data.id)
	
	if user_data.username != null and not str(user_data.username).is_empty():
		user_display_representation = str(user_data.username)
	elif user_data.name != null and not str(user_data.name).is_empty():
		user_display_representation = str(user_data.name)
	elif user_data.email != null and not str(user_data.email).is_empty():
		user_display_representation = str(user_data.email)

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
		spend_item_button.disabled = true
		_update_feature_tier_display()
		return

	for item_entry_dict in inventory_data:
		var extracted_info = _extract_detailed_item_info(item_entry_dict)
		if not extracted_info.is_empty():
			processed_count += 1
			if extracted_info.internal_name == PRIMARY_CURRENCY_INTERNAL_NAME:
				_primary_currency_uuid = extracted_info.id
				_primary_currency_balance = extracted_info.quantity
				print("[Playcademy Godot Template] Found primary currency '%s': UUID=%s, Balance=%d" % [PRIMARY_CURRENCY_INTERNAL_NAME, _primary_currency_uuid, _primary_currency_balance])

	if _primary_currency_uuid.is_empty():
		inventory_label.text = "Currency: 0 (Demo currency item not found)"
		printerr("[Playcademy Godot Template] Primary currency '%s' not found in inventory." % PRIMARY_CURRENCY_INTERNAL_NAME)
		grant_item_button.disabled = true
	else:
		inventory_label.text = "Currency: %d" % _primary_currency_balance
		grant_item_button.disabled = false

	spend_item_button.disabled = (_primary_currency_balance < CURRENCY_SPEND_AMOUNT or _primary_currency_uuid.is_empty())
	
	api_result_label.text = "API Result: Inventory fetched successfully. %d item(s)." % processed_count
	_update_feature_tier_display()
	
func _on_get_inventory_failed(error_message: String):
	printerr("[Playcademy Godot Template] Get Inventory Failed. Error: ", error_message)
	inventory_label.text = "Inventory: Failed to fetch - %s" % error_message
	api_result_label.text = "API Result: Get Inventory FAILED."

func _on_add_item_succeeded(response_data):
	print("[Playcademy Godot Template] Add Item Succeeded. Response: ", response_data)
	api_result_label.text = "API Result: Item '%s' granted!" % PRIMARY_CURRENCY_INTERNAL_NAME
	# The 'changed' signal from InventoryAPI should automatically trigger a re-fetch via _on_inventory_changed_event.

func _on_add_item_failed(error_message: String):
	printerr("[Playcademy Godot Template] Add Item Failed for '%s'. Error: " % [PRIMARY_CURRENCY_INTERNAL_NAME, error_message])
	api_result_label.text = "API Result: Grant Item FAILED - %s" % error_message

func _on_spend_item_succeeded(response_data):
	print("[Playcademy Godot Template] Spend Item Succeeded. Response: ", response_data)
	api_result_label.text = "API Result: Item '%s' spent!" % PRIMARY_CURRENCY_INTERNAL_NAME
	# The 'changed' signal from InventoryAPI should automatically trigger a re-fetch.

func _on_spend_item_failed(error_message: String):
	printerr("[Playcademy Godot Template] Spend Item Failed for '%s'. Error: " % [PRIMARY_CURRENCY_INTERNAL_NAME, error_message])
	api_result_label.text = "API Result: Spend Item FAILED - %s" % error_message

# Handles the generic 'changed' signal from the InventoryAPI.
# This signal indicates that the inventory has been modified (e.g., by adding or spending items).
func _on_inventory_changed_event(change_data): 
	print("[Playcademy Godot Template] Inventory 'changed' signal received. Data: ", change_data)
	api_result_label.text = "API Result: Inventory changed. Re-fetching..."
	# Best practice: re-fetch the full inventory to ensure UI consistency.
	PlaycademySdk.inventory.get_all() 

# This function processes a single inventory item entry
func _extract_detailed_item_info(item_data_dict: Dictionary) -> Dictionary:
	# Initialize with default values.
	var extracted_info = {
		"id": "N/A",
		"name": "Unknown Item",
		"internal_name": "N/A",
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

	var item_details_js: JavaScriptObject = item_data_dict.get("item")

	if item_details_js == null:
		printerr("[Playcademy Godot Template] Item details (JavaScriptObject) are null for an inventory entry. Quantity: %d. Dict: %s" % [int_quantity, item_data_dict])
		return extracted_info 
		
	if item_details_js.id != null:
		extracted_info.id = str(item_details_js.id)

	var display_name = "Unknown Item (ID: %s)" % extracted_info.id
	if item_details_js.name != null and not str(item_details_js.name).is_empty():
		display_name = str(item_details_js.name)
	elif item_details_js.internalName != null and not str(item_details_js.internalName).is_empty():
		display_name = str(item_details_js.internalName) + " (Internal)"
	
	extracted_info.name = display_name

	if item_details_js.internalName != null:
		extracted_info.internal_name = str(item_details_js.internalName)
	
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
