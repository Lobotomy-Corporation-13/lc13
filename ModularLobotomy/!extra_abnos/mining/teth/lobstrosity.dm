
/mob/living/simple_animal/hostile/asteroid/lobstrosity
	name = "lobstrosity"
	desc = "A marvel of evolution gone wrong, the frosty ice produces underground lakes where these ill tempered seafood gather. Beware its charge."
	icon = 'icons/mob/icemoon/icemoon_monsters.dmi'
	icon_state = "arctic_lobstrosity"
	icon_living = "arctic_lobstrosity"
	icon_dead = "arctic_lobstrosity_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	friendly_verb_continuous = "chitters at"
	friendly_verb_simple = "chits at"
	speak_emote = list("chitters")
	attack_verb_continuous = "snips"
	attack_verb_simple = "snip"
	attack_sound = 'sound/weapons/bite.ogg'
	weather_immunities = list("snow")
	vision_range = 5
	aggro_vision_range = 7
	charger = TRUE
	charge_distance = 4
	robust_searching = TRUE
	footstep_type = FOOTSTEP_MOB_CLAW

	maxHealth = 1100
	health = 1100
	rapid_melee = 2
	melee_damage_type = RED_DAMAGE
	move_to_delay = 5
	retreat_distance = 3
	minimum_distance = 3
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 10
	melee_damage_upper = 15
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 20,
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = 60,
		ABNORMALITY_WORK_REPRESSION = 0,
	)
	good_droprate = 20
	bad_droprate = 100
	work_damage_amount = 7
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/envy

	ego_list = list(
		/datum/ego_datum/weapon/mining/ethereal,
		/datum/ego_datum/armor/mining/ethereal,
	)
	gift_type =  /datum/ego_gifts/dream
	abnormality_origin = ABNORMALITY_ORIGIN_SS13MINING


/mob/living/simple_animal/hostile/asteroid/lobstrosity/Initialize()
	if(prob(50))
		name = "lobstrosity"
		desc = "A marvel of evolution gone wrong, the sulfur lakes of lavaland have given them a vibrant, red hued shell. Beware its charge."
		icon_state = "lobstrosity"
		icon_living = "lobstrosity"
		icon_dead = "lobstrosity_dead"
