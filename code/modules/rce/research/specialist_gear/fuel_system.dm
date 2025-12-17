// R-Corp Fuel Management System
// Central infrastructure for fuel storage and distribution

// MAIN FUEL STORAGE TANK
/obj/machinery/rce_fuel_storage
	name = "R-Corp central fuel storage"
	desc = "A massive fuel storage tank that supplies the entire base. Refills using resource materials."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_structures_32x48.dmi'
	icon_state = "silo"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	var/max_fuel = 10000
	var/current_fuel = 0
	var/refill_rate = 10 // Fuel per resource consumed
	var/resource_cost = 5 // Resources needed per refill cycle
	var/refilling = FALSE
	var/userface_color = COLOR_VIBRANT_LIME

/obj/machinery/rce_fuel_storage/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	update_icon()

/obj/machinery/rce_fuel_storage/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/machinery/rce_fuel_storage/process()
	if(!refilling)
		return

	// Check for nearby factory items to consume
	var/items_consumed = 0
	var/total_fuel_gained = 0

	for(var/obj/item/factoryitem/item in range(2, src))
		if(items_consumed >= resource_cost)
			break
		// Calculate fuel value based on resource type
		var/fuel_multiplier = GetResourceMultiplier(item)
		total_fuel_gained += refill_rate * fuel_multiplier
		qdel(item)
		items_consumed++

	if(items_consumed == 0)
		refilling = FALSE
		visible_message(span_warning("[src] stops refilling - no factory materials nearby!"))
		update_icon()
		return

	// Generate fuel from consumed items
	current_fuel = min(current_fuel + total_fuel_gained, max_fuel)
	visible_message(span_notice("[src] processes [items_consumed] factory materials into [total_fuel_gained] fuel."))
	update_icon()

/// Returns the fuel multiplier for a given factory item type
/obj/machinery/rce_fuel_storage/proc/GetResourceMultiplier(obj/item/factoryitem/item)
	// Base tier (1x): Green, Red
	if(istype(item, /obj/item/factoryitem/green))
		return 1
	if(istype(item, /obj/item/factoryitem/red))
		return 1
	// Mid tier (2x): Blue, Purple
	if(istype(item, /obj/item/factoryitem/blue))
		return 2
	if(istype(item, /obj/item/factoryitem/purple))
		return 2
	// High tier (4x): Orange, Silver
	if(istype(item, /obj/item/factoryitem/orange))
		return 4
	if(istype(item, /obj/item/factoryitem/silver))
		return 4
	// Default fallback
	return 1

/obj/machinery/rce_fuel_storage/examine(mob/user)
	. = ..()
	. += span_notice("Fuel level: [current_fuel]/[max_fuel]")
	. += span_notice("Refilling: [refilling ? "ACTIVE" : "INACTIVE"]")
	. += span_notice("Place factory materials nearby and Alt-click to toggle automatic refilling.")
	. += span_notice("Consumes up to [resource_cost] materials per cycle.")
	. += span_notice("Resource efficiency: Green/Red (1x), Blue/Purple (2x), Orange/Silver (4x)")

/obj/machinery/rce_fuel_storage/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	refilling = !refilling
	to_chat(user, span_notice("You [refilling ? "enable" : "disable"] automatic refilling."))
	update_icon()

/obj/machinery/rce_fuel_storage/update_icon_state()
	icon_state = "silo"

/obj/machinery/rce_fuel_storage/update_overlays()
	. = ..()
	// Add fill level overlay
	var/fill_overlay = GetFillOverlay()
	if(fill_overlay)
		. += fill_overlay
	// Add unloading overlay if refilling
	if(refilling)
		. += "silo_overlayunloading"

/// Returns the appropriate fill overlay based on current fuel level
/obj/machinery/rce_fuel_storage/proc/GetFillOverlay()
	var/fill_percent = (current_fuel / max_fuel) * 100
	var/fill_text
	switch(fill_percent)
		if(-INFINITY to 0)
			return null
		if(0.1 to 19)
			fill_text = 0
		if(20 to 39)
			fill_text = 20
		if(40 to 59)
			fill_text = 40
		if(60 to 79)
			fill_text = 60
		if(80 to 99)
			fill_text = 80
		if(100 to INFINITY)
			fill_text = 100
	var/mutable_appearance/percent_overlay = mutable_appearance(icon, "silo_overlay[fill_text]")
	percent_overlay.color = userface_color
	return percent_overlay

/obj/machinery/rce_fuel_storage/attackby(obj/item/I, mob/user, params)
	// Refill fuel tanks
	if(istype(I, /obj/item/rce_resource_tank/fuel_backpack))
		var/obj/item/rce_resource_tank/fuel_backpack/tank = I
		RefillTank(tank, user)
		return

	if(istype(I, /obj/item/rce_resource_tank/acid_backpack))
		var/obj/item/rce_resource_tank/acid_backpack/tank = I
		RefillAcidTank(tank, user)
		return

	if(istype(I, /obj/item/rce_resource_tank/capacitor_pack))
		var/obj/item/rce_resource_tank/capacitor_pack/pack = I
		RefillCapacitor(pack, user)
		return

	if(istype(I, /obj/item/rce_canister/power))
		var/obj/item/rce_canister/power/cell = I
		RefillPowerCell(cell, user)
		return

	if(istype(I, /obj/item/rce_canister/acid))
		var/obj/item/rce_canister/acid/canister = I
		RefillAcidCanister(canister, user)
		return

	if(istype(I, /obj/item/rce_canister/fuel))
		var/obj/item/rce_canister/fuel/canister = I
		RefillFuelCanister(canister, user)
		return

	return ..()

/obj/machinery/rce_fuel_storage/proc/RefillTank(obj/item/rce_resource_tank/tank, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/resource_needed = tank.max_resource - tank.resource_amount
	if(resource_needed <= 0)
		to_chat(user, span_notice("[tank] is already full."))
		return

	user.visible_message(span_notice("[user] begins refilling [tank]..."))

	if(do_after(user, 5 SECONDS, src))
		var/resource_transferred = min(resource_needed, current_fuel)
		tank.resource_amount += resource_transferred
		current_fuel -= resource_transferred
		to_chat(user, span_notice("You refill [tank]. ([resource_transferred] [tank.resource_name] transferred)"))
		playsound(src, tank.refill_sound, 50, TRUE)
		update_icon()

/obj/machinery/rce_fuel_storage/proc/RefillAcidTank(obj/item/rce_resource_tank/acid_backpack/tank, mob/user)
	return RefillTank(tank, user)

/obj/machinery/rce_fuel_storage/proc/RefillCapacitor(obj/item/rce_resource_tank/capacitor_pack/pack, mob/user)
	return RefillTank(pack, user)

/obj/machinery/rce_fuel_storage/proc/RefillPowerCell(obj/item/rce_canister/power/cell, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/charge_needed = cell.max_amount - cell.current_amount
	if(charge_needed <= 0)
		to_chat(user, span_notice("[cell] is already full."))
		return

	user.visible_message(span_notice("[user] begins charging [cell]..."))

	if(do_after(user, 3 SECONDS, src))
		var/charge_transferred = min(charge_needed, current_fuel, 100)
		cell.current_amount += charge_transferred
		current_fuel -= charge_transferred
		to_chat(user, span_notice("You charge [cell]. ([charge_transferred] charge transferred)"))
		playsound(src, 'sound/machines/defib_charge.ogg', 50, TRUE)
		do_sparks(2, TRUE, src)
		update_icon()

/obj/machinery/rce_fuel_storage/proc/RefillAcidCanister(obj/item/rce_canister/acid/canister, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/acid_needed = canister.max_amount - canister.current_amount
	if(acid_needed <= 0)
		to_chat(user, span_notice("[canister] is already full."))
		return

	user.visible_message(span_notice("[user] begins filling [canister]..."))

	if(do_after(user, 3 SECONDS, src))
		var/acid_transferred = min(acid_needed, current_fuel, 100)
		canister.current_amount += acid_transferred
		current_fuel -= acid_transferred
		to_chat(user, span_notice("You fill [canister]. ([acid_transferred] acid transferred)"))
		playsound(src, 'sound/effects/bubbles.ogg', 50, TRUE)
		update_icon()

/obj/machinery/rce_fuel_storage/proc/RefillFuelCanister(obj/item/rce_canister/fuel/canister, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/fuel_needed = canister.max_amount - canister.current_amount
	if(fuel_needed <= 0)
		to_chat(user, span_notice("[canister] is already full."))
		return

	user.visible_message(span_notice("[user] begins filling [canister]..."))

	if(do_after(user, 3 SECONDS, src))
		var/fuel_transferred = min(fuel_needed, current_fuel, 100)
		canister.current_amount += fuel_transferred
		current_fuel -= fuel_transferred
		to_chat(user, span_notice("You fill [canister]. ([fuel_transferred] fuel transferred)"))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
		update_icon()

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

// Fuel Tank Backpack
/obj/item/rce_resource_tank/fuel_backpack
	name = "heavy fuel tank"
	desc = "A large fuel tank designed to be worn on the back. Powers heavy flamethrower weapons."
	icon = 'icons/obj/tank.dmi'
	icon_state = "hellfire_tank"
	worn_icon = 'icons/mob/clothing/back.dmi'

	// Resource configuration
	resource_name = "fuel"
	resource_unit = "units"
	resource_amount = 500
	max_resource = 500

	// Compatible refill sources
	compatible_dispensers = list(/obj/structure/reagent_dispensers/fueltank)

/obj/item/rce_resource_tank/fuel_backpack/try_refill_from_dispenser(obj/structure/reagent_dispensers/fueltank/F, mob/user)
	if(resource_amount >= max_resource)
		to_chat(user, span_warning("[src] is already full!"))
		return
	if(!F.reagents.has_reagent(/datum/reagent/fuel))
		to_chat(user, span_warning("[F] is out of fuel!"))
		return
	var/fuel_needed = max_resource - resource_amount
	var/fuel_available = F.reagents.get_reagent_amount(/datum/reagent/fuel)
	var/fuel_to_transfer = min(fuel_needed, fuel_available)
	F.reagents.remove_reagent(/datum/reagent/fuel, fuel_to_transfer)
	resource_amount += fuel_to_transfer
	user.visible_message(span_notice("[user] refills [src] from [F]."), span_notice("You refill [src] from [F]."))
	playsound(src, refill_sound, 50, TRUE)

/obj/item/rce_resource_tank/fuel_backpack/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/rce_canister/fuel))
		var/obj/item/rce_canister/fuel/canister = I
		if(canister.current_amount <= 0)
			to_chat(user, span_warning("[canister] is empty!"))
			return
		if(resource_amount >= max_resource)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/transfer_amount = min(canister.current_amount, max_resource - resource_amount)
		resource_amount += transfer_amount
		canister.current_amount -= transfer_amount
		to_chat(user, span_notice("You refill [src] with [transfer_amount] units from [canister]."))
		playsound(src, refill_sound, 50, TRUE)
		return
	return ..()

// Acid Tank Backpack - Core resource for toxic weapons
/obj/item/rce_resource_tank/acid_backpack
	name = "heavy acid tank"
	desc = "A reinforced tank containing highly corrosive acids. Powers various R-Corp toxic weapon systems."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "waterbackpack"

	// Resource configuration
	resource_name = "acid"
	resource_unit = "units"
	resource_amount = 1000
	max_resource = 1000

	// Compatible refill sources
	compatible_dispensers = list(/obj/structure/acid_dispenser, /obj/structure/reagent_dispensers/watertank)

/obj/item/rce_resource_tank/acid_backpack/proc/use_acid(amount)
	return use_resource(amount)

/obj/item/rce_resource_tank/acid_backpack/attackby(obj/item/I, mob/user, params)
	// Portable acid canister for Ravens
	if(istype(I, /obj/item/rce_canister/acid))
		var/obj/item/rce_canister/acid/canister = I
		if(canister.current_amount <= 0)
			to_chat(user, span_warning("[canister] is empty!"))
			return
		if(resource_amount >= max_resource)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/transfer_amount = min(canister.current_amount, max_resource - resource_amount)
		resource_amount += transfer_amount
		canister.current_amount -= transfer_amount
		to_chat(user, span_notice("You refill [src] with [transfer_amount] units from [canister]."))
		playsound(src, refill_sound, 50, TRUE)
		return
	return ..()

/obj/item/rce_resource_tank/acid_backpack/try_refill_from_dispenser(obj/structure/dispenser, mob/user)
	// Handle acid dispensers
	if(istype(dispenser, /obj/structure/acid_dispenser))
		if(resource_amount >= max_resource)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/obj/structure/acid_dispenser/acid_disp = dispenser
		if(acid_disp.acid_stored <= 0)
			to_chat(user, span_warning("[dispenser] is out of acid!"))
			return
		var/acid_needed = max_resource - resource_amount
		var/acid_to_transfer = min(acid_needed, acid_disp.acid_stored, 100)
		acid_disp.acid_stored -= acid_to_transfer
		resource_amount += acid_to_transfer
		user.visible_message(span_notice("[user] refills [src] from [dispenser]."), span_notice("You refill [src] from [dispenser]. ([resource_amount]/[max_resource])"))
		playsound(src, refill_sound, 50, TRUE)
		return

	// Handle chemical tanks with acid
	if(istype(dispenser, /obj/structure/reagent_dispensers/watertank))
		if(resource_amount >= max_resource)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/obj/structure/reagent_dispensers/watertank/tank = dispenser
		if(!tank.reagents.has_reagent(/datum/reagent/toxin/acid))
			to_chat(user, span_warning("[tank] doesn't contain acid!"))
			return
		var/acid_needed = max_resource - resource_amount
		var/acid_available = tank.reagents.get_reagent_amount(/datum/reagent/toxin/acid)
		var/acid_to_transfer = min(acid_needed, acid_available)
		tank.reagents.remove_reagent(/datum/reagent/toxin/acid, acid_to_transfer)
		resource_amount += acid_to_transfer
		user.visible_message(span_notice("[user] refills [src] from [tank]."), span_notice("You refill [src] from [tank]. ([resource_amount]/[max_resource])"))
		playsound(src, refill_sound, 50, TRUE)

// Capacitor Pack - Core resource for electric weapons
/obj/item/rce_resource_tank/capacitor_pack
	name = "storm capacitor pack"
	desc = "A high-capacity energy storage system that powers Storm Ram burst attacks. Can be recharged at power stations."
	icon = 'icons/obj/tank.dmi'
	icon_state = "storm_tank"
	worn_icon = 'icons/mob/clothing/back.dmi'

	// Resource configuration
	resource_name = "charge"
	resource_unit = "units"
	resource_amount = 1000
	max_resource = 1000

	// Unique capacitor features
	var/speed_boost_active = FALSE


	// Custom sounds
	refill_sound = 'sound/magic/lightningshock.ogg'

/obj/item/rce_resource_tank/capacitor_pack/proc/use_charge(amount)
	. = use_resource(amount)
	if(. && ishuman(loc))  // If charge was successfully used and pack is in a human
		var/mob/living/carbon/human/H = loc
		var/stacks_to_add = round(amount / 5)  // 1 stack per 5 charge consumed
		if(stacks_to_add > 0)
			add_overcharge(H, stacks_to_add)
	return .

/obj/item/rce_resource_tank/capacitor_pack/attackby(obj/item/I, mob/user, params)
	// Portable power cell for Ravens
	if(istype(I, /obj/item/rce_canister/power))
		var/obj/item/rce_canister/power/cell = I
		if(cell.current_amount <= 0)
			to_chat(user, span_warning("[cell] is depleted!"))
			return
		if(resource_amount >= max_resource)
			to_chat(user, span_warning("[src] is already fully charged!"))
			return
		var/transfer_amount = min(cell.current_amount, max_resource - resource_amount)
		resource_amount += transfer_amount
		cell.current_amount -= transfer_amount
		to_chat(user, span_notice("You recharge [src] with [transfer_amount] units from [cell]."))
		playsound(src, refill_sound, 30, TRUE)
		return
	return ..()


/obj/item/rce_resource_tank/capacitor_pack/examine(mob/user)
	. = ..()
	if(speed_boost_active)
		. += span_nicegreen("Speed boost active!")

// Grant Overcharge stacks when charge is used
/obj/item/rce_resource_tank/capacitor_pack/proc/add_overcharge(mob/living/user, amount = 5)
	if(!ishuman(user))
		return

	// Get or create Overcharge status effect
	var/datum/status_effect/capacitor_overcharge/overcharge = user.has_status_effect(/datum/status_effect/capacitor_overcharge)

	if(!overcharge)
		overcharge = user.apply_status_effect(/datum/status_effect/capacitor_overcharge)

	if(overcharge)
		overcharge.add_stacks(amount)

		// Visual feedback at high stacks
		if(overcharge.stacks >= 80)
			do_sparks(5, TRUE, user)

// Capacitor Overcharge - Storm Ram charge accumulation system
/datum/status_effect/capacitor_overcharge
	id = "capacitor_overcharge"
	duration = -1  // Infinite, manual removal when stacks reach 0
	tick_interval = 10  // Process every 1 second (10 deciseconds)
	alert_type = /atom/movable/screen/alert/status_effect/overcharge
	var/stacks = 0
	var/max_stacks = 100
	var/drain_per_second = 5

/datum/status_effect/capacitor_overcharge/on_apply()
	if(!isliving(owner))
		return FALSE
	owner.density = FALSE

	// Register movement signal once on apply
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

	update_bonuses()
	to_chat(owner, span_nicegreen("Overcharge building! [stacks]/[max_stacks]"))
	return TRUE

/datum/status_effect/capacitor_overcharge/proc/on_moved()
	SIGNAL_HANDLER
	// Only create trail effect at 50+ stacks
	if(stacks >= 50)
		create_move_trail()

/datum/status_effect/capacitor_overcharge/proc/create_move_trail()
	set waitfor = FALSE
	var/obj/viscon_filtereffect/distortedform_trail/trail = new(owner.loc, themob = owner, waittime = 5)
	trail.vis_contents += owner
	trail.filters += filter(type="drop_shadow", x=0, y=0, size=3, offset=2, color=rgb(0, 200, 255))  // Electric blue
	trail.filters += filter(type = "blur", size = 3)
	animate(trail, alpha=120)
	animate(alpha = 0, time = 10)

/datum/status_effect/capacitor_overcharge/tick()
	// Drain stacks passively each second
	add_stacks(-drain_per_second)

/datum/status_effect/capacitor_overcharge/proc/add_stacks(amount)
	var/old_stacks = stacks
	stacks = clamp(stacks + amount, 0, max_stacks)

	// Remove effect if stacks depleted
	if(stacks <= 0)
		qdel(src)
		return

	// Update bonuses when stacks change
	if(old_stacks != stacks)
		update_bonuses()

	// Visual feedback at key thresholds
	if(stacks >= 80 && old_stacks < 80)
		to_chat(owner, span_danger("OVERCHARGE CRITICAL: [stacks]%!"))
	else if(stacks >= 50 && old_stacks < 50)
		to_chat(owner, span_warning("OVERCHARGE ACCELERATING: [stacks]%! Speed trails active!"))

/datum/status_effect/capacitor_overcharge/proc/update_bonuses()
	if(!isliving(owner))
		return

	var/mob/living/L = owner

	// Apply damage boost (1% per stack)
	L.extra_damage = stacks

	// Update speed boost (scales with stacks)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/overcharge)
	var/datum/movespeed_modifier/overcharge/speed_mod = new()
	speed_mod.stacks = stacks
	speed_mod.multiplicative_slowdown = -(stacks * 0.005)  // -0.005 per stack
	owner.add_movespeed_modifier(speed_mod)

	// Update alert display
	if(linked_alert)
		linked_alert.desc = "Capacitor Overcharge: [stacks]/[max_stacks] stacks\n\
		Damage Bonus: +[stacks]%\n\
		Speed Bonus: +[round(stacks * 0.5, 0.1)]%\n\
		Density: PHASED\n\
		Drain: -[drain_per_second] per second"

/datum/status_effect/capacitor_overcharge/on_remove()
	if(!owner)
		return

	// Unregister movement signal
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)

	// Remove damage boost
	if(isliving(owner))
		var/mob/living/L = owner
		L.extra_damage = max(0, L.extra_damage - stacks)  // Safely remove our contribution

	// Restore density
	owner.density = TRUE

	// Remove speed modifier
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/overcharge)

	to_chat(owner, span_notice("Overcharge dissipated."))

// Alert icon for Overcharge status
/atom/movable/screen/alert/status_effect/overcharge
	name = "Overcharge"
	desc = "Electrical energy surges through you!"
	icon_state = "regenerative_core"

// Dynamic movespeed modifier that scales with Overcharge stacks
/datum/movespeed_modifier/overcharge
	variable = TRUE
	var/stacks = 0

// Helper proc to check if user is a Raven
/proc/IsRaven(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/datum/job/user_job = H.mind?.assigned_role
	if(!user_job)
		return FALSE
	return istype(user_job, /datum/job/raven) || istype(user_job, /datum/job/raven_messenger) || istype(user_job, /datum/job/raven_mp) || istype(user_job, /datum/job/rcorp_captain/raven)

// BASE RCE CANISTER - Parent type for all portable canisters used by Ravens
/obj/item/rce_canister
	name = "R-Corp canister"
	desc = "A portable canister used by Ravens for field refueling."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle"
	w_class = WEIGHT_CLASS_NORMAL
	/// Current amount of resource in the canister
	var/current_amount = 100
	/// Maximum capacity of the canister
	var/max_amount = 100
	/// Name of the resource for display purposes
	var/resource_name = "resource"
	/// The type of tank this canister can refill
	var/tank_type = /obj/item/rce_resource_tank
	/// Sound to play when refilling
	var/refill_sound = 'sound/effects/refill.ogg'
	/// Time to refill a target's tank
	var/refill_time = 10 SECONDS

/obj/item/rce_canister/examine(mob/user)
	. = ..()
	. += span_notice("[resource_name]: [current_amount]/[max_amount]")
	if(current_amount > 0)
		. += span_nicegreen("Use on a compatible tank to transfer.")

/obj/item/rce_canister/afterattack(atom/target, mob/user, proximity_flag, params)
	if(!proximity_flag)
		return

	// Refill at central storage
	if(istype(target, /obj/machinery/rce_fuel_storage))
		RefillFromStorage(target, user)
		return

	// Check if user is a Raven
	if(!IsRaven(user))
		to_chat(user, span_warning("Only Ravens are trained in field refueling procedures!"))
		return

	// Refill tanks on humans
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/rce_resource_tank/tank = locate(tank_type) in H.contents

		if(!tank)
			to_chat(user, span_warning("[H] doesn't have a compatible tank!"))
			return

		RefillTarget(tank, H, user)

/// Override this to handle refilling from central storage
/obj/item/rce_canister/proc/RefillFromStorage(obj/machinery/rce_fuel_storage/storage, mob/user)
	return

/// Refill a target's tank
/obj/item/rce_canister/proc/RefillTarget(obj/item/rce_resource_tank/tank, mob/living/carbon/human/target, mob/user)
	if(current_amount <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/amount_needed = tank.max_resource - tank.resource_amount

	if(amount_needed <= 0)
		to_chat(user, span_notice("[target]'s tank is already full."))
		return

	user.visible_message(span_notice("[user] begins refilling [target]'s tank..."))

	if(do_after(user, refill_time, target))
		var/amount_transferred = min(amount_needed, current_amount)
		tank.resource_amount += amount_transferred
		current_amount -= amount_transferred
		to_chat(user, span_notice("You refill [target]'s tank. ([amount_transferred] [resource_name] transferred)"))
		to_chat(target, span_nicegreen("[user] refills your tank!"))
		playsound(src, refill_sound, 50, TRUE)
		OnRefillComplete(target, user)

/// Called after a successful refill - override for special effects
/obj/item/rce_canister/proc/OnRefillComplete(mob/living/carbon/human/target, mob/user)
	return

// FUEL CANISTER - For Ravens to refuel Hellfire specialists
/obj/item/rce_canister/fuel
	name = "portable fuel canister"
	desc = "A small canister of concentrated fuel for field refueling. Used by Ravens to support Hellfire specialists."
	icon_state = "bottle"
	color = "#ff4400"
	resource_name = "Fuel"
	tank_type = /obj/item/rce_resource_tank/fuel_backpack
	refill_sound = 'sound/effects/refill.ogg'

/obj/item/rce_canister/fuel/RefillFromStorage(obj/machinery/rce_fuel_storage/storage, mob/user)
	storage.RefillFuelCanister(src, user)

// ACID CANISTER - For Ravens to refuel Venom Rattlesnake specialists
/obj/item/rce_canister/acid
	name = "R-Corp acid canister"
	desc = "A portable acid canister used by Ravens to refill Venom Rattlesnake acid tanks in the field. Handle with care!"
	icon_state = "acid"
	resource_name = "Acid"
	tank_type = /obj/item/rce_resource_tank/acid_backpack
	refill_sound = 'sound/effects/bubbles.ogg'

/obj/item/rce_canister/acid/examine(mob/user)
	. = ..()
	. += span_warning("Corrosive! Handle with care.")

/obj/item/rce_canister/acid/RefillFromStorage(obj/machinery/rce_fuel_storage/storage, mob/user)
	storage.RefillAcidCanister(src, user)

// POWER CELL - For Ravens to recharge Storm Ram specialists
/obj/item/rce_canister/power
	name = "R-Corp power cell"
	desc = "A portable power cell used by Ravens to recharge Storm Ram capacitor packs in the field."
	icon = 'icons/obj/power.dmi'
	icon_state = "cell"
	resource_name = "Charge"
	tank_type = /obj/item/rce_resource_tank/capacitor_pack
	refill_sound = 'sound/magic/charge.ogg'

/obj/item/rce_canister/power/RefillFromStorage(obj/machinery/rce_fuel_storage/storage, mob/user)
	storage.RefillPowerCell(src, user)

/obj/item/rce_canister/power/OnRefillComplete(mob/living/carbon/human/target, mob/user)
	do_sparks(2, TRUE, target)
