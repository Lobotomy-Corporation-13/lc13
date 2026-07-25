// Fragmentum Touched ordeal mobs: base templates.
// Each is a /fragmentum subtype of an ordeal mob with its corrupted icon,
// name and desc. State names in the fragmentum DMIs match the originals, so
// only icon is overridden (icon_state/living/dead resolve inside the new file).
//
// Loot: instead of meat, each drops its ordeal colour's Pathstrider Trace
// Material (family by colour, rarity mix by tier: dawn=T1, noon=T1+some T2,
// dusk=T2+some T3). Meat harvests are cleared. Summoned adds (green factory
// bots, crimson splits) drop nothing, so a summoner can't be farmed twice.

// Global drop helpers (no changes to the base ordeal type).

/// Spawns a trace-material stack of the given family/tier at a turf.
/proc/SpawnFragMat(turf/T, family, tier, amount)
	if(!T || !family || amount <= 0)
		return
	var/mat_type = GetPathMatType("trace", family, tier)
	if(mat_type)
		new mat_type(T, amount)

/// Drops a fragmentum mob's trace material by family, rolling the tier mix.
/proc/SpawnFragmentumLoot(turf/T, family, tier)
	if(!T || !family)
		return
	switch(tier)
		if(1) // dawn -> T1
			SpawnFragMat(T, family, 1, rand(3, 5))
		if(2) // noon -> mostly T1, sometimes T2
			SpawnFragMat(T, family, 1, rand(3, 5))
			if(prob(35))
				SpawnFragMat(T, family, 2, 1)
		if(3) // dusk -> mostly T2, sometimes T3
			SpawnFragMat(T, family, 2, rand(3, 6))
			if(prob(35))
				SpawnFragMat(T, family, 3, 1)

// Green (Lens)
/mob/living/simple_animal/hostile/ordeal/green_bot/fragmentum
	name = "fragmentum doubt alpha"
	desc = "A slim robot with a spear in place of its hand, its frame split open by jagged black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/green_bot/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 1)

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/fragmentum
	name = "fragmentum doubt beta"
	desc = "A slim robot with a syringe in place of its hand. Corrosion has fused the needle to a growth of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 1)

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/fragmentum
	name = "fragmentum doubt gamma"
	desc = "A slim robot with two spears. Crystal bristles from every joint, and it twitches with alien speed."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 1)

/mob/living/simple_animal/hostile/ordeal/green_bot_big/fragmentum
	name = "fragmentum process of understanding"
	desc = "A big robot with a saw and a machine gun in place of its hands, half-swallowed by crystalline corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/green_bot_big/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 2)

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum
	name = "fragmentum where we must reach"
	desc = "A factory-like structure, still birthing ancient robots even as black crystal devours its shell."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dusk.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null
	/// Next world.time the AoE barrage may fire.
	var/barrage_cooldown = 0
	/// Radius of turfs the barrage scatters its markers across.
	var/barrage_range = 7

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 3)

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/Life()
	. = ..()
	if(!.)
		return
	if(world.time >= barrage_cooldown)
		barrage_cooldown = world.time + 15 SECONDS
		INVOKE_ASYNC(src, PROC_REF(FragmentumBarrage))

/// Scatters a mix of 1x1 and 3x3 AoE warning markers over random nearby turfs,
/// weighted toward 1x1, spawning them one at a time with a 0.2s gap.
/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/proc/FragmentumBarrage()
	var/list/candidates = list()
	for(var/turf/open/T in RANGE_TURFS(barrage_range, src))
		candidates += T
	if(!length(candidates))
		return
	for(var/i = 1 to rand(9, 14))
		if(stat == DEAD)
			return
		var/turf/T = pick(candidates)
		if(prob(28))
			new /obj/effect/temp_visual/helix_macrolaser(T)
		else
			new /obj/effect/temp_visual/helix_minilaser(T)
		SLEEP_CHECK_DEATH(2)

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/ProduceRobot()
	var/turf/T = get_step(get_turf(src), pick(0, EAST))
	var/picked_mob = /mob/living/simple_animal/hostile/ordeal/green_bot_big/factory/fragmentum
	if(prob(50))
		picked_mob = pick(
			/mob/living/simple_animal/hostile/ordeal/green_bot/factory/fragmentum,
			/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/factory/fragmentum,
			/mob/living/simple_animal/hostile/ordeal/green_bot/fast/factory/fragmentum,)
	var/mob/living/simple_animal/hostile/ordeal/nb = new picked_mob(T)
	spawned_mobs += nb
	if(ordeal_reference)
		nb.ordeal_reference = ordeal_reference
		ordeal_reference.ordeal_mobs += nb
	RegisterSignal(nb, COMSIG_PARENT_QDELETING, PROC_REF(DelinkRobot))
	return nb

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/Produce()
	if(producing || stat == DEAD)
		return
	producing = TRUE
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dusk_create.dmi'
	icon_state = "green_dusk_create"
	SLEEP_CHECK_DEATH(6)
	visible_message(span_danger("\The [src] produces a new set of robots!"))
	for(var/i = 1 to 3)
		ProduceRobot()
		SLEEP_CHECK_DEATH(1)
	SLEEP_CHECK_DEATH(2)
	icon = initial(icon)
	producing = FALSE
	spawn_progress = -5
	update_icon()

// Fragmentum factory-spawn variants: summoned adds, so they drop nothing.
/mob/living/simple_animal/hostile/ordeal/green_bot/factory/fragmentum
	name = "fragmentum doubt alpha"
	desc = "A slim robot with a spear in place of its hand, its frame split open by jagged black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/factory/fragmentum
	name = "fragmentum doubt beta"
	desc = "A slim robot with a syringe in place of its hand. Corrosion has fused the needle to a growth of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/factory/fragmentum
	name = "fragmentum doubt gamma"
	desc = "A slim robot with two spears. Crystal bristles from every joint, and it twitches with alien speed."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_dawn.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/green_bot_big/factory/fragmentum
	name = "fragmentum process of understanding"
	desc = "A big robot with a saw and a machine gun in place of its hands, half-swallowed by crystalline corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_green_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

// Crimson (Ichor)
/obj/projectile/fragmentum_dodgeball
	name = "corroded circus ball"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "dodgeball"
	damage = 12
	damage_type = WHITE_DAMAGE
	speed = 1
	range = 12

/// Against a target who has already gone insane (where white damage would only
/// heal their sanity), the ball corrodes into flesh instead: it deals RED.
/obj/projectile/fragmentum_dodgeball/on_hit(atom/target, blocked = FALSE, pierce_hit)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.sanity_lost)
			damage_type = RED_DAMAGE
	return ..()

// The dawn clown drops its console-sabotage act and becomes a skittish ranged
// kiter: it keeps its distance and pelts targets with WHITE-damage dodgeballs.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum
	name = "fragmentum cheers for the start"
	desc = "A tiny humanoid in jester's attire, its grin frozen and its body studded with black crystal shards."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_crimson_dawn.dmi'
	search_objects = 0
	wanted_objects = list()
	ranged = TRUE
	retreat_distance = 5
	minimum_distance = 6
	ranged_cooldown_time = 20
	projectiletype = /obj/projectile/fragmentum_dodgeball
	projectilesound = 'sound/effects/ordeals/crimson/ball.ogg'
	melee_damage_lower = 8
	melee_damage_upper = 12
	drop_meat = FALSE
	butcher_results = list(/obj/item/stack/trace_material/ichor = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	FragmentumDrop(T)

/// Loot hook, so no-loot /spawned splits can suppress it.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/proc/FragmentumDrop(turf/T)
	SpawnFragmentumLoot(T, TRACE_FAMILY_ICHOR, 1)

/// No-op: this variant hunts agents instead of teleporting to consoles.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/TeleportAway()
	return

/// Parent only allows attacking consoles; retarget onto living enemies.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/CanAttack(atom/the_target)
	if(QDELETED(the_target) || isturf(the_target) || !isliving(the_target))
		return FALSE
	var/mob/living/L = the_target
	if(L.status_flags & GODMODE)
		return FALSE
	if(L.stat > stat_attack)
		return FALSE
	if(faction_check_mob(L) && !attack_same)
		return FALSE
	return TRUE

// Spawned by a crimson split: identical kiter, but drops no loot.
/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/spawned/FragmentumDrop(turf/T)
	return

/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum
	name = "fragmentum harmony of skin"
	desc = "A large clown-like creature with 3 heads full of red tumors, now sprouting crystal spines between the growths."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_crimson_noon.dmi'
	clown_derivitive = /mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/spawned
	butcher_results = list(/obj/item/stack/trace_material/ichor = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	FragmentumDrop(T)

/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum/proc/FragmentumDrop(turf/T)
	SpawnFragmentumLoot(T, TRACE_FAMILY_ICHOR, 2)

// Spawned by a dusk split: drops no loot, and its own splits also drop nothing.
/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum/spawned
	clown_derivitive = /mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/spawned

/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum/spawned/FragmentumDrop(turf/T)
	return

/mob/living/simple_animal/hostile/ordeal/crimson_noon/crimson_dusk/fragmentum
	name = "fragmentum struggle of the peak"
	desc = "A round clown amalgamation holding a hammer and an axe, its flesh cracked open by veins of glowing corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_crimson_dusk.dmi'
	clown_derivitive = /mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum/spawned
	butcher_results = list(/obj/item/stack/trace_material/ichor = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/crimson_noon/crimson_dusk/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_ICHOR, 3)

// Amber (Ichor)
/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum
	name = "fragmentum complete food"
	desc = "A tiny worm-like creature with tough chitin and a pair of sharp claws, its shell overgrown with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_amber_dawn.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ichor = 1)
	guaranteed_butcher_results = null
	silk_results = null
	can_burrow_solo = FALSE // Cannot burrow-teleport across the map

/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_ICHOR, 1)

/// Resurface only on a turf that has line of sight to where it dug in, so it
/// can't emerge through a wall from its spawn point.
/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum/BurrowOut(turf/T)
	if(!T)
		T = get_turf(src)
	burrowing = TRUE
	alpha = 0
	var/list/visible = view(2, T)
	var/list/valid_turfs = list()
	for(var/turf/PT in RANGE_TURFS(2, T))
		if(PT.is_blocked_turf_ignore_climbable())
			continue
		if(!(PT in visible)) // must have line of sight to the dig-in turf
			continue
		valid_turfs |= PT
	if(!length(valid_turfs))
		valid_turfs = list(T)
	var/turf/target_turf = pick(valid_turfs)
	forceMove(target_turf)
	new /obj/effect/temp_visual/small_smoke/halfsecond(target_turf)
	animate(src, alpha = 255, time = 5)
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 25, 1)
	visible_message(span_bolddanger("[src] burrows out from the ground!"))
	SLEEP_CHECK_DEATH(5)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(target_turf, src)
	animate(D, alpha = 0, transform = matrix() * 1.5, time = 5)
	for(var/mob/living/L in target_turf)
		if(!faction_check_mob(L))
			L.deal_damage(5, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	burrow_cooldown = world.time + burrow_cooldown_time
	burrowing = FALSE

/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum
	name = "fragmentum food chain"
	desc = "A big worm-like creature with jagged teeth. Black crystal erupts along its back where its segments used to be."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_amber_dusk.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ichor = 1)
	guaranteed_butcher_results = null
	silk_results = null
	/// How far to look for a player to resurface beneath
	var/burrow_reach = 9
	/// Dawns spawned each time it resurfaces
	var/dawns_per_burrow = 3
	/// world.time until which it cannot attack (post-emerge lockout)
	var/emerge_attack_cd = 0

/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_ICHOR, 3)

/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/CanAttack(atom/the_target)
	if(world.time < emerge_attack_cd)
		return FALSE
	return ..()

/// The periodic four-bug birth is replaced by the ambush burrow below.
/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/AttemptBirth()
	return FALSE

/// Short-range ambush burrow: dive, then resurface beneath a nearby player
/// instead of teleporting to a random spawn across the map.
/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/BurrowIn()
	burrowing = TRUE
	var/turf/dest = GetBurrowDestination()
	visible_message(span_danger("[src] burrows into the ground!"))
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dusk_dig_in.ogg', 50, 1)
	animate(src, alpha = 0, time = 5)
	SLEEP_CHECK_DEATH(5)
	density = FALSE
	forceMove(dest)
	BurrowOut(dest)

/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/BurrowOut(turf/T)
	..() // Standard resurface (smoke, dig-out sound, AoE hit, cooldown)
	SpawnBurrowDawns()
	emerge_attack_cd = world.time + 10 // Cannot attack for ~1 second

/// Nearest living non-ally within reach; falls back to its own turf (no teleport).
/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/proc/GetBurrowDestination()
	var/mob/living/prey
	var/best_dist = INFINITY
	for(var/mob/living/carbon/human/H in range(burrow_reach, src))
		if(faction_check_mob(H) || H.stat == DEAD)
			continue
		var/d = get_dist(src, H)
		if(d < best_dist)
			best_dist = d
			prey = H
	return prey ? get_turf(prey) : get_turf(src)

/// Spawn a few fragmentum dawns on open tiles around the dusk.
/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/proc/SpawnBurrowDawns()
	var/turf/origin = get_turf(src)
	var/tries = dawns_per_burrow + 3
	var/spawned = 0
	while(spawned < dawns_per_burrow && tries > 0)
		tries--
		var/turf/T = get_step(origin, pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
		if(!T || T.density)
			continue
		var/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum/dawn = new(T)
		spawned++
		if(ordeal_reference)
			dawn.ordeal_reference = ordeal_reference
			ordeal_reference.ordeal_mobs += dawn

// Indigo (Fang)
/mob/living/simple_animal/hostile/ordeal/indigo_dawn/fragmentum
	name = "fragmentum unknown scout"
	desc = "A tall humanoid with a walking cane, its indigo armor pierced through by shards of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/invis/fragmentum
	name = "fragmentum unknown scout"
	desc = "A tall humanoid with a walking cane, its indigo armor pierced through by shards of black crystal. It barely seems to be there."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/invis/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/skirmisher/fragmentum
	name = "fragmentum unknown scout"
	desc = "A tall humanoid with a walking cane, its indigo armor pierced through by shards of black crystal. This one keeps its distance."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/skirmisher/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/indigo_noon/fragmentum
	name = "fragmentum sweeper"
	desc = "A humanoid in metallic armor with bloodied hooks. Crystalline corrosion has grafted itself to the hooks and helm."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/fragmentum
	name = "fragmentum sweeper"
	desc = "A humanoid in metallic armor with bloodied hooks. Slabs of black crystal have thickened its bulk; it won't go down easy."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/fragmentum
	name = "fragmentum sweeper"
	desc = "A humanoid in metallic armor with bloodied hooks. Thin crystal spines lace its limbs, and it moves with unnatural agility."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/fragmentum
	name = "\proper Fragmentum Commander Jacques"
	desc = "A tall humanoid with red claws dripping blood, black crystal splitting the skin of his arms."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 3)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/fragmentum
	name = "\proper Fragmentum Commander Silvina"
	desc = "A tall humanoid with glowing pale fists, now ringed with jagged corrosion crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 3)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/fragmentum
	name = "\proper Fragmentum Commander Adelheide"
	desc = "A tall humanoid with a white greatsword, its edge fused to a growth of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 3)

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/fragmentum
	name = "\proper Fragmentum Commander Maria"
	desc = "A tall humanoid with a large black hammer, crystalline corrosion crawling up the haft."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_indigo_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 3)

// Steel (Ward)
/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum
	name = "fragmentum gene corp remnant"
	desc = "An insect-augmented Gene corp remnant, its carapace shattered and regrown as black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ward = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_WARD, 1)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/fragmentum
	name = "fragmentum gene corp corporal"
	desc = "A heavily mutated employee with two sharp insectoid arms, now barbed with fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ward = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_WARD, 2)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying/fragmentum
	name = "fragmentum gene corp arial scout"
	desc = "A winged, mutated employee with long insectoid arms. Corrosion crystal weighs down its ragged wings."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ward = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_WARD, 2)

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/fragmentum
	name = "fragmentum gene corp corpsmen"
	desc = "An insect-augmented employee clutching a scavenged dufflebag, its body knotted with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ward = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_WARD, 1)

/mob/living/simple_animal/hostile/ordeal/steel_dusk/fragmentum
	name = "fragmentum gene corp manager"
	desc = "A bug-headed Gene corp manager. Fragmentum crystal twists its shrieking sonics into something that warps the air."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_steel_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ward = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/steel_dusk/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_WARD, 3)

// Violet (Ichor)
/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum
	name = "fragmentum fruit of understanding"
	desc = "A round purple creature leaking mind-damaging gas, its rind cracked open by black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_violet_dawn.dmi'
	maxHealth = 625 // 2.5x the base fruit
	health = 625
	butcher_results = list(/obj/item/stack/trace_material/ichor = 1)
	guaranteed_butcher_results = null
	silk_results = null
	/// world.time of the next AoE black burst
	var/next_burst = 0
	/// Delay between bursts
	var/burst_cooldown = 12 SECONDS
	/// Massive black damage dealt to everything nearby on burst
	var/burst_damage = 60

/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum/Initialize()
	. = ..()
	next_burst = world.time + burst_cooldown

/// The fragmentum fruit never gasses itself to death — that suicide is replaced
/// by the recurring AoE black burst in Life().
/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum/ReleaseDeathGas()
	return

/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(world.time >= next_burst)
		next_burst = world.time + burst_cooldown
		BlackBurst()
	return TRUE

/// Erupt with massive black damage to everything nearby, then keep living.
/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum/proc/BlackBurst()
	var/turf/origin = get_turf(src)
	visible_message(span_bolddanger("[src] convulses and erupts with dark energy!"))
	playsound(origin, 'sound/effects/ordeals/violet/fruit_suicide.ogg', 50, 1, 16)
	for(var/turf/open/T in view(4, src))
		new /obj/effect/temp_visual/revenant(T)
	for(var/mob/living/L in view(4, src))
		if(faction_check_mob(L))
			continue
		L.deal_damage(burst_damage, BLACK_DAMAGE, src, flags = (DAMAGE_FORCED))

/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_ICHOR, 1)

/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum
	name = "fragmentum grant us love"
	desc = "A dark monolith covered in incomprehensible writing, the script now bleeding gold light through crystalline fractures."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_violet_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/ichor = 1)
	guaranteed_butcher_results = null
	silk_results = null
	/// world.time the projectile line attack is next available
	var/line_cooldown = 0
	/// world.time the melee retaliation is next available
	var/melee_warn_cd = 0
	/// Black damage of the projectile-triggered line attack
	var/line_damage = 20
	/// Black damage of the melee 5x5 retaliation
	var/melee_damage = 30

/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_ICHOR, 2)

/// No landing shockwave — the fragmentum monolith drops in harmlessly.
/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/FallDown()
	pixel_z = 128
	alpha = 0
	density = FALSE
	animate(src, pixel_z = 0, alpha = 255, time = 10)
	SLEEP_CHECK_DEATH(10)
	density = TRUE
	visible_message(span_danger("[src] drops down from the ceiling!"))
	playsound(get_turf(src), 'sound/effects/ordeals/violet/monolith_down.ogg', 65, 1)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(get_turf(src), src)
	animate(D, alpha = 0, transform = matrix() * 2, time = 5)
	for(var/turf/open/T in view(4, src))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	SLEEP_CHECK_DEATH(5)
	icon_state = "violet_noon_attack"

/// Getting shot has a 50% chance to telegraph a line at the shooter.
/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	. = ..()
	if(world.time < line_cooldown)
		return
	var/mob/living/shooter = P?.firer
	if(!istype(shooter) || faction_check_mob(shooter))
		return
	if(!prob(50))
		return
	line_cooldown = world.time + 2 SECONDS
	INVOKE_ASYNC(src, PROC_REF(LineWarningAttack), shooter)

/// Telegraph a line to the target (extending a little past), then after 0.5s
/// hit whoever is still on it with black damage and reel them in.
/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/proc/LineWarningAttack(mob/living/target)
	var/turf/origin = get_turf(src)
	var/turf/tturf = get_turf(target)
	if(!origin || !tturf || origin == tturf)
		return
	var/reach = get_dist(origin, tturf) + 2 // extend lightly past the target
	var/turf/beyond = get_ranged_target_turf_direct(origin, tturf, reach)
	var/list/line = getline(origin, beyond) - origin
	for(var/turf/T in line)
		new /obj/effect/temp_visual/violet_warning(T)
	SLEEP_CHECK_DEATH(5) // 0.5 seconds
	for(var/turf/T in line)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			L.deal_damage(line_damage, BLACK_DAMAGE, src, flags = (DAMAGE_FORCED))
			Beam(L, "tentacle", time = 1 SECONDS) // pulling tendril, lasts 1s
			L.throw_at(src, reach, 2, src) // reel toward the monolith

/// Melee strikes leave a 5x5 warning that detonates after 1 second.
/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	if(world.time < melee_warn_cd)
		return
	melee_warn_cd = world.time + 4 SECONDS
	INVOKE_ASYNC(src, PROC_REF(MeleeWarningAttack))

/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/proc/MeleeWarningAttack()
	var/turf/origin = get_turf(src)
	var/list/area_turfs = RANGE_TURFS(2, origin) // 5x5
	for(var/turf/T in area_turfs)
		new /obj/effect/temp_visual/violet_warning/melee(T)
	SLEEP_CHECK_DEATH(10) // 1 second
	for(var/turf/T in area_turfs)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			L.deal_damage(melee_damage, BLACK_DAMAGE, src, flags = (DAMAGE_FORCED))

/// Pulse no longer touches abnormality qliphoth — it now deals unavoidable
/// black damage equal to 40% of max HP to everything within 7 tiles.
/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/PulseAttack()
	next_pulse = world.time + 15 SECONDS
	icon_state = "violet_noon_ability"
	for(var/i = 1 to 3)
		var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(get_turf(src), src)
		animate(D, alpha = 0, transform = matrix() * 1.5, time = 7)
		SLEEP_CHECK_DEATH(8)
	for(var/mob/living/L in view(7, src))
		if(faction_check_mob(L))
			continue
		L.deal_damage(L.maxHealth * 0.4, BLACK_DAMAGE, src, flags = (DAMAGE_FORCED))
	icon_state = "violet_noon_attack"

/obj/effect/temp_visual/violet_warning
	icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	icon_state = "target_box"
	layer = BELOW_MOB_LAYER
	color = "#7a3aa0"
	duration = 0.5 SECONDS

/obj/effect/temp_visual/violet_warning/melee
	duration = 1 SECONDS

// Brown / Seven Sins (Fang)
/mob/living/simple_animal/hostile/ordeal/sin_sloth/fragmentum
	name = "Fragmentum Peccatulum Acediae"
	desc = "It resembles a rock, one split open to reveal a core of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_sloth/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/fragmentum
	name = "Fragmentum Peccatulum Gulae"
	desc = "These plants gnash and gnaw like a rabid beast, their maws lined with corrosion crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/sin_gloom/fragmentum
	name = "Fragmentum Peccatulum Morositatis"
	desc = "An insect-like entity with a transparent body, black crystal suspended inside it like frozen rot."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_gloom/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/sin_pride/fragmentum
	name = "Fragmentum Peccatulum Superbiae"
	desc = "Those spikes look sharp, and half of them are now jagged fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_pride/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/sin_wrath/fragmentum
	name = "Fragmentum Peccatulum Irae"
	desc = "A dried tentacle full of glowing red liquid, its length crusted over with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_wrath/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/sin_lust/fragmentum
	name = "Fragmentum Peccatulum Luxuriae"
	desc = "A creature of fleshy lumps, eager to devour, its rolls split by veins of corrosion."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_lust.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_lust/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 1)

/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/fragmentum
	name = "Fragmentum Peccatulum Acediae?"
	desc = "Now the rock has more rocks, and every one of them weeps black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/fragmentum
	name = "Fragmentum Peccatulum Gulae?"
	desc = "Giant, hungry flowers. Is that blood, or corrosion seeping through the crystal?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/fragmentum
	name = "Fragmentum Peccatulum Morositatis?"
	desc = "A large translucent monster full of organs, throwing its crystal-laden weight around like a hammer."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/fragmentum
	name = "Fragmentum Peccatulum Superbiae?"
	desc = "A spiky wheel with clawed hands, its rim overgrown into a ring of black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/fragmentum
	name = "Fragmentum Peccatulum Irae?"
	desc = "A far bigger tentacle peccatula with a tail, corrosion crystal bursting from every seam."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

/mob/living/simple_animal/hostile/ordeal/sin_lust/noon/fragmentum
	name = "Fragmentum Peccatulum Luxuriae?"
	desc = "It holds its face up like a shield. The soft, rotten flesh is threaded with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_brown_noon.dmi'
	butcher_results = list(/obj/item/stack/trace_material/fang = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/sin_lust/noon/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_FANG, 2)

// Gold / Corrosion (Lens)
/mob/living/simple_animal/hostile/ordeal/fallen_amurdad_corrosion/fragmentum
	name = "Fragmentum Fallen Nepenthes"
	desc = "A level 1 Lobotomy Corporation agent, corrupted by an abnormality and then claimed again by Fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/fallen_amurdad_corrosion/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 1)

/mob/living/simple_animal/hostile/ordeal/beanstalk_corrosion/fragmentum
	name = "Fragmentum Beanstalk Searching for Jack"
	desc = "A Lobotomy Corporation clerk corrupted by an abnormality, its stalk now sheathed in black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32x48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/beanstalk_corrosion/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 1)

/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion/fragmentum
	name = "Fragmentum Lady of the Lake"
	desc = "An agent captain of central command, corrupted by an abnormality. Corrosion crystal has claimed what was left of her. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32x64.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 2)

/// Spawns the fragmentum handmaidens instead of the normal ones.
/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion/fragmentum/SpawnAdds()
	if(QDELETED(src))
		return
	adds_spawned = TRUE
	visible_message(span_danger("[src] screams!"))
	playsound(get_turf(src), 'sound/voice/human/femalescream_3.ogg', 75, 0, 4)
	var/matrix/init_transform = transform
	animate(src, transform = transform * 1.5, time = 3, easing = BACK_EASING | EASE_OUT)
	var/valid_directions = list(0)
	for(var/d in list(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST))
		var/turf/TF = get_step(src, d)
		if(!istype(TF))
			continue
		if(!TF.is_blocked_turf(TRUE))
			valid_directions += d
	for(var/i = 1 to 4)
		var/turf/T = get_step(get_turf(src), pick(valid_directions))
		var/mob/living/simple_animal/hostile/ordeal/silentgirl_corrosion/fragmentum/nc = new(T)
		if(ordeal_reference)
			nc.ordeal_reference = ordeal_reference
			ordeal_reference.ordeal_mobs += nc
	can_act = FALSE
	SLEEP_CHECK_DEATH(3)
	animate(src, transform = init_transform, time = 5)
	SLEEP_CHECK_DEATH(50)
	can_act = TRUE

/mob/living/simple_animal/hostile/ordeal/silentgirl_corrosion/fragmentum
	name = "Fragmentum Silent Handmaiden"
	desc = "A level 2 Lobotomy Corporation agent corrupted by an abnormality, her silence now edged with black crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/silentgirl_corrosion/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 2)

/mob/living/simple_animal/hostile/ordeal/centipede_corrosion/fragmentum
	name = "Fragmentum High-Voltage Centipede"
	desc = "An information team agent corrupted by an abnormality, its charge arcing across crystalline growths. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_64x48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/centipede_corrosion/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 3)

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion/fragmentum
	name = "Fragmentum Thunder Warrior"
	desc = "A disciplinary team agent corrupted by an abnormality, black crystal crackling along its frame. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32x48.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 3)

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion_boss/fragmentum
	name = "Fragmentum Thunder Chieftain"
	desc = "A disciplinary officer, heavily corrupted by an abnormality and studded through with fragmentum crystal."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_64.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion_boss/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 3)

/mob/living/simple_animal/hostile/ordeal/KHz_corrosion/fragmentum
	name = "Fragmentum 680 Ham Actor"
	desc = "A control team agent corrupted by an abnormality, its every gesture punctuated by jutting black crystal. But how?"
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_gold_32.dmi'
	butcher_results = list(/obj/item/stack/trace_material/lens = 1)
	guaranteed_butcher_results = null
	silk_results = null

/mob/living/simple_animal/hostile/ordeal/KHz_corrosion/fragmentum/death(gibbed)
	var/turf/T = get_turf(src)
	. = ..()
	SpawnFragmentumLoot(T, TRACE_FAMILY_LENS, 3)

// No gibs or blood. Fragmentum bodies crumble into crystal dust, so every
// variant suppresses its gib spawn (crimson /spawned splits inherit this).
/mob/living/simple_animal/hostile/ordeal/green_bot/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot_big/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot/factory/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/factory/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/factory/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot_big/factory/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/crimson_noon/crimson_dusk/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/invis/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/skirmisher/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/steel_dusk/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_sloth/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_gloom/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_pride/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_wrath/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_lust/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/sin_lust/noon/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/fallen_amurdad_corrosion/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/beanstalk_corrosion/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/silentgirl_corrosion/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/centipede_corrosion/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion_boss/fragmentum/spawn_gibs()
	return

/mob/living/simple_animal/hostile/ordeal/KHz_corrosion/fragmentum/spawn_gibs()
	return

// Every Fragmentum Touched mob keeps its original colour faction, but also
// joins a shared "fragmentum" faction so the different colour pools do not
// infight while they overrun the facility. (|= preserves any secondary
// factions the parent set, e.g. Gene_Corp, hostile, thunder_variant.)
/mob/living/simple_animal/hostile/ordeal/green_bot/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_bot_big/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_bot/factory/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/factory/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_bot/fast/factory/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/green_bot_big/factory/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/crimson_noon/crimson_dusk/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/invis/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_dawn/skirmisher/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/steel_dusk/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_sloth/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_gloom/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_pride/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_wrath/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_lust/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/sin_lust/noon/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/fallen_amurdad_corrosion/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/beanstalk_corrosion/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/silentgirl_corrosion/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/centipede_corrosion/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion_boss/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

/mob/living/simple_animal/hostile/ordeal/KHz_corrosion/fragmentum/Initialize()
	. = ..()
	faction |= "fragmentum"

