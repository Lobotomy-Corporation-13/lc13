// Fragmentum corruption: an admin-spawnable seed that overtakes the map.
// Dropping a /obj/structure/fragmentum_seed radiates outward, converting
// nearby open and closed turfs into their fragmentum (black-and-gold)
// versions ring by ring, scattering blackened rubble and gilded crystal.
// Built for recording the "the facility corrupts" beat of the trailer.

// ---------------------------------------------------------------------------
// Corrupted turfs
// ---------------------------------------------------------------------------

/turf/open/indestructible/fragmentum
	name = "fragmentum growth"
	desc = "The floor has been overtaken by black gold. It pulses faintly, as if something is breathing far beneath it."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_floor.dmi'
	icon_state = "necro1"
	baseturfs = /turf/open/indestructible/fragmentum
	footstep = FOOTSTEP_LAVA
	barefootstep = FOOTSTEP_LAVA
	clawfootstep = FOOTSTEP_LAVA
	heavyfootstep = FOOTSTEP_LAVA
	tiled_dirt = FALSE

/turf/open/indestructible/fragmentum/Initialize()
	. = ..()
	if(prob(30))
		icon_state = "necro[rand(2, 3)]"
	if(prob(15))
		if(prob(55))
			new /obj/structure/fragmentum_flora/rock(src)
		else
			new /obj/structure/fragmentum_flora/crystal(src)

/turf/closed/indestructible/fragmentum
	name = "fragmentum wall"
	desc = "A wall gone to black gold, its edges crusted with humming crystal. It does not remember being anything else."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_wall.dmi'
	icon_state = "facility-0"
	base_icon_state = "facility"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_WALLS, SMOOTH_GROUP_WINDOW_FULLTILE, SMOOTH_GROUP_AIRLOCK)

// ---------------------------------------------------------------------------
// Fragmentum flora (fluff placed on corrupted floors)
// ---------------------------------------------------------------------------

/obj/structure/fragmentum_flora
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	layer = ABOVE_NORMAL_TURF_LAYER

/obj/structure/fragmentum_flora/rock
	name = "blackened debris"
	desc = "Rubble fused into obsidian, threaded through with veins of stubborn gold."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_rocks.dmi'
	icon_state = "lavarocks1"

/obj/structure/fragmentum_flora/rock/Initialize()
	. = ..()
	icon_state = "lavarocks[rand(1, 3)]"

/obj/structure/fragmentum_flora/crystal
	name = "gilded crystal"
	desc = "A shard of black crystal with a molten-gold core. It hums on a note just below hearing."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_icedecor.dmi'
	icon_state = "ice_stalagmite"
	layer = ABOVE_MOB_LAYER

/obj/structure/fragmentum_flora/crystal/Initialize()
	. = ..()
	icon_state = pick("ice_stalagmite", "ice_shards", "ice_slab1", "ice_slab2", \
		"ice_grave1", "ice_grave2", "ice_chunk1", "ice_chunk2")
	if(prob(45))
		set_light(2, 0.7, "#e0a038")

// ---------------------------------------------------------------------------
// Spreading visual (a brief creep that blooms over each tile as it turns)
// ---------------------------------------------------------------------------

/obj/effect/temp_visual/fragmentum_creep
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_floor.dmi'
	icon_state = "necro1"
	layer = ABOVE_NORMAL_TURF_LAYER
	duration = 8
	randomdir = FALSE
	alpha = 0

/obj/effect/temp_visual/fragmentum_creep/Initialize()
	. = ..()
	var/matrix/small = matrix()
	small.Scale(0.2)
	transform = small
	animate(src, alpha = 210, transform = matrix(), time = 2.5, easing = SINE_EASING)
	animate(alpha = 0, time = 5.5)

// ---------------------------------------------------------------------------
// The seed (admin-spawnable; corrupts the map around it)
// ---------------------------------------------------------------------------

/obj/structure/fragmentum_seed
	name = "fragmentum seed"
	desc = "A splinter of impossible gold driven into the ground. The world around it is already forgetting what it used to be."
	icon = 'ModularLobotomy/_Lobotomyicons/fragmentum_icedecor.dmi'
	icon_state = "ice_stalagmite"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	light_range = 3
	light_power = 1.2
	light_color = "#e0a038"
	/// How far (in tiles) the corruption reaches from the seed.
	var/max_radius = 6
	/// How long after being placed before the corruption begins to spread.
	var/activation_delay = 10 SECONDS
	/// Deciseconds between each expanding ring of corruption.
	var/ring_delay = 15
	/// Chance (%) an edge turf hangs back a ring instead of spreading now.
	var/defer_chance = 28
	/// Chance (%) an active turf seeds any given eligible neighbour.
	var/spread_chance = 58
	/// Whether a spread is currently running.
	var/spreading = FALSE
	// Per-seed angular wobble, so the final blob is a lumpy circle rather than
	// a clean disc. Reach in a direction = max_radius + amp*(two sine lobes).
	var/wob_amp
	var/wob_freq1
	var/wob_freq2
	var/wob_phase1
	var/wob_phase2
	/// The seed's own turf, used as the corruption's centre.
	var/turf/origin
	/// Turfs on the current growing edge, corrupted next tick.
	var/list/turf/frontier
	/// Every turf already queued or corrupted (guards against re-visiting).
	var/list/reached

/obj/structure/fragmentum_seed/Initialize()
	. = ..()
	origin = get_turf(src)
	reached = list()
	addtimer(CALLBACK(src, PROC_REF(StartSpread)), activation_delay)

/obj/structure/fragmentum_seed/Destroy()
	frontier = null
	reached = null
	return ..()

/// Kicks off the ring-by-ring spread from the seed's turf.
/obj/structure/fragmentum_seed/proc/StartSpread()
	if(spreading || !origin)
		return
	spreading = TRUE
	// roll this seed's lumpy silhouette
	wob_freq1 = pick(2, 3)
	wob_freq2 = pick(4, 5)
	wob_phase1 = rand(0, 359)
	wob_phase2 = rand(0, 359)
	wob_amp = max_radius * 0.32
	frontier = list(origin)
	reached[origin] = TRUE
	SpreadRing()

/// TRUE if a turf is inside this seed's uneven (angularly wobbled) reach.
/obj/structure/fragmentum_seed/proc/WithinBounds(turf/N)
	var/dx = N.x - origin.x
	var/dy = N.y - origin.y
	var/dist = sqrt(dx * dx + dy * dy)
	if(dist <= 1.5)
		return TRUE
	var/ang = ATAN2(dx, dy)
	var/eff = max_radius + wob_amp * (sin(ang * wob_freq1 + wob_phase1) + 0.55 * sin(ang * wob_freq2 + wob_phase2))
	return dist <= eff

/// Corrupts part of the current frontier, then schedules the next ring.
/// Growth is deliberately uneven: some edge turfs hang back a ring, and each
/// active turf only seeds a random subset of its neighbours, so the corruption
/// creeps outward in a ragged, organic front rather than a clean circle.
/obj/structure/fragmentum_seed/proc/SpreadRing()
	if(!length(frontier))
		spreading = FALSE
		return
	var/list/turf/next = list()
	for(var/turf/T in frontier)
		// a few tiles on the edge lag behind, carried to the next ring
		if(prob(defer_chance))
			next += T
			continue
		CorruptTurf(T)
		for(var/turf/N in RANGE_TURFS(1, T))
			if(N == T || reached[N])
				continue
			if(!WithinBounds(N))
				reached[N] = TRUE
				continue
			if(!CanCorrupt(N))
				reached[N] = TRUE
				continue
			// only some neighbours catch this ring; the rest may be reached
			// later from another angle, filling gaps unevenly
			if(prob(spread_chance))
				reached[N] = TRUE
				next += N
	frontier = next
	if(length(next))
		addtimer(CALLBACK(src, PROC_REF(SpreadRing)), ring_delay)
	else
		spreading = FALSE

/// Converts a single turf into its fragmentum version, with a creep visual,
/// and corrupts any ordeal mob it sweeps over into its fragmentum variant.
/obj/structure/fragmentum_seed/proc/CorruptTurf(turf/T)
	if(!CanCorrupt(T))
		return
	var/turf/newT
	if(istype(T, /turf/closed))
		newT = T.ChangeTurf(/turf/closed/indestructible/fragmentum)
		QUEUE_SMOOTH_NEIGHBORS(newT)
	else
		newT = T.ChangeTurf(/turf/open/indestructible/fragmentum)
	new /obj/effect/temp_visual/fragmentum_creep(newT)
	for(var/mob/living/simple_animal/hostile/ordeal/O in newT)
		O.Fragmentize()

/// TRUE for a real floor or wall that has not already been corrupted.
/proc/CanCorrupt(turf/T)
	if(!T)
		return FALSE
	if(istype(T, /turf/open/indestructible/fragmentum))
		return FALSE
	if(istype(T, /turf/closed/indestructible/fragmentum))
		return FALSE
	if(isspaceturf(T) || istype(T, /turf/open/openspace))
		return FALSE
	// protected turfs the corruption refuses to overtake
	if(istype(T, /turf/closed/indestructible/rock))
		return FALSE
	if(istype(T, /turf/open/floor/plating))
		return FALSE
	if(istype(T, /turf/closed/indestructible/fakeglass))
		return FALSE
	return istype(T, /turf/open) || istype(T, /turf/closed)
