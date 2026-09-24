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

//Albino Hog. Does not do anything special
/mob/living/simple_animal/hostile/hogs/albino
	name = "Albino Hog"
	desc = "A rare albino hog!"
	icon_state = "hog_white"
	icon_living = "hog_white"

//The Dusk is a bunch of special Hogs
/mob/living/simple_animal/hostile/hogs/red
	icon_state = "hog_red"
	icon_living = "hog_red"
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)

/mob/living/simple_animal/hostile/hogs/white
	icon_state = "hog_white"
	icon_living = "hog_white"
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	melee_damage_type = WHITE_DAMAGE

/mob/living/simple_animal/hostile/hogs/black
	icon_state = "hog_black"
	icon_living = "hog_black"
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0, PALE_DAMAGE = 1)
	melee_damage_type = BLACK_DAMAGE


/mob/living/simple_animal/hostile/hogs/pale
	icon_state = "hog_pale"
	icon_living = "hog_pale"
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 0)
	melee_damage_type = PALE_DAMAGE


//The midnight is the coolest hogs, but I'm starting with these
