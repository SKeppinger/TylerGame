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

## TIMERS
var flicker_timer = 0.0 # Tracks how long a flicker attack has been active
var linger_timer = 0.0 # Tracks how long a linger attack has been active

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
	if linger_timer >= linger_time:
		queue_free()
	
	# Damage targets in the area
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and (targets == Weapon.TARGETS.Enemies or targets == Weapon.TARGETS.Both):
			body.hurt(damage)
			body.knockback(knockback, global_position)
		if body.is_in_group("player") and (targets == Weapon.TARGETS.Player or targets == Weapon.TARGETS.Both):
			#TODO: Player hurt function and knockback
			pass

## Custom (ABSTRACT)
# Custom behavior, to be overridden
func custom(delta):
	pass

## On Body Entered
# Deal damage to targets
func _on_body_entered(body):
	var hit = false
	# Don't hit self if the attack shouldn't (mainly for melee attacks enemies make against other enemies)
	if body == attacker and targets != Weapon.TARGETS.Both:
		return
	if body.is_in_group("enemy") and (targets == Weapon.TARGETS.Enemies or targets == Weapon.TARGETS.Both):
		body.hurt(damage)
		body.knockback(knockback, global_position)
		hit = true
	if body.is_in_group("player") and (targets == Weapon.TARGETS.Player or targets == Weapon.TARGETS.Both):
		#TODO: Player hurt function and knockback
		hit = true
	
	# Manage projectile destruction
	if hit and behavior == Weapon.BEHAVIOR.Projectile:
		pierces -= 1
		if pierces <= 0:
			queue_free()
	#TODO: Create "wall" group for projectile-destroying objects (or find another way to do this)
	if body.is_in_group("wall") and behavior == Weapon.BEHAVIOR.Projectile:
		queue_free()
