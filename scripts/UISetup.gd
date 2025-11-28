extends Node

# Helper class to set up the UI for the Playcademy SDK demo
class_name UISetup

const UI_ROOT_NODE_NAME = "GameHUD"

# Color palette - Clean dark theme
const COLORS = {
	"bg_dark": Color("#0d1117"),
	"bg_panel": Color("#161b22"),
	"bg_card": Color("#21262d"),
	"bg_input": Color("#0d1117"),
	"border": Color("#30363d"),
	"accent_blue": Color("#58a6ff"),
	"accent_green": Color("#3fb950"),
	"accent_red": Color("#f85149"),
	"accent_orange": Color("#d29922"),
	"accent_purple": Color("#a371f7"),
	"accent_gold": Color("#e3b341"),
	"text_primary": Color("#f0f6fc"),
	"text_secondary": Color("#8b949e"),
	"text_muted": Color("#484f58"),
}

static func setup_scene_ui(parent_control: Control, config_values: Dictionary) -> Dictionary:
	if parent_control.find_child(UI_ROOT_NODE_NAME, false, false) != null:
		return _find_existing_ui_elements(parent_control)

	parent_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = COLORS.bg_dark
	parent_control.add_theme_stylebox_override("panel", bg_style)

	# Main container with margin
	var margin = MarginContainer.new()
	margin.name = UI_ROOT_NODE_NAME
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	parent_control.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 20)
	margin.add_child(main_vbox)

	# ═══════════════════════════════════════════════════════════════════
	# HEADER
	# ═══════════════════════════════════════════════════════════════════
	var header = _create_header()
	main_vbox.add_child(header.container)

	# ═══════════════════════════════════════════════════════════════════
	# MAIN CONTENT - 2x2 Grid
	# ═══════════════════════════════════════════════════════════════════
	var content_grid = GridContainer.new()
	content_grid.columns = 2
	content_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_grid.add_theme_constant_override("h_separation", 20)
	content_grid.add_theme_constant_override("v_separation", 20)
	main_vbox.add_child(content_grid)

	# Card 1: Player
	var player_card = _create_player_card()
	player_card.container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_card.container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_grid.add_child(player_card.container)

	# Card 2: TimeBack
	var timeback_card = _create_timeback_card()
	timeback_card.container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeback_card.container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_grid.add_child(timeback_card.container)

	# Card 3: Wallet
	var wallet_card = _create_wallet_card(config_values)
	wallet_card.container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wallet_card.container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_grid.add_child(wallet_card.container)

	# Card 4: Actions
	var actions_card = _create_actions_card()
	actions_card.container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions_card.container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_grid.add_child(actions_card.container)

	# ═══════════════════════════════════════════════════════════════════
	# FOOTER - Console output
	# ═══════════════════════════════════════════════════════════════════
	var footer = _create_footer()
	main_vbox.add_child(footer.container)

	# Create user details modal (hidden by default)
	var user_modal = _create_user_details_modal(parent_control)

	return {
		"sdk_status_label": header.status_label,
		"status_indicator": header.status_indicator,
		"user_info_label": player_card.user_label,
		"view_user_details_button": player_card.details_button,
		"user_details_modal": user_modal.modal,
		"user_details_content": user_modal.content,
		"user_details_close_button": user_modal.close_button,
		"inventory_label": wallet_card.balance_label,
		"api_result_label": footer.result_label,
		"get_inventory_button": wallet_card.refresh_button,
		"grant_item_button": wallet_card.add_button,
		"remove_item_button": wallet_card.spend_button,
		"call_backend_button": actions_card.backend_button,
		"exit_button": actions_card.exit_button,
		"timeback_role_label": timeback_card.role_label,
		"timeback_enrollments_container": timeback_card.enrollments_container,
		"timeback_refresh_button": timeback_card.refresh_button,
	}

# ═══════════════════════════════════════════════════════════════════════════════
# COMPONENT BUILDERS
# ═══════════════════════════════════════════════════════════════════════════════

static func _create_header() -> Dictionary:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 16)

	# Logo/Title area
	var title_hbox = HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 12)
	container.add_child(title_hbox)

	# Status indicator dot
	var indicator = Panel.new()
	indicator.name = "StatusIndicator"
	indicator.custom_minimum_size = Vector2(10, 10)
	var ind_style = StyleBoxFlat.new()
	ind_style.bg_color = COLORS.accent_orange
	ind_style.set_corner_radius_all(5)
	indicator.add_theme_stylebox_override("panel", ind_style)
	title_hbox.add_child(indicator)

	# Title
	var title = Label.new()
	title.text = "PLAYCADEMY DEMO"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLORS.text_primary)
	title_hbox.add_child(title)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(spacer)

	# Status label
	var status_label = Label.new()
	status_label.name = "SDKStatusLabel"
	status_label.text = "INITIALIZING..."
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", COLORS.text_muted)
	container.add_child(status_label)

	return {
		"container": container,
		"status_label": status_label,
		"status_indicator": indicator,
	}

static func _create_player_card() -> Dictionary:
	var card = _create_card("PLAYER")
	var content = card.content

	# Center content vertically
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)

	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 16)
	center.add_child(inner_vbox)

	# Avatar + Info row
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 16)
	info_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(info_hbox)

	# Avatar circle
	var avatar = Panel.new()
	avatar.custom_minimum_size = Vector2(56, 56)
	var av_style = StyleBoxFlat.new()
	av_style.bg_color = COLORS.accent_purple.darkened(0.4)
	av_style.set_corner_radius_all(28)
	avatar.add_theme_stylebox_override("panel", av_style)
	info_hbox.add_child(avatar)

	# Avatar icon
	var avatar_icon = Label.new()
	avatar_icon.text = "U"
	avatar_icon.add_theme_font_size_override("font_size", 24)
	avatar_icon.add_theme_color_override("font_color", COLORS.accent_purple)
	avatar_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.add_child(avatar_icon)

	# User name label
	var user_label = Label.new()
	user_label.name = "UserInfoLabel"
	user_label.text = "Loading..."
	user_label.add_theme_font_size_override("font_size", 18)
	user_label.add_theme_color_override("font_color", COLORS.text_primary)
	info_hbox.add_child(user_label)

	# View details button
	var details_button = _create_button("VIEW DETAILS", COLORS.accent_purple)
	details_button.name = "ViewUserDetailsButton"
	inner_vbox.add_child(details_button)

	return {
		"container": card.container,
		"user_label": user_label,
		"details_button": details_button,
	}

static func _create_wallet_card(config_values: Dictionary) -> Dictionary:
	var card = _create_card("WALLET")
	var content = card.content

	# Center content
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)

	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 20)
	center.add_child(inner_vbox)

	# Balance display
	var balance_hbox = HBoxContainer.new()
	balance_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	balance_hbox.add_theme_constant_override("separation", 8)
	inner_vbox.add_child(balance_hbox)

	# Coin icon (circle)
	var coin = Panel.new()
	coin.custom_minimum_size = Vector2(32, 32)
	var coin_style = StyleBoxFlat.new()
	coin_style.bg_color = COLORS.accent_gold
	coin_style.set_corner_radius_all(16)
	coin.add_theme_stylebox_override("panel", coin_style)
	balance_hbox.add_child(coin)

	var balance_label = Label.new()
	balance_label.name = "InventoryLabel"
	balance_label.text = "---"
	balance_label.add_theme_font_size_override("font_size", 40)
	balance_label.add_theme_color_override("font_color", COLORS.text_primary)
	balance_hbox.add_child(balance_label)

	var credits_label = Label.new()
	credits_label.text = "credits"
	credits_label.add_theme_font_size_override("font_size", 14)
	credits_label.add_theme_color_override("font_color", COLORS.text_secondary)
	balance_hbox.add_child(credits_label)

	# Buttons row
	var buttons_hbox = HBoxContainer.new()
	buttons_hbox.add_theme_constant_override("separation", 12)
	inner_vbox.add_child(buttons_hbox)

	var add_button = _create_button("+%d" % config_values.get("currency_grant_amount", 50), COLORS.accent_green)
	add_button.name = "GrantItemButton"
	add_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons_hbox.add_child(add_button)

	var spend_button = _create_button("-%d" % config_values.get("currency_remove_amount", 50), COLORS.accent_red)
	spend_button.name = "RemoveItemButton"
	spend_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons_hbox.add_child(spend_button)

	var refresh_button = _create_button("...", COLORS.text_muted)
	refresh_button.name = "GetInventoryButton"
	refresh_button.custom_minimum_size.x = 50
	buttons_hbox.add_child(refresh_button)

	return {
		"container": card.container,
		"balance_label": balance_label,
		"add_button": add_button,
		"spend_button": spend_button,
		"refresh_button": refresh_button,
	}

static func _create_timeback_card() -> Dictionary:
	var card = _create_card("TIMEBACK")
	var content = card.content

	# Role section
	var role_panel = PanelContainer.new()
	role_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rp_style = StyleBoxFlat.new()
	rp_style.bg_color = COLORS.bg_input
	rp_style.set_corner_radius_all(6)
	rp_style.border_color = COLORS.border
	rp_style.set_border_width_all(1)
	role_panel.add_theme_stylebox_override("panel", rp_style)
	content.add_child(role_panel)

	var role_margin = MarginContainer.new()
	role_margin.add_theme_constant_override("margin_left", 12)
	role_margin.add_theme_constant_override("margin_right", 12)
	role_margin.add_theme_constant_override("margin_top", 10)
	role_margin.add_theme_constant_override("margin_bottom", 10)
	role_panel.add_child(role_margin)

	var role_hbox = HBoxContainer.new()
	role_hbox.add_theme_constant_override("separation", 12)
	role_margin.add_child(role_hbox)

	# Role indicator
	var role_indicator = Panel.new()
	role_indicator.custom_minimum_size = Vector2(4, 0)
	role_indicator.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var ri_style = StyleBoxFlat.new()
	ri_style.bg_color = COLORS.accent_purple
	ri_style.set_corner_radius_all(2)
	role_indicator.add_theme_stylebox_override("panel", ri_style)
	role_hbox.add_child(role_indicator)

	var role_info = VBoxContainer.new()
	role_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	role_info.add_theme_constant_override("separation", 2)
	role_hbox.add_child(role_info)

	var role_title = Label.new()
	role_title.text = "Role"
	role_title.add_theme_font_size_override("font_size", 11)
	role_title.add_theme_color_override("font_color", COLORS.text_muted)
	role_info.add_child(role_title)

	var role_label = Label.new()
	role_label.name = "TimebackRoleLabel"
	role_label.text = "---"
	role_label.add_theme_font_size_override("font_size", 16)
	role_label.add_theme_color_override("font_color", COLORS.text_primary)
	role_info.add_child(role_label)

	# Enrollments section
	var enrollments_title = Label.new()
	enrollments_title.text = "Enrollments"
	enrollments_title.add_theme_font_size_override("font_size", 11)
	enrollments_title.add_theme_color_override("font_color", COLORS.text_muted)
	content.add_child(enrollments_title)

	var enrollments_container = VBoxContainer.new()
	enrollments_container.name = "EnrollmentsContainer"
	enrollments_container.add_theme_constant_override("separation", 6)
	content.add_child(enrollments_container)

	# Placeholder for no enrollments
	var no_enrollments = Label.new()
	no_enrollments.name = "NoEnrollmentsLabel"
	no_enrollments.text = "No enrollments"
	no_enrollments.add_theme_font_size_override("font_size", 12)
	no_enrollments.add_theme_color_override("font_color", COLORS.text_muted)
	enrollments_container.add_child(no_enrollments)

	# Refresh button
	var refresh_button = _create_button("REFRESH", COLORS.accent_purple)
	refresh_button.name = "TimebackRefreshButton"
	content.add_child(refresh_button)

	return {
		"container": card.container,
		"role_label": role_label,
		"enrollments_container": enrollments_container,
		"refresh_button": refresh_button,
	}

static func _create_actions_card() -> Dictionary:
	var card = _create_card("ACTIONS")
	var content = card.content

	# Center content
	var center = CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)

	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 12)
	center.add_child(inner_vbox)

	var backend_button = _create_button("CALL BACKEND API", COLORS.accent_blue)
	backend_button.name = "CallBackendButton"
	backend_button.custom_minimum_size.x = 200
	inner_vbox.add_child(backend_button)

	var exit_button = _create_button("EXIT GAME", COLORS.accent_red.darkened(0.2))
	exit_button.name = "ExitButton"
	exit_button.custom_minimum_size.x = 200
	inner_vbox.add_child(exit_button)

	return {
		"container": card.container,
		"backend_button": backend_button,
		"exit_button": exit_button,
	}

static func _create_footer() -> Dictionary:
	var container = PanelContainer.new()
	container.custom_minimum_size.y = 44
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS.bg_panel
	style.set_corner_radius_all(6)
	style.border_color = COLORS.border
	style.set_border_width_all(1)
	container.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	container.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	var prompt = Label.new()
	prompt.text = ">"
	prompt.add_theme_font_size_override("font_size", 13)
	prompt.add_theme_color_override("font_color", COLORS.accent_green)
	hbox.add_child(prompt)

	var result_label = Label.new()
	result_label.name = "APIResultLabel"
	result_label.text = "Ready for API interactions..."
	result_label.add_theme_font_size_override("font_size", 13)
	result_label.add_theme_color_override("font_color", COLORS.text_secondary)
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(result_label)

	return {
		"container": container,
		"result_label": result_label,
	}

static func _create_user_details_modal(parent: Control) -> Dictionary:
	# Overlay background
	var modal = ColorRect.new()
	modal.name = "UserDetailsModal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.color = Color(0, 0, 0, 0.7)
	modal.visible = false
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(modal)

	# Center container
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)

	# Modal panel - auto-sizes to content
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLORS.bg_card
	panel_style.set_corner_radius_all(12)
	panel_style.border_color = COLORS.border
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Header row
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 400)  # Push close button to right
	vbox.add_child(header)

	var title = Label.new()
	title.text = "USER DETAILS"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", COLORS.text_muted)
	header.add_child(title)

	var close_button = Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(32, 32)
	var close_style = StyleBoxFlat.new()
	close_style.bg_color = COLORS.bg_input
	close_style.set_corner_radius_all(4)
	close_button.add_theme_stylebox_override("normal", close_style)
	var close_hover = close_style.duplicate()
	close_hover.bg_color = COLORS.accent_red.darkened(0.5)
	close_button.add_theme_stylebox_override("hover", close_hover)
	close_button.add_theme_font_size_override("font_size", 12)
	close_button.add_theme_color_override("font_color", COLORS.text_secondary)
	header.add_child(close_button)

	# Content - just a label, no scroll needed
	var content = Label.new()
	content.name = "UserDetailsContent"
	content.text = "Loading..."
	content.add_theme_font_size_override("font_size", 13)
	content.add_theme_color_override("font_color", COLORS.text_secondary)
	vbox.add_child(content)

	return {
		"modal": modal,
		"content": content,
		"close_button": close_button,
	}

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

static func _create_card(title: String) -> Dictionary:
	var container = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = COLORS.bg_card
	style.set_corner_radius_all(8)
	style.border_color = COLORS.border
	style.set_border_width_all(1)
	container.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 20)
	container.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	# Title row
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", COLORS.text_muted)
	vbox.add_child(title_label)

	# Content container (caller will add to this)
	var content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	vbox.add_child(content)

	return {
		"container": container,
		"content": content,
	}

static func _create_button(text: String, color: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 36

	var normal = StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.5)
	normal.set_corner_radius_all(6)
	normal.border_color = color.darkened(0.2)
	normal.set_border_width_all(1)

	var hover = normal.duplicate()
	hover.bg_color = color.darkened(0.3)

	var pressed = normal.duplicate()
	pressed.bg_color = color.darkened(0.6)

	var disabled = normal.duplicate()
	disabled.bg_color = COLORS.bg_input
	disabled.border_color = COLORS.border

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", COLORS.text_primary)
	button.add_theme_color_override("font_disabled_color", COLORS.text_muted)

	return button

static func _find_existing_ui_elements(parent_control: Control) -> Dictionary:
	return {}
