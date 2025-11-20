extends Node

func game_over():
	var game_over_scene = load("res://actors/game_over.tscn").instantiate()
	get_tree().current_scene.add_child(game_over_scene)
