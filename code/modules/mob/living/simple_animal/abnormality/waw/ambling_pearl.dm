/mob/living/simple_animal/hostile/abnormality/ambling_pearl
	name = "Ambling Pearl"
	desc = "A large clam in it's shell"
	icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
	icon_state = "ambling_pearl"
	icon_living = "ambling_pearl"
	pixel_x = -32
	base_pixel_x = -32


	maxHealth = 1200
	health = 1200
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2)
	ranged = TRUE

	//They shouldn't really be meleeing people. This is reseved for objects.
	melee_damage_lower = 30
	melee_damage_upper = 40
	move_to_delay = 6

	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT

	attack_sound = 'sound/abnormalities/fragment/attack.ogg'
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	faction = list("hostile")
	can_breach = TRUE
	threat_level = WAW_LEVEL
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(0, 0, 35, 40, 45),
		ABNORMALITY_WORK_INSIGHT = list(0, 0, 20, 25, 30),
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 40, 45, 50),
	)
	neutral_droprate = 30
	bad_droprate = 100
	work_damage_amount = 10
	work_damage_type = BLACK_DAMAGE
	var/work_poison_amount = 1
	chem_type = /datum/reagent/abnormality/sin/gluttony

	ego_list = list(
		/datum/ego_datum/weapon/effervescent,
		/datum/ego_datum/weapon/effervescent,
		/datum/ego_datum/poisonheal,
	)

	var/AOE_ready = TRUE
	var/shell_opened = FALSE
	var/aoe_size = 3
	var/shell_stamina = 30
	var/poison_range = 6

//Work mechanics
/mob/living/simple_animal/hostile/abnormality/ambling_pearl/WorktickFailure(mob/living/carbon/human/user)
	..()
	user.deal_damage(work_poison_amount, TOX, src, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))


//Here's the shell stamina mechanics.
/mob/living/simple_animal/hostile/abnormality/ambling_pearl/bullet_act(obj/projectile/Proj)
	..()
	if(shell_stamina)
		shell_stamina --
	else
		OpenShell()

/mob/living/simple_animal/hostile/abnormality/ambling_pearl/attacked_by(obj/item/I, mob/living/user)
	..()
	if(!user)
		return
	if(shell_stamina)
		shell_stamina --
	else
		OpenShell()


/mob/living/simple_animal/hostile/abnormality/ambling_pearl/Move()
	if(shell_opened)
		return FALSE
	..()


/mob/living/simple_animal/hostile/abnormality/ambling_pearl/proc/OpenShell()
	if(shell_opened)
		return
	shell_opened = TRUE
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	pixel_x = -16
	base_pixel_x = -16
	can_act = FALSE
	ChangeResistances(list(RED_DAMAGE = 2, WHITE_DAMAGE = 2, BLACK_DAMAGE = 2, PALE_DAMAGE = 2))
	SLEEP_CHECK_DEATH(10 SECONDS)

	//Reset everything
	icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
	pixel_x = -32
	base_pixel_x = -32
	ChangeResistances(list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2))
	shell_stamina = initial(shell_stamina)
	can_act = TRUE
	shell_opened = FALSE


//Here's the offensive stuff.
/mob/living/simple_animal/hostile/abnormality/ambling_pearl/AttackingTarget(atom/attacked_target)
	if(shell_opened)
		return
	if(!can_act)
		return
	if(ishuman(attacked_target))
		if(AOE_ready)
			PoisonAOE()
		Vomit(target)
		return
	..()

/mob/living/simple_animal/hostile/abnormality/ambling_pearl/OpenFire()
	if(shell_opened)
		return
	if(!can_act)
		return
	if(isliving(target))
		var/mob/living/L = target
		PoisonFire(L)

/mob/living/simple_animal/hostile/abnormality/ambling_pearl/proc/PoisonAOE()
	can_act = FALSE
	SLEEP_CHECK_DEATH(20)
	AOE_ready = FALSE
	for(var/i = 1 to aoe_size)
		playsound(src, 'sound/effects/meatslap.ogg', 75, FALSE, 4)
		for(var/turf/T in range(i, src))
			if(T in range(i - 1, src))
				continue
			if(prob(70))	//It looks better with holes.
				new /obj/effect/pearl_poison(T)
		SLEEP_CHECK_DEATH(2)

	addtimer(CALLBACK(src, PROC_REF(Refresh)), 10 SECONDS)
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/ambling_pearl/proc/Refresh()
	AOE_ready = TRUE

/mob/living/simple_animal/hostile/abnormality/ambling_pearl/proc/Vomit()
	can_act = FALSE
	SLEEP_CHECK_DEATH(20)
	for(var/turf/T in range(1, src))
		if(prob(70))		//This is the weak attack
			new /obj/effect/pearl_poison(T)
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/ambling_pearl/proc/PoisonFire(mob/living/L)
	var/turf/T = get_ranged_target_turf_direct(src, L, poison_range)
	var/list/poison_turfs = getline(src, T) - get_turf(src)
	PoisonLine(src, poison_turfs, 15)

/mob/living/simple_animal/hostile/abnormality/ambling_pearl/proc/PoisonLine(atom/source, list/turfs, damage)
	can_act = FALSE
	for(var/turf/T in turfs)
		if(istype(T, /turf/closed))
			break
		new /obj/effect/pearl_poison(T)
		SLEEP_CHECK_DEATH(1.5)
		playsound(T, 'sound/effects/meatslap.ogg', 75, FALSE, 4)
	can_act = TRUE


/obj/effect/pearl_poison
	name = "poison blast"
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenshatter"
	layer = ABOVE_ALL_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/poison_damage = 6	//Can't be terribly evil.
	var/black_damage = 50

/obj/effect/pearl_poison/Initialize(mapload, set_dir)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(Blast)),7)


/obj/effect/pearl_poison/proc/Blast()
	icon_state = "greenglow"
	animate(src, alpha = 0, time = 10)
	QDEL_IN(src, 10)
	var/current_tile = get_turf(src)
	for(var/mob/living/carbon/human/H in current_tile)
		H.adjustToxLoss(poison_damage)
		H.deal_damage(black_damage, BLACK_DAMAGE, src, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))
		if(H.sanity_lost)
			//Fuck 'em
			H.adjustToxLoss(999)
			H.deal_damage(207, RED_DAMAGE, src, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))

