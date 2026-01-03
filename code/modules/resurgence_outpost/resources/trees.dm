/**
 * Resurgence Outpost - Trees
 *
 * Harvestable trees with work-based progress that can be interrupted and resumed.
 * Trees regenerate via stumps after being felled.
 */

/obj/structure/resurgence_tree
	name = "gnarled tree"
	desc = "A twisted tree that has adapted to the harsh outskirts. Chop it with your hands or use an axe to work faster."
	icon = 'icons/obj/flora/jungletreesmall.dmi'
	max_integrity = 10000
	icon_state = "tree"
	density = TRUE
	anchored = TRUE
	layer = FLY_LAYER
	pixel_x = -32

	/// Current work points accumulated
	var/work_points = 0
	/// Total work points needed to fell the tree
	var/work_needed = 300
	/// Base amount of wood dropped when felled
	var/base_yield = 90
	/// Whether someone is currently chopping
	var/being_worked = FALSE
	/// What type of tree to spawn on regrowth
	var/tree_type = /obj/structure/resurgence_tree
	/// Whether to randomize icon on init
	var/randomize_icon = TRUE
	/// Speed bonus when using a sharp tool (0.25 = 25% faster)
	var/tool_speed_bonus = 0.25

/obj/structure/resurgence_tree/Initialize(mapload)
	. = ..()
	if(randomize_icon)
		icon_state = pick("tree", "tree1", "tree2", "tree3", "tree4", "tree5", "tree6")

/obj/structure/resurgence_tree/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(being_worked)
		to_chat(user, span_warning("Someone is already working on this tree."))
		return

	if(!ishuman(user))
		return

	start_chopping(user, null)

/obj/structure/resurgence_tree/attackby(obj/item/W, mob/user, params)
	// Check for valid cutting tool (needs sharpness) - if not, try bare hands
	if(!W.get_sharpness())
		return attack_hand(user)

	if(being_worked)
		to_chat(user, span_warning("Someone is already working on this tree."))
		return

	if(!ishuman(user))
		return ..()

	start_chopping(user, W)

/obj/structure/resurgence_tree/proc/start_chopping(mob/living/carbon/human/user, obj/item/tool)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to chop. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	// Work rate - base rate for bare hands, sharp tools provide speed bonus
	var/work_per_tick = GATHER_WORK_PER_TICK
	var/using_tool = FALSE
	if(tool?.get_sharpness())
		work_per_tick *= (1 + tool_speed_bonus) // 25% faster with sharp tool
		using_tool = TRUE

	// Harvesting stat bonus: +1 work per tick for each level above 1
	var/harvesting_level = get_harvesting_stat(user)
	work_per_tick += (harvesting_level - 1)

	// Tool tier bonus (hatchets)
	work_per_tick += get_tool_work_bonus(tool)

	// Starting message
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		to_chat(user, span_notice("You continue chopping [src]... ([progress_pct]% complete)"))
	else
		if(using_tool)
			to_chat(user, span_notice("You begin chopping [src] with [tool]..."))
		else
			to_chat(user, span_notice("You begin chopping [src] with your bare hands..."))

	// Play sound
	if(using_tool && tool.hitsound)
		playsound(src, tool.hitsound, 50, TRUE)
	else
		playsound(src, 'sound/effects/woodhit.ogg', 50, TRUE)

	being_worked = TRUE

	// Gathering loop - continues until interrupted or complete
	while(work_points < work_needed)
		// Check faith each tick
		if(!can_gather(user))
			to_chat(user, span_warning("You're too exhausted to continue chopping."))
			break

		// Do the work tick
		if(!do_after(user, GATHER_TICK_TIME, target = src))
			var/progress_pct = round((work_points / work_needed) * 100)
			to_chat(user, span_notice("You stop chopping [src]. Progress: [progress_pct]%"))
			break

		// Add work and drain faith
		work_points += work_per_tick
		apply_work_faith_drain(user, work_per_tick)

		// Decrement tool durability
		if(tool && !use_tool_durability(tool, user))
			// Tool broke - continue without tool bonuses
			tool = null
			using_tool = FALSE
			work_per_tick = GATHER_WORK_PER_TICK + (harvesting_level - 1)

		// Periodic sound (30% chance each tick)
		if(prob(30))
			if(using_tool && tool?.hitsound)
				playsound(src, tool.hitsound, 50, TRUE)
			else
				playsound(src, 'sound/effects/woodhit.ogg', 50, TRUE)

	being_worked = FALSE

	// Check completion
	if(work_points >= work_needed)
		fell_tree(user, tool)

/obj/structure/resurgence_tree/proc/fell_tree(mob/user, obj/item/tool)
	// Calculate yield with harvesting skill bonus
	var/yield = base_yield
	if(user)
		user.visible_message(
			span_notice("[user] fells [src] with a crash!"),
			span_notice("You fell [src]! The tree crashes to the ground."),
			span_hear("You hear a tree crashing down.")
		)
		// Award harvesting XP based on work difficulty (with tool multiplier)
		var/base_xp = round(work_needed / 10)
		var/xp_mult = get_tool_xp_multiplier(tool)
		award_harvesting_xp(user, round(base_xp * xp_mult))
		// Apply harvesting yield bonus (+1 every 5 levels)
		var/harvesting_level = get_harvesting_stat(user)
		yield += get_harvesting_yield_bonus(harvesting_level)
	else
		// Harvester or other automated source
		visible_message(span_notice("[src] crashes to the ground!"))
	playsound(src, 'sound/effects/meteorimpact.ogg', 80, TRUE)

	// Drop wood
	new /obj/item/stack/sheet/mineral/wood(get_turf(src), yield)

	// Drop vines (roughly 1 vine per 5 wood)
	var/vine_yield = max(1, round(yield / 5))
	new /obj/item/stack/resurgence_vines(get_turf(src), vine_yield)

	// Create stump that will regrow
	var/obj/structure/resurgence_tree_stump/stump = new(loc)
	stump.name = "[name] stump"
	stump.tree_type = tree_type

	qdel(src)

/obj/structure/resurgence_tree/examine(mob/user)
	. = ..()
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		. += span_notice("It has been partially chopped. ([progress_pct]% complete)")
		. += span_notice("Anyone can continue working on it. A sharp tool works faster.")
	else
		. += span_notice("Chop it with your hands, or use a sharp tool for faster work.")

// ===== Tree Variants =====

/obj/structure/resurgence_tree/oak
	name = "oak tree"
	desc = "A sturdy oak tree with thick branches."
	icon = 'icons/obj/flora/jungletrees.dmi'
	icon_state = "tree1"
	pixel_x = -48
	pixel_y = -20
	base_yield = 100
	work_needed = 350
	tree_type = /obj/structure/resurgence_tree/oak

/obj/structure/resurgence_tree/oak/Initialize(mapload)
	. = ..()
	if(randomize_icon)
		icon_state = pick("tree1", "tree2", "tree3", "tree4", "tree5", "tree6")

/obj/structure/resurgence_tree/dead
	name = "dead tree"
	desc = "A withered tree, long since dead. Easy to chop but yields less wood."
	icon = 'icons/obj/flora/deadtrees.dmi'
	icon_state = "tree_1"
	pixel_x = -16
	base_yield = 40
	work_needed = 150
	tree_type = /obj/structure/resurgence_tree/dead

/obj/structure/resurgence_tree/dead/Initialize(mapload)
	. = ..()
	if(randomize_icon)
		icon_state = pick("tree_1", "tree_2", "tree_3", "tree_4", "tree_5", "tree_6")

// ===== Tree Stump (Regrowth) =====

/obj/structure/resurgence_tree_stump
	name = "tree stump"
	desc = "The remains of a felled tree. Given time, it may regrow. You can chop it down to clear the area."
	icon = 'icons/obj/flora/deadtrees.dmi'
	icon_state = "tree_stump"
	density = FALSE
	anchored = TRUE

	/// Time until the stump regrows into a tree
	var/regrow_time = 10 MINUTES
	/// What type of tree to spawn on regrowth
	var/tree_type = /obj/structure/resurgence_tree
	/// Current work points accumulated
	var/work_points = 0
	/// Total work points needed to remove the stump
	var/work_needed = 100
	/// Amount of wood dropped when removed
	var/base_yield = 10
	/// Whether someone is currently chopping
	var/being_worked = FALSE
	/// Speed bonus when using a sharp tool
	var/tool_speed_bonus = 0.25

/obj/structure/resurgence_tree_stump/Initialize(mapload)
	. = ..()
	// Start regrowth timer
	addtimer(CALLBACK(src, PROC_REF(regrow)), regrow_time)

/obj/structure/resurgence_tree_stump/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(being_worked)
		to_chat(user, span_warning("Someone is already working on this stump."))
		return

	if(!ishuman(user))
		return

	start_chopping(user, null)

/obj/structure/resurgence_tree_stump/attackby(obj/item/W, mob/user, params)
	// Check for valid cutting tool (needs sharpness) - if not, try bare hands
	if(!W.get_sharpness())
		return attack_hand(user)

	if(being_worked)
		to_chat(user, span_warning("Someone is already working on this stump."))
		return

	if(!ishuman(user))
		return ..()

	start_chopping(user, W)

/obj/structure/resurgence_tree_stump/proc/start_chopping(mob/living/carbon/human/user, obj/item/tool)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to chop. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	// Work rate - base rate for bare hands, sharp tools provide speed bonus
	var/work_per_tick = GATHER_WORK_PER_TICK
	var/using_tool = FALSE
	if(tool?.get_sharpness())
		work_per_tick *= (1 + tool_speed_bonus)
		using_tool = TRUE

	// Harvesting stat bonus
	var/harvesting_level = get_harvesting_stat(user)
	work_per_tick += (harvesting_level - 1)

	// Tool tier bonus (hatchets)
	work_per_tick += get_tool_work_bonus(tool)

	// Starting message
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		to_chat(user, span_notice("You continue chopping [src]... ([progress_pct]% complete)"))
	else
		if(using_tool)
			to_chat(user, span_notice("You begin chopping [src] with [tool]..."))
		else
			to_chat(user, span_notice("You begin chopping [src] with your bare hands..."))

	// Play sound
	if(using_tool && tool.hitsound)
		playsound(src, tool.hitsound, 50, TRUE)
	else
		playsound(src, 'sound/effects/woodhit.ogg', 50, TRUE)

	being_worked = TRUE

	// Gathering loop
	while(work_points < work_needed)
		if(!can_gather(user))
			to_chat(user, span_warning("You're too exhausted to continue chopping."))
			break

		if(!do_after(user, GATHER_TICK_TIME, target = src))
			var/progress_pct = round((work_points / work_needed) * 100)
			to_chat(user, span_notice("You stop chopping [src]. Progress: [progress_pct]%"))
			break

		work_points += work_per_tick
		apply_work_faith_drain(user, work_per_tick)

		// Decrement tool durability
		if(tool && !use_tool_durability(tool, user))
			tool = null
			using_tool = FALSE
			work_per_tick = GATHER_WORK_PER_TICK + (harvesting_level - 1)

		// Periodic sound
		if(prob(30))
			if(using_tool && tool?.hitsound)
				playsound(src, tool.hitsound, 50, TRUE)
			else
				playsound(src, 'sound/effects/woodhit.ogg', 50, TRUE)

	being_worked = FALSE

	// Check completion
	if(work_points >= work_needed)
		remove_stump(user, tool)

/obj/structure/resurgence_tree_stump/proc/remove_stump(mob/user, obj/item/tool)
	var/yield = base_yield
	if(user)
		user.visible_message(
			span_notice("[user] uproots [src]!"),
			span_notice("You uproot [src]!")
		)
		// Award harvesting XP
		var/base_xp = round(work_needed / 10)
		var/xp_mult = get_tool_xp_multiplier(tool)
		award_harvesting_xp(user, round(base_xp * xp_mult))
		// Apply harvesting yield bonus
		var/harvesting_level = get_harvesting_stat(user)
		yield += get_harvesting_yield_bonus(harvesting_level)
	else
		visible_message(span_notice("[src] is uprooted!"))

	playsound(src, 'sound/effects/woodhit.ogg', 50, TRUE)

	// Drop wood
	if(yield > 0)
		new /obj/item/stack/sheet/mineral/wood(get_turf(src), yield)

	qdel(src)

/obj/structure/resurgence_tree_stump/proc/regrow()
	// Don't regrow if something is on top of us
	if(locate(/obj/structure) in loc)
		// Try again later
		addtimer(CALLBACK(src, PROC_REF(regrow)), 2 MINUTES)
		return

	var/obj/structure/resurgence_tree/new_tree = new tree_type(loc)
	new_tree.name = "young [initial(new_tree.name)]"
	new_tree.desc = "[initial(new_tree.desc)] This one is still young."
	// Young trees yield a bit less
	new_tree.base_yield = round(initial(new_tree.base_yield) * 0.75)

	qdel(src)

/obj/structure/resurgence_tree_stump/examine(mob/user)
	. = ..()
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		. += span_notice("It has been partially chopped. ([progress_pct]% complete)")
	else
		. += span_notice("You can chop it down to clear the area, or wait for it to regrow.")
