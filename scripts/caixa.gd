extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_botao_body_entered(_RigidBody2D) -> void: 
	$"../StaticBody2D/parede".set_deferred("disabled", true) 
	$"../StaticBody2D/spriteparede".visible = false
	
func _on_botao_body_exited(_RigidBody2D) -> void: 
	$"../StaticBody2D/parede".set_deferred("disabled", false) 
	$"../StaticBody2D/spriteparede".visible = true
