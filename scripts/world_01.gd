extends Node

var players: Array
var index_atual: int = 0

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
		p.ativo = false   
	players[i].ativo = true  
