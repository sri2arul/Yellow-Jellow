extends CharacterBody2D

var gravity = 1200.0
var speed = 300.0
var gloop_speed = 120.0
var jump_power = 450.0
var launch_power = 900.0

var charge = 0.0
var wall_direction = Vector2.ZERO
var freeze_timer = 0.0
var time_since_w = 10.0

var mass = 1.0
var hurt_timer = 0.0
var heat_zones = 0
var cold_zones = 0
var dead = false # NEW

@onready var visual = $ColorRect
@onready var shape = $CollisionShape2D


func _physics_process(delta):
	if dead: # NEW
		return # NEW
	hurt_timer = hurt_timer - delta
	freeze_timer = freeze_timer - delta
	time_since_w = time_since_w + delta



	var is_frozen = freeze_timer > 0
	var is_gloopy = Input.is_action_pressed("gloop") and not is_frozen and cold_zones == 0

	check_jump_and_freeze()

	var floor_charge = Input.is_action_pressed("down") and is_on_floor()
	if Input.is_action_pressed("squish") and (is_on_wall() or floor_charge):
		charge_on_wall(delta, floor_charge)
	else:
		if charge > 0:
			launch(is_frozen)
		walk(delta, is_gloopy)

	move_and_slide()
	update_look(is_frozen, is_gloopy)


func check_jump_and_freeze():
	# heat melts you out of freeze
	if heat_zones > 0:
		freeze_timer = 0.0

	if Input.is_action_just_pressed("jump"):
		# second tap in the air, not in heat = freeze
		if time_since_w < 0.25 and not is_on_floor() and heat_zones == 0:
			freeze_timer = 3.0
		elif is_on_floor():
			velocity.y = -jump_power
		time_since_w = 0.0


func charge_on_wall(delta, floor_charge):
	if floor_charge:
		# charging against the floor, launches straight up
		wall_direction = Vector2.UP
		velocity.x = 0
		velocity.y = 50 
	else:
		wall_direction = get_wall_normal()
		velocity.x = -wall_direction.x * 100
		velocity.y = 0
	charge = charge + delta * 1.5
	if charge > 1.0:
		charge = 1.0


func launch(is_frozen):
	var power = 0.4 + 0.6 * charge
	power = power * (0.6 + 0.4 * mass)
	if is_frozen:
		power = power * 1.4
	if wall_direction == Vector2.UP:
		velocity = Vector2(0, -launch_power * power)
	else:
		velocity = wall_direction * launch_power * power
		velocity.y = velocity.y - 350 * power
	charge = 0.0


func walk(delta, is_gloopy):
	if not is_on_floor():
		velocity.y = velocity.y + gravity * delta

	var direction = Input.get_axis("move_left", "move_right")
	var current_speed = speed
	if is_gloopy:
		current_speed = gloop_speed

	if is_on_floor() or direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, 2000 * delta)


func update_look(is_frozen, is_gloopy):
	var new_scale = Vector2(1.0 - 0.4 * charge, 1.0 + 0.3 * charge)

	if is_gloopy:
		new_scale = Vector2(1.6, 0.45)
		shape.scale.y = 0.45
		shape.position.y = 13
	else:
		shape.scale.y = 1.0
		shape.position.y = 0

	visual.scale = new_scale
	# default: centered
	var x_pos = -24 * new_scale.x
	# when charging on a wall, keep the squished side glued to that wall
	if charge > 0:
		if wall_direction.x > 0:
			x_pos = -24
		elif wall_direction.x < 0:
			x_pos = 24 - 48 * new_scale.x
	visual.position = Vector2(x_pos, 24 - 48 * new_scale.y)

	if is_frozen:
		visual.modulate = Color(0.6, 0.85, 1.0)
	else:
		visual.modulate = Color.WHITE


func take_hit():
	# brief protection after hit so 
	if hurt_timer > 0:
		return
	hurt_timer = 1.0

	# at normal size or smaller, spikes kill
	if mass <= 1.01:
		die() # NEW (was get_tree().reload_current_scene())
		return

	# bigger than 1x: lose one packet, never go below 1x
	mass = mass - 0.15
	if mass < 1.01:
		mass = 1.0
	scale = Vector2(mass, mass)
	velocity.y = -400


func absorb():
	# each packet makes you bigger
	mass = mass + 0.15
	if mass > 2.0:
		mass = 2.0
	scale = Vector2(mass, mass)
	global_position.y = global_position.y - 8


func enter_zone(is_heat):
	if is_heat:
		heat_zones = heat_zones + 1
	else:
		cold_zones = cold_zones + 1


func exit_zone(is_heat):
	if is_heat:
		heat_zones = heat_zones - 1
	else:
		cold_zones = cold_zones - 1


func die(): # NEW
	if dead:
		return
	dead = true
	visual.hide()
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()
