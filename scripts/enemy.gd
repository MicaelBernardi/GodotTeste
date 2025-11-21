extends CharacterBody2D

# --- CONFIGURAÇÕES DE DETECÇÃO ---
@export var distancia_deteccao: float = 40.0
@export var tolerancia_altura: float = 40.0
@export var distancia_perda_vista: float = 300.0

# --- MOVIMENTAÇÃO ---
@export var walk_speed: float = 40.0
@export var run_speed: float = 120.0
@export var distancia_sensor_x: float = 25.0 

# --- COMPORTAMENTO ---
@export var tempo_min_parado: float = 1.0
@export var tempo_max_parado: float = 3.0
@export var tempo_min_andando: float = 1.0
@export var tempo_max_andando: float = 4.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var direcao_movimento := 1

enum Estado { OCIOSO, VAGANDO, PERSEGUINDO }
var estado_atual = Estado.OCIOSO
var tempo_no_estado: float = 0.0

func _ready():
	randomize()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	_trocar_para_ocioso()

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	_verificar_deteccao_player()
	
	match estado_atual:
		Estado.OCIOSO:
			velocity.x = 0
			_processar_timer_aleatorio(delta)
			
		Estado.VAGANDO:
			_mover_com_seguranca(walk_speed)
			_processar_timer_aleatorio(delta)
			
		Estado.PERSEGUINDO:
			_perseguir_player()

	_virar_sprite()
	move_and_slide()
	
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if col.get_collider().is_in_group("player"):
			print("PEGOU! DANO!")

func _verificar_deteccao_player():
	if not player: return
	
	# --- PRIORIDADE MÁXIMA: O ESCONDERIJO ---
	# Esta verificação TEM que vir antes de calcular distâncias!
	# Usamos .get() para evitar erro caso o script do player mude
	if player.get("esta_escondido") == true:
		
		# Se eu estava correndo atrás dele e ele sumiu:
		if estado_atual == Estado.PERSEGUINDO:
			print("Inimigo: Onde ele foi?? (Player entrou no esconderijo)")
			_trocar_para_ocioso()
			
		# O "return" aqui é o segredo. 
		# Ele obriga o código a PARAR de ler. Ele nem vai ver a distância.
		return 
	# ---------------------------------------
	
	# Só se o código passar dali de cima ele calcula isso:
	var dist = global_position.distance_to(player.global_position)
	var alt = abs(player.global_position.y - global_position.y)
	
	# REGRAS PARA COMEÇAR A PERSEGUIR:
	if dist < distancia_deteccao and alt < tolerancia_altura:
		if estado_atual != Estado.PERSEGUINDO:
			print("VI O PLAYER NO MEU NÍVEL!")
			estado_atual = Estado.PERSEGUINDO

	# REGRAS PARA PARAR DE PERSEGUIR:
	elif estado_atual == Estado.PERSEGUINDO:
		if dist > distancia_perda_vista or alt > (tolerancia_altura * 1.5):
			print("Perdi o player (foi pra longe)")
			_trocar_para_ocioso()

func _tem_chao_na_frente() -> bool:
	var transform_teste = global_transform.translated(Vector2(distancia_sensor_x * direcao_movimento, 0))
	return test_move(transform_teste, Vector2(0, 10))

func _perseguir_player():
	if player.global_position.x > global_position.x:
		direcao_movimento = 1
	else:
		direcao_movimento = -1
	
	var tem_chao = _tem_chao_na_frente()
	if not tem_chao:
		velocity.x = 0
	else:
		velocity.x = direcao_movimento * run_speed

func _mover_com_seguranca(velocidade_atual: float):
	var tem_chao = _tem_chao_na_frente()
	var bateu_parede = is_on_wall()
	
	if not tem_chao or bateu_parede:
		direcao_movimento *= -1
		velocity.x = direcao_movimento * velocidade_atual
	else:
		velocity.x = direcao_movimento * velocidade_atual

func _processar_timer_aleatorio(delta):
	tempo_no_estado -= delta
	if tempo_no_estado <= 0:
		if estado_atual == Estado.OCIOSO: _trocar_para_vagando()
		else: _trocar_para_ocioso()

func _trocar_para_ocioso():
	estado_atual = Estado.OCIOSO
	velocity.x = 0
	tempo_no_estado = randf_range(tempo_min_parado, tempo_max_parado)

func _trocar_para_vagando():
	estado_atual = Estado.VAGANDO
	var direcoes = [-1, 1]
	direcao_movimento = direcoes.pick_random()
	tempo_no_estado = randf_range(tempo_min_andando, tempo_max_andando)

func _olhar_para_player():
	if player.global_position.x > global_position.x: sprite.flip_h = false
	else: sprite.flip_h = true

func _virar_sprite():
	if abs(velocity.x) > 0.1: sprite.flip_h = velocity.x < 0
