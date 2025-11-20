extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -350.0
const RUN_SPEED = 200.0

@onready var animation := $animation as AnimatedSprite2D

@export var camera_zoom := Vector2(5, 5)

var is_jumping := false
var ativo: bool = false


func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	if ativo:

		# ------------------------------
		# PULO
		# ------------------------------
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_jumping = true
		elif is_on_floor():
			is_jumping = false

		# ------------------------------
		# MOVIMENTO HORIZONTAL / CORRIDA
		# ------------------------------
		var direction := Input.get_axis("ui_left", "ui_right")

		if direction != 0:
			var current_speed := RUN_SPEED if Input.is_action_pressed("acao_correr") else SPEED
			velocity.x = direction * current_speed
			animation.scale.x = direction

			if is_on_floor():
				animation.play("run")

		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if is_on_floor():
				animation.play("idle")

		# ------------------------------
		# ANIMAÇÃO DE PULO
		# ------------------------------
		if not is_on_floor():
			animation.play("jump")

	else:
		velocity.x = 0
		if is_on_floor():
			animation.play("idle")

	move_and_slide()


# ---------- SEUS SINAIS ----------
func _on_botao_body_entered(_body: Node2D) -> void:
	$"../StaticBody2D/parede".set_deferred("disabled", true)
	$"../StaticBody2D/spriteparede".visible = false

func _on_botao_body_exited(_body: Node2D) -> void:
	$"../StaticBody2D/parede".set_deferred("disabled", false)
	$"../StaticBody2D/spriteparede".visible = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var input_dir := Input.get_axis("ui_left", "ui_right")
		body.apply_impulse(Vector2(input_dir * 400, 0))
