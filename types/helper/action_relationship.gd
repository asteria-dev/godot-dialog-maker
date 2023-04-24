extends HBoxContainer

@onready var action_node := $"../../.."
@onready var option_button : = $VBoxContainer/Target/OptionButton

func _ready():
	var index := 0
	for _i in action_node.characters:
		for character_name in _i:
			option_button.add_item(character_name, index)
			index += 1

func _on_remove_button_pressed():
	action_node.remove_action_button_pressed.emit("Relationship", $".")

func _on_add_button_pressed():
	action_node.add_action_button_pressed.emit("Relationship")
