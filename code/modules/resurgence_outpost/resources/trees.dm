/**
 * Resurgence Outpost - Trees
 *
 * Harvestable trees with work-based progress that can be interrupted and resumed.
 * Trees regenerate via stumps after being felled.
 */

/obj/structure/resurgence_tree
	name = "gnarled tree"
	desc = "A twisted tree that has adapted to the harsh outskirts. It can be chopped for wood."
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
	var/base_yield = 45
	/// Whether someone is currently chopping
	var/being_worked = FALSE
	/// What type of tree to spawn on regrowth
	var/tree_type = /obj/structure/resurgence_tree
	/// Whether to randomize icon on init
	var/randomize_icon = TRUE

/obj/structure/resurgence_tree/Initialize(mapload)
	. = ..()
	if(randomize_icon)
		icon_state = pick("tree", "tree1", "tree2", "tree3", "tree4", "tree5", "tree6")

/obj/structure/resurgence_tree/attackby(obj/item/W, mob/user, params)
	// Check for valid cutting tool (needs sharpness and force)
	if(!W.get_sharpness() || W.force <= 0)
		return ..()

	if(being_worked)
		to_chat(user, span_warning("Someone is already working on this tree."))
		return

	// Must be human with resurgence core
	if(!ishuman(user))
		return ..()

	start_chopping(user, W)

/obj/structure/resurgence_tree/proc/start_chopping(mob/living/carbon/human/user, obj/item/tool)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to chop. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	// Calculate work rate based on tool force (force 10 = base rate)
	var/work_per_tick = GATHER_WORK_PER_TICK * (tool.force / 10)

	// Starting message
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		to_chat(user, span_notice("You continue chopping [src]... ([progress_pct]% complete)"))
	else
		to_chat(user, span_notice("You begin chopping [src]..."))

	if(tool.hitsound)
		playsound(src, tool.hitsound, 50, TRUE)

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

		// Periodic sound (30% chance each tick)
		if(prob(30) && tool.hitsound)
			playsound(src, tool.hitsound, 50, TRUE)

	being_worked = FALSE

	// Check completion
	if(work_points >= work_needed)
		fell_tree(user)

/obj/structure/resurgence_tree/proc/fell_tree(mob/user)
	if(user)
		user.visible_message(
			span_notice("[user] fells [src] with a crash!"),
			span_notice("You fell [src]! The tree crashes to the ground."),
			span_hear("You hear a tree crashing down.")
		)
	else
		// Harvester or other automated source
		visible_message(span_notice("[src] crashes to the ground!"))
	playsound(src, 'sound/effects/meteorimpact.ogg', 80, TRUE)

	// Calculate yield (base, will be modified by gathering stat later)
	var/yield = base_yield

	// Drop wood
	new /obj/item/stack/sheet/mineral/wood(get_turf(src), yield)

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
		. += span_notice("Anyone can continue working on it with a sharp tool.")
	else
		. += span_notice("Use a sharp tool to chop it down for wood.")

// ===== Tree Variants =====

/obj/structure/resurgence_tree/oak
	name = "oak tree"
	desc = "A sturdy oak tree with thick branches."
	icon = 'icons/obj/flora/jungletrees.dmi'
	icon_state = "tree1"
	pixel_x = -48
	pixel_y = -20
	base_yield = 50
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
	base_yield = 20
	work_needed = 150
	tree_type = /obj/structure/resurgence_tree/dead

/obj/structure/resurgence_tree/dead/Initialize(mapload)
	. = ..()
	if(randomize_icon)
		icon_state = pick("tree_1", "tree_2", "tree_3", "tree_4", "tree_5", "tree_6")

// ===== Tree Stump (Regrowth) =====

/obj/structure/resurgence_tree_stump
	name = "tree stump"
	desc = "The remains of a felled tree. Given time, it may regrow."
	icon = 'icons/obj/flora/deadtrees.dmi'
	icon_state = "tree_stump"
	density = FALSE
	anchored = TRUE

	/// Time until the stump regrows into a tree
	var/regrow_time = 10 MINUTES
	/// What type of tree to spawn on regrowth
	var/tree_type = /obj/structure/resurgence_tree

/obj/structure/resurgence_tree_stump/Initialize(mapload)
	. = ..()
	// Start regrowth timer
	addtimer(CALLBACK(src, PROC_REF(regrow)), regrow_time)

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
	. += span_notice("The stump looks like it could sprout new growth eventually.")
