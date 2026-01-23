/mob/living/simple_animal/hostile/ordeal/grungeon_boss
	name = "denial of concept" //Placeholder name
	desc = "A massive metallic dome outfitted with several cannons and guns."
	icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
	icon_state = "grungeonboss"
	icon_living = "grungeonboss"
	icon_dead = "grungeonboss"
	attack_sound = 'sound/abnormalities/clock/clank.ogg'
	layer = LYING_MOB_LAYER
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	occupied_tiles_left = 1
	occupied_tiles_right = 1
	occupied_tiles_up = 1
	occupied_tiles_down = 1
	faction = list("green_ordeal")
	gender = NEUTER
	mob_biotypes = MOB_ROBOTIC
	maxHealth = 25000
	health = 25000
	melee_damage_lower = 5
	melee_damage_upper = 5
	ranged = TRUE
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1)
	butcher_results = list(/obj/item/food/meat/slab/robot = 22)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 16)
	death_sound = 'sound/effects/ordeals/green/midnight_dead.ogg'
	offsets_pixel_x = list("south" = -96, "north" = -96, "west" = -96, "east" = -96)
	damage_effect_scale = 1.25
	rapid = 50
	rapid_fire_delay = 0.4
	projectilesound = 'sound/weapons/gun/smg/shot.ogg'
	casingtype = /obj/item/ammo_casing/caseless/soda_mini
	var/datum/beam/current_beam = null
	var/can_act = TRUE
	var/napalm_cooldown
	var/napalm_cd_duration = 60 SECONDS
	melee_reach = 0

//Enemies made by Xeros with bits of help from other coders listed below.

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/Move()
	return FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/OpenFire(atom/A) //We able to burn them? No? Rev up the minigun.
	if(!can_act)
		return
	if(napalm_blast())
		return FALSE
	if(PrepareToFire(A))
		return ..()
	return FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/proc/PrepareToFire(atom/A) //Copypasted code from TTLS snipers. Intended to serve as the "warning" for the minigun.
	var/turf/my_turf = get_turf(src) //Slight alteration so there isn't any visual bugs. Many thanks to Eidos on the discord for helping me with this.
	current_beam = my_turf.Beam(A, icon_state="blood", time = 2.2 SECONDS)
	can_act = FALSE
	SLEEP_CHECK_DEATH(2.6 SECONDS)
	can_act = TRUE
	return TRUE

/obj/item/ammo_casing/caseless/soda_mini
	name = "9mm casing"
	desc = "A 9mm casing."
	projectile_type = /obj/projectile/ego_bullet/ego_soda
	variance = 45

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/proc/shoot_projectile(turf/marker, set_angle) //Copypasted Colossus Code
	if(!isnum(set_angle) && (!marker || marker == loc))
		return
	var/turf/startloc = get_turf(src)
	var/obj/projectile/P = new /obj/projectile/ego_bullet/napalm(startloc)
	P.preparePixelProjectile(marker, startloc)
	P.firer = src
	if(target)
		P.original = target
	P.fire(set_angle)

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/proc/dir_shots(list/dirs) //Many, many thanks to Destrok for helping me find out how in the goddamn I was supposed to do this
	if(!islist(dirs))
		dirs = GLOB.alldirs.Copy()
	SLEEP_CHECK_DEATH(3)
	playsound(src, 'sound/weapons/ego/cannon.ogg', 150, TRUE, 2)
	for(var/d in dirs)
		var/turf/E = get_step(src, d)
		shoot_projectile(E)

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/proc/napalm_blast() //The bane of my fucking existence
	if(napalm_cooldown>world.time)
		return FALSE
	playsound(src, 'sound/magic/clockwork/invoke_general.ogg', 200, TRUE, 2)
	napalm_cooldown = (world.time+napalm_cd_duration)
	SLEEP_CHECK_DEATH(10)
	dir_shots(GLOB.cardinals)
	dir_shots(GLOB.diagonals)
	return TRUE

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/AttackingTarget() //AoE attack to shove people far enough away that the boss can get their other attacks off//
	can_act = FALSE
	playsound(get_turf(src), attack_sound, 200, 0, 3)
	SLEEP_CHECK_DEATH(15)
	for(var/turf/T in view(4, src))
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/H in HurtInTurf(T, list(), melee_damage_upper, FIRE, check_faction = TRUE, hurt_mechs = TRUE))
			var/atom/throw_target = get_edge_target_turf(H, dir)
			if(!H.anchored)
				H.throw_at(throw_target, rand(6, 10), 18, H)
	playsound(get_turf(src), 'sound/machines/clockcult/steam_whoosh.ogg', 150, 0, 3)
	SLEEP_CHECK_DEATH(3)
	icon_state = icon_living
	can_act = TRUE

//Spawner stuff//

/mob/living/simple_animal/hostile/ordeal/grungeon_spawner
	name = "Factory Chute"
	desc = "A chute which seems to routinely pump out enemies. Completely impervious to all methods of deconstruction."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "grungeonchute"
	icon_living = "grungeonchute"
	icon_dead = "grungeonchute_dead"
	faction = list("green_ordeal")
	health = 1000
	maxHealth = 1000
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	gender = NEUTER
	density = 0
	mob_biotypes = MOB_ROBOTIC
	death_sound = 'sound/effects/ordeals/green/dusk_dead.ogg'
	var/spawn_progress = 18 //spawn ready to produce robots
	var/list/spawned_mobs = list()
	var/producing = FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_spawner/Move()
	return FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_spawner/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_spawner/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	listclearnulls(spawned_mobs)
	for(var/mob/living/L in spawned_mobs)
		if(L.stat == DEAD || QDELETED(L))
			spawned_mobs -= L
	if(producing)
		return
	update_icon()
	if(length(spawned_mobs) >= 2)
		return
	if(spawn_progress < 15)
		spawn_progress += 1
		return
	Produce()

/mob/living/simple_animal/hostile/ordeal/grungeon_spawner/proc/Produce() //Another bane of my existence
	if(producing || stat == DEAD)
		return
	producing = TRUE
	SLEEP_CHECK_DEATH(6)
	visible_message(span_danger("\The [src] produces a new set of robots!"))
	for(var/i = 1 to 1)
		var/picked_mob = /mob/living/simple_animal/hostile/ordeal/green_bot/fast/factory

		var/mob/living/simple_animal/hostile/ordeal/nb = new picked_mob(get_turf(src))
		spawned_mobs += nb
		if(ordeal_reference)
			nb.ordeal_reference = ordeal_reference
			ordeal_reference.ordeal_mobs += nb
		SLEEP_CHECK_DEATH(1)
	SLEEP_CHECK_DEATH(2)
	icon = initial(icon)
	producing = FALSE
	spawn_progress = -5 // Basically, puts us on a tiny cooldown
	update_icon()

///mob/living/simple_animal/hostile/ordeal/grungeon_spawner/Initialize() //idk if this is actually the right way to go about this ngl

/mob/living/simple_animal/hostile/ordeal/grungeon_boss/death()
	var/obj/structure/grungeon_bomb/b = new /obj/structure/grungeon_bomb(loc)
	b.faction = faction
	. = ..()
	gib()
	for(var/mob/living/simple_animal/hostile/ordeal/grungeon_spawner/Z in range(15, src)) //Many thanks to Ender for helping me see the minor error in the code that prevented this from working.
		Z.death()

/obj/structure/grungeon_bomb //bomb shamelessly copypasted from Ender's Resurgence Demoman
	name = "Bomb of Oblivion"
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_48x48.dmi'
	desc = "There is an engraving that says, 'If we're going down, we're taking you with us.'"
	icon_state = "demolisher_bomb"
	max_integrity = 5000
	pixel_x = -8
	base_pixel_x = -8
	density = FALSE
	layer = BELOW_OBJ_LAYER
	armor = list(RED_DAMAGE = 100, WHITE_DAMAGE = 100, BLACK_DAMAGE = 100, PALE_DAMAGE = 100)
	var/object_break = FALSE
	var/detonate_time = 120
	var/beep_time = 10
	var/beep_counter = 0
	var/detonate_max_damage = 3000
	var/detonate_min_damage = 150
	var/detonate_object_max_damage = 40
	var/detonate_object_min_damage = 15
	var/list/faction = list("hostile")

/obj/structure/grungeon_bomb/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(detonate)), detonate_time)
	addtimer(CALLBACK(src, PROC_REF(beep)), beep_time)

/obj/structure/grungeon_bomb/proc/beep()
	playsound(loc, 'sound/items/timer.ogg', 40, 3, 3)
	if (beep_counter == 0)
		say("T-10 Seconds before detonation...")
	else if (beep_counter == 5)
		say("T-5 Seconds before detonation...")
	else if (beep_counter == 7)
		say("3...")
	else if (beep_counter == 8)
		say("2...")
	else if (beep_counter == 9)
		say("1...")
	else if (beep_counter == 10)
		say("Join us.")

	beep_counter++
	addtimer(CALLBACK(src, PROC_REF(beep)), beep_time)

/obj/structure/grungeon_bomb/proc/detonate()
	var/mob/living/carbon/human/dummy/D = new /mob/living/carbon/human/dummy(get_turf(src))
	D.faction = faction
	new /obj/effect/temp_visual/explosion/fast(get_turf(src))
	playsound(src, 'sound/effects/explosion1.ogg', 75, TRUE)
	for(var/mob/living/L in view(12, src))
		if(D.faction_check_mob(L, FALSE))
			continue
		var/dist = get_dist(D, L)
		if(ishuman(L)) //Different damage formulae for humans vs mobs
			L.deal_damage(clamp((15 * (2 ** (8 - dist))), detonate_min_damage, detonate_max_damage), FIRE) //15-3840 damage scaling exponentially with distance
		else
			L.deal_damage(600 - ((dist > 2 ? dist : 0 )* 75), FIRE) //0-600 damage scaling on distance, we don't want it oneshotting mobs
		if(object_break)
			for(var/turf/T in view(8, src))
				for(var/obj/S in T)
					S.take_damage(clamp((15 * (2 ** (8 - dist))), detonate_object_min_damage, detonate_object_max_damage), RED_DAMAGE)
	explosion(loc, 0, 0, 1)
	qdel(D)
	qdel(src)
