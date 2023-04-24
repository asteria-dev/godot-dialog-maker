extends HBoxContainer

@onready var action_node := $"../../.."
@onready var option_button : = $VBoxContainer/Target/OptionButton

func _ready():
	var index := 0
	for area in action_node.area:
		option_button.add_item(area, index)
		index += 1

func _on_remove_button_pressed():
	action_node.remove_action_button_pressed.emit("Reputation", $".")

func _on_add_button_pressed():
	action_node.add_action_button_pressed.emit("Reputation")
