/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe
	name = "Joe Shmoe"
	desc = "It's a regular dummy with straw poking out of it."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/joe.dmi'
	icon_state = "joe_1"
	icon_living = "joe_1"
	blood_volume = 0
	threat_level = WAW_LEVEL
	start_qliphoth = 4
	can_breach = FALSE
	max_boxes = 22
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 40,
		ABNORMALITY_WORK_INSIGHT = 40,
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 40,
	)
	work_damage_amount = 10
	work_damage_type = WHITE_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/branch12/joe,
		/datum/ego_datum/armor/branch12/joe,
	)
	//gift_type =  /datum/ego_gifts/signal
	abnormality_origin = ABNORMALITY_ORIGIN_BRANCH12

	var/list/joelist = list()
	var/mob/living/carbon/human/marked

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/Destroy()
	JoegiveAndShmoeget()
	MassJoestinction()
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/Initialize()
	. = ..()
	if(prob(10))
		icon_state = "joe_[rand(1,12)]"

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(1)
	return

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/Life()
	. = ..()
	if(marked && marked.sanity_lost)
		AndThenThereWasJoe(get_turf(marked))
		var/mob/living/im_going_to_explode_you = marked
		marked = null
		im_going_to_explode_you.gib()

	if(length(joelist) == 0)
		JoegiveAndShmoeget()

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/ZeroQliphoth(mob/living/carbon/human/user, work_type, pe, work_time)
	..()
	for(var/i = 1 to 6)
		var/turf/W = pick(GLOB.xeno_spawn)
		AndThenThereWasJoe(get_turf(W))

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/proc/WoahDude(mob/living/unjoe)
	if(marked)
		JoegiveAndShmoeget()
	marked = unjoe
	RegisterSignal(unjoe, COMSIG_PARENT_QDELETING, PROC_REF(JoegiveAndShmoeget))

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/proc/JoegiveAndShmoeget()
	if(!marked)
		return
	UnregisterSignal(marked, COMSIG_PARENT_QDELETING)
	marked = null

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/proc/Shmoed(mob/living/simple_animal/hostile/subjoe/joelet)
	UnregisterSignal(joelet, COMSIG_PARENT_QDELETING)
	joelet.masterjoe = null
	joelist -= joelet

/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/proc/AndThenThereWasJoe(turf/drop_point)
	var/mob/living/simple_animal/hostile/subjoe/S = new (get_turf(drop_point))
	S.masterjoe = src
	joelist+=S
	RegisterSignal(S, COMSIG_PARENT_QDELETING, PROC_REF(Shmoed))

//The Joes lose their connection to the ur-Joe. Now they are truely lost.
/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/proc/MassJoestinction()
	for(var/mob/living/simple_animal/hostile/subjoe/lil_joe in joelist)
		Shmoed(lil_joe)
	//Redundant but failsafe
	joelist.Cut()

//Most of the meat is in the simples
/mob/living/simple_animal/hostile/subjoe
	name = "Joe Shmoe"
	desc = "It's a regular dummy with straw poking out of it."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/joe.dmi'
	icon_state = "joe_1"
	icon_living = "joe_1"
	del_on_death = TRUE
	maxHealth = 800
	health = 800
	density = TRUE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	melee_damage_type = RED_DAMAGE
	stat_attack = HARD_CRIT
	melee_damage_lower = 20
	melee_damage_upper = 30
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	attack_sound = 'sound/abnormalities/laetitia/spider_attack.ogg'

	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	blood_volume = BLOOD_VOLUME_NORMAL
	simple_mob_flags = SILENCE_RANGED_MESSAGE
	can_patrol = TRUE

	var/mob/living/simple_animal/hostile/abnormality/branch12/joe_shmoe/masterjoe


/mob/living/simple_animal/hostile/subjoe/Destroy()
	if(masterjoe)
		masterjoe.Shmoed(src)
	masterjoe = null
	return ..()

//Random sprite
/mob/living/simple_animal/hostile/subjoe/Initialize()
	. = ..()
	if(prob(10))
		icon_state = "joe_[rand(1,12)]"
	if(prob(1))
		icon_state = "joe_13"

/mob/living/simple_animal/hostile/subjoe/Life()
	. = ..()
	for(var/mob/living/carbon/human/H in view(3, src))
		if(masterjoe)
			if(masterjoe.marked)
				H.deal_damage(2, WHITE_DAMAGE, source = src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		H.deal_damage(10, WHITE_DAMAGE, source = src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))

	//don't move or attack if there's no marked.
/mob/living/simple_animal/hostile/subjoe/Move()
	if(masterjoe)
		if(!masterjoe.marked)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/subjoe/CanAttack(atom/the_target)
	if(masterjoe)
		if(the_target != masterjoe.marked)
			return FALSE
	return ..()

//Turn anyone that attacks one into an enemy of all
/mob/living/simple_animal/hostile/subjoe/bullet_act(obj/projectile/Proj)
	if(!ishuman(Proj.firer))
		return
	if(masterjoe)
		masterjoe.WoahDude(Proj.firer)
	return ..()

/mob/living/simple_animal/hostile/subjoe/attacked_by(obj/item/I, mob/living/user)
	..()
	if(!user)
		return
	if(masterjoe)
		masterjoe.WoahDude(user)

/mob/living/simple_animal/hostile/subjoe/PickTarget(list/Targets) // Only patrol to the marked
	if(masterjoe)
		if(masterjoe.marked)
			return masterjoe.marked

/mob/living/simple_animal/hostile/subjoe/patrol_reset()
	. = ..()
	if(masterjoe)
		if(masterjoe.marked)
			FindTarget() // KILL HIM, KILL HIM NOW


/mob/living/simple_animal/hostile/subjoe/SelectPatrolLocation()
	if(!masterjoe)
		return

	if(!masterjoe.marked)
		return

	var/patrol_turf = get_turf(masterjoe.marked)

	var/turf/target_turf = get_closest_atom(/turf/open, patrol_turf, src)

	if(istype(target_turf))
		return target_turf

	return ..()
