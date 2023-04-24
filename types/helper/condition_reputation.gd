extends HBoxContainer

@onready var condition_container := $".."
@onready var option_button := $OptionButton

var condition : String
var condition_type := "reputation"

func _ready():
	var index := 0
	for area in condition_container.area:
		option_button.add_item(area, index)
		index += 1

func _on_remove_button_pressed():
	condition_container.emit_signal("condition_removed", self)
