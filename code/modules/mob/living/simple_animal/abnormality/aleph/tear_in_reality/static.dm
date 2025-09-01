//Most basic enemy spawned by Tear in Reality


//////////////////////FOR OPEN SOURCE:
//////////////////////USE AS A TEMPLATE FOR YOUR ENEMIES
//////////////////////ONCE ENEMY IS FINISHED, PUT IN LIST AT LINE 61
//////////////////////(picked_mob = pick())

/mob/living/simple_animal/hostile/tir_static
	name = "Interdimensional Static"
	desc = "Whatever it was, looks like it got lost."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = 'lost_clown' //Remake this sprite once I fix the errors
	icon_living = 'lost_clown' //Potential inspirations: SJSM's Ghost Cow/Mad Cow, or The Thing
	icon_dead = 'lost_clown_dead'
	faction = list("hostile") //Will not attack other abnos, only players and ordeals.
	maxHealth = 250 //Tbh, I don't know the difference between maxHealth and health
	health = 250
	move_to_delay = 5
	melee_damage_type = WHITE_DAMAGE //Changes damage type to White, it is Red by default.
	melee_damage_lower = 45 //Attacks deal 45-60 damage per hit
	melee_damage_upper = 60
	attack_verb_continuous = "???" //The message when it continues attacking the same person, should say "I.S. ???'s John Doe"
	attack_verb_simple = "does something? to" //The message when it attacks someone, should say "Interdimensional Static does something? to John Doe"
	attack_sound = 'sound/abnormalities/censored/attack.ogg' //The sound that is made when it attacks someone, currently the sound effect CENSORED uses
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = -2, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 2) //Absorbs white, Fatal to pale.

