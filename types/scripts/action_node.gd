extends GraphNode

var node_type = "action"

@export var characters = Characters.characters
@export var area = Location.location

@export var main_box : VBoxContainer
@export var additional_box : VBoxContainer
@export var node_title : LineEdit
@export var signal_emit : HBoxContainer
@export var relationship : CheckButton
@export var reputation : CheckButton
@export var end : HBoxContainer

@onready var end_toggle := $HBoxContainer/Addtional/End
@onready var emit_toggle := $HBoxContainer/Addtional/EmitSignal
@onready var relationship_toggle := $HBoxContainer/Addtional/Relationship
@onready var reputation_toggle := $HBoxContainer/Addtional/Reputation

signal add_action_button_pressed
signal remove_action_button_pressed

var relationship_list = ["Relationship1"]
var relationship_stack_count = 0

var reputation_list = ["Reputation1"]
var reputation_stack_count = 0

func _ready():
	add_action_button_pressed.connect(_on_add_action_button_pressed)
	remove_action_button_pressed.connect(_on_remove_action_button_pressed)

func _on_more_button_toggled(button_pressed):
	if button_pressed:
		additional_box.visible = true
	else:
		additional_box.visible = false

func _on_title_text_changed(new_text):
	name = "ACTION_" + new_text
	title = "ACTION_" + new_text

func _on_end_button_toggled(button_pressed):
	end.visible = button_pressed
	end_toggle.button_pressed = button_pressed

func _on_emit_signal_button_toggled(button_pressed):
	signal_emit.visible = button_pressed
	emit_toggle.button_pressed = button_pressed

func _on_relationship_button_toggled(button_pressed):
	if button_pressed:
		relationship_toggle.button_pressed = true
		for items in relationship_list:
			main_box.get_node(items).visible = true
			relationship_stack_count += 1
	else:
		relationship_toggle.button_pressed = false
		for items in relationship_list:
			main_box.get_node(items).visible = false
			relationship_stack_count -= 1

func _on_reputation_button_toggled(button_pressed):
	if button_pressed:
		reputation_toggle.button_pressed = true
		for items in reputation_list:
			main_box.get_node(items).visible = true
			reputation_stack_count += 1
	else:
		reputation_toggle.button_pressed = false
		for items in reputation_list:
			main_box.get_node(items).visible = false
			reputation_stack_count -= 1

func _on_add_action_button_pressed(type : String, loading_save : bool = false):
	var action_node = load("res://types/helper/action_" + type.to_lower() + ".tscn").instantiate()
	action_node.name = type + "-1"
	main_box.add_child(action_node)
	
	var main_index = main_box.get_node(type + "1").get_index()
	var count = 1
	var final_name : String
	
	for children in main_box.get_children():
		if children.name.begins_with(type):
			if int(children.name.lstrip(type)) != count:
				final_name = type + str(count)
				children.name = final_name
				main_box.move_child(children, main_index + count-1)
			count += 1
	
	if type == "Relationship":
		relationship_stack_count += 1
		relationship_list.append(final_name)
	elif type == "Reputation":
		reputation_stack_count += 1
		reputation_list.append(final_name)
	
	if loading_save:
		return main_box.get_node(final_name)
	
func _on_remove_action_button_pressed(type : String, action_node : HBoxContainer):
	var button_number = int(action_node.name.lstrip(type))
	
	for children in main_box.get_children(false):
		if children.name.begins_with(type):
			if int(children.name.lstrip(type)) > button_number:
				children.name = type + str(button_number)
				button_number += 1
			elif int(children.name.lstrip(type)) == button_number:
				children.name = "QUEUEFREE"
	
	action_node.queue_free()
	
	if type == "Relationship":
		relationship_stack_count -= 1
		relationship_list.pop_back()
	elif type == "Reputation":
		reputation_stack_count -= 1
		reputation_list.pop_back()
		
	print(relationship_list)
	print(reputation_list)
	
# GRAPH FUNCS
func _on_resize_request(new_minsize):
	custom_minimum_size = new_minsize

func _on_close_request():
	if get_parent().get_parent().action_index == (int(self.name.lstrip("ACTION_"))):
		get_parent().get_parent().action_index -= 1
		get_parent().get_parent().all_nodes_index -=1
	queue_free()
