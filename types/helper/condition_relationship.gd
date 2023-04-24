extends HBoxContainer

@onready var condition_container := $".."
@onready var option_button := $OptionButton

var condition : String
var condition_type := "relationship"

func _ready():
	var index := 0
	for _i in condition_container.characters:
		for character_name in _i:
			option_button.add_item(character_name, index)
			index += 1

func _on_remove_button_pressed():
	condition_container.emit_signal("condition_removed", self)
