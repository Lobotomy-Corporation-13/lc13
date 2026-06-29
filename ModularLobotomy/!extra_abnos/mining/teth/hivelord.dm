/mob/living/simple_animal/hostile/abnormality/mining/hivelord
	name = "hivelord"
	desc = "A truly alien creature, it is a mass of unknown organic material, constantly fluctuating. When attacking, pieces of it split off and attack in tandem with the original."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Hivelord_alert"
	icon_living = "Hivelord_alert"
	icon_dead = "Hivelord_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_ORGANIC
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	ranged = 1
	vision_range = 5
	aggro_vision_range = 9
	harm_intent_damage = 5
	melee_damage_lower = 0
	melee_damage_upper = 0
	attack_verb_continuous = "lashes out at"
	attack_verb_simple = "lash out at"
	speak_emote = list("telepathically cries")
	attack_sound = 'sound/weapons/pierce.ogg'
	ranged_cooldown = 0
	ranged_cooldown_time = 20
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	retreat_distance = 3
	minimum_distance = 3
	pass_flags = PASSTABLE
	loot = list(/obj/item/organ/regenerative_core)
	var/brood_type = /mob/living/simple_animal/hostile/hivelordbrood

	maxHealth = 900
	health = 900
	rapid_melee = 2
	melee_damage_type = BLACK_DAMAGE
	move_to_delay = 5
	retreat_distance = 3
	minimum_distance = 3
	damage_coeff = list(RED_DAMAGE = 1.6, WHITE_DAMAGE = 1.4, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 2)
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

/mob/living/simple_animal/hostile/abnormality/mining/hivelord/OpenFire(the_target)
	if(world.time >= ranged_cooldown)
		var/mob/living/simple_animal/hostile/hivelordbrood/A = new brood_type(src.loc)

		A.flags_1 |= (flags_1 & ADMIN_SPAWNED_1)
		A.GiveTarget(target)
		A.friends = friends
		A.faction = faction.Copy()
		ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/abnormality/mining/hivelord/AttackingTarget()
	OpenFire()
	return TRUE

/mob/living/simple_animal/hostile/abnormality/mining/hivelord/death(gibbed)
	mouse_opacity = MOUSE_OPACITY_ICON
	..(gibbed)

//A fragile but rapidly produced creature
/mob/living/simple_animal/hostile/hivelordbrood
	name = "hivelord brood"
	desc = "A fragment of the original Hivelord, rallying behind its original. One isn't much of a threat, but..."
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "Hivelordbrood"
	icon_living = "Hivelordbrood"
	icon_dead = "Hivelordbrood"
	icon_gib = "syndicate_gib"
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	move_to_delay = 1
	friendly_verb_continuous = "buzzes near"
	friendly_verb_simple = "buzz near"
	vision_range = 10
	maxHealth = 1
	health = 1
	is_flying_animal = TRUE
	harm_intent_damage = 5
	melee_damage_lower = 6
	melee_damage_upper = 6
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	speak_emote = list("telepathically cries")
	attack_sound = 'sound/weapons/pierce.ogg'
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	pass_flags = PASSTABLE | PASSMOB
	density = FALSE
	del_on_death = 1

/mob/living/simple_animal/hostile/hivelordbrood/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(death)), 100)
	AddComponent(/datum/component/swarming)

