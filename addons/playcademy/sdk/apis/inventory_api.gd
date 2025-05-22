class_name InventoryAPI extends RefCounted

# Signals for get_all operation (renamed from get)
signal get_all_succeeded(inventory_data)
signal get_all_failed(error_message)

# Signals for add operation
signal add_succeeded(response_data)
signal add_failed(error_message)

# Signals for spend operation
signal spend_succeeded(response_data)
signal spend_failed(error_message)

signal changed(change_data)

var _main_client: JavaScriptObject

# To keep JS callbacks alive for ongoing operations
var _get_all_resolve_cb_js: JavaScriptObject = null
var _get_all_reject_cb_js: JavaScriptObject = null
var _add_resolve_cb_js: JavaScriptObject = null
var _add_reject_cb_js: JavaScriptObject = null
var _spend_resolve_cb_js: JavaScriptObject = null
var _spend_reject_cb_js: JavaScriptObject = null

func _init(client_js_object: JavaScriptObject):
	_main_client = client_js_object
	print("[InventoryAPI] Initialized with client.")
	
	# TODO: Potentially subscribe to the JS SDK's event bus for 'inventoryChange' 
	# and emit the Godot 'changed' signal when that JS event fires.
	# This would require an additional JavaScriptBridge.create_callback for the event listener.


# Corresponds to client.users.inventory.get()
func get_all():
	if _main_client == null:
		printerr("[InventoryAPI] Main client not set. Cannot call get_all().")
		emit_signal("get_all_failed", "MAIN_CLIENT_NULL")
		return

	if not ('users' in _main_client and 
			_main_client.users is JavaScriptObject and 
			'inventory' in _main_client.users and 
			_main_client.users.inventory is JavaScriptObject and 
			'get' in _main_client.users.inventory):
		printerr("[InventoryAPI] client.users.inventory.get() path not found for get_all().")
		emit_signal("get_all_failed", "METHOD_PATH_INVALID")
		return

	print("[InventoryAPI] Calling _main_client.users.inventory.get() for get_all()...")
	var promise = _main_client.users.inventory.get()

	if not promise is JavaScriptObject:
		printerr("[InventoryAPI] inventory.get() did not return a Promise for get_all().")
		emit_signal("get_all_failed", "NOT_A_PROMISE")
		return

	var on_resolve = Callable(self, "_on_get_all_resolved").bind()
	var on_reject = Callable(self, "_on_get_all_rejected").bind()

	_get_all_resolve_cb_js = JavaScriptBridge.create_callback(on_resolve)
	_get_all_reject_cb_js = JavaScriptBridge.create_callback(on_reject)

	promise.then(_get_all_resolve_cb_js, _get_all_reject_cb_js)
	print("[InventoryAPI] .then() called on inventory.get() promise for get_all().")

func _on_get_all_resolved(args: Array):
	print("[InventoryAPI] Get inventory promise resolved. Args: ", args)
	if args.size() == 0:
		printerr("[InventoryAPI] Get inventory promise resolved with no data arguments.")
		emit_signal("get_all_succeeded", [])
		_clear_get_all_callbacks()
		return

	var raw_inventory_data = args[0] 
	var normalized_inventory_data = []
	var inv_len = int(raw_inventory_data.length)

	for i in range(inv_len):
		var item_entry_js = raw_inventory_data[i]

		if item_entry_js == null:
			printerr("[InventoryAPI] WARNING: Encountered null item entry at index %d. Skipping." % i)
			continue

		var item_data_dict = {}
		item_data_dict["item"] = item_entry_js.item 

		var raw_quantity = item_entry_js.quantity
		var int_quantity = 0

		if raw_quantity != null:
			if typeof(raw_quantity) == TYPE_INT:
				int_quantity = int(raw_quantity)
			elif typeof(raw_quantity) == TYPE_FLOAT:
				int_quantity = int(raw_quantity) # Truncate
			elif typeof(raw_quantity) == TYPE_STRING:
				if String(raw_quantity).is_valid_int():
					int_quantity = String(raw_quantity).to_int()
				else:
					printerr("[InventoryAPI] WARNING: Quantity for item at index %d is a non-integer string: '%s'. Defaulting to 0." % [i, raw_quantity])
			else:
				printerr("[InventoryAPI] WARNING: Quantity for item at index %d has unexpected type: %s. Value: '%s'. Defaulting to 0." % [i, typeof(raw_quantity), raw_quantity])
		
		item_data_dict["quantity"] = int_quantity
		normalized_inventory_data.append(item_data_dict)
			
	emit_signal("get_all_succeeded", normalized_inventory_data)
	_clear_get_all_callbacks()

func _on_get_all_rejected(args: Array):
	print("[InventoryAPI] Get inventory promise rejected. Args: ", args)
	var error_msg = "FETCH_REJECTED_UNKNOWN"
	if args.size() > 0: error_msg = str(args[0])
	emit_signal("get_all_failed", error_msg)
	_clear_get_all_callbacks()

func _clear_get_all_callbacks():
	_get_all_resolve_cb_js = null
	_get_all_reject_cb_js = null


# Corresponds to client.users.inventory.add(itemId, qty)
func add(item_id: String, quantity: int = 1):
	if _main_client == null:
		printerr("[InventoryAPI] Main client not set. Cannot call add().")
		emit_signal("add_failed", "MAIN_CLIENT_NULL")
		return
	
	if not ('users' in _main_client and 
			_main_client.users is JavaScriptObject and 
			'inventory' in _main_client.users and 
			_main_client.users.inventory is JavaScriptObject and 
			'add' in _main_client.users.inventory):
		printerr("[InventoryAPI] client.users.inventory.add() path not found.")
		emit_signal("add_failed", "METHOD_PATH_INVALID")
		return

	print("[InventoryAPI] Calling _main_client.users.inventory.add('%s', %d)..." % [item_id, quantity])
	var promise = _main_client.users.inventory.add(item_id, quantity)

	if not promise is JavaScriptObject:
		printerr("[InventoryAPI] add() did not return a Promise.")
		emit_signal("add_failed", "NOT_A_PROMISE")
		return

	var on_resolve = Callable(self, "_on_add_resolved").bind()
	var on_reject = Callable(self, "_on_add_rejected").bind()

	_add_resolve_cb_js = JavaScriptBridge.create_callback(on_resolve)
	_add_reject_cb_js = JavaScriptBridge.create_callback(on_reject)

	promise.then(_add_resolve_cb_js, _add_reject_cb_js)
	print("[InventoryAPI] .then() called on inventory.add() promise.")

func _on_add_resolved(args: Array):
	print("[InventoryAPI] Add item promise resolved. Args: ", args)
	var response_data = null
	if args.size() > 0: response_data = args[0]
	emit_signal("add_succeeded", response_data)
	emit_signal("changed", response_data)
	_clear_add_callbacks()

func _on_add_rejected(args: Array):
	print("[InventoryAPI] Add item promise rejected. Args: ", args)
	var error_msg = "ADD_REJECTED_UNKNOWN"
	if args.size() > 0: error_msg = str(args[0])
	emit_signal("add_failed", error_msg)
	_clear_add_callbacks()

func _clear_add_callbacks():
	_add_resolve_cb_js = null
	_add_reject_cb_js = null


# Corresponds to client.users.inventory.spend(itemId, qty)
func spend(item_id: String, quantity: int = 1): # Changed amount to quantity, or use qty
	if _main_client == null:
		printerr("[InventoryAPI] Main client not set. Cannot call spend().")
		emit_signal("spend_failed", "MAIN_CLIENT_NULL")
		return

	if not ('users' in _main_client and 
			_main_client.users is JavaScriptObject and 
			'inventory' in _main_client.users and 
			_main_client.users.inventory is JavaScriptObject and 
			'spend' in _main_client.users.inventory):
		printerr("[InventoryAPI] client.users.inventory.spend() path not found.")
		emit_signal("spend_failed", "METHOD_PATH_INVALID")
		return

	print("[InventoryAPI] Calling _main_client.users.inventory.spend('%s', %d)..." % [item_id, quantity])
	var promise = _main_client.users.inventory.spend(item_id, quantity)

	if not promise is JavaScriptObject:
		printerr("[InventoryAPI] spend() did not return a Promise.")
		emit_signal("spend_failed", "NOT_A_PROMISE")
		return

	var on_resolve = Callable(self, "_on_spend_resolved").bind()
	var on_reject = Callable(self, "_on_spend_rejected").bind()

	_spend_resolve_cb_js = JavaScriptBridge.create_callback(on_resolve)
	_spend_reject_cb_js = JavaScriptBridge.create_callback(on_reject)

	promise.then(_spend_resolve_cb_js, _spend_reject_cb_js)
	print("[InventoryAPI] .then() called on inventory.spend() promise.")

func _on_spend_resolved(args: Array):
	print("[InventoryAPI] Spend item promise resolved. Args: ", args)
	var response_data = null
	if args.size() > 0: response_data = args[0]
	emit_signal("spend_succeeded", response_data)
	emit_signal("changed", response_data)
	_clear_spend_callbacks()

func _on_spend_rejected(args: Array):
	print("[InventoryAPI] Spend item promise rejected. Args: ", args)
	var error_msg = "SPEND_REJECTED_UNKNOWN"
	if args.size() > 0: error_msg = str(args[0])
	emit_signal("spend_failed", error_msg)
	_clear_spend_callbacks()

func _clear_spend_callbacks():
	_spend_resolve_cb_js = null
	_spend_reject_cb_js = null


# TODO: Implement listening to JS event bus for 'inventoryChange'
# func _on_js_inventory_changed_event(args: Array):
# 	 print("[InventoryAPI] Received 'inventoryChange' event from JS SDK event bus. Args: ", args)
# 	 if args.size() > 0:
# 		 emit_signal("changed", args[0])
# 	 else:
# 		 emit_signal("changed", null) # Or some default notification data 
