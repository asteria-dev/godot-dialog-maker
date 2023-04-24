extends Control

#debug purposes
var dialog_for_localisation := []

var last_dir := "res://dialogs/"
var curr_file := ""

#graph edit
@onready var graph_edit := $GraphEdit
@onready var timer := $Timer
@onready var notif := $HBoxContainer/Notification

@onready var file_dialog := $FileDialog


#tracker
var all_nodes_index := 0
var node_index := 0
var option_index := 0
var action_index := 0

func _ready() -> void:
	timer.timeout.connect(_save)

func _on_new_node_button_pressed():
	all_nodes_index += 1
	node_index += 1
	
	var node = load("res://types/standard_node.tscn").instantiate()
	node.name = "NODE_" + str(node_index)
	graph_edit.add_child(node)
	graph_edit.move_child(node, all_nodes_index)

func _on_new_option_button_pressed():
	all_nodes_index += 1
	option_index += 1
	
	var node = load("res://types/option_node.tscn").instantiate()
	node.name = "OPTION_" + str(option_index)
	graph_edit.add_child(node)
	graph_edit.move_child(node, all_nodes_index)

func _on_new_action_button_pressed():
	all_nodes_index += 1
	action_index += 1
	
	var node = load("res://types/action_node.tscn").instantiate()
	node.name = "ACTION_" + str(action_index)
	graph_edit.add_child(node)
	graph_edit.move_child(node, node_index)

func _on_save_button_pressed():
	file_dialog.set_file_mode(FileDialog.FILE_MODE_SAVE_FILE)
	file_dialog.set_current_dir(last_dir)
	file_dialog.title = "Save Dialog"
	file_dialog.visible = true

func _on_load_button_pressed():
	file_dialog.set_file_mode(FileDialog.FILE_MODE_OPEN_FILE)
	file_dialog.set_current_dir(last_dir)
	
	file_dialog.title = "Load Dialog"
	file_dialog.visible = true

func _on_clear_button_pressed():
	_on_autosave_button_toggled(false)
	
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		node.queue_free()
	graph_edit.clear_connections()
	
	all_nodes_index = 0
	node_index = 0
	option_index = 0
	action_index = 0
	curr_file = ""

func _on_autosave_button_toggled(button_pressed):
	if button_pressed:
		timer.start()
	else:
		timer.stop()

#SAVING
func _save_dialog():
	var dialog := {}
	
	for node in get_tree().get_nodes_in_group("graph_nodes"):
		var dialog_template = {}
		var localise_dialog = {}
		
		dialog[str(node.name)] = dialog_template
		dialog_template["id"] = str(node.name)

		dialog_template["offset x"] = node.position_offset.x
		dialog_template["offset y"] = node.position_offset.y
		
		dialog_template["go to"] = []
		for connection in graph_edit.get_connection_list():
			if connection["from"] == node.name:
				dialog_template["go to"].append(str(connection["to"]))
		
		if node.node_type == "node":
			dialog_template["character"] = node.character.get_node("LineEdit").text
			if node.display_name.visible:
				dialog_template["display_name"] = node.display_name.get_node("LineEdit").text
			
			if node.text.visible and node.text.get_node("TextEdit").text != "":
				dialog_template["text"] = node.text.get_node("TextEdit").text
			
			if node.asset.visible:
				dialog_template["asset"] = node.asset.get_node("LineEdit").text
			
			if node.condition_container.visible and node.condition_stack_count > 0:
				dialog_template["condition"] = _condition_handler(node)
		
		elif node.node_type == "option":
			if node.text.visible and node.text.get_node("TextEdit").text != "":
				dialog_template["text"] = node.text.get_node("TextEdit").text
			if node.condition_container.visible:
				dialog_template["condition"] = _condition_handler(node)
			
		elif node.node_type == "action":
			if node.signal_emit.visible:
				dialog_template["signal emit"] = node.signal_emit.get_node("LineEdit").text
			if node.end.visible:
				dialog_template["end"] = true
			if node.relationship.button_pressed and node.relationship_stack_count > 0:
				dialog_template["relationship"] = _action_handler(node, "relationship")
			if node.reputation.button_pressed and node.reputation_stack_count > 0:
				dialog_template["reputation"] = _action_handler(node, "reputation")
				
		dialog[str(node.name)] = dialog_template
	
	dialog["all_nodes_index"] = all_nodes_index
	dialog["node_index"] = node_index
	dialog["option_index"] = option_index
	dialog["action_index"] = action_index
	
	return dialog

func _condition_handler(node : Node) -> Dictionary:
	var condition_template = {}
	
	var if_conditions = []
	var or_conditions = []
	
	var if_condition_list = node.if_condition_list
	var or_condition_list = node.or_condition_list
	var condition_list = node.condition_list
	
	var expression_format = "{value1} {operator} {value2}"
	
	for condition_name in condition_list:
		var condition_node = node.condition_container.get_node(condition_name)
		var condition = condition_node.condition
		var condition_type = condition_node.condition_type

		var condition_obj = {}
		
		condition_obj["type"] = condition_type
		#checker for debug purposes
		if _condition_checker(condition_node, condition, if_condition_list, or_condition_list):
			match condition_type:
				"custom":
					for text in condition_node.get_node("LineEdit").text.split(" "):
						condition_obj["statement"] = text
				_:
					var value1 = condition_node.get_node("OptionButton").get_item_text(condition_node.get_node("OptionButton").get_selected_id())
					var operator = condition_node.get_node("OptionButton2").get_item_text(condition_node.get_node("OptionButton2").get_selected_id())
					var value2 : String
					if condition_type == "progress":
						value2 = condition_node.get_node("LineEdit").text
					else:
						value2 = condition_node.get_node("SpinBox").get_line_edit().text.split(" ")[0]
					condition_obj["statement"] = expression_format.format({"value1" : value1, "operator" : operator, "value2" : value2})
		if condition == "if":
			if_conditions.append(condition_obj)
		elif condition == "or":
			or_conditions.append(condition_obj)
	
	condition_template["if"] = if_conditions
	condition_template["or"] = or_conditions
	
	return condition_template
	
func _condition_checker(node : Node, type : String, if_condition_list : Array, or_condition_list : Array) -> bool:
	if if_condition_list.has(node.name):
		if type == "if":
			return true
	if or_condition_list.has(node.name):
		if type == "or":
			return true
	return false

func _action_handler(node : Node, type : String) -> Array:
	var template = []
	var list = node.get(type + "_list")
	
	for names in list:
		var action_template := {}
		var action_node = node.main_box.get_node(names)
		
		var target = action_node.get_node("VBoxContainer/Target/OptionButton")
		var amount = action_node.get_node("VBoxContainer/Amount/SpinBox")
		
		action_template["target"] = target.get_item_text(target.get_selected_id())
		action_template["amount"] = amount.get_line_edit().text.split(" ")[0]
		
		template.append(action_template)
	
	return template

#LOADING
func _load_dialog(dialog_data : Dictionary):
	all_nodes_index = dialog_data["all_nodes_index"]
	node_index = dialog_data["node_index"]
	option_index = dialog_data["option_index"]
	action_index = dialog_data["action_index"]
	
	for graph_node in dialog_data:
		var node
		if not "index" in graph_node:
			if "NODE" in graph_node:
				node = load("res://types/standard_node.tscn").instantiate()
				graph_edit.add_child(node)
				node.character.get_node("LineEdit").text = dialog_data[graph_node]["character"]
				if "text" in dialog_data[graph_node]:
					node._on_text_button_toggled(true)
					node.text.get_node("TextEdit").text = dialog_data[graph_node]["text"]
				else:
					node._on_text_button_toggled(false)
				if "display_name" in dialog_data[graph_node]:
					node._on_display_name_button_toggled(true)
					node.display_name.get_node("LineEdit").text = dialog_data[graph_node]["display_name"]
				if "asset" in dialog_data[graph_node]:
					node._on_asset_button_toggled(true)
					node.asset.get_node("LineEdit").text = dialog_data[graph_node]["asset"]
				if "condition" in dialog_data[graph_node]:
					node._on_condition_toggled(true)
					_condition_loader(node, dialog_data[graph_node]["condition"])
			elif "OPTION" in graph_node:
				node = load("res://types/option_node.tscn").instantiate()
				graph_edit.add_child(node)
				if "text" in dialog_data[graph_node]:
					node._on_text_button_toggled(true)
					node.text.get_node("TextEdit").text = dialog_data[graph_node]["text"]
				else:
					node._on_text_button_toggled(false)
				if "condition" in dialog_data[graph_node]:
					node._on_condition_toggled(true)
					_condition_loader(node, dialog_data[graph_node]["condition"])
			elif "ACTION" in graph_node:
				node = load("res://types/action_node.tscn").instantiate()
				graph_edit.add_child(node)
				if "signal emit" in dialog_data[graph_node]:
					node._on_emit_signal_button_toggled(true)
					node.signal_emit.get_node("LineEdit").text = dialog_data[graph_node]["signal emit"]
				if "end" in dialog_data[graph_node]:
					node._on_emit_signal_button_toggled(true)
				if "relationship" in dialog_data[graph_node]:
					node._on_relationship_button_toggled(true)
					_action_loader(node, dialog_data[graph_node], "Relationship")
				if "reputation" in dialog_data[graph_node]:
					node._on_reputation_button_toggled(true)
					_action_loader(node, dialog_data[graph_node], "Reputation")
					
			node.name = dialog_data[graph_node]["id"]
			node.title = dialog_data[graph_node]["id"]
			node.node_title.text = node.name.split("_")[1]
			
			if "go to" in dialog_data[graph_node]:
				var go_to_count = 0
				for go_to in dialog_data[graph_node]["go to"]:
					graph_edit.connect_node(node.name, 0, dialog_data[graph_node]["go to"][go_to_count], 0)
					go_to_count += 1
			
			node.position_offset.x = dialog_data[graph_node]["offset x"]
			node.position_offset.y = dialog_data[graph_node]["offset y"]

func _condition_loader(node : Node, conditions : Dictionary):
	var index = 1
	for condition in conditions:
		for data in conditions[condition]:
			var condition_node = _condition_type_loader(data["type"], data["statement"], str(index), node)
			
			match condition:
				"if":
					node.if_condition_list.append(str(condition_node.name))
					condition_node.condition = "if"
				"or":
					node.or_condition_list.append(str(condition_node.name))
					condition_node.get_node("Label").text = "OR " + data["type"].capitalize()
			
			node.condition_list.append(str(condition_node.name))
			node.condition_stack_count += 1
			
			index += 1

func _condition_type_loader(type : String, statement : String, index : String, node : Node) -> Node:
	var condition_node
	match type:
		"relationship":
			condition_node = load("res://types/helper/condition_relationship.tscn").instantiate()
		"reputation":
			condition_node = load("res://types/helper/condition_reputation.tscn").instantiate()
		"progress":
			condition_node = load("res://types/helper/condition_progress.tscn").instantiate()
		"custom":
			condition_node = load("res://types/helper/condition_custom.tscn").instantiate()
	
	condition_node.name = "Condition" + index
	#add node so we can activate the ready function of the condition node
	node.condition_container.add_child(condition_node)
	node.condition_container.move_child(condition_node,int(index))
	
	match type:
		"custom":
			condition_node.get_node("LineEdit").text = statement
		_:
			var statement_split = statement.split(" ")
			var value1 = condition_node.get_node("OptionButton")
			var operator = condition_node.get_node("OptionButton2")
			for _i in range(value1.item_count):
				if statement_split[0] == value1.get_item_text(_i):
					value1.select(_i)
					break
			for _i in range(operator.item_count):
				if statement_split[1] == operator.get_item_text(_i):
					operator.select(_i)
					break
			#value2
			if type == "progress":
				condition_node.get_node("LineEdit").text = statement_split[2]
			else:
				condition_node.get_node("SpinBox").get_line_edit().text = statement_split[2]
				condition_node.get_node("SpinBox").apply()
	return condition_node

func _action_loader(node : Node, node_dict : Dictionary, type : String):
	var index = 1
	for action in node_dict[type.to_lower()]:
		var action_node : HBoxContainer
		if index == 1:
			action_node = node.main_box.get_node(type + "1")
		else:
			action_node = node._on_add_action_button_pressed(type, true)
		
		var target = action_node.get_node("VBoxContainer/Target/OptionButton")
		var amount = action_node.get_node("VBoxContainer/Amount/SpinBox")
		
		for _i in range(target.item_count):
			if action["target"] == target.get_item_text(_i):
				target.select(_i)
				break
				
		amount.get_line_edit().text = action["amount"]
		amount.apply()
		
		index += 1

#FILE
func _on_file_dialog_file_selected(path):
	#IF SAVE MODE
	if file_dialog.file_mode == 4:
		curr_file = path
		_save()
	#IF OPEN MODE
	elif file_dialog.file_mode == 0:
		_on_clear_button_pressed()
		var load_file = FileAccess.get_file_as_bytes(path)
		var dialog_data : Dictionary = bytes_to_var(load_file)
		_load_dialog(dialog_data)
		curr_file = path
		notif.text = "LOAD SUCCESS"
	last_dir = file_dialog.get_current_dir()

func _save():
	var path
	var time = Time.get_datetime_dict_from_system()
	if curr_file == "":
		var year = str(time["year"])
		var month = str(time["month"])
		var day = str(time["day"])
		var hour = str(time["hour"])
		var minute = str(time["minute"])
		
		var time_string = day + "." + month + "." + year + "_" + hour + minute

		path = last_dir + "/autosaves/dialog_" + time_string + ".dialog"
	
	else:
		path = curr_file

	var save_file = FileAccess.open(path, FileAccess.WRITE)
	if FileAccess.file_exists(path):
		var dialog_json = var_to_bytes(_save_dialog())
		save_file.store_buffer(dialog_json)
	save_file.close()
	notif.text = "SAVE SUCCESS " + str(time["hour"]) + ":" + str(time["minute"])

#GRAPH FUNCS
func _on_graph_edit_connection_request(from_node, from_port, to_node, to_port):
	graph_edit.connect_node(from_node, from_port, to_node, to_port)

func _on_graph_edit_disconnection_request(from_node, from_port, to_node, to_port):
	graph_edit.disconnect_node(from_node, from_port, to_node, to_port)
