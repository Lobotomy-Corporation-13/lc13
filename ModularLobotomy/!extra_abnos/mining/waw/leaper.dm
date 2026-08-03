#define PLAYER_HOP_DELAY 25

//Huge, carnivorous toads that spit an immobilizing toxin at its victims before leaping onto them.
//It has no melee attack, and its damage comes from the toxin in its bubbles and its crushing leap.
//Its eyes will turn red to signal an imminent attack!
/mob/living/simple_animal/hostile/abnormality/mining/leaper
	name = "leaper"
	desc = "Commonly referred to as 'leapers', the Geron Toad is a massive beast that spits out highly pressurized bubbles containing a unique toxin, knocking down its prey and then crushing it with its girth."
	icon = 'icons/mob/jungle/leaper.dmi'
	icon_state = "leaper"
	icon_living = "leaper"
	icon_dead = "leaper_dead"
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	ranged = TRUE
	projectiletype = /obj/projectile/leaper
	projectilesound = 'sound/weapons/pierce.ogg'
	ranged_cooldown_time = 30
	pixel_x = -16
	base_pixel_x = -16
	layer = LARGE_MOB_LAYER
	stat_attack = HARD_CRIT
	robust_searching = 1


	maxHealth = 2100
	health = 2100
	rapid_melee = 2
	melee_damage_type = RED_DAMAGE
	move_to_delay = 9
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.5)
	melee_damage_lower = 20
	melee_damage_upper = 30
	can_breach = TRUE
	threat_level = WAW_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 35,
		ABNORMALITY_WORK_INSIGHT = 0,
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 45,
	)
	neutral_droprate = 100
	bad_droprate = 50
	work_damage_amount = 8
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gloom

	ego_list = list(
		/datum/ego_datum/weapon/mining/goliath,
		/datum/ego_datum/armor/mining/goliath,
	)
//	gift_type =  /datum/ego_gifts/dream
	abnormality_origin = ABNORMALITY_ORIGIN_SS13MINING




	var/hopping = FALSE
	var/hop_cooldown = 0 //Strictly for player controlled leapers
	var/projectile_ready = FALSE //Stopping AI leapers from firing whenever they want, and only doing it after a hop has finished instead

	footstep_type = FOOTSTEP_MOB_HEAVY


/mob/living/simple_animal/hostile/abnormality/mining/leaper/Initialize()
	. = ..()
	remove_verb(src, /mob/living/verb/pulled)

/mob/living/simple_animal/hostile/abnormality/mining/leaper/CtrlClickOn(atom/A)
	face_atom(A)
	FindTarget(list(A), TRUE)
	if(!isturf(loc))
		return
	if(next_move > world.time)
		return
	if(hopping)
		return
	if(isliving(A))
		var/mob/living/L = A
		if(L.incapacitated())
			BellyFlop()
			return
	if(hop_cooldown <= world.time)
		Hop(player_hop = TRUE)

/mob/living/simple_animal/hostile/abnormality/mining/leaper/AttackingTarget()
	if(isliving(target))
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/mining/leaper/handle_automated_action()
	if(hopping || projectile_ready)
		return
	. = ..()
	if(target)
		if(isliving(target))
			var/mob/living/L = target
			if(L.incapacitated())
				BellyFlop()
				return
		if(!hopping)
			Hop()

/mob/living/simple_animal/hostile/abnormality/mining/leaper/Life()
	. = ..()
	update_icons()

/mob/living/simple_animal/hostile/abnormality/mining/leaper/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(prob(33) && !ckey)
		ranged_cooldown = 0 //Keeps em on their toes instead of a constant rotation
	..()

/mob/living/simple_animal/hostile/abnormality/mining/leaper/OpenFire()
	face_atom(target)
	if(ranged_cooldown <= world.time)
		if(ckey)
			if(hopping)
				return
			if(isliving(target))
				var/mob/living/L = target
				if(L.incapacitated())
					return //No stunlocking. Hop on them after you stun them, you donk.
		if(AIStatus == AI_ON && !projectile_ready && !ckey)
			return
		. = ..(target)
		projectile_ready = FALSE
		update_icons()

/mob/living/simple_animal/hostile/abnormality/mining/leaper/proc/Hop(player_hop = FALSE)
	if(z != target.z)
		return
	hopping = TRUE
	density = FALSE
	pass_flags |= PASSMOB
	notransform = TRUE
	var/turf/new_turf = locate((target.x + rand(-3,3)),(target.y + rand(-3,3)),target.z)
	if(player_hop)
		new_turf = get_turf(target)
		hop_cooldown = world.time + PLAYER_HOP_DELAY
	if(AIStatus == AI_ON && ranged_cooldown <= world.time)
		projectile_ready = TRUE
		update_icons()
	throw_at(new_turf, max(3,get_dist(src,new_turf)), 1, src, FALSE, callback = CALLBACK(src, PROC_REF(FinishHop)))

/mob/living/simple_animal/hostile/abnormality/mining/leaper/proc/FinishHop()
	density = TRUE
	notransform = FALSE
	pass_flags &= ~PASSMOB
	hopping = FALSE
	playsound(src.loc, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	if(target && AIStatus == AI_ON && projectile_ready && !ckey)
		face_atom(target)
		addtimer(CALLBACK(src, PROC_REF(OpenFire), target), 5)

/mob/living/simple_animal/hostile/abnormality/mining/leaper/proc/BellyFlop()
	var/turf/new_turf = get_turf(target)
	hopping = TRUE
	notransform = TRUE
	new /obj/effect/temp_visual/leaper_crush(new_turf)
	addtimer(CALLBACK(src, PROC_REF(BellyFlopHop), new_turf), 30)

/mob/living/simple_animal/hostile/abnormality/mining/leaper/proc/BellyFlopHop(turf/T)
	density = FALSE
	throw_at(T, get_dist(src,T),1,src, FALSE, callback = CALLBACK(src, PROC_REF(Crush)))

/mob/living/simple_animal/hostile/abnormality/mining/leaper/proc/Crush()
	hopping = FALSE
	density = TRUE
	notransform = FALSE
	playsound(src, 'sound/effects/meteorimpact.ogg', 200, TRUE)
	for(var/mob/living/L in orange(1, src))
		L.adjustBruteLoss(35)
		if(!QDELETED(L)) // Some mobs are deleted on death
			var/throw_dir = get_dir(src, L)
			if(L.loc == loc)
				throw_dir = pick(GLOB.alldirs)
			var/throwtarget = get_edge_target_turf(src, throw_dir)
			L.throw_at(throwtarget, 3, 1)
			visible_message(span_warning("[L] is thrown clear of [src]!"))
	if(ckey)//Lessens ability to chain stun as a player
		ranged_cooldown = ranged_cooldown_time + world.time
		update_icons()

/mob/living/simple_animal/hostile/abnormality/mining/leaper/Goto()
	return

/mob/living/simple_animal/hostile/abnormality/mining/leaper/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	return

/mob/living/simple_animal/hostile/abnormality/mining/leaper/update_icons()
	. = ..()
	if(stat)
		icon_state = "leaper_dead"
		return
	if(ranged_cooldown <= world.time)
		if(AIStatus == AI_ON && projectile_ready || ckey)
			icon_state = "leaper_alert"
			return
	icon_state = "leaper"

#undef PLAYER_HOP_DELAY
