/obj/projectile/ego_bullet/ego_soda/rifle
	damage = 17
	speed = 0.25

/obj/projectile/ego_bullet/shrimp_red
	name = "9mm soda bullet R"
	damage = 8
	range = 12
	spread = 20
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/shrimp_white
	name = "9mm soda bullet W"
	damage = 70
	speed = 0.1
	damage_type = WHITE_DAMAGE
	projectile_piercing = PASSMOB

/obj/projectile/ego_bullet/shrimp_white/on_hit(atom/target, blocked = FALSE)
	..()
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	if(H.sanity_lost)
		var/obj/item/bodypart/head/head = H.get_bodypart("head")
		if(istype(head))
			if(QDELETED(head))
				return
			head.dismember()
			QDEL_NULL(head)
			H.regenerate_icons()
			visible_message(span_danger("[H]'s head blew right off!"))

/obj/projectile/ego_bullet/shrimp_pale
	name = "9mm soda bullet P"
	damage = 6
	damage_type = PALE_DAMAGE

/obj/projectile/ego_bullet/ego_kcorp
	damage = 15

/obj/projectile/ego_bullet/ego_knade
	damage = 15
	speed = 1
	icon_state = "kcorp_nade"

/obj/projectile/ego_bullet/ego_knade/on_hit(atom/target, blocked = FALSE)
	..()
	for(var/turf/T in view(1, src))
		for(var/mob/living/L in T)
			L.deal_damage(60, RED_DAMAGE, firer, attack_type = (ATTACK_TYPE_RANGED))
	new /obj/effect/explosion(get_turf(src))
	qdel(src)
	return BULLET_ACT_HIT

/obj/projectile/ego_bullet/flammenwerfer
	name = "flames"
	icon_state = "flamethrower_fire"
	damage = 1
	damage_type = RED_DAMAGE
	speed = 2
	range = 5
	hitsound_wall = 'sound/weapons/tap.ogg'
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser

/obj/projectile/ego_bullet/flammenwerfer/on_hit(atom/target, blocked = FALSE)
	..()
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	H.adjust_fire_stacks(0.1)
	H.IgniteMob()
	return BULLET_ACT_HIT

/obj/projectile/ego_bullet/tendamage
	name = "bullet"
	damage = 10

/obj/projectile/ego_bullet/napalm
	name = "napalm"
	icon_state = "pulse0"
	damage = 3
	damage_type = FIRE
	projectile_piercing = PASSMOB

/obj/projectile/ego_bullet/napalm/Move()
	..()
	for(var/turf/open/T in range(1, src))
		if(locate(/obj/effect/turf_fire/ardor) in T)
			for(var/obj/effect/turf_fire/ardor/floor_fire in T)
				qdel(floor_fire)
		new /obj/effect/turf_fire/ardor(T)

/obj/effect/turf_fire/ardor
	burn_time = 15 SECONDS

/obj/effect/turf_fire/ardor/DoDamage(mob/living/fuel)
	if(ishuman(fuel))
		fuel.deal_damage(4, FIRE)
		fuel.apply_lc_burn(2)
		return TRUE

/obj/projectile/beam/vulcan //Hitscan lasers for Descent into Malice and the Class-1 Driller
	name = "vulcan"
	icon_state = "omnilaser"
	hitsound = null
	damage = 20
	damage_type = RED_DAMAGE
	hitscan = TRUE
	muzzle_type = /obj/effect/projectile/muzzle/laser/vulcan
	tracer_type = /obj/effect/projectile/tracer/laser/vulcan
	impact_type = /obj/effect/projectile/impact/laser/vulcan
	wound_bonus = -100
	bare_wound_bonus = -100

/obj/effect/projectile/muzzle/laser/vulcan
	name = "vulcan flash"
	icon_state = "muzzle_vulcan"

/obj/effect/projectile/tracer/laser/vulcan
	name = "vulcan beam"
	icon_state = "vulcan"

/obj/effect/projectile/impact/laser/vulcan
	name = "vulcan impact"
	icon_state = "impact_vulcan"

/obj/projectile/ego_bullet/smart_missile //Used for Descent into Malice and the Boarshead
	name = "smart missile"
	icon_state = "pulse0"
	damage = 40 // Direct hit
	damage_type = RED_DAMAGE
	ignore_bulletproof = TRUE

/obj/projectile/ego_bullet/smart_missile/on_hit(atom/target, blocked = FALSE) //release the plasma
	..()
	for(var/i = 1 to 4)
		var/turf/T = get_step(get_turf(src), pick(1,2,4,5,6,8,9,10))
		if(T.density)
			i -= 1
			continue
		var/obj/projectile/ego_bullet/smart_plasma/P
		P = new(T)
		P.starting = T
		P.firer = src
		P.fired_from = T
		P.yo = target.y - T.y
		P.xo = target.x - T.x
		P.original = target
		P.preparePixelProjectile(target, T)
		addtimer(CALLBACK (P, TYPE_PROC_REF(/obj/projectile, fire)), 0.1)

/obj/projectile/ego_bullet/smart_plasma
	name = "plasma"
	icon_state = "green_laser"
	damage = 40
	damage_type = BLACK_DAMAGE
	speed = 5
	homing = TRUE
	homing_turn_speed = 75		//Angle per tick.
	var/homing_range = 7
	ricochets_max = 2 //I can't get this godforsaken sack of shit to go away from the wall properly without this so suffer
	ricochet_chance = 100
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1
	ricochet_auto_aim_range = 5
	ricochet_incidence_leeway = 0
/obj/projectile/ego_bullet/smart_plasma/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(fireback)), 3)

/obj/projectile/ego_bullet/smart_plasma/proc/fireback()
	icon_state = "green_laser"
	var/list/targetslist = list()
	for(var/mob/living/L in range(homing_range, src))
		if(ishuman(L) || isbot(L))
			continue
		if(L.stat == DEAD)
			continue
		if(L.status_flags & GODMODE)
			continue
		targetslist+=L
	if(!LAZYLEN(targetslist))
		return
	homing_target = pick(targetslist)

/obj/projectile/ego_bullet/smart_plasma/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	if(istype(A, /obj/structure/window))
		return TRUE
	if(istype(A, /obj/machinery/door))
		return TRUE

	return FALSE
