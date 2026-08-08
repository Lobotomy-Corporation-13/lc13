//A slow but strong beast that tries to stun using its tentacles
/mob/living/simple_animal/hostile/abnormality/mining/goliath
	name = "goliath"
	desc = "A massive beast that uses long tentacles to ensnare its prey, threatening them is not advised under any conditions."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Goliath"
	icon_living = "Goliath"
	icon_dead = "Goliath_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	mouse_opacity = MOUSE_OPACITY_ICON
	ranged = 1
	ranged_cooldown_time = 120
	friendly_verb_continuous = "wails at"
	friendly_verb_simple = "wail at"
	speak_emote = list("bellows")
	harm_intent_damage = 0
	obj_damage = 100
	attack_verb_continuous = "pulverizes"
	attack_verb_simple = "pulverize"
	attack_sound = 'sound/weapons/punch1.ogg'
	vision_range = 5
	aggro_vision_range = 9
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	gender = MALE
	var/pre_attack = 0
	var/pre_attack_icon = "Goliath_preattack"

	footstep_type = FOOTSTEP_MOB_HEAVY


	maxHealth = 1200
	health = 1200
	rapid_melee = 2
	melee_damage_type = RED_DAMAGE
	move_to_delay = 6
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	patrol_cooldown_time = 5 SECONDS // Zooming around the place
	melee_damage_lower = 20
	melee_damage_upper = 30
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = 10,
		ABNORMALITY_WORK_ATTACHMENT = 50,
		ABNORMALITY_WORK_REPRESSION = 30,
	)
	good_droprate = 20
	bad_droprate = 100
	work_damage_amount = 6
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath

	ego_list = list(
		/datum/ego_datum/weapon/mining/goliath,
		/datum/ego_datum/armor/mining/goliath,
	)
//	gift_type =  /datum/ego_gifts/dream
	abnormality_origin = ABNORMALITY_ORIGIN_SS13MINING

/mob/living/simple_animal/hostile/abnormality/mining/goliath/Intitialize()
	..()
	if(prob(50))
		//Who the fuck named these sprites?
		icon_state = "goliath"
		icon_living = "goliath"
		icon_dead = "goliath_dead"
		pre_attack_icon = "goliath2"


/mob/living/simple_animal/hostile/abnormality/mining/goliath/Life()
	. = ..()
	handle_preattack()

/mob/living/simple_animal/hostile/abnormality/mining/goliath/proc/handle_preattack()
	if(status_flags & GODMODE)
		return
	if(ranged_cooldown <= world.time + ranged_cooldown_time*0.25 && !pre_attack)
		pre_attack++
	if(!pre_attack || stat || AIStatus == AI_IDLE)
		return
	icon_state = pre_attack_icon

/mob/living/simple_animal/hostile/abnormality/mining/goliath/revive(full_heal = FALSE, admin_revive = FALSE)//who the fuck anchors mobs
	. = ..()
	if(.)
		move_force = MOVE_FORCE_VERY_STRONG
		move_resist = MOVE_FORCE_VERY_STRONG
		pull_force = MOVE_FORCE_VERY_STRONG
		. = 1

/mob/living/simple_animal/hostile/abnormality/mining/goliath/death(gibbed)
	move_force = MOVE_FORCE_DEFAULT
	move_resist = MOVE_RESIST_DEFAULT
	pull_force = PULL_FORCE_DEFAULT
	return ..(gibbed)

/mob/living/simple_animal/hostile/abnormality/mining/goliath/OpenFire()
	var/tturf = get_turf(target)
	if(!isturf(tturf))
		return
	if(get_dist(src, target) <= 7)//Screen range check, so you can't get tentacle'd offscreen
		visible_message(span_warning("[src] digs its tentacles under [target]!"))
		new /obj/effect/temp_visual/goliath_tentacle/original(tturf, src)
		ranged_cooldown = world.time + ranged_cooldown_time
		icon_state = icon_living
		pre_attack = 0

/mob/living/simple_animal/hostile/abnormality/mining/goliath/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	ranged_cooldown -= 10
	handle_preattack()
	. = ..()

/mob/living/simple_animal/hostile/abnormality/mining/goliath/Aggro()
	vision_range = aggro_vision_range
	handle_preattack()
