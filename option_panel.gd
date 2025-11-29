extends Control

var previous_scene : Node = null


func exitButton_pressed():
	
	if previous_scene and previous_scene.has_method("show"):
		previous_scene.show()
		
	queue_free()
