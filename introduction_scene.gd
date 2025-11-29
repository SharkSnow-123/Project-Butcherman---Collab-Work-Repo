extends Node2D

func _on_return_to_main_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
	


func _on_continue_pressed():
	get_tree().change_scene_to_file("res://game_play_scene.tscn")
