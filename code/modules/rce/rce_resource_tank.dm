// Base Resource Tank System for RCE
// Provides common functionality for fuel tanks, acid tanks, and capacitor packs

/obj/item/rce_resource_tank
	name = "RCE resource tank"
	desc = "A resource tank for RCE equipment."
	icon = 'icons/obj/tank.dmi'
	icon_state = "rce_fuel"
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY

	// Resource management
	var/resource_amount = 1000
	var/max_resource = 1000
	var/resource_name = "resource"  // "fuel", "acid", "charge"
	var/resource_unit = "units"  // Display name for units

	// Weapon linking
	var/obj/item/linked_weapon

	// Refill settings
	var/refill_sound = 'sound/effects/refill.ogg'
	var/transfer_rate = 100  // Max units per refill action

	// Dispenser types this tank can refill from
	var/list/compatible_dispensers = list()
	var/list/compatible_stations = list()

/obj/item/rce_resource_tank/Initialize()
	. = ..()
	resource_amount = max_resource

/obj/item/rce_resource_tank/examine(mob/user)
	. = ..()
	. += span_notice("[capitalize(resource_name)] level: [resource_amount]/[max_resource]")
	if(resource_amount < max_resource * 0.2)
		. += span_warning("Low [resource_name]! Find a refill station.")

/obj/item/rce_resource_tank/proc/use_resource(amount)
	if(resource_amount >= amount)
		resource_amount -= amount
		return TRUE
	return FALSE

/obj/item/rce_resource_tank/proc/add_resource(amount)
	var/space_available = max_resource - resource_amount
	var/amount_to_add = min(amount, space_available)
	resource_amount += amount_to_add
	return amount_to_add

/obj/item/rce_resource_tank/dropped(mob/user)
	. = ..()
	if(linked_weapon)
		to_chat(user, span_warning("The weapon's [resource_name] line disconnects!"))
		linked_weapon = null

/obj/item/rce_resource_tank/attackby(obj/item/I, mob/user, params)
	// Transfer from another tank of same type
	if(istype(I, type))
		var/obj/item/rce_resource_tank/other_tank = I
		if(other_tank.resource_amount <= 0)
			to_chat(user, span_warning("[other_tank] is empty!"))
			return
		if(resource_amount >= max_resource)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/transfer_amount = min(other_tank.resource_amount, max_resource - resource_amount)
		resource_amount += transfer_amount
		other_tank.resource_amount -= transfer_amount
		to_chat(user, span_notice("You transfer [transfer_amount] [resource_unit] of [resource_name] from [other_tank] to [src]."))
		playsound(src, refill_sound, 50, TRUE)
		return
	return ..()

/obj/item/rce_resource_tank/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return

	// Try to refill from compatible dispensers
	for(var/dispenser_type in compatible_dispensers)
		if(istype(target, dispenser_type))
			try_refill_from_dispenser(target, user)
			return

	// Try to refill from compatible stations
	for(var/station_type in compatible_stations)
		if(istype(target, station_type))
			try_refill_from_station(target, user)
			return

/obj/item/rce_resource_tank/proc/try_refill_from_dispenser(obj/structure/dispenser, mob/user)
	// Override in subtypes for specific dispenser logic
	return

/obj/item/rce_resource_tank/proc/try_refill_from_station(obj/structure/station, mob/user)
	// Override in subtypes for specific station logic
	return

/obj/item/rce_resource_tank/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		user.AddComponent(/datum/component/fuel_slowdown)

/obj/item/rce_resource_tank/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		var/datum/component/fuel_slowdown/C = user.GetComponent(/datum/component/fuel_slowdown)
		if(C)
			C.CheckFuelTank(user)
