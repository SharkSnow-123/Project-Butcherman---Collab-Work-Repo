extends Node2D

func _on_quit_button_pressed():
	get_tree().quit()

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://Introduction_scene.tscn")

@onready var optionPanel = $CanvasLayer/OptionPanel


func option_pressed():
		var option_scene = load("res://Option_Panel.tscn").instantiate()
		option_scene.previous_scene = get_tree().current_scene
		get_tree().root.add_child(option_scene)
		hide()
		
		
