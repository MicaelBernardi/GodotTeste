extends CharacterBody2D

@export var speed: float = 50.0
@export var distancia_deteccao: float = 150.0
@export var distancia_ataque: float = 20.0

# Ajuste este valor! Ele deve ser MAIOR que a metade da largura do seu Inimigo.
# Ex: Se o inimigo tem 40px de largura, coloque isso como 22.0 ou 25.0
@export var distancia_sensor_x: float = 25.0 

@onready var floor_detector: RayCast2D = $RayCast2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var direcao_patrulha := 1

func _ready():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# --- CONFIGURAÇÃO DO SENSOR ---
	floor_detector.enabled = true 
	floor_detector.add_exception(self)
	
	# O raio agora vai um pouco para baixo (30) e levemente para trás (-5)
	# Isso cria uma diagonal que evita "falsos positivos" na pontinha da plataforma
	floor_detector.target_position = Vector2(0, 40) 
	floor_detector.position.x = distancia_sensor_x

func _physics_process(delta):
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	if player:
		var distancia = global_position.distance_to(player.global_position)
		var dif_altura = abs(player.global_position.y - global_position.y)

		# Lógica de Perseguição
		if distancia < distancia_deteccao and dif_altura < 50:
			if distancia > distancia_ataque:
				_tentar_perseguir()
			else:
				velocity.x = 0 # Perto demais, para para atacar
				_olhar_para_player() # Mantém o olhar no player
		else:
			_patrulhar()
	else:
		_patrulhar()

	_virar_sprite()
	move_and_slide()

func _patrulhar():
	# Posiciona o sensor na frente
	floor_detector.position.x = distancia_sensor_x * direcao_patrulha
	floor_detector.force_raycast_update()

	# Verifica: Se não tem chão ou bateu na parede
	if not floor_detector.is_colliding() or is_on_wall():
		direcao_patrulha *= -1
		# Atualiza sensor imediatamente para o outro lado
		floor_detector.position.x = distancia_sensor_x * direcao_patrulha
	
	velocity.x = direcao_patrulha * speed

func _tentar_perseguir():
	var direcao_player := 1 if player.global_position.x > global_position.x else -1
	
	# Posiciona o sensor na direção que QUEREMOS ir
	floor_detector.position.x = distancia_sensor_x * direcao_player
	floor_detector.force_raycast_update()

	# Segurança: Se não tiver chão na frente, NÃO ANDA.
	if not floor_detector.is_colliding() and is_on_floor():
		velocity.x = 0
		# Opcional: Se ele travar na borda olhando pro player, 
		# você pode descomentar a linha abaixo para ele ficar "nervoso" andando no lugar
		# _patrulhar() 
	else:
		velocity.x = direcao_player * speed

func _olhar_para_player():
	if player.global_position.x > global_position.x:
		sprite.flip_h = false
	else:
		sprite.flip_h = true

func _virar_sprite():
	# Vira baseado no movimento real
	if abs(velocity.x) > 0.1:
		sprite.flip_h = velocity.x < 0
