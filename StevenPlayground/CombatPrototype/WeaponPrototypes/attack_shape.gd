extends Area2D
class_name AttackShape

## ATTRIBUTES
const flicker_time = 0.1

## INSTANCE VARIABLES (SET BY WEAPON)
var attacker # The attacker
var damage # The attack's damage
var knockback # The attack's knockback
var behavior # The attack's behavior (equivalent to Weapon.BEHAVIOR enum)
var targets # The attack's targets (equivalent to Weapon.TARGETS enum)
var pierces # Given the attack is a projectile, how many enemies it pierces before being destroyed
var projectile_speed # Given the attack is a projectile, how fast it travels
var linger_time # Given the attack lingers, how long it lingers
var linger_ticks # Given the attack lingers, how many times it deals damage

## TIMERS AND CONTROL
var flicker_timer = 0.0 # Tracks how long a flicker attack has been active
var linger_timer = 0.0 # Tracks how long a linger attack has been active
var linger_tick_count = 0 # Tracks how many times a linger attack has dealt damage
var hit = false # Checks if the attack has hit a target

## FUNCTIONS
## Process
func _process(delta):
	match behavior:
		Weapon.BEHAVIOR.Flicker:
			flicker(delta)
		Weapon.BEHAVIOR.Projectile:
			projectile(delta)
		Weapon.BEHAVIOR.Linger:
			linger(delta)
		Weapon.BEHAVIOR.Custom:
			custom(delta)

## Flicker
# Flicker the attack shape
func flicker(delta):
	flicker_timer += delta
	if flicker_timer >= flicker_time:
		queue_free()

## Projectile
# Treat the attack shape like a projectile
func projectile(delta):
	var direction = Vector2(1, 0).rotated(rotation)
	position += direction * projectile_speed * delta

## Linger
# The attack shape lingers and damages targets in its area
func linger(delta):
	linger_timer += delta
	# Damage targets in the area
	if linger_timer >= (linger_time / linger_ticks) * (linger_tick_count + 1):
		linger_tick_count += 1
		for body in get_overlapping_bodies():
			if body.is_in_group("enemy") and (targets == Weapon.TARGETS.Enemies or targets == Weapon.TARGETS.Both):
				body.knockback(knockback, global_position)
				body.hurt(damage)
			if body.is_in_group("player") and (targets == Weapon.TARGETS.Player or targets == Weapon.TARGETS.Both):
				body.knockback(knockback, global_position)
				body.hurt(damage)
	if linger_timer >= linger_time:
		queue_free()

## Custom (ABSTRACT)
# Custom behavior, to be overridden
# When overriding this function, make sure to include a condition to queue_free the attack
func custom(_delta):
	pass

## On Body Entered
# Deal damage to targets
func _on_body_entered(body):
	if damage > 0:
		if (behavior == Weapon.BEHAVIOR.Projectile and not hit) or behavior != Weapon.BEHAVIOR.Projectile:
			# Don't hit self if the attack shouldn't (mainly for melee attacks enemies make against other enemies)
			if body == attacker and targets != Weapon.TARGETS.Both:
				return
			if body.is_in_group("enemy") and (targets == Weapon.TARGETS.Enemies or targets == Weapon.TARGETS.Both):
				body.knockback(knockback, global_position)
				body.hurt(damage)
				hit = true
			if body.is_in_group("player") and (targets == Weapon.TARGETS.Player or targets == Weapon.TARGETS.Both):
				body.knockback(knockback, global_position)
				body.hurt(damage)
				hit = true
			
			# Manage projectile destruction
			if hit and behavior == Weapon.BEHAVIOR.Projectile:
				if pierces <= 0:
					queue_free()
				else:
					hit = false
				pierces -= 1
			#TODO: Create "wall" group for projectile-destroying objects (or find another way to do this)
			if body.is_in_group("wall") and behavior == Weapon.BEHAVIOR.Projectile:
				queue_free()
