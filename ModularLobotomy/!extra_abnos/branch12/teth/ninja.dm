/mob/living/simple_animal/hostile/abnormality/branch12/ninja
	name = "The Stagehand"
	desc = "A crouched over figure that looks like a stagehand."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "ninja"
	icon_living = "ninja"
	del_on_death = TRUE
	maxHealth = 600		//Little fast ninja
	health = 600
	rapid_melee = 2
	move_to_delay = 3
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2)
	melee_damage_lower = 13
	melee_damage_upper = 13
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cuts"
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2

	ranged = 1
	retreat_distance = 3
	minimum_distance = 1
	work_chances = list(
					ABNORMALITY_WORK_INSTINCT = list(20, 20, 20, 30, 30),
					ABNORMALITY_WORK_INSIGHT = list(40, 40, 50, 50, 50),
					ABNORMALITY_WORK_ATTACHMENT = list(20, 25, 30, 30, 35),
					ABNORMALITY_WORK_REPRESSION = list(50, 50, 40, 40, 40)
	)
	work_damage_amount = 5
	work_damage_type = RED_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/branch12/iai,
		//datum/ego_datum/armor/trick,
	)
	abnormality_origin = ABNORMALITY_ORIGIN_BRANCH12

/mob/living/simple_animal/hostile/abnormality/branch12/ninja/AttackingTarget(atom/attacked_target)
	. = ..()
	if(alpha != 255)
		alpha = 255
		if(ishuman(attacked_target))
			var/mob/living/carbon/human/L = attacked_target
			L.apply_lc_tremor(10, 40)


/mob/living/simple_animal/hostile/abnormality/branch12/ninja/attacked_by(obj/item/I, mob/living/user)
	..()
	if(!user)
		return
	alpha = 20

/mob/living/simple_animal/hostile/abnormality/branch12/ninja/bullet_act(obj/projectile/Proj)
	..()
	alpha = 20

/mob/living/simple_animal/hostile/abnormality/branch12/ninja/Initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death)) // Hell

/mob/living/simple_animal/hostile/abnormality/branch12/ninja/Destroy()
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/ninja/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(!istype(died, /mob/living/carbon))
		return FALSE
	if(died.z != z)
		return FALSE
	datum_reference.qliphoth_change(-1) // One death reduces it
	return TRUE
