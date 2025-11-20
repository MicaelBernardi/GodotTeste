extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -350.0

@onready var animation := $animation as AnimatedSprite2D

@export var camera_zoom := Vector2(1.5,1.5)

var is_jumping := false
var ativo: bool = false

func _physics_process(delta: float) -> void:
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
		
	move_and_slide()

func _on_botao_body_entered(_body: Node2D) -> void: 
	$"../StaticBody2D/parede".set_deferred("disabled", true) 
	$"../StaticBody2D/spriteparede".visible = false
	
func _on_botao_body_exited(_body: Node2D) -> void: 
	$"../StaticBody2D/parede".set_deferred("disabled", false) 
	$"../StaticBody2D/spriteparede".visible = true

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is RigidBody2D:
		var input_dir = Input.get_axis("ui_left", "ui_right")
		body.apply_impulse(Vector2(input_dir * 400, 0))
