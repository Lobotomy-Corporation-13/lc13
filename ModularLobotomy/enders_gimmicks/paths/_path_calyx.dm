// Calyx system: Fragmentum incursions.
// On a non-ordeal meltdown the Calyx subsystem blooms 2-4 dormant Calyxes at
// the facility's xeno-spawn turfs. Each is themed to an ordeal colour (its
// Fragmentum mob pool) and rolls a danger tier. Tiers are UNLOCKED by clearing
// ordeals: finishing a Dawn ordeal unlocks Dawn (tier 1) Calyxes, a Noon ordeal
// unlocks Noon (tier 2), and so on. A crew member can touch a Calyx to tear it
// open, spilling waves of Fragmentum Touched creatures (which drop Trace
// Material on death). Ignored Calyxes wither.
//
// A Calyx mirrors ONE ordeal spawn point: its squad is that point's group -
// either a leaderless swarm (green/amber packs) or a single unique commander
// plus a refilling escort (steel/indigo/gold). Its live size never exceeds what
// one ordeal spawn point deploys; the commander, if any, is spawned only once.

// ---- Subsystem ----

SUBSYSTEM_DEF(calyx)
	name = "Calyx"
	flags = SS_NO_FIRE
	/// Highest ordeal tier the crew has cleared (1 dawn .. 4 midnight). A Calyx
	/// tier only appears once its matching ordeal tier has been finished; 0 = no
	/// Calyxes yet.
	var/unlocked_tier = 0
	/// TRUE only under the Pathstriders facility trait; gates all blooming.
	var/enabled = FALSE
	/// Currently-live Calyxes (dormant or active), oldest first, for the cap.
	var/list/active_calyxes = list()
	/// Most Calyxes allowed at once. Newer blooms clear the oldest over this.
	var/max_active = 5
	/// colour -> list(tier -> squad def). Built once. A squad def is
	/// list("leaders" = weighted list, "grunts" = weighted list, "count" = N).
	var/static/list/color_pools
	/// colour -> core tint hex. Built once.
	var/static/list/color_tints

/datum/controller/subsystem/calyx/Initialize(start_timeofday)
	. = ..()
	BuildPools()
	RegisterSignal(SSdcs, COMSIG_GLOB_MELTDOWN_START, PROC_REF(OnMeltdown))
	RegisterSignal(SSdcs, COMSIG_GLOB_ORDEAL_END, PROC_REF(OnOrdealEnd))
	// The Pathstriders facility trait switches the whole system on. Runs after
	// SSmaptype (trait chosen) and SSatoms (station structures exist).
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_PATHSTRIDERS)
		enabled = TRUE
		SpawnStarterSynth()

/// Places a starter Omni-Synthesizer on a table beside a random grid crafting
/// station, so a Pathstrider crew has somewhere to refine materials.
/datum/controller/subsystem/calyx/proc/SpawnStarterSynth()
	var/list/stations = list()
	for(var/obj/structure/grid_crafting_station/G in GLOB.lobotomy_devices)
		stations += G
	if(!length(stations))
		return
	for(var/obj/structure/grid_crafting_station/G in shuffle(stations))
		var/list/tables = list()
		for(var/obj/structure/table/T in orange(1, G))
			tables += T
		if(!length(tables))
			continue
		new /obj/machinery/omni_synthesizer(get_turf(pick(tables)))
		return

/// Clearing an ordeal unlocks Calyxes up to that ordeal's tier.
/datum/controller/subsystem/calyx/proc/OnOrdealEnd(datum/source, datum/ordeal/O)
	SIGNAL_HANDLER
	if(!istype(O) || O.level < 1 || O.level > 4)
		return
	if(O.level > unlocked_tier)
		unlocked_tier = O.level

/// Builds a squad def mirroring one ordeal spawn point.
/// boss: weighted list of a single unique commander, spawned once (null for a
///   leaderless swarm).
/// pool: weighted list of refillable mobs - a commander's escort, or the whole
///   swarm - respawned as they fall (null for a lone boss with no escort).
/// alive: how many mobs one ordeal spawn point fields at once; the Calyx never
///   keeps more than this alive.
/datum/controller/subsystem/calyx/proc/Squad(list/boss, list/pool, alive)
	return list("boss" = boss, "pool" = pool, "alive" = alive)

/datum/controller/subsystem/calyx/proc/BuildPools()
	if(color_pools)
		return
	color_pools = list(
		// Green (Lens): loose robot packs, 1 per spawn point; the dusk factory
		// self-produces, so one is plenty.
		"green" = list(
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/green_bot/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/green_bot/syringe/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/green_bot/fast/fragmentum = 1), 1),
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/green_bot_big/fragmentum = 1), 1),
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/green_dusk/fragmentum = 1), 1),
		),
		// Crimson (Ichor): clown swarms; noon/dusk split further on death.
		"crimson" = list(
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/crimson_clown/fragmentum = 1), 3),
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/crimson_noon/fragmentum = 1), 1),
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/crimson_noon/crimson_dusk/fragmentum = 1), 1),
		),
		// Amber (Ichor): worm broods; dawn spawns 3 per point, dusk 1.
		"amber" = list(
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/amber_bug/fragmentum = 1), 3),
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/amber_dusk/fragmentum = 1), 1),
		),
		// Indigo (Fang): scout pairs, sweeper packs, then a commander + sweepers.
		"indigo" = list(
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/indigo_dawn/fragmentum = 2,
				/mob/living/simple_animal/hostile/ordeal/indigo_dawn/invis/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/indigo_dawn/skirmisher/fragmentum = 1), 2),
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/indigo_noon/fragmentum = 3,
				/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky/fragmentum = 1), 4),
			Squad(list(/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black/fragmentum = 1),
				list(/mob/living/simple_animal/hostile/ordeal/indigo_noon/fragmentum = 1), 5),
		),
		// Steel (Ward): remnant packs, then a Gene Corp heavy escorted by remnants.
		"steel" = list(
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum = 1), 2),
			Squad(list(/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/fragmentum = 1),
				list(/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum = 1), 4),
			Squad(list(/mob/living/simple_animal/hostile/ordeal/steel_dusk/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/steel_dawn/medic/fragmentum = 1),
				list(/mob/living/simple_animal/hostile/ordeal/steel_dawn/fragmentum = 1), 7),
		),
		// Violet (Ichor): fruit swarm, then the lone monolith.
		"violet" = list(
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/violet_fruit/fragmentum = 1), 2),
			Squad(list(/mob/living/simple_animal/hostile/ordeal/violet_monolith/fragmentum = 1), null, 1),
		),
		// Brown (Fang): a leaderless sin swarm, then a noon Peccatulum + lesser sins.
		"brown" = list(
			Squad(null, list(/mob/living/simple_animal/hostile/ordeal/sin_sloth/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/sin_gluttony/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/sin_gloom/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/sin_pride/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/sin_wrath/fragmentum = 1,
				/mob/living/simple_animal/hostile/ordeal/sin_lust/fragmentum = 1), 2),
			Squad(list(/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_lust/noon/fragmentum = 1),
				list(/mob/living/simple_animal/hostile/ordeal/sin_sloth/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_gluttony/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_gloom/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_pride/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_wrath/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/sin_lust/fragmentum = 1), 8),
		),
		// Gold (Lens): corrupted agents; a commander with corrosion escorts, and
		// the Lady of the Lake, who fields her own handmaidens alone.
		"gold" = list(
			Squad(list(/mob/living/simple_animal/hostile/ordeal/fallen_amurdad_corrosion/fragmentum = 1),
				list(/mob/living/simple_animal/hostile/ordeal/beanstalk_corrosion/fragmentum = 1), 4),
			Squad(list(/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion/fragmentum = 1), null, 1),
			Squad(list(/mob/living/simple_animal/hostile/ordeal/centipede_corrosion/fragmentum = 1,
					/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion_boss/fragmentum = 1),
				list(/mob/living/simple_animal/hostile/ordeal/thunderbird_corrosion/fragmentum = 2,
					/mob/living/simple_animal/hostile/ordeal/KHz_corrosion/fragmentum = 1), 5),
		),
	)
	color_tints = list(
		"green" = "#33cc77",
		"crimson" = "#cc3333",
		"amber" = "#ffaa33",
		"indigo" = "#5566cc",
		"steel" = "#99aabb",
		"violet" = "#aa55dd",
		"brown" = "#997744",
		"gold" = "#ffcc33",
	)

/datum/controller/subsystem/calyx/proc/OnMeltdown(datum/source, ran_ordeal)
	SIGNAL_HANDLER
	if(ran_ordeal)
		return
	INVOKE_ASYNC(src, PROC_REF(BloomCalyxes))

/datum/controller/subsystem/calyx/proc/BloomCalyxes()
	if(!enabled) // only under the Pathstriders trait
		return
	if(unlocked_tier < 1) // no ordeal tier cleared yet, no Calyxes
		return
	if(!LAZYLEN(GLOB.xeno_spawn))
		return
	var/count = rand(2, 4)
	for(var/i in 1 to count)
		SpawnOneCalyx()

/datum/controller/subsystem/calyx/proc/SpawnOneCalyx()
	var/turf/T = get_turf(pick(GLOB.xeno_spawn))
	if(!T)
		return
	var/color = pick(color_pools)
	var/list/pools = color_pools[color]
	var/tier = RollTier(length(pools))
	var/obj/structure/calyx/C = new(T)
	C.Setup(color, tier, pools[tier], color_tints[color])
	active_calyxes += C
	EnforceCap()

/// Keeps at most `max_active` Calyxes alive by collapsing the oldest ones,
/// which reverts their corrupted turfs as they die.
/datum/controller/subsystem/calyx/proc/EnforceCap()
	while(length(active_calyxes) > max_active)
		var/obj/structure/calyx/oldest = active_calyxes[1]
		active_calyxes -= oldest
		if(!QDELETED(oldest))
			oldest.Collapse()

/// Highest cleared ordeal tier (capped by the colour's pool depth), weighted
/// toward the top so later Calyxes lean more dangerous.
/datum/controller/subsystem/calyx/proc/RollTier(color_max)
	var/unlocked = min(unlocked_tier, color_max)
	if(unlocked < 1)
		return 1
	var/list/weighted = list()
	for(var/t in 1 to unlocked)
		for(var/j in 1 to t)
			weighted += t
	return pick(weighted)

// ---- Calyx structure ----

/obj/structure/calyx
	name = "calyx"
	desc = "A blackened crystal-laced growth wound around a core of molten light. Something stirs inside it."
	icon = 'ModularLobotomy/_Lobotomyicons/calyx.dmi'
	icon_state = "calyx_closed"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	pixel_x = -16
	/// Ordeal colour theme.
	var/calyx_color = "green"
	/// Danger tier (1 = lesser .. 4 = fractal).
	var/tier = 1
	/// Core tint hex.
	var/color_tint = "#33cc77"
	/// Squad def for this tier: list("leaders", "grunts", "count").
	var/list/squad
	/// Total mobs this Calyx will spill over its lifetime.
	var/max_spawns = 10
	/// Mobs alive at once.
	var/max_alive = 6
	var/spawned_total = 0
	var/list/spawned_mobs = list()
	/// TRUE once this Calyx has spilled its single commander/leader. Later waves
	/// only refill grunts, so one Calyx never fields more than one commander.
	var/leader_spawned = FALSE
	var/spawn_cooldown = 0
	var/spawn_cooldown_time = 7 SECONDS
	/// TRUE until a crew member tears it open.
	var/dormant = TRUE
	var/collapsing = FALSE
	/// Fragmentum turfs this Calyx has infected -> their original type. Reverted
	/// when the Calyx dies so the corruption recedes with it.
	var/list/corrupted_turfs
	/// How far (tiles) the passive turf infection reaches.
	var/infect_radius = 4
	/// Infection ring reached so far (one new ring every 5s).
	var/infect_ring = 0
	/// Chance (%) a turf in the active ring is infected (patchy, natural spread).
	var/infect_chance = 65
	/// Origin turf for measuring infection distance.
	var/turf/infect_origin
	/// Guards the activation prompt against double-clicks.
	var/prompting = FALSE
	/// Test/admin presets: if set, the Calyx configures itself on spawn instead
	/// of waiting for the subsystem to call Setup(). See the subtypes below.
	var/preset_color
	var/preset_tier = 0

/obj/structure/calyx/Initialize(mapload)
	. = ..()
	if(preset_color)
		SelfSetup()
	update_icon()
	corrupted_turfs = list()
	infect_origin = get_turf(src)
	// begin infecting the surrounding turfs, one ring outward every 5 seconds
	addtimer(CALLBACK(src, PROC_REF(InfectRing)), 5 SECONDS)

/// Configures a preset Calyx from the subsystem's pools (for direct spawning).
/obj/structure/calyx/proc/SelfSetup()
	if(!SScalyx)
		return
	SScalyx.BuildPools()
	var/list/pools = SScalyx.color_pools[preset_color]
	if(!pools)
		return
	var/set_tier = clamp(preset_tier, 1, length(pools))
	Setup(preset_color, set_tier, pools[set_tier], SScalyx.color_tints[preset_color])

/obj/structure/calyx/Destroy()
	RevertTurfs()
	STOP_PROCESSING(SSobj, src)
	if(SScalyx)
		SScalyx.active_calyxes -= src
	spawned_mobs = null
	corrupted_turfs = null
	return ..()

/// Configures colour, tier, squad and tier-scaled wave size.
/obj/structure/calyx/proc/Setup(color, new_tier, list/squad_def, tint)
	calyx_color = color
	tier = new_tier
	color_tint = tint
	squad = squad_def
	name = "[color] calyx"
	// One Calyx keeps at most one ordeal spawn point's group alive at a time, so
	// the danger at any given moment matches one spawn point. The lifetime total
	// is a multiple of that, so a Calyx keeps feeding replacements for a while
	// instead of running dry after a single wave.
	max_alive = squad_def["alive"]
	max_spawns = max(max_alive * 3, 6)
	update_icon()
	Emerge()

/obj/structure/calyx/update_overlays()
	. = ..()
	var/mutable_appearance/core = mutable_appearance(icon, dormant ? "calyx_core" : "calyx_core_open")
	core.color = color_tint
	. += core

/obj/structure/calyx/proc/Emerge()
	alpha = 0
	animate(src, alpha = 255, time = 8)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))
	visible_message(span_bolddanger("A [calyx_color] calyx tears its way out of the ground!"))

/obj/structure/calyx/attack_hand(mob/user)
	if(!dormant)
		return ..()
	if(prompting)
		return
	prompting = TRUE
	var/choice = tgui_alert(user, "Activating this Calyx releases waves of Fragmentum Touched [calyx_color] creatures. They hit hard, but drop valuable materials. Open it?", "Fragmentum Calyx", list("Open", "Cancel"))
	prompting = FALSE
	if(choice != "Open")
		return
	if(QDELETED(src) || !dormant)
		return
	if(!user.Adjacent(src))
		to_chat(user, span_warning("You are too far from [src]."))
		return
	Activate()

/obj/structure/calyx/proc/Activate()
	if(!dormant)
		return
	dormant = FALSE
	icon_state = "calyx_open"
	update_icon()
	visible_message(span_bolddanger("[src] splits open and begins pouring out Fragmentum creatures!"))
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 60, TRUE)
	spawn_cooldown = world.time + 2 SECONDS
	START_PROCESSING(SSobj, src)

/obj/structure/calyx/process()
	if(dormant || collapsing)
		return
	if(spawned_total >= max_spawns)
		CleanupMobs()
		if(!length(spawned_mobs))
			Collapse()
		return
	if(spawn_cooldown <= world.time)
		CleanupMobs()
		while(length(spawned_mobs) < max_alive && spawned_total < max_spawns)
			if(!SpawnSquad())
				break
		spawn_cooldown = world.time + spawn_cooldown_time

/obj/structure/calyx/proc/CleanupMobs()
	for(var/i in length(spawned_mobs) to 1 step -1)
		var/mob/living/M = spawned_mobs[i]
		if(QDELETED(M) || M.stat == DEAD)
			spawned_mobs -= M

/// Spawns one mob toward filling the squad: its unique commander on the first
/// call (if any), then refillable pool mobs. The commander is spawned only once,
/// so a Calyx never fields more than one. Returns FALSE when nothing more can be
/// spawned, so process() stops and eventually collapses the spent Calyx.
/obj/structure/calyx/proc/SpawnSquad()
	var/list/boss = squad?["boss"]
	var/list/pool = squad?["pool"]
	if(LAZYLEN(boss) && !leader_spawned)
		SpawnAt(pickweight(boss), ValidTurf(src, 2))
		leader_spawned = TRUE
		return TRUE
	if(!LAZYLEN(pool))
		// A lone boss with no escort: nothing left to refill, so let this Calyx
		// wind down and collapse once its commander falls.
		spawned_total = max_spawns
		return FALSE
	SpawnAt(pickweight(pool), ValidTurf(src, 2))
	return TRUE

/// Spawns one mob at a turf and tracks it toward the wave count.
/obj/structure/calyx/proc/SpawnAt(mob_type, turf/T)
	var/mob/living/M = new mob_type(T)
	spawned_mobs += M
	spawned_total++
	return M

/// A random open, unblocked turf within `radius` of `center` (falls back to it).
/obj/structure/calyx/proc/ValidTurf(atom/center, radius)
	var/turf/c = get_turf(center)
	var/list/valid = list(c)
	for(var/turf/open/PT in RANGE_TURFS(radius, c))
		if(!PT.is_blocked_turf(TRUE))
			valid |= PT
	return pick(valid)

/obj/structure/calyx/proc/Collapse()
	if(collapsing)
		return
	collapsing = TRUE
	STOP_PROCESSING(SSobj, src)
	if(SScalyx)
		SScalyx.active_calyxes -= src
	visible_message(span_danger("[src] crumbles into fading crystal dust."))
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))
	animate(src, alpha = 0, time = 1 SECONDS)
	QDEL_IN(src, 1 SECONDS)

/// Infects a patchy subset of the next ring of turfs, then schedules the ring
/// beyond it 5 seconds later, out to infect_radius.
/obj/structure/calyx/proc/InfectRing()
	if(QDELETED(src) || collapsing || !infect_origin)
		return
	infect_ring++
	for(var/turf/T in RANGE_TURFS(infect_ring, infect_origin))
		if(get_dist(infect_origin, T) != infect_ring)
			continue
		if(!prob(infect_chance))
			continue
		InfectTurf(T)
	if(infect_ring < infect_radius)
		addtimer(CALLBACK(src, PROC_REF(InfectRing)), 5 SECONDS)

/// Turns one turf into its fragmentum version, remembering its original type.
/obj/structure/calyx/proc/InfectTurf(turf/T)
	if(!CanCorrupt(T))
		return
	var/orig = T.type
	var/turf/newT
	if(istype(T, /turf/closed))
		newT = T.ChangeTurf(/turf/closed/indestructible/fragmentum)
		QUEUE_SMOOTH_NEIGHBORS(newT)
	else
		newT = T.ChangeTurf(/turf/open/indestructible/fragmentum)
	corrupted_turfs[newT] = orig
	new /obj/effect/temp_visual/fragmentum_creep(newT)

/// Restores every turf this Calyx infected back to its original form.
/obj/structure/calyx/proc/RevertTurfs()
	if(!length(corrupted_turfs))
		return
	for(var/turf/T in corrupted_turfs)
		var/orig = corrupted_turfs[T]
		if(!orig)
			continue
		// only revert turfs still corrupted (don't clobber later changes)
		if(!istype(T, /turf/open/indestructible/fragmentum) && !istype(T, /turf/closed/indestructible/fragmentum))
			continue
		for(var/obj/structure/fragmentum_flora/F in T)
			qdel(F)
		if(istype(T, /turf/closed))
			var/turf/rT = T.ChangeTurf(orig)
			QUEUE_SMOOTH_NEIGHBORS(rT)
		else
			T.ChangeTurf(orig)
	corrupted_turfs.Cut()

// ---- Preset Calyxes (for direct in-game spawning / testing) ----
// Each configures itself on spawn with a fixed colour + tier. Tiers: t1 =
// lesser (dawn), t2 = common (noon), t3 = greater (dusk). Colours with only two
// tiers (amber/violet/brown) stop at t2.

/obj/structure/calyx/green
	preset_color = "green"
/obj/structure/calyx/green/t1
	preset_tier = 1
/obj/structure/calyx/green/t2
	preset_tier = 2
/obj/structure/calyx/green/t3
	preset_tier = 3

/obj/structure/calyx/crimson
	preset_color = "crimson"
/obj/structure/calyx/crimson/t1
	preset_tier = 1
/obj/structure/calyx/crimson/t2
	preset_tier = 2
/obj/structure/calyx/crimson/t3
	preset_tier = 3

/obj/structure/calyx/amber
	preset_color = "amber"
/obj/structure/calyx/amber/t1
	preset_tier = 1
/obj/structure/calyx/amber/t2
	preset_tier = 2

/obj/structure/calyx/indigo
	preset_color = "indigo"
/obj/structure/calyx/indigo/t1
	preset_tier = 1
/obj/structure/calyx/indigo/t2
	preset_tier = 2
/obj/structure/calyx/indigo/t3
	preset_tier = 3

/obj/structure/calyx/steel
	preset_color = "steel"
/obj/structure/calyx/steel/t1
	preset_tier = 1
/obj/structure/calyx/steel/t2
	preset_tier = 2
/obj/structure/calyx/steel/t3
	preset_tier = 3

/obj/structure/calyx/violet
	preset_color = "violet"
/obj/structure/calyx/violet/t1
	preset_tier = 1
/obj/structure/calyx/violet/t2
	preset_tier = 2

/obj/structure/calyx/brown
	preset_color = "brown"
/obj/structure/calyx/brown/t1
	preset_tier = 1
/obj/structure/calyx/brown/t2
	preset_tier = 2

/obj/structure/calyx/gold
	preset_color = "gold"
/obj/structure/calyx/gold/t1
	preset_tier = 1
/obj/structure/calyx/gold/t2
	preset_tier = 2
/obj/structure/calyx/gold/t3
	preset_tier = 3
