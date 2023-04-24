extends GraphNode

var node_type = "option"

@export var main_box : VBoxContainer
@export var additional_box : VBoxContainer
@export var node_title : LineEdit
@export var text : HBoxContainer
@export var condition_container : VBoxContainer
@export var condition_creator : HBoxContainer

@onready var text_toggle  := $VBoxContainer/HBoxContainer/Additional/Text
@onready var conddition_toggle := $VBoxContainer/HBoxContainer/Additional/VBoxContainer/HboxContainer/CheckButton

#STATUS

var if_condition_list := []
var or_condition_list := []

var condition_list := []
var condition_stack_count := 0

func _on_more_button_toggled(button_pressed):
	if button_pressed:
		additional_box.visible = true
	else:
		additional_box.visible = false

func _on_title_text_changed(new_text):
	name = "OPTION_" + new_text
	title = "OPTION_" + new_text
	
func _on_text_button_toggled(button_pressed):
	text.visible = button_pressed
	text_toggle.button_pressed = button_pressed

func _on_condition_toggled(button_pressed):
	condition_container.visible = button_pressed
	condition_creator.visible = button_pressed
	conddition_toggle.button_pressed = button_pressed

#GRAPH FUNCS
func _on_resize_request(new_minsize):
	custom_minimum_size = new_minsize

func _on_close_request():
	if get_parent().get_parent().option_index == (int(self.name.lstrip("OPTION_"))):
		get_parent().get_parent().option_index -= 1
		get_parent().get_parent().all_nodes_index -=1
	queue_free()
