/**
 * Resurgence Outpost - Mining
 *
 * Ore deposit turfs with work-based progress that can be interrupted and resumed.
 * Unlike trees, ore deposits do NOT regenerate - they are a finite resource.
 *
 * Based on /turf/closed/mineral but with extended work-based mining.
 * Supports scanner overlays via scan_state.
 */

/turf/closed/mineral/resurgence
	name = "rock"
	desc = "A rocky outcrop. Use a pickaxe to mine it."
	icon = 'icons/turf/mining.dmi'
	icon_state = "rock"
	baseturfs = /turf/open/floor/plating/dirt
	// Base rock contains plain rock chunks
	mineralType = /obj/item/stack/ore/rock
	mineralAmt = 30

	/// Current work points accumulated
	var/work_points = 0
	/// Total work points needed to mine
	var/work_needed = 100
	/// Whether someone is currently mining
	var/being_worked = FALSE
	/// Whether this turf can be spread to by ore veins (base rock only)
	var/can_be_spread_to = TRUE

/turf/closed/mineral/resurgence/Initialize(mapload)
	. = ..()
	update_ore_color()

/turf/closed/mineral/resurgence/proc/update_ore_color()
	// Color is set per-subtype, no action needed here
	return

/turf/closed/mineral/resurgence/attackby(obj/item/I, mob/user, params)
	// Check for mining tool
	if(I.tool_behaviour != TOOL_MINING)
		to_chat(user, span_warning("You need a mining tool like a pickaxe to mine this."))
		return

	if(being_worked)
		to_chat(user, span_warning("Someone is already mining this."))
		return

	// Must be human with resurgence core
	if(!ishuman(user))
		return

	start_mining(user, I)

/turf/closed/mineral/resurgence/proc/start_mining(mob/living/carbon/human/user, obj/item/tool)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to mine. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	// Work rate based on tool speed (lower toolspeed = faster)
	var/work_per_tick = GATHER_WORK_PER_TICK / tool.toolspeed

	// Starting message
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		to_chat(user, span_notice("You continue mining [src]... ([progress_pct]% complete)"))
	else
		to_chat(user, span_notice("You begin mining [src]..."))

	// Play tool sound
	if(islist(tool.usesound))
		playsound(src, pick(tool.usesound), 50, TRUE)
	else if(tool.usesound)
		playsound(src, tool.usesound, 50, TRUE)

	being_worked = TRUE

	// Mining loop - continues until interrupted or complete
	while(work_points < work_needed)
		// Check faith each tick
		if(!can_gather(user))
			to_chat(user, span_warning("You're too exhausted to continue mining."))
			break

		// Do the work tick
		if(!do_after(user, GATHER_TICK_TIME, target = src))
			var/progress_pct = round((work_points / work_needed) * 100)
			to_chat(user, span_notice("You stop mining [src]. Progress: [progress_pct]%"))
			break

		// Add work and drain faith
		work_points += work_per_tick
		apply_work_faith_drain(user, work_per_tick)

		// Periodic sound (30% chance each tick)
		if(prob(30))
			if(islist(tool.usesound))
				playsound(src, pick(tool.usesound), 50, TRUE)
			else if(tool.usesound)
				playsound(src, tool.usesound, 50, TRUE)

	being_worked = FALSE

	// Check completion
	if(work_points >= work_needed)
		complete_mining(user)

/turf/closed/mineral/resurgence/proc/complete_mining(mob/user)
	if(user)
		user.visible_message(
			span_notice("[user] breaks through [src]!"),
			span_notice("You break through [src] and collect the ore!"),
			span_hear("You hear rock breaking.")
		)
	else
		// Harvester or other automated source
		visible_message(span_notice("[src] crumbles apart!"))
	playsound(src, 'sound/effects/break_stone.ogg', 60, TRUE)

	// Drop ore
	if(mineralType && mineralAmt > 0)
		new mineralType(src, mineralAmt)

	// Remove scanner overlay if present
	for(var/obj/effect/temp_visual/mining_overlay/M in src)
		qdel(M)

	// Transform to open turf
	ScrapeAway()

/turf/closed/mineral/resurgence/examine(mob/user)
	. = ..()
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		. += span_notice("It has been partially mined. ([progress_pct]% complete)")
		. += span_notice("Anyone can continue working on it with a pickaxe.")
	else if(mineralType)
		. += span_notice("Use a pickaxe to mine the ore inside.")
	else
		. += span_notice("Use a pickaxe to break through the rock.")

/// Check if a turf is a valid target for vein spreading (base rock only, not ore)
/turf/closed/mineral/resurgence/proc/is_valid_spread_target(turf/T)
	// Must be a resurgence mineral turf that allows spreading
	var/turf/closed/mineral/resurgence/R = T
	if(!istype(R))
		return FALSE
	return R.can_be_spread_to

/// Spread ore vein to adjacent base rock turfs
/turf/closed/mineral/resurgence/proc/spread_vein(min_count, max_count, chance = 80)
	if(min_count <= 0 && max_count <= 0)
		return

	var/target_count = rand(max(0, min_count), max(0, max_count))
	if(target_count <= 0)
		return

	var/list/spawned = list(src)
	var/list/candidates = list()

	// Get initial candidates from our neighbors
	for(var/dir in GLOB.cardinals)
		var/turf/T = get_step(src, dir)
		// Debug: log what we find
		if(T)
			log_world("Vein spread check: [T] at [T.x],[T.y] - type: [T.type] - istype resurgence: [istype(T, /turf/closed/mineral/resurgence)]")
			if(istype(T, /turf/closed/mineral/resurgence))
				var/turf/closed/mineral/resurgence/R = T
				log_world("  -> can_be_spread_to: [R.can_be_spread_to]")
		if(is_valid_spread_target(T))
			candidates += T

	log_world("Vein spreading from [src] at [x],[y] - found [length(candidates)] candidates, target: [target_count]")
	visible_message(span_notice("DEBUG: Vein at [x],[y] found [length(candidates)] valid neighbors to spread to."))

	// Spread outward
	while(target_count > 0 && length(candidates))
		var/turf/chosen = pick(candidates)
		candidates -= chosen

		// Check spread chance
		if(!prob(chance))
			continue

		// Verify still valid (might have changed)
		if(!is_valid_spread_target(chosen))
			continue

		// Change to our ore type
		var/turf/closed/mineral/resurgence/new_ore = chosen.ChangeTurf(type)
		if(!new_ore)
			continue

		spawned += new_ore
		target_count--

		// Add its neighbors as new candidates
		for(var/dir in GLOB.cardinals)
			var/turf/neighbor = get_step(new_ore, dir)
			if(is_valid_spread_target(neighbor) && !(neighbor in spawned) && !(neighbor in candidates))
				candidates += neighbor

// ===== Ore Deposit Variants =====

/turf/closed/mineral/resurgence/iron
	name = "iron deposit"
	desc = "Rock with visible veins of iron ore."
	mineralType = /obj/item/stack/ore/iron
	mineralAmt = 80
	color = "#8B5A2B" // Brown-orange for iron
	work_needed = 200
	can_be_spread_to = FALSE

/turf/closed/mineral/resurgence/coal
	name = "coal deposit"
	desc = "Rock containing dark coal."
	mineralType = /obj/item/stack/sheet/mineral/coal
	mineralAmt = 100
	color = "#2A2A2A" // Dark gray for coal
	work_needed = 150
	can_be_spread_to = FALSE

/turf/closed/mineral/resurgence/silver
	name = "silver deposit"
	desc = "Rock glinting with veins of silver."
	mineralType = /obj/item/stack/ore/silver
	mineralAmt = 50
	color = "#C0C0C0" // Silver/light gray
	work_needed = 250
	can_be_spread_to = FALSE

/turf/closed/mineral/resurgence/gold
	name = "gold deposit"
	desc = "Rock with golden veins running through it."
	mineralType = /obj/item/stack/ore/gold
	mineralAmt = 40
	color = "#FFD700" // Gold/yellow
	work_needed = 300
	can_be_spread_to = FALSE

/turf/closed/mineral/resurgence/glass_rubble
	name = "glass rubble"
	desc = "Broken glass that can be recycled."
	mineralType = /obj/item/stack/ore/glassrubble
	mineralAmt = 60
	color = "#87CEEB" // Light blue for glass
	work_needed = 80
	can_be_spread_to = FALSE

/turf/closed/mineral/resurgence/iron_scrap
	name = "iron scrap pile"
	desc = "Rusted iron scrap that can be salvaged."
	mineralType = /obj/item/stack/ore/ironscrap
	mineralAmt = 100
	color = "#B7410E" // Rust orange for scrap
	work_needed = 120
	can_be_spread_to = FALSE

// ===== Random Ore Turfs (Spread Veins on Init) =====
// Place these on the map - they become ore and spread a vein to adjacent base rock

/turf/closed/mineral/resurgence/random
	name = "ore vein"
	can_be_spread_to = FALSE // Don't let other veins overwrite spawners

	/// What ore type this becomes
	var/ore_turf_type = null
	/// Minimum deposits to spread (not counting self)
	var/min_spread = 5
	/// Maximum deposits to spread (not counting self)
	var/max_spread = 8
	/// Chance to spread to each adjacent rock (0-100)
	var/spread_chance = 80

/turf/closed/mineral/resurgence/random/Initialize(mapload)
	. = ..()
	// Delay vein spawning to ensure all turfs are loaded
	if(ore_turf_type)
		addtimer(CALLBACK(src, PROC_REF(spawn_vein)), 10 SECONDS)

/turf/closed/mineral/resurgence/random/proc/spawn_vein()
	if(!ore_turf_type)
		return
	// Store values before we get deleted by ChangeTurf
	var/stored_ore_type = ore_turf_type
	var/stored_min = min_spread
	var/stored_max = max_spread
	var/stored_chance = spread_chance
	var/our_x = x
	var/our_y = y
	var/our_z = z

	// Change ourselves to the ore type (this deletes src)
	ChangeTurf(stored_ore_type)

	// Get the new turf at our old location and spread
	var/turf/closed/mineral/resurgence/T = locate(our_x, our_y, our_z)
	if(T)
		T.spread_vein(stored_min, stored_max, stored_chance)

// Random ore variants - place these on the map where you want veins

/turf/closed/mineral/resurgence/random/iron
	ore_turf_type = /turf/closed/mineral/resurgence/iron
	min_spread = 5
	max_spread = 8

/turf/closed/mineral/resurgence/random/coal
	ore_turf_type = /turf/closed/mineral/resurgence/coal
	min_spread = 5
	max_spread = 8

/turf/closed/mineral/resurgence/random/silver
	ore_turf_type = /turf/closed/mineral/resurgence/silver
	min_spread = 3
	max_spread = 6

/turf/closed/mineral/resurgence/random/gold
	ore_turf_type = /turf/closed/mineral/resurgence/gold
	min_spread = 2
	max_spread = 4

/turf/closed/mineral/resurgence/random/glass_rubble
	ore_turf_type = /turf/closed/mineral/resurgence/glass_rubble
	min_spread = 4
	max_spread = 7

/turf/closed/mineral/resurgence/random/iron_scrap
	ore_turf_type = /turf/closed/mineral/resurgence/iron_scrap
	min_spread = 5
	max_spread = 8

// Random ore picker - randomly selects an ore type on initialization
/turf/closed/mineral/resurgence/random/any
	name = "random ore vein"
	/// List of possible ore types with their weights
	var/static/list/ore_weights = list(
		/turf/closed/mineral/resurgence/iron = 30,
		/turf/closed/mineral/resurgence/coal = 25,
		/turf/closed/mineral/resurgence/iron_scrap = 15,
		/turf/closed/mineral/resurgence/glass_rubble = 15,
		/turf/closed/mineral/resurgence/silver = 10,
		/turf/closed/mineral/resurgence/gold = 5
	)

/turf/closed/mineral/resurgence/random/any/Initialize(mapload)
	// Pick a random ore type based on weights
	ore_turf_type = pickweight(ore_weights)
	// Set spread values based on what was picked
	switch(ore_turf_type)
		if(/turf/closed/mineral/resurgence/iron)
			min_spread = 5
			max_spread = 8
		if(/turf/closed/mineral/resurgence/coal)
			min_spread = 5
			max_spread = 8
		if(/turf/closed/mineral/resurgence/silver)
			min_spread = 3
			max_spread = 6
		if(/turf/closed/mineral/resurgence/gold)
			min_spread = 2
			max_spread = 4
		if(/turf/closed/mineral/resurgence/glass_rubble)
			min_spread = 4
			max_spread = 7
		if(/turf/closed/mineral/resurgence/iron_scrap)
			min_spread = 5
			max_spread = 8
	return ..()
