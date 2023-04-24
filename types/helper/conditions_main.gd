extends VBoxContainer

@export var characters = Characters.characters
@export var area = Location.location

@onready var if_or_option := $"../HBoxContainer/Additional/VBoxContainer/HBoxContainer2/VBoxContainer/OptionButton"
@onready var condition_option := $"../HBoxContainer/Additional/VBoxContainer/HBoxContainer2/VBoxContainer/OptionButton2"
@onready var graph_node = $"../.."

var if_or_type := "IF"
var condition_type := "Relationship"

signal condition_removed

func _ready():
	condition_removed.connect(_on_condition_removed)

func _on_add_condition_button_pressed():
	
	var condition_stack_count = graph_node.condition_stack_count
	
	var node : HBoxContainer
	
	match condition_type.to_lower():
		"relationship":
			node = load("res://types/helper/condition_relationship.tscn").instantiate()
		"reputation":
			node = load("res://types/helper/condition_reputation.tscn").instantiate()
		"progress":
			node = load("res://types/helper/condition_progress.tscn").instantiate()
		"custom":
			node = load("res://types/helper/condition_custom.tscn").instantiate()
		
	node.name = "Condition_node"
	add_child(node)
	
	var instanced_node = $Condition_node
	
	var count = 1
	var final_name : String

	if condition_stack_count == 0:
		node.name = "Condition1"
		final_name = "Condition1"
	elif condition_stack_count > 0:
		for children in get_children():
			if children.name.begins_with("Condition"):
				if int(children.name.lstrip("Condition")) != count:
					final_name = "Condition" + str(count)
					instanced_node.name = final_name
					move_child(instanced_node, condition_stack_count+1)
					break
				count += 1

	var label_ref = get_node(final_name + "/Label")
	
	if if_or_type == "IF":
		node.condition = "if"
		label_ref.text = "IF " + condition_type
		graph_node.if_condition_list.append(final_name)
	elif if_or_type == "OR":
		node.condition = "or"
		label_ref.text = "OR " + condition_type
		graph_node.or_condition_list.append(final_name)
		
	graph_node.condition_list.append(final_name)
	graph_node.condition_stack_count += 1

func _on_condition_removed(condition):
	var node = get_node(str(condition.name))

	if graph_node.if_condition_list.has(condition.name):
		graph_node.if_condition_list.remove_at(graph_node.if_condition_list.find(condition.name))
	elif graph_node.or_condition_list.has(condition.name):
		graph_node.or_condition_list.remove_at(graph_node.or_condition_list.find(condition.name))
	
	graph_node.condition_list.remove_at(graph_node.condition_list.find(condition.name))
	graph_node.condition_stack_count -= 1
	
	node.queue_free()
	
	print(graph_node.condition_list)

func _on_if_or_button_item_selected(index):
	if_or_type = if_or_option.get_item_text(index)


func _on_condition_button_item_selected(index):
	condition_type = condition_option.get_item_text(index)
