extends CharacterBody2D

const SPEED := 100.0
const PUSH_SPEED := 60.0
const JUMP_VELOCITY := -350.0

const DISTANCIA_MAXIMA_AGARRE := 95.0
const TOLERANCIA_ALTURA := 10.0
const DISTANCIA_DETECCAO_TETO := 15.0

@onready var animation: AnimatedSprite2D = $animation

# --- NOVO: Referência para os esconderijos ---
# Arraste o seu "TileMapLayer" de esconderijos para cá no Inspector
@onready var layer_esconderijos: TileMapLayer = $"../level/esconderijo"

# --- NOVO: Variável de Estado ---
var esta_escondido: bool = false

var is_jumping := false
var ativo := true
var in_tube := false
var caixa_encostada: RigidBody2D = null

var offset_agarre: float = 0.0
var esta_agarrado: bool = false
var player_no_botao: bool = false
var escalando_teto: bool = false

func _physics_process(delta: float) -> void:
	if not in_tube:
		
		# --- NOVO: LÓGICA DE ESCONDER ---
		# Verifica se apertou CIMA para Entrar ou Sair
		if Input.is_action_just_pressed("ui_up"):
			if esta_escondido:
				_sair_do_esconderijo()
				return # Impede que ele tente pular ou agarrar teto no mesmo frame
			else:
				if _tentar_entrar_esconderijo():
					return # Se entrou, não faz mais nada
		
		# Se estiver escondido, para tudo e não processa física
		if esta_escondido:
			velocity = Vector2.ZERO
			animation.play("idle") # Ou uma animação de "duck/agachar"
			return
		# ----------------------------------

		# --- LÓGICA DE GRUDAR NO TETO (Mantida, mas agora no 'else' do esconderijo) ---
		if Input.is_action_just_pressed("ui_up"):
			if escalando_teto:
				escalando_teto = false
			else:
				var tem_teto = test_move(transform, Vector2.UP * DISTANCIA_DETECCAO_TETO) or is_on_ceiling()
				
				if tem_teto:
					escalando_teto = true
					is_jumping = false
					esta_agarrado = false 
					velocity.y = 0 
					velocity.x = 0

		# Verifica se o teto acabou
		if escalando_teto:
			var ainda_tem_teto = test_move(transform, Vector2.UP * DISTANCIA_DETECCAO_TETO)
			if not ainda_tem_teto:
				escalando_teto = false

		# --- COMPORTAMENTO DA FÍSICA ---
		if escalando_teto:
			velocity.y = -10.0 # Mantém grudado no teto
			animation.flip_v = false 
		else:
			animation.flip_v = false
			if not is_on_floor():
				velocity += get_gravity() * delta

		if ativo:
			# Pulo
			if Input.is_action_just_pressed("ui_accept"):
				if escalando_teto:
					escalando_teto = false
					velocity.y = 0 
				elif is_on_floor() and not esta_agarrado:
					velocity.y = JUMP_VELOCITY
					is_jumping = true
			
			if is_on_floor() and not escalando_teto:
				is_jumping = false

			# Empurrar Caixa
			if Input.is_action_just_pressed("empurrar"):
				if player_no_botao:
					_alternar_parede()
				elif caixa_encostada != null and not escalando_teto:
					var dist_x = abs(global_position.x - caixa_encostada.global_position.x)
					var dist_y = abs(global_position.y - caixa_encostada.global_position.y)
					if dist_x <= DISTANCIA_MAXIMA_AGARRE and dist_y <= TOLERANCIA_ALTURA:
						esta_agarrado = true
						offset_agarre = caixa_encostada.global_position.x - global_position.x
						caixa_encostada.lock_rotation = true
						caixa_encostada.freeze = false

			if Input.is_action_just_released("empurrar"):
				esta_agarrado = false
				if caixa_encostada:
					caixa_encostada.linear_velocity = Vector2.ZERO
			
			if caixa_encostada == null:
				esta_agarrado = false

			# Movimento Horizontal
			var direction := Input.get_axis("ui_left", "ui_right")
			
			if esta_agarrado and caixa_encostada != null:
				if direction != 0:
					velocity.x = direction * PUSH_SPEED
					animation.scale.x = direction
					animation.play("run")
					caixa_encostada.linear_velocity.x = velocity.x
				else:
					velocity.x = 0
					animation.play("idle")
					caixa_encostada.linear_velocity.x = 0
			else:
				if direction != 0:
					velocity.x = direction * SPEED
					animation.scale.x = direction
					
					if escalando_teto:
						animation.play("run") 
					elif not is_jumping: 
						animation.play("run")
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)
					animation.play("idle")
			
			if is_jumping and not escalando_teto:
				animation.play("jump")
			
			move_and_slide()
			
			if esta_agarrado and caixa_encostada != null:
				caixa_encostada.global_position.x = global_position.x + offset_agarre
				caixa_encostada.rotation = 0

	else:
		# Dentro do tubo
		velocity.x = 0
		animation.play("idle")

	if in_tube:
		var dir := Vector2.ZERO
		if Input.is_action_pressed("ui_right"): dir.x += 1
		if Input.is_action_pressed("ui_left"):  dir.x -= 1
		if Input.is_action_pressed("ui_up"):    dir.y -= 1
		if Input.is_action_pressed("ui_down"):  dir.y += 1
		velocity = dir.normalized() * SPEED
		if dir != Vector2.ZERO: animation.play("run")
		else: animation.play("idle")
		move_and_slide()

# --- FUNÇÕES AUXILIARES ---

# --- NOVO: Funções de Esconderijo ---
func _tentar_entrar_esconderijo() -> bool:
	if not layer_esconderijos:
		print("ERRO: Nó layer_esconderijos não encontrado!")
		return false

	# 1. Converte a posição global do player para a posição dentro do mapa
	var posicao_local = layer_esconderijos.to_local(global_position)
	var coords = layer_esconderijos.local_to_map(posicao_local)
	
	print("--------------------------------")
	print("Player está na coordenada do mapa: ", coords)

	# 2. Tenta pegar os dados do tile nessa coordenada
	var dados = layer_esconderijos.get_cell_tile_data(coords)
	
	if dados:
		print("Achei um tile aqui!")
		# Verifica se a flag 'esconderijo' existe e é verdadeira
		var valor_esconderijo = dados.get_custom_data("esconderijo")
		print("Valor do Custom Data 'esconderijo': ", valor_esconderijo)
		
		if valor_esconderijo == true:
			print("SUCESSO: É um esconderijo válido!")
			esta_escondido = true
			modulate.a = 0.5 
			return true
		else:
			print("FALHA: O tile existe, mas a caixinha 'esconderijo' não está marcada no TileSet.")
	else:
		print("FALHA: Não tem nenhum tile nesta coordenada da camada 'esconderijo'.")
		print("Dica: Verifique se você pintou a caixa no nó correto!")
	
	print("--------------------------------")
	return false

func _sair_do_esconderijo():
	print("Player: Sai do esconderijo!")
	esta_escondido = false
	modulate.a = 1.0 # Volta cor normal
# ------------------------------------

func _alternar_parede() -> void:
	# Jeito seguro usando acesso direto se possível ou GetNode
	var parede = $"../StaticBody2D/parede" # Cuidado com caminhos relativos!
	var sprite = $"../StaticBody2D/spriteparede"
	if parede and sprite:
		var esta_desativada = parede.disabled
		parede.set_deferred("disabled", !esta_desativada)
		sprite.visible = esta_desativada

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		caixa_encostada = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == caixa_encostada:
		caixa_encostada = null
		esta_agarrado = false

func _on_botao_body_entered(_body: Node2D) -> void:
	player_no_botao = true

func _on_botao_body_exited(_body: Node2D) -> void:
	player_no_botao = false

func _on_tubo_body_entered(body: Node2D) -> void:
	if body.name == "player1": body.in_tube = true

func _on_tubo_body_exited(body: Node2D) -> void:
	if body.name == "player1": body.in_tube = false
