// --------- SHRIMP DUNGEON BOSS ENEMIES ---------
// --------- (badly) MADE BY XEROS       ---------

/mob/living/simple_animal/hostile/shrimp_hos
	name = "Wellcheers Head of Security"
	desc = "A heavily armored, gas mask-clad shrimp, armed with a semi-automatic shotgun and gas grenades." //Literally just the Enforcer from Cultic lmao
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers_hos"
	icon_living = "wellcheers_hos"
	icon_dead = "wellcheers_hos_dead"
	attack_sound = 'sound/effects/meteorimpact.ogg'
	faction = list("hostile") //Not fooled by the shrimp injector
	gender = MALE
	maxHealth = 4000
	health = 4000
	melee_damage_lower = 16
	melee_damage_upper = 20
	ranged = TRUE
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2)
	move_to_delay = 6
	rapid = 3
	rapid_fire_delay = 3.5
	ranged_cooldown_time = 15
	casingtype = /obj/item/ammo_casing/caseless/ego_shrimpsoldier
	projectilesound = 'sound/weapons/gun/shotgun/shot.ogg'
	retreat_distance = 2
	minimum_distance = 1
	var/datum/beam/current_beam = null
	var/grenade_cooldown
	var/grenade_cd_duration = 15 SECONDS


/mob/living/simple_animal/hostile/shrimp_hos/OpenFire(atom/A) //We able to gas them? No? Bust out the shotty.
	if(!can_act)
		return
	if(gas_grenade())
		return FALSE
	if(PrepareToFire(A))
		return ..()
	return FALSE

/mob/living/simple_animal/hostile/shrimp_hos/proc/PrepareToFire(atom/A) //Copypasted code from TTLS snipers. Intended to serve as the "warning" for the shotgun.
	current_beam = Beam(A, icon_state="blood", time = 0.8 SECONDS)
	playsound(src, 'sound/weapons/gun/shotgun/rack.ogg', 200, TRUE, 2)
	can_act = FALSE
	SLEEP_CHECK_DEATH(0.9 SECONDS) //WAY faster than the Denial of Concept
	can_act = TRUE
	return TRUE

/mob/living/simple_animal/hostile/shrimp_hos/proc/gas_grenade()
	if(grenade_cooldown>world.time)
		return FALSE
	playsound(src, 'sound/magic/clockwork/invoke_general.ogg', 200, TRUE, 2)
	grenade_cooldown = (world.time+grenade_cd_duration)
	SLEEP_CHECK_DEATH(12)
	return TRUE



/mob/living/simple_animal/hostile/shrimp_comms
	name = "Wellcheers Communications Officer"
	desc = "A shrimp packing a pistol and carrying a portable comms array on their back." //The guy who summons mooks
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers_comms"
	icon_living = "wellcheers_comms"
	icon_dead = "wellcheers_comms_dead"
	attack_sound = 'sound/effects/meteorimpact.ogg'
	faction = list("hostile") //Not fooled by the shrimp injector
	gender = MALE
	maxHealth = 3000
	health = 3000
	melee_damage_lower = 8
	melee_damage_upper = 12 //Fucking puny melee damage lmao
	ranged = TRUE
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	move_to_delay = 3
	ranged_cooldown_time = 23
	casingtype = /obj/item/ammo_casing/caseless/ego_shrimpsoldier
	projectilesound = 'sound/weapons/gun/shotgun/shot.ogg'
	retreat_distance = 3
	minimum_distance = 2
	var/datum/beam/current_beam = null
	var/reinforcements_cooldown
	var/reinforcements_cd_duration = 30 SECONDS

/mob/living/simple_animal/hostile/shrimp_qm
	name = "Wellcheers Quartermaster"
	desc = "A very muscular shrimp wearing a brown beret and fingerless gloves." //Rushdown guy
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers_qm"
	icon_living = "wellcheers_qm"
	icon_dead = "wellcheers_qm_dead"
	attack_sound = 'sound/effects/meteorimpact.ogg'
	faction = list("hostile") //Not fooled by the shrimp injector
	gender = MALE
	maxHealth = 5000
	health = 5000
	ranged = TRUE
	melee_damage_lower = 24
	melee_damage_upper = 28 //He punches decently hard
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.2)
	move_to_delay = 2.5 //he zoom

	var/list/dash_hitlist = list()
	var/list/dash_hitlist_turfs = list()
	var/dash_range = 5
	var/preparing = FALSE
	var/dash_speed = 0.3
	var/dash_windup = 0.9 SECONDS
	var/dash_cooldown
	var/dash_cooldown_time = 8 SECONDS
	var/dashing = FALSE


/mob/living/simple_animal/hostile/shrimp_qm/Move(atom/newloc, dir, step_x, step_y)
	if(preparing) // You can't move during these. Never add lunging/dashing to this check, we kinda need to move during those
		return FALSE
	. = ..()

	if(dashing)
		playsound(src, 'sound/effects/meteorimpact.ogg', 75, TRUE, 2, TRUE)
		dash_hitlist_turfs |= get_turf(newloc)
		ShrimpChargeHit(get_turf(newloc))
		for(var/turf/T in view(1, newloc))
			if(!(T in dash_hitlist_turfs))
				dash_hitlist_turfs |= T // Okay I know |= automatically checks if it's already in the list, but I only want to render the small_smoke once per turf, I think the ifcheck is less expensive than actually creating a tempvisual, right?
				ShrimpChargeHit(T)
				new /obj/effect/temp_visual/small_smoke/halfsecond(T)

/mob/living/simple_animal/hostile/shrimp_qm/AttackingTarget(atom/attacked_target)
	if(dash_cooldown > world.time || dashing || preparing)
		return ..()
	if(!client && prob(20))
		var/mob/living/victim = attacked_target
		if(istype(victim) && victim.stat != DEAD)
			ShrimpCharge(victim)
			return
	. = ..()


/mob/living/simple_animal/hostile/shrimp_qm/OpenFire(atom/A)
	if(dash_cooldown > world.time || dashing || preparing)
		return
	if(client)
		ShrimpCharge(A)
		return
	else if(prob(50))
		ShrimpCharge(A)
		return

/mob/living/simple_animal/hostile/shrimp_qm/proc/ShrimpCharge(atom/intruder = target)
	if(stat >= DEAD || !can_act)
		return FALSE
	if(get_dist(src, intruder) > dash_range)
		return FALSE
	var/turf/dash_start_turf = get_turf(src)
	var/turf/dash_target_turf = get_ranged_target_turf_direct(src, intruder, dash_range)
	if(!dash_target_turf)
		return FALSE
	dash_cooldown = world.time + dash_cooldown_time
	PrepareDash()
	LoseTarget()
	/// This section is for telegraphing the attack.
	face_atom(intruder)
	// Hard deletes this telegraph for some reason.
	var/obj/effect/temp_visual/dragon_swoop/bubblegum/shrimp_qm/telegraph = new(dash_start_turf)
	walk_towards(telegraph, dash_target_turf, 0.1 SECONDS)
	SLEEP_CHECK_DEATH(0.9 SECONDS)
	/// We're now dashing.
	BeginDash()
	walk_towards(src, dash_target_turf, 0.2)
	SLEEP_CHECK_DEATH(get_dist(src, dash_target_turf) * 0.2)
	/// Yes it needs to get slept for 0.2 seconds here because... it hasn't finished moving or something. I've tested it. Trust me.
	SLEEP_CHECK_DEATH(0.2 SECONDS)
	CancelDash()

	walk(src, 0)
	return TRUE

/mob/living/simple_animal/hostile/shrimp_qm/proc/PrepareDash()
	walk_to(src, 0)
	preparing = TRUE
	dashing = FALSE
	/// Can't get pushed away during this.
	anchored = TRUE
	/// Reset our hit lists.
	dash_hitlist = list()
	dash_hitlist_turfs = list()

/mob/living/simple_animal/hostile/shrimp_qm/proc/BeginDash()
	preparing = FALSE
	/// All turfs we move into while dashing as long as this variable is TRUE will be registered by Move() to be passed onto ShrimpChargeHit() by ShrimpCharge().
	dashing = TRUE
	/// We can move again.
	anchored = FALSE
	/// We can move through mobs and tables.
	pass_flags = PASSMOB | PASSTABLE
	density = FALSE

/mob/living/simple_animal/hostile/shrimp_qm/proc/CancelDash()
	dashing = FALSE
	anchored = FALSE
	pass_flags = initial(pass_flags)
	density = TRUE

/mob/living/simple_animal/hostile/shrimp_qm/proc/ShrimpChargeHit(turf/impacted)
	if(istype(impacted))
		for(var/mob/living/hit_mob in HurtInTurf(impacted, dash_hitlist, melee_damage_upper * 0.8, melee_damage_type, check_faction = TRUE, exact_faction_match = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE))
			if(hit_mob.stat >= DEAD)
				continue
			var/hit_id = AddIdentifier(hit_mob)
			if(hit_id in dash_hitlist)
				continue
			dash_hitlist += hit_id
			to_chat(hit_mob, span_userdanger("[src] slams you straight into the ground as he dashes past!"))
			playsound(hit_mob, attack_sound, 100)
			hit_mob.Knockdown(20)
			// Big slice VFX
			var/obj/effect/temp_visual/dir_setting/slash/temp = new(impacted)
			temp.dir = dir
			temp.transform = temp.transform * 2.5
			temp.color = COLOR_RED


/obj/effect/temp_visual/dragon_swoop/bubblegum/shrimp_qm
	duration = 0.91 SECONDS
	layer = POINT_LAYER
	movement_type = FLYING | PHASING
