extends Node

class_name LocalInventoryAPI

signal get_all_succeeded(inventory_data)
signal get_all_failed(error_message)

signal add_succeeded(response_data)
signal add_failed(error_message)

signal spend_succeeded(response_data)
signal spend_failed(error_message)

signal changed(change_data)

var _base_url: String

func _init(base_url: String):
	_base_url = base_url.rstrip("/")

# ------------------------ GET ALL ----------------------
func get_all():
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_get_all_completed.bind(http))
	var err := http.request("%s/inventory" % _base_url)
	if err != OK:
		emit_signal("get_all_failed", "HTTP_REQUEST_FAILED")
		http.queue_free()

func _on_get_all_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	if response_code != 200:
		emit_signal("get_all_failed", "HTTP_%d" % response_code)
		return
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		emit_signal("get_all_failed", "JSON_PARSE_ERROR")
		return
	var data = json.data
	emit_signal("get_all_succeeded", data)

# ------------------------ ADD ----------------------
func add(item_id: String, quantity: int = 1):
	var payload = {"itemId": item_id, "qty": quantity}
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_add_completed.bind(http))
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := http.request("%s/inventory/add" % _base_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		emit_signal("add_failed", "HTTP_REQUEST_FAILED")
		http.queue_free()

func _on_add_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	if response_code != 200:
		emit_signal("add_failed", "HTTP_%d" % response_code)
		return
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		emit_signal("add_failed", "JSON_PARSE_ERROR")
		return
	var data = json.data
	emit_signal("add_succeeded", data)
	emit_signal("changed", data)

# ------------------------ SPEND ----------------------
func spend(item_id: String, quantity: int = 1):
	var payload = {"itemId": item_id, "qty": quantity}
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_spend_completed.bind(http))
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := http.request("%s/inventory/spend" % _base_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		emit_signal("spend_failed", "HTTP_REQUEST_FAILED")
		http.queue_free()

func _on_spend_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest):
	http.queue_free()
	if response_code != 200:
		emit_signal("spend_failed", "HTTP_%d" % response_code)
		return
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK:
		emit_signal("spend_failed", "JSON_PARSE_ERROR")
		return
	var data = json.data
	emit_signal("spend_succeeded", data)
	emit_signal("changed", data) 
