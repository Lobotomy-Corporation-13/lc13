//These are mostly like basic zombies, something for R-Corp to cut through like butter.
/mob/living/simple_animal/hostile/sweeper
	name = "Sweeper"
	desc = "When night comes in the backstreets..."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "sweeper_1"
	icon_living = "sweeper_1"
	speak_chance = 0
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 21
	melee_damage_upper = 21
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cut"
	attack_sound = 'sound/effects/ordeals/indigo/stab_1.ogg'
	a_intent = INTENT_HARM
	status_flags = CANPUSH
	del_on_death = 1

//Rcorp couldn't kill the first one with 2 whole platoons
/mob/living/simple_animal/hostile/distortion/shrimp_rambo/easy
	maxHealth = 4000 //you asked for a star of the city
	health = 4000
	melee_damage_lower = 35
	melee_damage_upper = 50
	rapid = 25
