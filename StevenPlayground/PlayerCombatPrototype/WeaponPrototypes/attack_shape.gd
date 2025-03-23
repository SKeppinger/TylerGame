extends Area2D
class_name AttackShape

## ATTRIBUTES
const flicker_time = 0.1

## INSTANCE VARIABLES (SET BY WEAPON)
var damage # The attack's damage
var knockback # The attack's knockback
var behavior # The attack's behavior (equivalent to Weapon.BEHAVIOR enum)
var targets # The attack's targets (equivalent to Weapon.TARGETS enum)
var pierces # Given the attack is a projectile, how many enemies it pierces before being destroyed
var linger_time # Given the attack lingers, how long it lingers

## TIMERS
var flicker_timer = 0.0

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
	pass

## Linger
# The attack shape lingers
func linger(delta):
	pass

## Custom (ABSTRACT)
# Custom behavior, to be overridden
func custom(delta):
	pass

## On Body Entered
# Deal damage to targets
func _on_body_entered(body):
	if body.is_in_group("enemy") and (targets == Weapon.TARGETS.Enemies or targets == Weapon.TARGETS.Both):
		body.hurt(damage)
	if body.is_in_group("player") and (targets == Weapon.TARGETS.Player or targets == Weapon.TARGETS.Both):
		pass
