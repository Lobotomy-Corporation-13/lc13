/**
 * Resurgence Outpost - Craftable Light Sources
 *
 * Torches, lanterns, flashlights, campfires, and fireplaces
 * that machines can craft to illuminate their outpost.
 * All portable lights have limited fuel and burn out over time.
 */

// ==================== TORCHES ====================
// Inherit from /obj/item/flashlight/flare/torch (has fuel system, process, turn_off)

/obj/item/flashlight/flare/torch/resurgence
	name = "crude torch"
	desc = "A rough torch cobbled together from wood and coal. It won't last long."
	light_range = 3
	on_damage = 8

/obj/item/flashlight/flare/torch/resurgence/Initialize()
	. = ..()
	fuel = rand(400, 500)

/obj/item/flashlight/flare/torch/resurgence/examine(mob/user)
	. = ..()
	if(fuel > 0 && !on)
		. += span_notice("It looks ready to light.")
	else if(fuel > 0)
		switch(fuel)
			if(300 to INFINITY)
				. += span_notice("It's burning brightly.")
			if(100 to 300)
				. += span_warning("The flame is getting low.")
			else
				. += span_danger("It's about to burn out!")
	else
		. += span_warning("It's completely spent.")

/obj/item/flashlight/flare/torch/resurgence/long
	name = "long torch"
	desc = "A well-made torch with a longer handle and better fuel packing. Burns significantly longer than a crude torch."
	light_range = 4

/obj/item/flashlight/flare/torch/resurgence/long/Initialize()
	. = ..()
	fuel = rand(700, 900)

// ==================== LANTERNS ====================
// Inherit from /obj/item/flashlight/lantern but ADD fuel mechanics (parent has none)

/obj/item/flashlight/lantern/resurgence
	name = "oil lantern"
	desc = "A metal lantern that burns coal oil for a steady, reliable light."
	light_range = 5
	/// Current fuel remaining in seconds
	var/fuel = 0
	/// Maximum fuel capacity in seconds
	var/max_fuel = 1500
	/// Fuel seconds gained per piece of coal
	var/fuel_per_coal = 300

/obj/item/flashlight/lantern/resurgence/Initialize()
	. = ..()
	fuel = max_fuel

/obj/item/flashlight/lantern/resurgence/examine(mob/user)
	. = ..()
	var/fuel_percent = round((fuel / max_fuel) * 100)
	. += span_notice("Fuel: [fuel_percent]%")
	if(fuel <= 0)
		. += span_warning("It's out of fuel. Add coal to refuel.")

/obj/item/flashlight/lantern/resurgence/attack_self(mob/user)
	if(fuel <= 0)
		to_chat(user, span_warning("[src] is out of fuel!"))
		return
	if(on)
		on = FALSE
		playsound(user, 'sound/weapons/magout.ogg', 40, TRUE)
		update_brightness(user)
		STOP_PROCESSING(SSobj, src)
	else
		on = TRUE
		playsound(user, 'sound/weapons/magin.ogg', 40, TRUE)
		update_brightness(user)
		START_PROCESSING(SSobj, src)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/flashlight/lantern/resurgence/process(delta_time)
	fuel = max(fuel - delta_time, 0)
	if(fuel <= 0)
		visible_message(span_warning("[src] flickers and dies — out of fuel."))
		on = FALSE
		update_brightness()
		STOP_PROCESSING(SSobj, src)
		for(var/X in actions)
			var/datum/action/A = X
			A.UpdateButtonIcon()

/obj/item/flashlight/lantern/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/mineral/coal))
		var/obj/item/stack/sheet/mineral/coal/coal_stack = I
		var/space = max_fuel - fuel
		if(space <= 0)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/fuel_space_in_coal = round(space / fuel_per_coal)
		if(fuel_space_in_coal <= 0)
			fuel_space_in_coal = 1 // Allow topping off
		var/to_use = min(coal_stack.amount, fuel_space_in_coal)
		coal_stack.use(to_use)
		fuel = min(fuel + (to_use * fuel_per_coal), max_fuel)
		to_chat(user, span_notice("You add coal to [src]. (Fuel: [round((fuel / max_fuel) * 100)]%)"))
		playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)
		return
	return ..()

/obj/item/flashlight/lantern/resurgence/glass
	name = "glass lantern"
	desc = "A finely crafted lantern with glass panels that project a wide, clear light. Uses coal for fuel."
	light_range = 6
	max_fuel = 2250
	fuel_per_coal = 375

// ==================== FLASHLIGHTS ====================
// Inherit from /obj/item/flashlight but ADD fuel mechanics

/obj/item/flashlight/resurgence
	name = "hand light"
	desc = "A compact electric light powered by cable coils. Efficient and reliable."
	light_range = 5
	light_system = MOVABLE_LIGHT
	/// Current fuel remaining in seconds
	var/fuel = 0
	/// Maximum fuel capacity in seconds
	var/max_fuel = 2500
	/// Fuel seconds gained per cable piece
	var/fuel_per_cable = 100
	/// Maximum cables that can be loaded at once
	var/max_cable_per_refuel = 15

/obj/item/flashlight/resurgence/Initialize()
	. = ..()
	fuel = max_fuel

/obj/item/flashlight/resurgence/examine(mob/user)
	. = ..()
	var/fuel_percent = round((fuel / max_fuel) * 100)
	. += span_notice("Charge: [fuel_percent]%")
	if(fuel <= 0)
		. += span_warning("It's out of charge. Add cable coils to recharge.")

/obj/item/flashlight/resurgence/attack_self(mob/user)
	if(fuel <= 0)
		to_chat(user, span_warning("[src] is out of charge!"))
		return
	if(on)
		on = FALSE
		playsound(user, 'sound/weapons/magout.ogg', 40, TRUE)
		update_brightness(user)
		STOP_PROCESSING(SSobj, src)
	else
		on = TRUE
		playsound(user, 'sound/weapons/magin.ogg', 40, TRUE)
		update_brightness(user)
		START_PROCESSING(SSobj, src)
	for(var/X in actions)
		var/datum/action/A = X
		A.UpdateButtonIcon()

/obj/item/flashlight/resurgence/process(delta_time)
	fuel = max(fuel - delta_time, 0)
	if(fuel <= 0)
		visible_message(span_warning("[src] flickers and dies — out of charge."))
		on = FALSE
		update_brightness()
		STOP_PROCESSING(SSobj, src)
		for(var/X in actions)
			var/datum/action/A = X
			A.UpdateButtonIcon()

/obj/item/flashlight/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/coil = I
		var/space = max_fuel - fuel
		if(space <= 0)
			to_chat(user, span_warning("[src] is already fully charged!"))
			return
		var/fuel_space_in_cable = round(space / fuel_per_cable)
		if(fuel_space_in_cable <= 0)
			fuel_space_in_cable = 1
		var/to_use = min(coil.amount, fuel_space_in_cable, max_cable_per_refuel)
		coil.use(to_use)
		fuel = min(fuel + (to_use * fuel_per_cable), max_fuel)
		to_chat(user, span_notice("You feed cable into [src]. (Charge: [round((fuel / max_fuel) * 100)]%)"))
		playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)
		return
	return ..()

/obj/item/flashlight/resurgence/bright
	name = "spotlight"
	desc = "A powerful electric lamp that throws a wide beam. Drains charge quickly but illuminates a large area."
	light_range = 7
	max_fuel = 1750
	fuel_per_cable = 75

// ==================== CAMPFIRE ====================
// Inherit from /obj/structure/bonfire but ADD a fuel system (base bonfire burns forever)

/obj/structure/bonfire/resurgence
	name = "campfire"
	desc = "A carefully arranged campfire. Add wood to keep it burning."
	/// Fuel remaining in seconds
	var/fuel = 0
	/// Maximum fuel capacity in seconds
	var/max_fuel = 1500
	/// Fuel seconds gained per wood plank
	var/fuel_per_wood = 150

/obj/structure/bonfire/resurgence/Initialize()
	. = ..()
	fuel = max_fuel

/obj/structure/bonfire/resurgence/examine(mob/user)
	. = ..()
	if(burning)
		switch(fuel)
			if(1000 to INFINITY)
				. += span_notice("The fire is roaring strongly.")
			if(500 to 1000)
				. += span_notice("The fire is burning steadily.")
			if(100 to 500)
				. += span_warning("The flames are getting low.")
			else
				. += span_danger("The fire is about to go out!")
	else if(fuel > 0)
		. += span_notice("It has fuel and is ready to be lit.")
	else
		. += span_warning("It's out of fuel. Add wood to refuel.")

/obj/structure/bonfire/resurgence/attack_hand(mob/living/user, list/modifiers)
	if(burning)
		if(do_after(user, 20, target = src))
			extinguish()
			to_chat(user, span_notice("You smother the campfire."))
		return
	if(fuel <= 0)
		to_chat(user, span_warning("[src] has no fuel to burn."))
		return
	// Machines can light by hand
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(istype(H.dna?.species, /datum/species/resurgence_machine))
			to_chat(user, span_notice("You ignite [src] with a spark from your fingers."))
			StartBurning()
			return
	to_chat(user, span_warning("You need a fire source to light this."))

/obj/structure/bonfire/resurgence/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/stack/sheet/mineral/wood))
		var/obj/item/stack/sheet/mineral/wood/wood = W
		var/space = max_fuel - fuel
		if(space <= 0)
			to_chat(user, span_warning("The campfire can't hold any more wood!"))
			return
		var/fuel_space_in_wood = round(space / fuel_per_wood)
		if(fuel_space_in_wood <= 0)
			fuel_space_in_wood = 1
		var/to_use = min(wood.amount, fuel_space_in_wood)
		wood.use(to_use)
		fuel = min(fuel + (to_use * fuel_per_wood), max_fuel)
		to_chat(user, span_notice("You add wood to the campfire."))
		playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)
		return
	if(W.get_temperature())
		StartBurning()
		return
	return ..()

/obj/structure/bonfire/resurgence/StartBurning()
	if(fuel <= 0)
		return
	..()

/obj/structure/bonfire/resurgence/process(delta_time)
	if(!burning)
		return
	fuel = max(fuel - delta_time, 0)
	if(fuel <= 0)
		visible_message(span_warning("[src] sputters and dies out — no more fuel."))
		extinguish()
		return
	..()

// ==================== STONE FIREPLACE ====================
// Inherit from /obj/structure/fireplace and extend with coal support + hand-lighting

/obj/structure/fireplace/resurgence
	name = "stone fireplace"
	desc = "A sturdy stone fireplace that provides warmth and light. Burns wood or coal."
	/// Maximum fuel capacity (same as base MAXIMUM_BURN_TIMER)
	var/max_burn_timer = 3000

/obj/structure/fireplace/resurgence/attackby(obj/item/T, mob/user)
	if(istype(T, /obj/item/stack/sheet/mineral/coal))
		var/obj/item/stack/sheet/mineral/coal/coal = T
		var/space_remaining = max_burn_timer - burn_time_remaining()
		var/coal_burn_time = LOG_BURN_TIMER * 2
		var/space_for_coal = round(space_remaining / coal_burn_time)
		if(space_for_coal < 1)
			to_chat(user, span_warning("You can't fit any more fuel in [src]!"))
			return
		var/coal_used = min(space_for_coal, coal.amount)
		coal.use(coal_used)
		adjust_fuel_timer(coal_burn_time * coal_used)
		user.visible_message(span_notice("[user] adds some coal to [src]."), span_notice("You add coal to [src]."))
		return
	return ..()

/obj/structure/fireplace/resurgence/attack_hand(mob/living/user, list/modifiers)
	if(lit)
		return ..()
	if(!fuel_added && !lit)
		to_chat(user, span_warning("[src] needs fuel before it can be lit."))
		return
	// Machines can light by hand
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(istype(H.dna?.species, /datum/species/resurgence_machine))
			to_chat(user, span_notice("You ignite [src] with a spark from your fingers."))
			ignite()
			return
	to_chat(user, span_warning("You need a fire source to light this."))
