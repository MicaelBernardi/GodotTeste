extends CharacterBody2D

# --- MOVIMENTO ---
const SPEED = 100.0
const RUN_SPEED = 200.0
const JUMP_VELOCITY = -350.0
const GRAVITY = 900.0

# --- WALL MECHANICS ---
const WALL_SLIDE_SPEED = 100.0
const WALL_JUMP_FORCE = Vector2(250, -350)

# --- VARIÁVEIS ---
var is_jumping := false
var on_wall := false
var ativo := false
var in_tube := false

@export var camera_zoom := Vector2(2,2)

# --- CHILDREN ---
@onready var animation: AnimatedSprite2D = $animation
@onready var ray_left: RayCast2D = $RayCastLeft
@onready var ray_right: RayCast2D = $RayCastRight


func _physics_process(delta: float) -> void:

	# ----------- MODO TUBO ------------
	if in_tube:
		var dir := Vector2.ZERO
		if Input.is_action_pressed("ui_right"):
			dir.x += 1
		if Input.is_action_pressed("ui_left"):
			dir.x -= 1
		if Input.is_action_pressed("ui_up"):
			dir.y -= 1
		if Input.is_action_pressed("ui_down"):
			dir.y += 1

		# movimento sem gravidade
		velocity = dir.normalized() * SPEED

		if dir != Vector2.ZERO:
			animation.play("run")
		else:
			animation.play("idle")

		move_and_slide()
		return
	# -----------------------------------


	# --- GRAVIDADE NORMAL ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		is_jumping = false
		on_wall = false


	# --- DETECTAR PAREDE ---
	var touching_left = ray_left.is_colliding()
	var touching_right = ray_right.is_colliding()

	if (touching_left or touching_right) and not is_on_floor() and velocity.y > 0:
		on_wall = true
	else:
		on_wall = false


	# --- MOVIMENTO NORMAL ---
	if ativo:
		var direction := Input.get_axis("ui_left", "ui_right")

		# se **não está na parede**, movimento normal
		if not on_wall:

			if direction != 0:
				var current_speed := SPEED

# só corre se estiver no chão
				if is_on_floor() and Input.is_action_pressed("acao_correr"):
					current_speed = RUN_SPEED

				velocity.x = direction * current_speed

				animation.scale.x = direction
				if not is_jumping:
					animation.play("run")
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				if not is_jumping:
					animation.play("idle")

		# --- WALL SLIDE ---
		if on_wall:
			velocity.y = min(velocity.y, WALL_SLIDE_SPEED)

			# --- WALL JUMP ---
			if Input.is_action_just_pressed("ui_accept"):
				var jump_dir = 1 if touching_left else -1
				velocity = Vector2(WALL_JUMP_FORCE.x * jump_dir, WALL_JUMP_FORCE.y)
				on_wall = false
				is_jumping = true
				animation.play("jump")

		# --- PULO NORMAL ---
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			animation.play("jump")

	else:
		velocity.x = 0
		animation.play("idle")


	move_and_slide()





func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var input_dir = Input.get_axis("ui_left", "ui_right")
		body.apply_impulse(Vector2(input_dir * 400, 0))


# --- ENTRAR NO TUBO ---
func _on_tubo_body_entered(body: Node2D) -> void:
	if body == self:
		in_tube = true

func _on_tubo_body_exited(body: Node2D) -> void:
	if body == self:
		in_tube = false
