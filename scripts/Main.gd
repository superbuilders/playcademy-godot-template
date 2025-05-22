extends Control

# --- UI Element Node References ---
# These will be assigned in _ready() after the UI is programmatically created.
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

# Predefined item ID for testing grant/spend operations
const TARGET_ITEM_INTERNAL_NAME = "FIRST_GAME_BADGE"

var _detailed_inventory_items: Array = []

func _ready():
	# Use the UISetup class to create our UI
	var ui_elements = UISetup.setup_scene_ui(self)
	
	# Assign all UI element references from the returned dictionary
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
	
	# Check if all crucial UI elements were found
	if not (sdk_status_label and user_info_label and inventory_label and api_result_label and
			get_user_button and get_inventory_button and grant_item_button and spend_item_button and exit_button and status_indicator_node):
		printerr("[SampleMain] CRITICAL: Not all UI elements could be found after setup! Check UISetup script.")
		return # Stop further execution if UI is broken

	# Check initial SDK status immediately
	_update_sdk_status_display()

	# Connect to SDK signals
	if PlaycademySdk:
		PlaycademySdk.sdk_ready.connect(_on_sdk_ready)
		PlaycademySdk.sdk_initialization_failed.connect(_on_sdk_init_failed)

		# Connect to InventoryAPI signals
		if PlaycademySdk.inventory:
			PlaycademySdk.inventory.get_all_succeeded.connect(_on_get_inventory_succeeded)
			PlaycademySdk.inventory.get_all_failed.connect(_on_get_inventory_failed)
			PlaycademySdk.inventory.add_succeeded.connect(_on_add_item_succeeded)
			PlaycademySdk.inventory.add_failed.connect(_on_add_item_failed)
			PlaycademySdk.inventory.spend_succeeded.connect(_on_spend_item_succeeded)
			PlaycademySdk.inventory.spend_failed.connect(_on_spend_item_failed)
			PlaycademySdk.inventory.changed.connect(_on_inventory_changed_event) # Listen for general changes
		
		# Connect to UserAPI signals
		if PlaycademySdk.users:
			if PlaycademySdk.users.has_signal("profile_received"):
				PlaycademySdk.users.profile_received.connect(_on_get_me_succeeded)
			if PlaycademySdk.users.has_signal("profile_fetch_failed"):
				PlaycademySdk.users.profile_fetch_failed.connect(_on_get_me_failed)
	else:
		sdk_status_label.text = "SDK Status: PlaycademySdk Autoload NOT FOUND!"
		_disable_buttons()

	# Connect button signals
	get_user_button.pressed.connect(_on_get_user_button_pressed)
	get_inventory_button.pressed.connect(_on_get_inventory_button_pressed)
	grant_item_button.pressed.connect(_on_grant_item_button_pressed)
	spend_item_button.pressed.connect(_on_spend_item_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

func _update_sdk_status_display():
	if PlaycademySdk and PlaycademySdk.is_ready():
		sdk_status_label.text = "SDK Status: Initialized and Ready!"
		_enable_buttons()
		
		# Update indicator to green
		if status_indicator_node:
			var indicator_style = status_indicator_node.get_theme_stylebox("panel", "Panel").duplicate()
			indicator_style.bg_color = Color("#4CAF50") # Green for ready
			status_indicator_node.add_theme_stylebox_override("panel", indicator_style)
	else:
		sdk_status_label.text = "SDK Status: Not Ready / Initializing..."
		_disable_buttons()
		
		# Update indicator to yellow
		if status_indicator_node:
			var indicator_style = status_indicator_node.get_theme_stylebox("panel", "Panel").duplicate()
			indicator_style.bg_color = Color("#FFC107") # Amber for initializing
			status_indicator_node.add_theme_stylebox_override("panel", indicator_style)

func _disable_buttons():
	get_user_button.disabled = true
	get_inventory_button.disabled = true
	grant_item_button.disabled = true
	spend_item_button.disabled = true
	exit_button.disabled = true

func _enable_buttons():
	get_user_button.disabled = false
	get_inventory_button.disabled = false
	grant_item_button.disabled = false
	spend_item_button.disabled = false
	exit_button.disabled = false

# --- SDK Initialization Signal Handlers ---
func _on_sdk_ready():
	print("[SampleMain] Playcademy SDK is Ready!")
	_update_sdk_status_display()
	api_result_label.text = "API Result: SDK Ready!"

func _on_sdk_init_failed(error_message: String):
	printerr("[SampleMain] Playcademy SDK Initialization Failed: ", error_message)
	_update_sdk_status_display()
	sdk_status_label.text = "SDK Status: FAILED - %s" % error_message
	api_result_label.text = "API Result: SDK Init FAILED! Check console."


# --- Button Press Handlers ---
func _on_get_user_button_pressed():
	api_result_label.text = "API Result: Fetching user..."
	if PlaycademySdk and PlaycademySdk.is_ready() and PlaycademySdk.users:
		# Signals are now connected in _ready()
		
		# Call the correct fetch method (me())
		if PlaycademySdk.users.has_method("me"):
			PlaycademySdk.users.me()
		else:
			PlaycademySdk.users.get_me() # fallback
	else:
		user_info_label.text = "User Info: SDK not ready or UsersAPI unavailable."
		api_result_label.text = "API Result: SDK not ready for Get User."

func _on_get_inventory_button_pressed():
	api_result_label.text = "API Result: Fetching inventory..."
	if PlaycademySdk and PlaycademySdk.is_ready() and PlaycademySdk.inventory:
		PlaycademySdk.inventory.get_all() 
	else:
		inventory_label.text = "Inventory: SDK not ready or InventoryAPI unavailable."
		api_result_label.text = "API Result: SDK not ready for Get Inventory."

func _on_grant_item_button_pressed():
	api_result_label.text = "API Result: Looking for item with internal name '%s' to grant..." % TARGET_ITEM_INTERNAL_NAME
	if not (PlaycademySdk and PlaycademySdk.is_ready() and PlaycademySdk.inventory):
		api_result_label.text = "API Result: SDK not ready for Grant Item."
		return

	if _detailed_inventory_items.is_empty():
		api_result_label.text = "API Result: Inventory not fetched or is empty. Cannot find item to grant."
		# Optionally, trigger a fetch here if you want to be more proactive
		# PlaycademySdk.inventory.get_all()
		return

	var found_item_id = null
	for item_detail in _detailed_inventory_items:
		if item_detail.has("internal_name") and item_detail.internal_name == TARGET_ITEM_INTERNAL_NAME:
			if item_detail.has("id"):
				found_item_id = item_detail.id
				break
	
	if found_item_id:
		api_result_label.text = "API Result: Found item. Granting UUID '%s' ('%s')..." % [found_item_id, TARGET_ITEM_INTERNAL_NAME]
		PlaycademySdk.inventory.add(found_item_id, 1)
	else:
		api_result_label.text = "API Result: Item with internal name '%s' not found in current inventory details." % TARGET_ITEM_INTERNAL_NAME

func _on_spend_item_button_pressed():
	api_result_label.text = "API Result: Looking for item with internal name '%s' to spend..." % TARGET_ITEM_INTERNAL_NAME
	if not (PlaycademySdk and PlaycademySdk.is_ready() and PlaycademySdk.inventory):
		api_result_label.text = "API Result: SDK not ready for Spend Item."
		return

	if _detailed_inventory_items.is_empty():
		api_result_label.text = "API Result: Inventory not fetched or is empty. Cannot find item to spend."
		return

	var found_item_id = null
	for item_detail in _detailed_inventory_items:
		if item_detail.has("internal_name") and item_detail.internal_name == TARGET_ITEM_INTERNAL_NAME:
			if item_detail.has("id"):
				found_item_id = item_detail.id
				break

	if found_item_id:
		api_result_label.text = "API Result: Found item. Spending UUID '%s' ('%s')..." % [found_item_id, TARGET_ITEM_INTERNAL_NAME]
		PlaycademySdk.inventory.spend(found_item_id, 1)
	else:
		api_result_label.text = "API Result: Item with internal name '%s' not found in current inventory details." % TARGET_ITEM_INTERNAL_NAME

func _on_exit_button_pressed():
	api_result_label.text = "API Result: Attempting to exit game..."
	if PlaycademySdk and PlaycademySdk.is_ready() and PlaycademySdk.runtime:
		PlaycademySdk.runtime.exit()
		# Optionally, you can provide more feedback here, but the game might close before it's seen
		# api_result_label.text = "API Result: Exit signal sent."
		# exit_button.disabled = true # Disable after clicking if desired
	else:
		api_result_label.text = "API Result: SDK not ready or RuntimeAPI unavailable for exit."


# --- UserAPI Signal Handlers ---
func _on_get_me_succeeded(user_data):
	print("[SampleMain] User profile received: ", user_data)
	var user_display_representation := "N/A"
	var user_id_str := "N/A"

	if user_data == null:
		user_info_label.text = "User Info: Profile data is null."
		api_result_label.text = "API Result: User data null."
		return

	# Handle Dictionary (Godot-converted JS object)
	if user_data is Dictionary:
		if user_data.has("id"):
			user_id_str = str(user_data.id)
		if user_data.has("username") and user_data.username != null and not str(user_data.username).is_empty():
			user_display_representation = str(user_data.username)
		elif user_data.has("name") and user_data.name != null and not str(user_data.name).is_empty():
			user_display_representation = str(user_data.name)
		elif user_data.has("email"):
			user_display_representation = str(user_data.email) # Fallback to email if no name/username
	# Handle raw JavaScriptObject
	elif user_data is JavaScriptObject:
		if "id" in user_data:
			user_id_str = str(user_data.id)
		if "username" in user_data and user_data.username != null and not str(user_data.username).is_empty():
			user_display_representation = str(user_data.username)
		elif "name" in user_data and user_data.name != null and not str(user_data.name).is_empty():
			user_display_representation = str(user_data.name)
		elif "email" in user_data:
			user_display_representation = str(user_data.email) # Fallback to email

	if user_display_representation == "N/A" and user_id_str != "N/A":
		user_display_representation = "User (ID: %s)" % user_id_str # Fallback if no name fields
	elif user_display_representation == "N/A" and user_id_str == "N/A":
		user_info_label.text = "User Info: Received incomplete or unidentifiable data."
		api_result_label.text = "API Result: User data incomplete."
		return

	user_info_label.text = "User: %s (ID: %s)" % [user_display_representation, user_id_str]
	api_result_label.text = "API Result: User fetched successfully."

func _on_get_me_failed(error_message):
	printerr("[SampleMain] Get User Failed: ", error_message)
	user_info_label.text = "User fetch failed: %s" % error_message
	api_result_label.text = "API Result: Get User FAILED."


# --- InventoryAPI Signal Handlers ---
func _on_get_inventory_succeeded(inventory_data):
	print("[SampleMain] Get Inventory Succeeded. Data: ", inventory_data)
	var text_display := ""
	_detailed_inventory_items.clear() # Clear previous detailed items

	if inventory_data == null:
		text_display = "Inventory data is null."
	# Case 1: Native Godot Array (auto-converted from JS array)
	elif inventory_data is Array:
		var inv_arr: Array = inventory_data
		if inv_arr.is_empty():
			text_display = "Your inventory is empty."
		else:
			text_display = ""
			for item_entry in inv_arr:
				text_display += _format_item_entry(item_entry)
				var detailed_item = _extract_detailed_item_info(item_entry)
				if not detailed_item.is_empty(): # Check if dictionary is not empty
					_detailed_inventory_items.append(detailed_item)
	# Case 2: JavaScriptObject (raw JS array or object)
	elif inventory_data is JavaScriptObject:
		var js_obj: JavaScriptObject = inventory_data
		var inv_len := 0
		if "length" in js_obj:
			inv_len = int(js_obj.length)
		if inv_len == 0:
			text_display = "Your inventory is empty."
		else:
			text_display = ""
			for i in range(inv_len):
				var item_entry_js = js_obj.get(str(i))
				text_display += _format_item_entry(item_entry_js)
				var detailed_item = _extract_detailed_item_info(item_entry_js)
				if not detailed_item.is_empty(): # Check if dictionary is not empty
					_detailed_inventory_items.append(detailed_item)
	# Case 3: Dictionary with 'items' key
	elif inventory_data is Dictionary and inventory_data.has("items"):
		var items_arr = inventory_data.items
		if items_arr.is_empty():
			text_display = "Your inventory is empty."
		else:
			text_display = ""
			for item_entry in items_arr:
				text_display += _format_item_entry(item_entry)
				var detailed_item = _extract_detailed_item_info(item_entry)
				if not detailed_item.is_empty(): # Check if dictionary is not empty
					_detailed_inventory_items.append(detailed_item)
	else:
		text_display = "Unrecognized inventory data format. Check console."

	inventory_label.text = text_display
	api_result_label.text = "API Result: Inventory fetched."

# Helper to extract structured item info (id and internalName)
func _extract_detailed_item_info(entry) -> Dictionary:
	if entry == null: return {} # Return empty dictionary

	var item_id_str := ""
	var item_internal_name_str := ""

	if ((entry is Dictionary and entry.has("item")) or (entry is JavaScriptObject and "item" in entry)) and entry.item != null:
		var item_obj = entry.item

		if (item_obj is Dictionary and item_obj.has("id")) or (item_obj is JavaScriptObject and "id" in item_obj):
			item_id_str = str(item_obj.id)

		if (item_obj is Dictionary and item_obj.has("internalName") and item_obj.internalName != null and not str(item_obj.internalName).is_empty()) or \
		   (item_obj is JavaScriptObject and "internalName" in item_obj and item_obj.internalName != null and not str(item_obj.internalName).is_empty()):
			item_internal_name_str = str(item_obj.internalName)
		
		if not item_id_str.is_empty() and not item_internal_name_str.is_empty():
			return {"id": item_id_str, "internal_name": item_internal_name_str}
		else:
			print("[SampleMain] Could not extract full detailed info (id/internalName) for an item entry: ", entry)

	return {} # Return empty dictionary

# Helper to format a single inventory entry regardless of its representation
func _format_item_entry(entry):
	if entry == null:
		return "- (null entry)\n"

	var quantity_str := "N/A"
	if (entry is Dictionary and entry.has("quantity")) or (entry is JavaScriptObject and "quantity" in entry):
		quantity_str = str(entry.quantity)

	var item_display_name := "N/A"
	var item_id_str := "N/A"

	if ((entry is Dictionary and entry.has("item")) or (entry is JavaScriptObject and "item" in entry)) and entry.item != null:
		var item_obj = entry.item # This is the 'Item' object

		# Get Item ID
		if (item_obj is Dictionary and item_obj.has("id")) or (item_obj is JavaScriptObject and "id" in item_obj):
			item_id_str = str(item_obj.id)

		# Get Item Display Name (prioritize displayName, then internalName, then fallback to ID)
		if (item_obj is Dictionary and item_obj.has("displayName") and item_obj.displayName != null and not str(item_obj.displayName).is_empty()) or \
		   (item_obj is JavaScriptObject and "displayName" in item_obj and item_obj.displayName != null and not str(item_obj.displayName).is_empty()):
			item_display_name = str(item_obj.displayName)
		elif (item_obj is Dictionary and item_obj.has("internalName") and item_obj.internalName != null and not str(item_obj.internalName).is_empty()) or \
			 (item_obj is JavaScriptObject and "internalName" in item_obj and item_obj.internalName != null and not str(item_obj.internalName).is_empty()):
			item_display_name = str(item_obj.internalName)
		elif item_id_str != "N/A": # Fallback to item ID if no other name is found
			item_display_name = "Item (ID: %s)" % item_id_str
		else:
			item_display_name = "(Unknown Item)"
	else:
		item_display_name = "(Item data missing)"

	return "- %s (x%s)\n" % [item_display_name, quantity_str]

func _on_get_inventory_failed(error_message: String):
	printerr("[SampleMain] Get Inventory Failed. Error: ", error_message)
	inventory_label.text = "Inventory: Failed to fetch - %s" % error_message
	api_result_label.text = "API Result: Get Inventory FAILED."

func _on_add_item_succeeded(response_data):
	print("[SampleMain] Add Item Succeeded. Response: ", response_data)
	api_result_label.text = "API Result: Item '%s' granted!" % TARGET_ITEM_INTERNAL_NAME
	# The 'changed' signal should also fire, triggering a re-fetch or update.
	# Optionally, you can call get_inventory() again here if not relying on 'changed' for immediate update.
	# PlaycademySdk.inventory.get_all() 

func _on_add_item_failed(error_message: String):
	printerr("[SampleMain] Add Item Failed for '%s'. Error: " % [TARGET_ITEM_INTERNAL_NAME, error_message])
	api_result_label.text = "API Result: Grant Item FAILED - %s" % error_message

func _on_spend_item_succeeded(response_data):
	print("[SampleMain] Spend Item Succeeded. Response: ", response_data)
	api_result_label.text = "API Result: Item '%s' spent!" % TARGET_ITEM_INTERNAL_NAME
	# The 'changed' signal should also fire, triggering a re-fetch or update.
	# PlaycademySdk.inventory.get_all() 

func _on_spend_item_failed(error_message: String):
	printerr("[SampleMain] Spend Item Failed for '%s'. Error: " % [TARGET_ITEM_INTERNAL_NAME, error_message])
	api_result_label.text = "API Result: Spend Item FAILED - %s" % error_message

func _on_inventory_changed_event(change_data): # This is the generic one from InventoryAPI
	print("[SampleMain] Inventory 'changed' signal received. Data: ", change_data)
	api_result_label.text = "API Result: Inventory changed. Re-fetching..."
	# Good practice to re-fetch the full inventory to reflect the change
	if PlaycademySdk and PlaycademySdk.is_ready() and PlaycademySdk.inventory:
		PlaycademySdk.inventory.get_all() 
