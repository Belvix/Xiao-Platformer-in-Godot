extends Actor



export var skill_speed = 1000
export var plunge_speed = 2000
export var sprint_speed: = 300

onready var label = get_node("../Debug/Label")

var plunging: = false
var dashing: = false
var jumping: = true
var jump_start_height: = 0
var facing: = 1
var dashes: = 2

onready var dash_particle: = get_node("DashParticle")
onready var plunge_particle: Particles2D = get_node("PlungeParticle")
onready var player_sprite: Sprite = get_node("Player")
onready var player_animation: AnimatedSprite = get_node("PlayerAnimation")
var default_camera_offset = Camera2D


func _ready() -> void:
	dash_particle.emitting = false
	plunge_particle.emitting = false
	player_animation.animation = "standing"
	player_animation.playing = true
	$SkillCoolDown.one_shot = true
	Engine.set_target_fps(60)

# warning-ignore:unused_argument
func _physics_process(delta: float) -> void:
	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0
	var skill_status: = Input.is_action_just_pressed("skill")
	var is_sprinting: = Input.is_action_pressed("sprint")
	label.add_stat("is_sprinting",is_sprinting)
	var direction: = get_direction()
	var plunge_key = Input.is_action_just_pressed("attack")
	if direction.x != 0:
		facing = direction.x
	player_animation.scale.x = abs(player_sprite.scale.x) * facing
	_velocity = do_skill(_velocity, direction, skill_status, facing)
	_velocity = calculate_move_velocity(_velocity, speed, direction, is_jump_interrupted, is_sprinting)
	label.add_stat("player velocity",_velocity)
	label.add_stat("dashes",dashes)
	label.add_stat("jumping",jumping)
	label.add_stat("fps",Engine.get_frames_per_second())
	label.add_stat("position", self.position)
	label.add_stat("animation", player_animation.animation)
	label.add_stat("animation_playing",player_animation.frame)
	label.add_stat("anim play",player_animation.playing)
	label.add_stat("OS name",OS.get_name())
	label.add_stat("timer",$SkillCoolDown.time_left)
	label.display()
	check_plunging(plunge_key)
	get_animation(_velocity, speed, direction, dashing, is_sprinting)
	check_timers()
	_velocity = move_and_slide(_velocity, FLOOR_NORMAL)

func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		,-1.0 if Input.is_action_just_pressed("jump") and is_on_floor() else 1.0
		)
		
func check_plunging(plunge_key):
	if plunge_key==true and !is_on_floor():
		plunge_key = false
		plunging = true
	elif is_on_floor():
		plunging = false
		
func calculate_move_velocity(
		linear_velocity: Vector2,
		speed: Vector2,
		direction: Vector2,
		is_jump_interrupted: bool,
		sprint: bool
	) -> Vector2:
	var out: = linear_velocity
	if facing < 0 and out.x < speed.x * direction.x and dashing:
		out.x += 300
		out.y = 0
	elif facing > 0 and out.x > speed.x * direction.x and dashing:
		out.x -= 300
		out.y = 0
	else:
		dash_particle.emitting = false
		dashing = false
		self.set_collision_mask_bit(1, true)
		player_animation.material.set_shader_param("greenify",false)
		player_animation.rotation_degrees = 0
		out.x = speed.x * direction.x
		if sprint and is_on_floor():
			out.x = out.x + sprint_speed*direction.x
		if plunging == false:
			out.y += gravity * get_physics_process_delta_time()
		else:
			out.y = plunge_speed
			out.x = 0
	if direction.y == -1.0:
		out.y = speed.y * direction.y
		jump_start_height = self.get_global_transform().get_origin().y
		jumping = true
	if _velocity.y > 0.0:
		jumping = false
	if jumping == true and self.position.distance_to(Vector2(self.position.x,jump_start_height)) > 350:
		is_jump_interrupted = true
	if is_jump_interrupted:
		out.y = 0.0
		jumping = false
	return out
	
func get_animation(linear_velocity: Vector2,
					speed: Vector2,
					direction: Vector2,
					dashing: bool,
					sprinting: bool):
	if linear_velocity.x == 0 or !is_on_floor():
		if !jumping and is_on_floor():
			player_animation.animation = "standing"
	elif !jumping and is_on_floor():
		player_animation.animation = "running"
	if dashing:
		player_animation.playing = false
	else:
		player_animation.playing = true
		if sprinting:
			player_animation.speed_scale = 1.5
		elif jumping or !is_on_floor():
			player_animation.animation = "jumping"
			player_animation.play("jumping")
			player_animation.playing = true
			if player_animation.frame == 2:
				player_animation.playing = false	
		else:
			player_animation.speed_scale = 1
	if plunging:
		player_animation.animation = "standing"
		player_animation.scale.y = -1*player_animation.scale.y if player_animation.scale.y > 0 else player_animation.scale.y
		if plunge_particle.emitting == false:
			plunge_particle.restart()
			plunge_particle.visible = true
			plunge_particle.process_material.set_shader_param("plunge_start_pos",Vector3(self.position.x, self.position.y,0.0))
			plunge_particle.emitting = true
	else:
		player_animation.scale.y = abs(player_animation.scale.y)
		plunge_particle.emitting = false
		plunge_particle.visible = false
	
func do_skill(linear_velocity: Vector2, direction: Vector2, skill_status: bool, facing):
	var out: = linear_velocity
	if skill_status and dashing == false and dashes!=0 and !plunging:
		dashing = true
		$SkillCoolDown.start(1)
		self.set_collision_mask_bit(1,false)
		dashes -= 1
		dash_particle.process_material.direction = Vector3(-facing,0, 0)
		player_animation.rotation_degrees = 90 * facing
		dash_particle.emitting = true
		player_animation.material.set_shader_param("greenify",true)
		out.x = skill_speed * facing
		$DashSound.play()
	#if is_on_floor() and dashes == 0:
	#	dashes = 2
	return out
	
func check_timers():
	if dashes != 2 and $SkillCoolDown.time_left == 0:
		$SkillCoolDown.start(1)


func _on_Timer_timeout() -> void:
	if dashes < 2:
		dashes+=1
