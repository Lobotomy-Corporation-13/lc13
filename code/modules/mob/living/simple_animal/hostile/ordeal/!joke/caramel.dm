//Reception of 500 Feral Hogs
/mob/living/simple_animal/hostile/hogs
	name = "Feral Hog"
	desc = "One of the many feral hogs."
	icon = 'icons/mob/animal.dmi'
	icon_state = "feral_hog"
	icon_living = "feral_hog"
	icon_dead = "dead_hog"
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 10
	melee_damage_upper = 10
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	a_intent = INTENT_HARM
	faction = list("hogs")
	status_flags = CANPUSH
	del_on_death = 1
