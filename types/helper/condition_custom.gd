extends HBoxContainer

@onready var condition_container := $".."

var condition : String
var condition_type := "custom"

func _on_remove_button_pressed():
	condition_container.emit_signal("condition_removed", self)
