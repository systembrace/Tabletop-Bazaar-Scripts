extends Button
class_name PageSwitcher

@export var switch_to: VBoxContainer

func _pressed() -> void:
	get_parent().hide()
	switch_to.show()
