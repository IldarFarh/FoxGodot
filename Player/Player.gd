extends KinematicBody2D

export var ACCELERATION = 500
export var MAX_SPEED = 80
export var ROLL_SPEED = 110
export var FRICTION = 500

enum {
	MOVE,
	ROLL,
	ATTACK
}

var state = MOVE
var velocity = Vector2.ZERO
var current_vector = Vector2.DOWN

onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var hurtBox = $Hurtbox

func _ready():
	PlayerStats.connect("no_health", self, "queue_free")
	animationTree.active = true

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state()
		ATTACK:
			attack_state()

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		current_vector = input_vector
		$HitboxPivot/SwordHitbox.knockback_vector = current_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	
	velocity = move_and_slide(velocity)
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK
	elif Input.is_action_just_pressed("roll"):
		state = ROLL

func attack_state():
	velocity = Vector2.ZERO
	animationState.travel("Attack")

func roll_state():
	velocity = current_vector * ROLL_SPEED
	animationState.travel("Roll")
	velocity = move_and_slide(velocity)

func attack_animation_finished():
	velocity = velocity / 2
	state = MOVE

func _on_Hurtbox_area_entered(area):
	PlayerStats.health -= area.damage
	hurtBox.start_invincibility(0.5)
	hurtBox.create_hit_effect()
