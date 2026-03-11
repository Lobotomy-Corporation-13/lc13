
/mob/living/simple_animal/hostile/abnormality/mining/ice_whelp
	name = "ice whelp"
	desc = "The offspring of an ice drake, weak in comparison but still terrifying."
	icon = 'icons/mob/icemoon/icemoon_monsters.dmi'
	icon_state = "ice_whelp"
	icon_living = "ice_whelp"
	icon_dead = "ice_whelp_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	friendly_verb_continuous = "stares down"
	friendly_verb_simple = "stare down"
	speak_emote = list("roars")
	ranged = TRUE
	ranged_cooldown_time = 50
	obj_damage = 40
	melee_damage_lower = 20
	melee_damage_upper = 20
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	vision_range = 9
	aggro_vision_range = 9
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	death_message = "collapses on its side."
	death_sound = 'sound/magic/demon_dies.ogg'
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	footstep_type = FOOTSTEP_MOB_CLAW


	maxHealth = 1000
	health = 1000
	rapid_melee = 2
	melee_damage_type = RED_DAMAGE
	move_to_delay = 6
	damage_coeff = list(RED_DAMAGE = 0.4, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 2, PALE_DAMAGE = 2)
	patrol_cooldown_time = 5 SECONDS // Zooming around the place
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 45,
		ABNORMALITY_WORK_INSIGHT = 45,
		ABNORMALITY_WORK_ATTACHMENT = 60,
		ABNORMALITY_WORK_REPRESSION = 20,
	)
	neutral_droprate = 100
	work_damage_amount = 6
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/sloth

	ego_list = list(
		/datum/ego_datum/weapon/dream,
		/datum/ego_datum/armor/dream,
	)
	gift_type =  /datum/ego_gifts/dream
	abnormality_origin = ABNORMALITY_ORIGIN_SS13MINING


	/// How far the whelps fire can go
	var/fire_range = 4

/mob/living/simple_animal/hostile/abnormality/mining/ice_whelp/OpenFire()
	var/turf/T = get_ranged_target_turf_direct(src, target, fire_range)
	var/list/burn_turfs = getline(src, T) - get_turf(src)
	dragon_fire_line(src, burn_turfs)

/mob/living/simple_animal/hostile/abnormality/mining/ice_whelp/Life()
	. = ..()
	if(!. || target)
		return
	adjustHealth(-maxHealth*0.025)

/mob/living/simple_animal/hostile/abnormality/mining/ice_whelp/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	return ..()
