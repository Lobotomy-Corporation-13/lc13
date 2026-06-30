// --------- SHRIMP DUNGEON ENEMIES ---------
// --------- (badly) MADE BY XEROS  ---------

//Original enemies

/mob/living/simple_animal/hostile/shrimp_security
	name = "wellcheers corp security officer"
	desc = "A security officer who happens to also be a shrimp. Packs a mean tackle and rocks a pair of sunglasses."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers_sec"
	icon_living = "wellcheers_sec"
	icon_dead = "wellcheers_sec_dead"
	faction = list("hostile") //Not fooled by the shrimp injector
	health = 1200
	maxHealth = 1200
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 16
	move_to_delay = 4.5
	melee_damage_upper = 20
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "bashes"
	attack_verb_simple = "bashes"
	attack_sound = 'sound/weapons/punch4.ogg'
	speak_emote = list("burbles")
	butcher_results = list(/obj/item/stack/spacecash/c100 = 1, /obj/item/stack/spacecash/c50 = 1)
	silk_results = list(/obj/item/stack/sheet/silk/shrimple_simple = 12, /obj/item/stack/sheet/silk/shrimple_advanced = 6)
	ranged = TRUE
	projectiletype = null

	var/dash_attack_sound = 'sound/effects/meteorimpact.ogg'
	var/dash_cooldown
	var/dash_cooldown_time = 8 SECONDS // my god Destrok used a lot of vars for this fuckass dash
	var/dash_range = 3
	var/dash_preparing = FALSE
	var/dash_dashing = FALSE
	var/dash_speed = 0.3
	var/dash_windup = 0.9 SECONDS
	var/list/dash_hitlist = list()
	var/list/dash_hitlist_turfs = list()

/mob/living/simple_animal/hostile/shrimp_security/FindTarget(list/possible_targets, HasTargetsList)
	if(dash_dashing || dash_preparing)
		return null
	. = ..()

/mob/living/simple_animal/hostile/shrimp_security/Destroy()
	/// To avoid a hard delete.
	dash_hitlist = null
	dash_hitlist_turfs = null
	. = ..()

/mob/living/simple_animal/hostile/shrimp_security/AttackingTarget(atom/attacked_target)
	if(dash_cooldown > world.time || dash_dashing || dash_preparing)
		return ..()
	if(!client && prob(60))
		var/mob/living/victim = attacked_target
		if(istype(victim) && victim.stat != DEAD)
			Tackle(victim)
			return
	. = ..()

/mob/living/simple_animal/hostile/shrimp_security/OpenFire(atom/A)
	if(dash_cooldown > world.time || dash_dashing || dash_preparing)
		return
	if(client)
		Tackle(A)
		return
	else if(prob(50))
		Tackle(A)
		return

/mob/living/simple_animal/hostile/shrimp_security/Move(atom/newloc, dir, step_x, step_y)
	if(dash_preparing)
		return FALSE
	. = ..()
	if(!.)
		CancelDash()
	if(dash_dashing)
		dash_hitlist_turfs |= get_turf(newloc)

/mob/living/simple_animal/hostile/shrimp_security/proc/Tackle(atom/trespasser = target) //Jesus fuck this thing is so complex what the hell
	if(stat == DEAD || !can_act)
		return FALSE
	if(dash_cooldown > world.time || dash_dashing || dash_preparing)
		return FALSE
	if(get_dist(src, trespasser) > dash_range)
		return FALSE
	var/turf/dash_start_turf = get_turf(src)
	var/turf/dash_target_turf = get_ranged_target_turf_direct(src, trespasser, dash_range)
	if(!dash_target_turf)
		return FALSE
	/// We got those checks out of the way - prepare to dash.
	dash_cooldown = world.time + dash_cooldown_time
	PrepareDash()
	LoseTarget()
	/// This section is for telegraphing the attack.
	face_atom(trespasser)
	var/obj/effect/temp_visual/shrimp_dash_warning/telegraph = new(get_turf(src))
	walk_towards(telegraph, dash_target_turf, 0.1 SECONDS)
	SLEEP_CHECK_DEATH(dash_windup)
	/// We're now dashing.
	BeginDash()
	walk_towards(src, dash_target_turf, dash_speed)
	SLEEP_CHECK_DEATH(get_dist(src, dash_target_turf) * dash_speed)

	/// This part is for some visual/audio feedback.
	var/datum/beam/really_temporary_beam = dash_start_turf.Beam(src, icon_state = "1-full", time = 3)
	really_temporary_beam.visuals.color = "#FE5343"
	playsound(src, 'sound/effects/meteorimpact.ogg', 100, FALSE, 4)

	var/moved_cardinals = FALSE
	var/direction_moved = get_dir(src, dash_start_turf)
	if(direction_moved == NORTH || direction_moved == SOUTH || direction_moved == WEST || direction_moved == EAST)
		moved_cardinals = TRUE
	if(!moved_cardinals)
		if(length(dash_hitlist_turfs) > 0)
			dash_hitlist_turfs -= dash_hitlist_turfs[1]
	SLEEP_CHECK_DEATH(0.1 SECONDS)
	CancelDash()
	walk(src, 0)
	dash_hitlist_turfs |= get_turf(src)
	TackleHit(dash_hitlist_turfs)
	SLEEP_CHECK_DEATH(0.4 SECONDS)

	if(!client)
		GiveTarget(trespasser)
	return TRUE

/mob/living/simple_animal/hostile/shrimp_security/proc/TackleHit(list/turfs)
	for(var/hit_turf in turfs)
		for(var/mob/living/hit_mob in HurtInTurf(hit_turf, dash_hitlist, melee_damage_upper * 1.2, melee_damage_type, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
			to_chat(hit_mob, span_userdanger("The [src.name] tackles you straight to the ground!"))
			playsound(hit_mob, dash_attack_sound, 100)
			hit_mob.Knockdown(20)
			/// Dash will come off cooldown faster if it hits someone. Dodge it!
			dash_cooldown -= 3 SECONDS

/mob/living/simple_animal/hostile/shrimp_security/proc/PrepareDash()
	dash_preparing = TRUE
	dash_dashing = FALSE
	anchored = TRUE
	dash_hitlist = list()
	dash_hitlist_turfs = list()

/mob/living/simple_animal/hostile/shrimp_security/proc/BeginDash()
	dash_preparing = FALSE
	dash_dashing = TRUE
	anchored = FALSE
	pass_flags = PASSMOB | PASSTABLE
	density = FALSE

/mob/living/simple_animal/hostile/shrimp_security/proc/CancelDash()
	dash_dashing = FALSE
	dash_preparing = FALSE
	pass_flags = initial(pass_flags)
	density = TRUE

/obj/effect/temp_visual/shrimp_dash_warning
	name = "dash warning"
	desc = "Move aside!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	color = COLOR_RED
	duration = 0.6 SECONDS
	movement_type = FLYING | PHASING

//Modified enemies

/mob/living/simple_animal/hostile/shrimp/dungeon
	name = "wellcheers corp dock worker"
	faction = list("hostile") //Not fooled by the shrimp injector

/mob/living/simple_animal/hostile/senior_shrimp/dungeon
	name = "wellcheers corp senior hauler"
	faction = list("hostile") //Also not fooled by the shrimp injector

/mob/living/simple_animal/hostile/shrimp_soldier/dungeon
	name = "wellcheers corp senior security"
	faction = list("hostile") //Shrimp injector might not work on them
