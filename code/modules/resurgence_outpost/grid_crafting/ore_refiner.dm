/**
 * Resurgence Outpost - Ore Refiner
 *
 * The Ore Refiner processes raw ores into Ore Cores for grid crafting.
 * The ratio of Iron, Silver, and Gold determines the core type.
 * Coal acts as fuel to modify the movement distance.
 */

/// Processing time per batch
#define REFINER_PROCESS_TIME (5 SECONDS)

/obj/structure/ore_refiner
	name = "ore refiner"
	desc = "A machine that processes raw ores into specialized cores for grid crafting."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "furnace"
	density = TRUE
	anchored = TRUE

	/// Iron ore loaded
	var/iron_count = 0
	/// Silver ore loaded
	var/silver_count = 0
	/// Gold ore loaded
	var/gold_count = 0
	/// Coal loaded (fuel)
	var/coal_count = 0

	/// Whether the refiner is currently processing
	var/processing = FALSE

	/// Maximum ore that can be loaded at once
	var/max_ore_per_type = 50
	/// Maximum coal that can be loaded
	var/max_coal = 100

/obj/structure/ore_refiner/Initialize(mapload)
	. = ..()

/obj/structure/ore_refiner/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/structure/ore_refiner/attackby(obj/item/I, mob/user, params)
	// Handle ore/coal insertion
	if(istype(I, /obj/item/stack/ore/iron) || istype(I, /obj/item/stack/ore/ironscrap))
		add_ore(I, user, "iron")
		return
	if(istype(I, /obj/item/stack/ore/silver))
		add_ore(I, user, "silver")
		return
	if(istype(I, /obj/item/stack/ore/gold))
		add_ore(I, user, "gold")
		return
	if(istype(I, /obj/item/stack/sheet/mineral/coal))
		add_coal(I, user)
		return

	return ..()

/// Add ore to the refiner
/obj/structure/ore_refiner/proc/add_ore(obj/item/stack/ore, mob/user, ore_type)
	if(processing)
		to_chat(user, span_warning("The refiner is currently processing!"))
		return

	var/current_count
	switch(ore_type)
		if("iron")
			current_count = iron_count
		if("silver")
			current_count = silver_count
		if("gold")
			current_count = gold_count
		else
			return

	var/space = max_ore_per_type - current_count
	if(space <= 0)
		to_chat(user, span_warning("The [ore_type] ore hopper is full!"))
		return

	var/to_add = min(ore.amount, space)
	ore.use(to_add)

	switch(ore_type)
		if("iron")
			iron_count += to_add
		if("silver")
			silver_count += to_add
		if("gold")
			gold_count += to_add

	to_chat(user, span_notice("You add [to_add] [ore_type] ore to the refiner."))
	playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)
	SStgui.update_uis(src)

/// Add coal to the refiner
/obj/structure/ore_refiner/proc/add_coal(obj/item/stack/sheet/mineral/coal/coal_stack, mob/user)
	if(processing)
		to_chat(user, span_warning("The refiner is currently processing!"))
		return

	var/space = max_coal - coal_count
	if(space <= 0)
		to_chat(user, span_warning("The coal hopper is full!"))
		return

	var/to_add = min(coal_stack.amount, space)
	coal_stack.use(to_add)
	coal_count += to_add

	to_chat(user, span_notice("You add [to_add] coal to the refiner."))
	playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)
	SStgui.update_uis(src)

/// Get the total primary ore count
/obj/structure/ore_refiner/proc/get_total_ore()
	return iron_count + silver_count + gold_count

/// Calculate what type of core will be produced
/obj/structure/ore_refiner/proc/calculate_core_type()
	var/total = get_total_ore()
	if(total <= 0)
		return null

	var/iron_pct = (iron_count / total) * 100
	var/silver_pct = (silver_count / total) * 100
	var/gold_pct = (gold_count / total) * 100

	// Resolution order from the plan:
	// 1. Gold >= 51%: Gold Core
	if(gold_pct >= 51)
		return CORE_ORE_GOLD

	// 2. Gold 26-50%: Gilded Gold Core (handled separately)
	// 3. Gold 1-25%: Gilded prefix (handled in gilded check)

	// For non-gold dominant:
	// 4. Iron 40-60% AND Silver 40-60%: Alloy Core
	if(iron_pct >= 40 && iron_pct <= 60 && silver_pct >= 40 && silver_pct <= 60)
		return CORE_ORE_ALLOY

	// 5. Iron > Silver: Iron Core
	// 6. Silver > Iron: Silver Core
	// 7. Iron = Silver: Alloy Core
	if(iron_pct > silver_pct)
		return CORE_ORE_IRON
	else if(silver_pct > iron_pct)
		return CORE_ORE_SILVER
	else if(iron_pct > 0 && silver_pct > 0)
		return CORE_ORE_ALLOY

	// Pure gold (but less than 51%)
	if(gold_pct > 0)
		return CORE_ORE_GOLD

	return null

/// Check if the core should be gilded
/obj/structure/ore_refiner/proc/is_gilded()
	var/total = get_total_ore()
	if(total <= 0)
		return FALSE

	var/gold_pct = (gold_count / total) * 100
	return gold_pct >= 1 && gold_pct <= 50

/// Check if the core gets the "Gilded Gold" treatment (26-50% gold)
/obj/structure/ore_refiner/proc/is_gilded_gold()
	var/total = get_total_ore()
	if(total <= 0)
		return FALSE

	var/gold_pct = (gold_count / total) * 100
	return gold_pct >= 26 && gold_pct <= 50

/// Check if the core has a minor ore bonus (+5% from unbalanced mix)
/obj/structure/ore_refiner/proc/has_minor_ore_bonus()
	var/total = get_total_ore()
	if(total <= 0)
		return FALSE

	var/iron_pct = (iron_count / total) * 100
	var/silver_pct = (silver_count / total) * 100

	// Unbalanced mix: one is 61%+ and the other is present
	if(iron_pct >= 61 && silver_count > 0)
		return TRUE
	if(silver_pct >= 61 && iron_count > 0)
		return TRUE

	return FALSE

/// Calculate the refinement level based on total ore (uncapped)
/obj/structure/ore_refiner/proc/calculate_raw_refinement_level()
	var/total = get_total_ore()

	if(total >= 21)
		return CORE_LEVEL_LEGENDARY
	if(total >= 11)
		return CORE_LEVEL_EXCEPTIONAL
	if(total >= 6)
		return CORE_LEVEL_REFINED
	if(total >= 3)
		return CORE_LEVEL_COMMON
	return CORE_LEVEL_CRUDE

/// Calculate the refinement level based on total ore (no research cap)
/obj/structure/ore_refiner/proc/calculate_refinement_level()
	return calculate_raw_refinement_level()

/// Calculate the fuel level based on coal ratio
/obj/structure/ore_refiner/proc/calculate_fuel_level()
	var/total_ore = get_total_ore()
	if(total_ore <= 0)
		return CORE_FUEL_UNFUELED

	var/coal_ratio = coal_count / total_ore

	// 2:1 coal = supercharged
	if(coal_ratio >= 2)
		return CORE_FUEL_SUPERCHARGED
	// 1:1 coal = high
	if(coal_ratio >= 1)
		return CORE_FUEL_HIGH
	// 1:2 coal = standard
	if(coal_ratio >= 0.5)
		return CORE_FUEL_STANDARD
	// 1:4 coal = low
	if(coal_ratio >= 0.25)
		return CORE_FUEL_LOW
	// 0 or less = unfueled
	return CORE_FUEL_UNFUELED

/// Get a preview of what will be produced
/obj/structure/ore_refiner/proc/get_preview()
	var/list/preview = list()

	var/core_type = calculate_core_type()
	if(!core_type)
		preview["valid"] = FALSE
		preview["error"] = "No ore loaded"
		return preview

	preview["valid"] = TRUE
	preview["core_type"] = core_type

	// Get refinement level (no research cap)
	preview["refinement_level"] = calculate_refinement_level()
	preview["level_capped"] = FALSE

	preview["fuel_level"] = calculate_fuel_level()
	preview["gilded"] = is_gilded()
	preview["gilded_gold"] = is_gilded_gold()
	preview["minor_ore_bonus"] = has_minor_ore_bonus()

	// Get display names
	var/level_name
	switch(preview["refinement_level"])
		if(CORE_LEVEL_CRUDE)
			level_name = "Crude"
		if(CORE_LEVEL_COMMON)
			level_name = "Common"
		if(CORE_LEVEL_REFINED)
			level_name = "Refined"
		if(CORE_LEVEL_EXCEPTIONAL)
			level_name = "Exceptional"
		if(CORE_LEVEL_LEGENDARY)
			level_name = "Legendary"

	var/fuel_name
	switch(preview["fuel_level"])
		if(CORE_FUEL_UNFUELED)
			fuel_name = "Unfueled (-50%)"
		if(CORE_FUEL_LOW)
			fuel_name = "Low Fuel (-25%)"
		if(CORE_FUEL_STANDARD)
			fuel_name = "Standard"
		if(CORE_FUEL_HIGH)
			fuel_name = "High Fuel (+25%)"
		if(CORE_FUEL_SUPERCHARGED)
			fuel_name = "Supercharged (+50%)"

	var/ore_name
	switch(core_type)
		if(CORE_ORE_IRON)
			ore_name = "Iron"
		if(CORE_ORE_SILVER)
			ore_name = "Silver"
		if(CORE_ORE_ALLOY)
			ore_name = "Alloy"
		if(CORE_ORE_GOLD)
			ore_name = "Gold"

	// Build the full name
	var/full_name = "[level_name]"
	if(preview["gilded"])
		if(preview["gilded_gold"])
			full_name += " Gilded Gold"
		else
			full_name += " Gilded [ore_name]"
	else
		full_name += " [ore_name]"
	full_name += " Core"

	preview["display_name"] = full_name
	preview["level_name"] = level_name
	preview["fuel_name"] = fuel_name
	preview["ore_name"] = ore_name

	return preview

/// Faith cost to refine a core
#define REFINER_FAITH_COST 0.25

/// Start the refining process
/obj/structure/ore_refiner/proc/start_refining(mob/user)
	if(processing)
		to_chat(user, span_warning("The refiner is already processing!"))
		return FALSE

	var/total_ore = get_total_ore()
	if(total_ore <= 0)
		to_chat(user, span_warning("Load some ore first!"))
		return FALSE

	// Check faith cost
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			if(core.faith < REFINER_FAITH_COST)
				to_chat(user, span_warning("You lack the faith to operate the refiner! (Need [REFINER_FAITH_COST] faith)"))
				return FALSE
			core.adjust_faith(-REFINER_FAITH_COST)

	processing = TRUE
	to_chat(user, span_notice("The refiner begins processing..."))
	playsound(src, 'sound/machines/juicer.ogg', 50, TRUE)
	SStgui.update_uis(src)

	addtimer(CALLBACK(src, PROC_REF(complete_refining), user), REFINER_PROCESS_TIME)
	return TRUE

/// Complete the refining process and create the core
/obj/structure/ore_refiner/proc/complete_refining(mob/user)
	if(!processing)
		return

	// Calculate all properties
	var/core_type = calculate_core_type()
	var/refinement_level = calculate_refinement_level()
	var/fuel_level = calculate_fuel_level()
	var/gilded = is_gilded()
	var/gilded_gold = is_gilded_gold()
	var/minor_bonus = has_minor_ore_bonus()

	// If gilded gold, override core type to gold
	if(gilded_gold)
		core_type = CORE_ORE_GOLD

	// Create the core
	var/obj/item/ore_core/new_core = new(get_turf(src))
	new_core.ore_type = core_type
	new_core.refinement_level = refinement_level
	new_core.fuel_level = fuel_level
	new_core.gilded = gilded
	new_core.has_minor_ore_bonus = minor_bonus
	new_core.update_movement_type()
	new_core.update_appearance()

	// Consume materials
	// Coal consumption based on fuel level achieved
	var/total_ore = get_total_ore()
	var/coal_used
	switch(fuel_level)
		if(CORE_FUEL_SUPERCHARGED)
			coal_used = total_ore * 2
		if(CORE_FUEL_HIGH)
			coal_used = total_ore
		if(CORE_FUEL_STANDARD)
			coal_used = round(total_ore / 2)
		if(CORE_FUEL_LOW)
			coal_used = round(total_ore / 4)
		else
			coal_used = 0

	// Clear all loaded materials
	iron_count = 0
	silver_count = 0
	gold_count = 0
	coal_count = max(0, coal_count - coal_used)

	processing = FALSE

	visible_message(span_notice("The [src] finishes processing and produces a [new_core.name]!"))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	SStgui.update_uis(src)

// ===== TGUI Interface =====

/obj/structure/ore_refiner/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OreRefiner", name)
		ui.open()

/obj/structure/ore_refiner/ui_data(mob/user)
	var/list/data = list()

	data["iron_count"] = iron_count
	data["silver_count"] = silver_count
	data["gold_count"] = gold_count
	data["coal_count"] = coal_count
	data["max_ore"] = max_ore_per_type
	data["max_coal"] = max_coal
	data["processing"] = processing
	data["total_ore"] = get_total_ore()

	// Calculate percentages
	var/total = get_total_ore()
	if(total > 0)
		data["iron_pct"] = round((iron_count / total) * 100, 1)
		data["silver_pct"] = round((silver_count / total) * 100, 1)
		data["gold_pct"] = round((gold_count / total) * 100, 1)
	else
		data["iron_pct"] = 0
		data["silver_pct"] = 0
		data["gold_pct"] = 0

	// Preview
	data["preview"] = get_preview()

	return data

/obj/structure/ore_refiner/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("refine")
			start_refining(usr)
			return TRUE

		if("eject_iron")
			eject_material("iron", usr)
			return TRUE

		if("eject_silver")
			eject_material("silver", usr)
			return TRUE

		if("eject_gold")
			eject_material("gold", usr)
			return TRUE

		if("eject_coal")
			eject_material("coal", usr)
			return TRUE

	return FALSE

/// Eject a material from the refiner
/obj/structure/ore_refiner/proc/eject_material(material_type, mob/user)
	if(processing)
		to_chat(user, span_warning("Cannot eject while processing!"))
		return

	var/count
	var/stack_type

	switch(material_type)
		if("iron")
			count = iron_count
			stack_type = /obj/item/stack/ore/iron
			iron_count = 0
		if("silver")
			count = silver_count
			stack_type = /obj/item/stack/ore/silver
			silver_count = 0
		if("gold")
			count = gold_count
			stack_type = /obj/item/stack/ore/gold
			gold_count = 0
		if("coal")
			count = coal_count
			stack_type = /obj/item/stack/sheet/mineral/coal
			coal_count = 0
		else
			return

	if(count <= 0)
		to_chat(user, span_warning("No [material_type] to eject!"))
		return

	new stack_type(get_turf(src), count)
	to_chat(user, span_notice("You eject [count] [material_type]."))
	playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)
	SStgui.update_uis(src)

/obj/structure/ore_refiner/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the interface.")
	if(iron_count > 0 || silver_count > 0 || gold_count > 0)
		. += span_notice("Loaded: [iron_count] iron, [silver_count] silver, [gold_count] gold ore.")
	if(coal_count > 0)
		. += span_notice("Coal fuel: [coal_count]")
	if(processing)
		. += span_warning("Currently processing...")

#undef REFINER_PROCESS_TIME
