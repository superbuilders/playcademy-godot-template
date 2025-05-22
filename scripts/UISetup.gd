extends Node

# Helper class to set up the UI for the Playcademy SDK demo
class_name UISetup

const UI_ROOT_NODE_NAME = "MainVBoxContainer"

# Sets up the entire UI programmatically for the Playcademy SDK demo
static func setup_scene_ui(parent_control: Control) -> Dictionary:
	# Check if UI is already set up to prevent re-creating it on scene reload in editor
	if parent_control.find_child(UI_ROOT_NODE_NAME, false, false) != null:
		print("[UISetup] UI already appears to be set up.")
		return _find_existing_ui_elements(parent_control)

	print("[UISetup] Setting up scene UI programmatically...")

	# Set a nicer background color for the main control
	parent_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_color = Color("#2e2e2e") # Dark gray background
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	parent_control.add_theme_stylebox_override("panel", style)

	# Create main VBox with proper margins
	var vbox_container = VBoxContainer.new()
	vbox_container.name = UI_ROOT_NODE_NAME
	vbox_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox_container.add_theme_constant_override("separation", 20) # INCREASED spacing between elements
	vbox_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# INCREASED margins
	var margin = 40
	vbox_container.set("theme_override_constants/margin_top", margin)
	vbox_container.set("theme_override_constants/margin_bottom", margin)
	vbox_container.set("theme_override_constants/margin_left", margin)
	vbox_container.set("theme_override_constants/margin_right", margin)
	parent_control.add_child(vbox_container)

	# Title panel
	var title_panel = PanelContainer.new()
	var title_style = StyleBoxFlat.new()
	title_style.bg_color = Color("#3d3d3d") # Slightly lighter than background
	title_style.set_corner_radius_all(12) # INCREASED corners
	# Add padding inside the panel
	title_style.content_margin_top = 16
	title_style.content_margin_bottom = 16
	title_style.content_margin_left = 16
	title_style.content_margin_right = 16
	title_panel.add_theme_stylebox_override("panel", title_style)
	title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_container.add_child(title_panel)

	var title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Playcademy Template"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36) # INCREASED font size
	title_label.add_theme_color_override("font_color", Color("#ffffff"))
	title_panel.add_child(title_label)

	# Status Panel - Using a panel with styling for a better look
	var status_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#363636")
	panel_style.set_corner_radius_all(12) # INCREASED corners
	# Add padding inside the panel
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	status_panel.add_theme_stylebox_override("panel", panel_style)
	status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_container.add_child(status_panel)

	var status_vbox = VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 12) # INCREASED separation
	status_panel.add_child(status_vbox)

	# SDK Status with icon indicator
	var status_hbox = HBoxContainer.new()
	status_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	status_hbox.add_theme_constant_override("separation", 16) # INCREASED separation
	status_vbox.add_child(status_hbox)

	# Create a status indicator (circular panel) - INCREASED size
	var status_indicator = Panel.new()
	status_indicator.name = "StatusIndicator"
	status_indicator.custom_minimum_size = Vector2(24, 24) # INCREASED size
	status_indicator.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	status_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var indicator_style = StyleBoxFlat.new()
	indicator_style.bg_color = Color("#f9a825") # Amber/yellow for initializing
	indicator_style.set_corner_radius_all(12) # Makes it a circle
	status_indicator.add_theme_stylebox_override("panel", indicator_style)
	status_hbox.add_child(status_indicator)

	var sdk_status_label = Label.new()
	sdk_status_label.name = "SDKStatusLabel"
	sdk_status_label.text = "SDK Status: Initializing..."
	sdk_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sdk_status_label.add_theme_font_size_override("font_size", 24) # INCREASED font size
	status_hbox.add_child(sdk_status_label)

	var user_info_label = Label.new()
	user_info_label.name = "UserInfoLabel"
	user_info_label.text = "No user data yet - click 'Get User' to fetch"
	user_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	user_info_label.add_theme_font_size_override("font_size", 20) # INCREASED font size
	status_vbox.add_child(user_info_label)

	# Inventory Section with ScrollContainer for potentially long content
	var inventory_section = VBoxContainer.new()
	inventory_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_section.add_theme_constant_override("separation", 12) # INCREASED separation
	vbox_container.add_child(inventory_section)

	var inventory_panel = PanelContainer.new()
	var inventory_style = StyleBoxFlat.new()
	inventory_style.bg_color = Color("#363636")
	inventory_style.set_corner_radius_all(12) # INCREASED corners
	# Add padding inside the panel
	inventory_style.content_margin_top = 16
	inventory_style.content_margin_bottom = 16
	inventory_style.content_margin_left = 16
	inventory_style.content_margin_right = 16
	inventory_panel.add_theme_stylebox_override("panel", inventory_style)
	inventory_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_section.add_child(inventory_panel)

	var inventory_vbox = VBoxContainer.new()
	inventory_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_panel.add_child(inventory_vbox)

	var inventory_title = Label.new()
	inventory_title.text = "Inventory"
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_title.add_theme_font_size_override("font_size", 24) # INCREASED font size
	inventory_title.add_theme_color_override("font_color", Color("#bbdefb")) # Light blue title
	inventory_vbox.add_child(inventory_title)

	var scroll_container = ScrollContainer.new()
	scroll_container.name = "InventoryScrollContainer"
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0, 120) # REDUCED height to avoid excessive spacing
	inventory_vbox.add_child(scroll_container)

	var inventory_label = Label.new()
	inventory_label.name = "InventoryLabel"
	inventory_label.text = "No items to display - click 'Get Inventory' to fetch"
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	inventory_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_label.add_theme_font_size_override("font_size", 20) # INCREASED font size
	inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scroll_container.add_child(inventory_label)

	# API Result Panel
	var result_panel = PanelContainer.new()
	var result_style = StyleBoxFlat.new()
	result_style.bg_color = Color("#363636")
	result_style.set_corner_radius_all(12) # INCREASED corners
	# Add padding inside the panel
	result_style.content_margin_top = 16
	result_style.content_margin_bottom = 16
	result_style.content_margin_left = 16
	result_style.content_margin_right = 16
	result_panel.add_theme_stylebox_override("panel", result_style)
	result_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_container.add_child(result_panel)

	var api_result_label = Label.new()
	api_result_label.name = "APIResultLabel"
	api_result_label.text = "Ready for API interactions"
	api_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	api_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	api_result_label.add_theme_font_size_override("font_size", 20) # INCREASED font size
	result_panel.add_child(api_result_label)

	# Action Buttons Panel
	var button_panel = PanelContainer.new()
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("#363636") 
	button_style.set_corner_radius_all(12) # INCREASED corners
	# Add padding inside the panel
	button_style.content_margin_top = 16
	button_style.content_margin_bottom = 16
	button_style.content_margin_left = 16
	button_style.content_margin_right = 16
	button_panel.add_theme_stylebox_override("panel", button_style)
	button_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_container.add_child(button_panel)
	
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 16) # INCREASED separation
	button_panel.add_child(button_vbox)
	
	var button_label = Label.new()
	button_label.text = "Actions"
	button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_label.add_theme_font_size_override("font_size", 24) # INCREASED font size
	button_label.add_theme_color_override("font_color", Color("#bbdefb")) # Light blue title
	button_vbox.add_child(button_label)

	var hbox_buttons = HBoxContainer.new()
	hbox_buttons.name = "ButtonHBox"
	hbox_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_buttons.add_theme_constant_override("separation", 20) # INCREASED separation
	button_vbox.add_child(hbox_buttons)

	# Create styled buttons with INCREASED size
	var get_user_button = Button.new()
	get_user_button.name = "GetUserButton"
	get_user_button.text = "Get User"
	_style_button(get_user_button, Color("#4CAF50")) # Green
	hbox_buttons.add_child(get_user_button)

	var get_inventory_button = Button.new()
	get_inventory_button.name = "GetInventoryButton"
	get_inventory_button.text = "Get Inventory"
	_style_button(get_inventory_button, Color("#2196F3")) # Blue
	hbox_buttons.add_child(get_inventory_button)

	var grant_item_button = Button.new()
	grant_item_button.name = "GrantItemButton"
	grant_item_button.text = "Grant Item"
	_style_button(grant_item_button, Color("#FFC107")) # Amber
	hbox_buttons.add_child(grant_item_button)

	var spend_item_button = Button.new()
	spend_item_button.name = "SpendItemButton"
	spend_item_button.text = "Spend Item"
	_style_button(spend_item_button, Color("#FF5722")) # Deep Orange
	hbox_buttons.add_child(spend_item_button)

	var exit_button = Button.new()
	exit_button.name = "ExitButton"
	exit_button.text = "Exit Game"
	_style_button(exit_button, Color("#F44336")) # Red for exit
	hbox_buttons.add_child(exit_button)

	print("[UISetup] Scene UI setup complete.")
	
	# Return a dictionary with references to all the created UI elements
	return {
		"sdk_status_label": sdk_status_label,
		"user_info_label": user_info_label,
		"inventory_label": inventory_label,
		"api_result_label": api_result_label,
		"get_user_button": get_user_button,
		"get_inventory_button": get_inventory_button,
		"grant_item_button": grant_item_button,
		"spend_item_button": spend_item_button,
		"status_indicator": status_indicator,
		"exit_button": exit_button
	}

# Find existing UI elements when the UI has already been created
static func _find_existing_ui_elements(parent_control: Control) -> Dictionary:
	var root_node = parent_control.get_node(UI_ROOT_NODE_NAME)
	var button_hbox = root_node.get_node_or_null("ButtonHBox")
	
	if not button_hbox:
		var button_panel = root_node.get_node_or_null("ButtonPanel/VBoxContainer")
		if button_panel:
			button_hbox = button_panel.get_node_or_null("ButtonHBox")

	return {
		"sdk_status_label": root_node.get_node_or_null("StatusIndicator/SDKStatusLabel"),
		"user_info_label": root_node.get_node_or_null("StatusPanel/VBoxContainer/UserInfoLabel"),
		"inventory_label": root_node.get_node_or_null("InventorySection/InventoryPanel/VBoxContainer/InventoryScrollContainer/InventoryLabel"),
		"api_result_label": root_node.get_node_or_null("ResultPanel/APIResultLabel"),
		"get_user_button": button_hbox.get_node_or_null("GetUserButton") if button_hbox else null,
		"get_inventory_button": button_hbox.get_node_or_null("GetInventoryButton") if button_hbox else null,
		"grant_item_button": button_hbox.get_node_or_null("GrantItemButton") if button_hbox else null,
		"spend_item_button": button_hbox.get_node_or_null("SpendItemButton") if button_hbox else null,
		"status_indicator": root_node.get_node_or_null("StatusIndicator"),
		"exit_button": button_hbox.get_node_or_null("ExitButton") if button_hbox else null
	}

# Helper function to style a button
static func _style_button(button: Button, color: Color):
	# Normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = color
	normal_style.set_corner_radius_all(8)
	# INCREASED padding
	normal_style.content_margin_top = 12
	normal_style.content_margin_bottom = 12
	normal_style.content_margin_left = 16
	normal_style.content_margin_right = 16
	
	# Hover state
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = color.lightened(0.1) # Lighter
	hover_style.set_corner_radius_all(8)
	# INCREASED padding
	hover_style.content_margin_top = 12
	hover_style.content_margin_bottom = 12
	hover_style.content_margin_left = 16
	hover_style.content_margin_right = 16
	
	# Pressed state
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = color.darkened(0.2) # Darker
	pressed_style.set_corner_radius_all(8)
	# INCREASED padding
	pressed_style.content_margin_top = 12
	pressed_style.content_margin_bottom = 12
	pressed_style.content_margin_left = 16
	pressed_style.content_margin_right = 16
	
	# Disabled state
	var disabled_style = StyleBoxFlat.new()
	disabled_style.bg_color = Color("#78909C") # Bluish gray
	disabled_style.set_corner_radius_all(8)
	# INCREASED padding
	disabled_style.content_margin_top = 12
	disabled_style.content_margin_bottom = 12
	disabled_style.content_margin_left = 16
	disabled_style.content_margin_right = 16
	
	button.add_theme_font_size_override("font_size", 18) # INCREASED font size
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.5))
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.custom_minimum_size = Vector2(150, 0) # INCREASED minimum width 
