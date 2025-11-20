extends Node

var players: Array
var index_atual: int = 0

@onready var cam: Camera2D = $Camera2D

func _ready():
	players = [
		$player1,
		$player2,
		$player3
	]
	_set_player_ativo(index_atual)


func _input(_event):
	if Input.is_action_just_pressed("trocar_personagem"):
		index_atual = (index_atual + 1) % players.size()
		_set_player_ativo(index_atual)


func _set_player_ativo(i):
	for p in players:
		p.ativo = false   # todos desativam movimento

	var atual = players[i]
	atual.ativo = true  # este se torna jogável

	_mover_camera_para(atual)  # <<< adicionamos ISSO


func _mover_camera_para(player):
	# tira a câmera do parent atual
	if cam.get_parent() != null:
		cam.get_parent().remove_child(cam)

	# coloca a câmera dentro do novo player
	player.add_child(cam)

	# reseta posição da câmera relativa ao player
	cam.position = Vector2.ZERO

	# aplica zoom personalizado (se existir)
	var zoom = player.get("camera_zoom")
	if zoom != null:
		cam.zoom = zoom
	else:
		cam.zoom = Vector2(1, 1)  # fallback
