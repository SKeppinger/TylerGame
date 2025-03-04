## The Dummy simply registers the amount of damage it takes to the console, then heals so that it does not die.
extends Enemy

## Hurt Action
# Register the damage taken to the console, then heal
func hurt_action():
	# Print the damage
	print("Dummy took %d damage" % (max_hp - current_hp))
	# Heal to maximum HP
	heal(max_hp)
