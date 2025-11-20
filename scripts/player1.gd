extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -350.0

@onready var animation := $animation as AnimatedSprite2D

var is_jumping := false
var ativo := false
var in_tube := false  # novo controle
var bodies

func _physics_process(delta: float) -> void:
	
	bodies = $"../camera".get_overlapping_bodies()
	
	if not in_tube:
		# movimento de plataforma normal
		if not is_on_floor():
			velocity += get_gravity() * delta

		if ativo:
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				is_jumping = true
			elif is_on_floor():
				is_jumping = false

			var direction := Input.get_axis("ui_left", "ui_right")
			if direction:
				velocity.x = direction * SPEED
				animation.scale.x = direction
				if not is_jumping:
					animation.play("run")
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				animation.play("idle")

			if is_jumping:
				animation.play("jump")
		else:
			velocity.x = 0
			animation.play("idle")

	else:
		# movimento dentro do tubo: 4 direções, sem gravidade
		var dir := Vector2.ZERO
		if Input.is_action_pressed("ui_right"):
			dir.x += 1
		if Input.is_action_pressed("ui_left"):
			dir.x -= 1
		if Input.is_action_pressed("ui_up"):
			dir.y -= 1
		if Input.is_action_pressed("ui_down"):
			dir.y += 1

		velocity = dir.normalized() * SPEED
		if dir != Vector2.ZERO:
			animation.play("run")
		else:
			animation.play("idle")

	move_and_slide()

# parede e botões
func _on_botao_body_entered(_body: Node2D) -> void:
	$"../StaticBody2D/parede".set_deferred("disabled", true)
	$"../StaticBody2D/spriteparede".visible = false

func _on_botao_body_exited(_body: Node2D) -> void:
	$"../StaticBody2D/parede".set_deferred("disabled", false)
	$"../StaticBody2D/spriteparede".visible = true

# empurrar objetos
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var input_dir = Input.get_axis("ui_left", "ui_right")
		body.apply_impulse(Vector2(input_dir * 400, 0))

# zonas de tubo
func _on_tubo_body_entered(body: Node2D) -> void:
	if body.name == "player1":
		body.in_tube = true

func _on_tubo_body_exited(body: Node2D) -> void:
	if body.name == "player1":
		body.in_tube = false


func die():
	GameManager.game_over()


func _on_camera_body_entered(body: Node2D) -> void:
	await get_tree().create_timer(5.0).timeout
	if body in bodies:
		die()
