extends Node

# Helper class to set up the UI for the Playcademy SDK demo
class_name UISetup

const UI_ROOT_NODE_NAME = "MainVBoxContainer"

# Sets up the entire UI programmatically for the Playcademy SDK demo
static func setup_scene_ui(parent_control: Control, config_values: Dictionary) -> Dictionary:
	if parent_control.find_child(UI_ROOT_NODE_NAME, false, false) != null:
		return _find_existing_ui_elements(parent_control)

	parent_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style = StyleBoxFlat.new(); style.bg_color = Color("#2e2e2e"); parent_control.add_theme_stylebox_override("panel", style)

	var vbox_container = VBoxContainer.new(); vbox_container.name = UI_ROOT_NODE_NAME
	vbox_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox_container.add_theme_constant_override("separation", 20)
	var margin = 20; vbox_container.set("theme_override_constants/margin_left", margin); vbox_container.set("theme_override_constants/margin_right", margin); vbox_container.set("theme_override_constants/margin_top", margin); vbox_container.set("theme_override_constants/margin_bottom", margin)
	parent_control.add_child(vbox_container)

	# --- Title Panel ---
	var title_panel = PanelContainer.new(); var ts = StyleBoxFlat.new(); ts.bg_color = Color("#3d3d3d"); ts.set_corner_radius_all(12); ts.content_margin_top = 16; ts.content_margin_bottom = 16; ts.content_margin_left = 16; ts.content_margin_right = 16; title_panel.add_theme_stylebox_override("panel", ts); title_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vbox_container.add_child(title_panel)
	var title_label = Label.new(); title_label.text = "Playcademy Template"; title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.add_theme_font_size_override("font_size", 36); title_panel.add_child(title_label)

	# --- SDK & User Info Panel ---
	var sdk_user_panel = PanelContainer.new(); var sup_style = StyleBoxFlat.new(); sup_style.bg_color = Color("#363636"); sup_style.set_corner_radius_all(12); sup_style.content_margin_top = 16; sup_style.content_margin_bottom = 16; sup_style.content_margin_left = 16; sup_style.content_margin_right = 16; sdk_user_panel.add_theme_stylebox_override("panel", sup_style); sdk_user_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vbox_container.add_child(sdk_user_panel)
	var sdk_user_vbox = VBoxContainer.new(); sdk_user_vbox.add_theme_constant_override("separation", 12); sdk_user_panel.add_child(sdk_user_vbox)

	var status_hbox = HBoxContainer.new(); status_hbox.alignment = BoxContainer.ALIGNMENT_CENTER; status_hbox.add_theme_constant_override("separation", 16); sdk_user_vbox.add_child(status_hbox)
	var status_indicator = Panel.new(); status_indicator.name = "StatusIndicator"; status_indicator.custom_minimum_size = Vector2(24, 24); status_indicator.size_flags_horizontal = Control.SIZE_SHRINK_CENTER; status_indicator.size_flags_vertical = Control.SIZE_SHRINK_CENTER; var ind_style = StyleBoxFlat.new(); ind_style.bg_color = Color("#f9a825"); ind_style.set_corner_radius_all(12); status_indicator.add_theme_stylebox_override("panel", ind_style); status_hbox.add_child(status_indicator)
	var sdk_status_label = Label.new(); sdk_status_label.name = "SDKStatusLabel"; sdk_status_label.text = "SDK Status: Initializing..."; sdk_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; sdk_status_label.add_theme_font_size_override("font_size", 24); status_hbox.add_child(sdk_status_label)
	var user_info_label = Label.new(); user_info_label.name = "UserInfoLabel"; user_info_label.text = "No user data yet - click 'Get User' to fetch"; user_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; user_info_label.add_theme_font_size_override("font_size", 20); sdk_user_vbox.add_child(user_info_label)

	# --- Currency & Unlocks Panel ---
	var currency_unlocks_panel = PanelContainer.new(); var cu_style = StyleBoxFlat.new(); cu_style.bg_color = Color("#363636"); cu_style.set_corner_radius_all(12); cu_style.content_margin_top = 16; cu_style.content_margin_bottom = 16; cu_style.content_margin_left = 16; cu_style.content_margin_right = 16; currency_unlocks_panel.add_theme_stylebox_override("panel", cu_style); currency_unlocks_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vbox_container.add_child(currency_unlocks_panel)
	var currency_unlocks_vbox = VBoxContainer.new(); currency_unlocks_vbox.name = "CurrencyUnlocksVBox"; currency_unlocks_vbox.add_theme_constant_override("separation", 12); currency_unlocks_panel.add_child(currency_unlocks_vbox)

	var inventory_title_label = Label.new(); inventory_title_label.text = "Inventory"; inventory_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; inventory_title_label.add_theme_font_size_override("font_size", 24); inventory_title_label.add_theme_color_override("font_color", Color("#bbdefb")); currency_unlocks_vbox.add_child(inventory_title_label)
	var inventory_label = Label.new(); inventory_label.name = "InventoryLabel"; inventory_label.text = "Currency: ---"; inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; inventory_label.add_theme_font_size_override("font_size", 20); currency_unlocks_vbox.add_child(inventory_label)

	var feature_tiers_vbox = VBoxContainer.new(); feature_tiers_vbox.name = "FeatureTiersVBox"; feature_tiers_vbox.add_theme_constant_override("separation", 6); currency_unlocks_vbox.add_child(feature_tiers_vbox)
	var feature_tier_labels_dict: Dictionary = {}
	var feature_tiers_data = config_values.get("feature_tiers", [])
	for tier_data in feature_tiers_data:
		var tier_label = Label.new(); tier_label.name = tier_data.label_node_name_in_setup; tier_label.text = "%s: Locked (Requires %s Credits)" % [tier_data.name, tier_data.cost]; tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; tier_label.add_theme_font_size_override("font_size", 18); tier_label.add_theme_color_override("font_color", Color("#FFCDD2")); feature_tiers_vbox.add_child(tier_label)
		feature_tier_labels_dict[tier_data.label_node_name_in_setup] = tier_label

	# --- API Result Panel ---
	var result_panel = PanelContainer.new(); var res_style = StyleBoxFlat.new(); res_style.bg_color = Color("#363636"); res_style.set_corner_radius_all(12); res_style.content_margin_top = 16; res_style.content_margin_bottom = 16; res_style.content_margin_left = 16; res_style.content_margin_right = 16; result_panel.add_theme_stylebox_override("panel", res_style); result_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vbox_container.add_child(result_panel)
	var api_result_label = Label.new(); api_result_label.name = "APIResultLabel"; api_result_label.text = "Ready for API interactions"; api_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; api_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD; api_result_label.add_theme_font_size_override("font_size", 20); result_panel.add_child(api_result_label)

	# --- Action Buttons Panel ---
	var button_panel = PanelContainer.new(); var btn_panel_style = StyleBoxFlat.new(); btn_panel_style.bg_color = Color("#363636"); btn_panel_style.set_corner_radius_all(12); btn_panel_style.content_margin_top = 16; btn_panel_style.content_margin_bottom = 16; btn_panel_style.content_margin_left = 16; btn_panel_style.content_margin_right = 16; button_panel.add_theme_stylebox_override("panel", btn_panel_style); button_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL; vbox_container.add_child(button_panel)
	var button_vbox = VBoxContainer.new(); button_vbox.add_theme_constant_override("separation", 16); button_panel.add_child(button_vbox)
	var button_actions_label = Label.new(); button_actions_label.text = "Actions"; button_actions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; button_actions_label.add_theme_font_size_override("font_size", 24); button_actions_label.add_theme_color_override("font_color", Color("#bbdefb")); button_vbox.add_child(button_actions_label)
	var hbox_buttons = HBoxContainer.new(); hbox_buttons.name = "ButtonHBox"; hbox_buttons.alignment = BoxContainer.ALIGNMENT_CENTER; hbox_buttons.add_theme_constant_override("separation", 20); button_vbox.add_child(hbox_buttons)

	var get_user_button = Button.new(); get_user_button.name = "GetUserButton"; get_user_button.text = "Get User"; _style_button(get_user_button, Color("#4CAF50")); hbox_buttons.add_child(get_user_button)
	var get_inventory_button = Button.new(); get_inventory_button.name = "GetInventoryButton"; get_inventory_button.text = "Get Inventory"; _style_button(get_inventory_button, Color("#2196F3")); hbox_buttons.add_child(get_inventory_button)
	var grant_item_button = Button.new(); grant_item_button.name = "GrantItemButton"; grant_item_button.text = "Grant %s Credits" % config_values.get("currency_grant_amount", 10); _style_button(grant_item_button, Color("#FFC107")); hbox_buttons.add_child(grant_item_button)
	var spend_item_button = Button.new(); spend_item_button.name = "SpendItemButton"; spend_item_button.text = "Spend %s Credits" % config_values.get("currency_spend_amount", 10); _style_button(spend_item_button, Color("#FF5722")); hbox_buttons.add_child(spend_item_button)
	var exit_button = Button.new(); exit_button.name = "ExitButton"; exit_button.text = "Exit Game"; _style_button(exit_button, Color("#F44336")); hbox_buttons.add_child(exit_button)

	return {
		"sdk_status_label": sdk_status_label, "user_info_label": user_info_label, "inventory_label": inventory_label, 
		"api_result_label": api_result_label, "get_user_button": get_user_button, "get_inventory_button": get_inventory_button,
		"grant_item_button": grant_item_button, "spend_item_button": spend_item_button, "status_indicator": status_indicator,
		"exit_button": exit_button, "feature_tier_labels": feature_tier_labels_dict
	}

# Find existing UI elements when the UI has already been created
static func _find_existing_ui_elements(parent_control: Control) -> Dictionary:
	var root = parent_control.get_node(UI_ROOT_NODE_NAME)
	var sdk_user_vbox = root.get_node_or_null("SdkUserPanel/SdkUserVBox") # Path needs to be based on new panel names
	var currency_unlocks_vbox = root.get_node_or_null("CurrencyUnlocksPanel/CurrencyUnlocksVBox")
	var feature_tiers_vbox = currency_unlocks_vbox.get_node_or_null("FeatureTiersVBox") if currency_unlocks_vbox else null
	var button_hbox = root.get_node_or_null("ButtonPanel/VBoxContainer/ButtonHBox") # Assuming this structure is stable for buttons

	var found_feature_labels: Dictionary = {}
	if feature_tiers_vbox and Engine.has_singleton("Main"):
		var main = Engine.get_singleton("Main")
		for tier_data in main.FEATURE_TIERS:
			var label = feature_tiers_vbox.get_node_or_null(tier_data.label_node_name_in_setup)
			if label: found_feature_labels[tier_data.label_node_name_in_setup] = label
	
	return {
		"sdk_status_label": sdk_user_vbox.get_node_or_null("StatusHBox/SDKStatusLabel") if sdk_user_vbox else null,
		"user_info_label": sdk_user_vbox.get_node_or_null("UserInfoLabel") if sdk_user_vbox else null,
		"inventory_label": currency_unlocks_vbox.get_node_or_null("InventoryLabel") if currency_unlocks_vbox else null,
		"api_result_label": root.get_node_or_null("ResultPanel/APIResultLabel"),
		"get_user_button": button_hbox.get_node_or_null("GetUserButton") if button_hbox else null,
		"get_inventory_button": button_hbox.get_node_or_null("GetInventoryButton") if button_hbox else null,
		"grant_item_button": button_hbox.get_node_or_null("GrantItemButton") if button_hbox else null,
		"spend_item_button": button_hbox.get_node_or_null("SpendItemButton") if button_hbox else null,
		"status_indicator": sdk_user_vbox.get_node_or_null("StatusHBox/StatusIndicator") if sdk_user_vbox else null,
		"exit_button": button_hbox.get_node_or_null("ExitButton") if button_hbox else null,
		"feature_tier_labels": found_feature_labels
	}

# Helper function to style a button
static func _style_button(button: Button, color: Color):
	var ns = StyleBoxFlat.new(); ns.bg_color = color; ns.set_corner_radius_all(8); ns.content_margin_top = 12; ns.content_margin_bottom = 12; ns.content_margin_left = 16; ns.content_margin_right = 16
	var hs = StyleBoxFlat.new(); hs.bg_color = color.lightened(0.1); hs.set_corner_radius_all(8); hs.content_margin_top = 12; hs.content_margin_bottom = 12; hs.content_margin_left = 16; hs.content_margin_right = 16
	var ps = StyleBoxFlat.new(); ps.bg_color = color.darkened(0.2); ps.set_corner_radius_all(8); ps.content_margin_top = 12; ps.content_margin_bottom = 12; ps.content_margin_left = 16; ps.content_margin_right = 16
	var ds = StyleBoxFlat.new(); ds.bg_color = Color("#78909C"); ds.set_corner_radius_all(8); ds.content_margin_top = 12; ds.content_margin_bottom = 12; ds.content_margin_left = 16; ds.content_margin_right = 16
	button.add_theme_font_size_override("font_size", 18); button.add_theme_color_override("font_color", Color.WHITE); button.add_theme_color_override("font_disabled_color", Color(1,1,1,0.5)); button.add_theme_stylebox_override("normal", ns); button.add_theme_stylebox_override("hover", hs); button.add_theme_stylebox_override("pressed", ps); button.add_theme_stylebox_override("disabled", ds); button.custom_minimum_size = Vector2(150,0)
