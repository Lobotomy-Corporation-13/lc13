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
	var/max_fuel = 10000
	var/current_fuel = 500
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

	if(istype(I, /obj/item/rce_power_cell))
		var/obj/item/rce_power_cell/cell = I
		RefillPowerCell(cell, user)
		return

	if(istype(I, /obj/item/rce_acid_canister))
		var/obj/item/rce_acid_canister/canister = I
		RefillAcidCanister(canister, user)
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

/obj/machinery/rce_fuel_storage/proc/RefillPowerCell(obj/item/rce_power_cell/cell, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/charge_needed = cell.max_charge - cell.current_charge
	if(charge_needed <= 0)
		to_chat(user, span_notice("[cell] is already full."))
		return

	user.visible_message(span_notice("[user] begins charging [cell]..."))

	if(do_after(user, 3 SECONDS, src))
		var/charge_transferred = min(charge_needed, current_fuel, 100)
		cell.current_charge += charge_transferred
		current_fuel -= charge_transferred
		to_chat(user, span_notice("You charge [cell]. ([charge_transferred] charge transferred)"))
		playsound(src, 'sound/machines/defib_charge.ogg', 50, TRUE)
		do_sparks(2, TRUE, src)
		update_icon()

/obj/machinery/rce_fuel_storage/proc/RefillAcidCanister(obj/item/rce_acid_canister/canister, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/acid_needed = canister.max_acid - canister.current_acid
	if(acid_needed <= 0)
		to_chat(user, span_notice("[canister] is already full."))
		return

	user.visible_message(span_notice("[user] begins filling [canister]..."))

	if(do_after(user, 3 SECONDS, src))
		var/acid_transferred = min(acid_needed, current_fuel, 100)
		canister.current_acid += acid_transferred
		current_fuel -= acid_transferred
		to_chat(user, span_notice("You fill [canister]. ([acid_transferred] acid transferred)"))
		playsound(src, 'sound/effects/bubbles.ogg', 50, TRUE)
		update_icon()

// PORTABLE POWER CELL FOR RAVENS (Storm Ram support)
/obj/item/rce_power_cell
	name = "R-Corp power cell"
	desc = "A portable power cell used by Ravens to recharge Storm Ram capacitor packs in the field."
	icon = 'icons/obj/power.dmi'
	icon_state = "cell"
	w_class = WEIGHT_CLASS_NORMAL
	var/max_charge = 100
	var/current_charge = 100

/obj/item/rce_power_cell/examine(mob/user)
	. = ..()
	. += span_notice("Charge level: [current_charge]/[max_charge]")

/obj/item/rce_power_cell/afterattack(atom/target, mob/user, proximity_flag, params)
	if(!proximity_flag)
		return

	// Refill at central storage
	if(istype(target, /obj/machinery/rce_fuel_storage))
		var/obj/machinery/rce_fuel_storage/storage = target
		storage.RefillPowerCell(src, user)
		return

	// Check if user is a Raven
	if(!IsRaven(user))
		to_chat(user, span_warning("Only Ravens are trained in field refueling procedures!"))
		return

	// Recharge capacitor packs
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/rce_resource_tank/capacitor_pack/pack = locate() in H.contents

		if(!pack)
			to_chat(user, span_warning("[H] doesn't have a capacitor pack!"))
			return

		RechargeTarget(pack, H, user)

/obj/item/rce_power_cell/proc/RechargeTarget(obj/item/rce_resource_tank/capacitor_pack/pack, mob/living/carbon/human/target, mob/user)
	if(current_charge <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/charge_needed = pack.max_resource - pack.resource_amount

	if(charge_needed <= 0)
		to_chat(user, span_notice("[target]'s capacitor pack is already full."))
		return

	user.visible_message(span_notice("[user] begins recharging [target]'s capacitor pack..."))

	if(do_after(user, 10 SECONDS, target))
		var/charge_transferred = min(charge_needed, current_charge)
		pack.resource_amount += charge_transferred
		current_charge -= charge_transferred
		to_chat(user, span_notice("You recharge [target]'s capacitor pack. ([charge_transferred] charge transferred)"))
		to_chat(target, span_nicegreen("[user] recharges your capacitor pack!"))
		playsound(src, 'sound/machines/defib_charge.ogg', 50, TRUE)
		do_sparks(2, TRUE, target)

// PORTABLE ACID CANISTER FOR RAVENS (Venom Rattlesnake support)
/obj/item/rce_acid_canister
	name = "R-Corp acid canister"
	desc = "A portable acid canister used by Ravens to refill Venom Rattlesnake acid tanks in the field. Handle with care!"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "acid"
	w_class = WEIGHT_CLASS_NORMAL
	var/max_acid = 100
	var/current_acid = 100

/obj/item/rce_acid_canister/examine(mob/user)
	. = ..()
	. += span_notice("Acid level: [current_acid]/[max_acid]")
	. += span_warning("Corrosive! Handle with care.")

/obj/item/rce_acid_canister/afterattack(atom/target, mob/user, proximity_flag, params)
	if(!proximity_flag)
		return

	// Refill at central storage
	if(istype(target, /obj/machinery/rce_fuel_storage))
		var/obj/machinery/rce_fuel_storage/storage = target
		storage.RefillAcidCanister(src, user)
		return

	// Check if user is a Raven
	if(!IsRaven(user))
		to_chat(user, span_warning("Only Ravens are trained in field refueling procedures!"))
		return

	// Refill acid tanks
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/rce_resource_tank/acid_backpack/tank = locate() in H.contents

		if(!tank)
			to_chat(user, span_warning("[H] doesn't have an acid tank!"))
			return

		RefillTarget(tank, H, user)

/obj/item/rce_acid_canister/proc/RefillTarget(obj/item/rce_resource_tank/acid_backpack/tank, mob/living/carbon/human/target, mob/user)
	if(current_acid <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/acid_needed = tank.max_resource - tank.resource_amount

	if(acid_needed <= 0)
		to_chat(user, span_notice("[target]'s acid tank is already full."))
		return

	user.visible_message(span_notice("[user] begins refilling [target]'s acid tank..."))

	if(do_after(user, 10 SECONDS, target))
		var/acid_transferred = min(acid_needed, current_acid)
		tank.resource_amount += acid_transferred
		current_acid -= acid_transferred
		to_chat(user, span_notice("You refill [target]'s acid tank. ([acid_transferred] acid transferred)"))
		to_chat(target, span_nicegreen("[user] refills your acid tank!"))
		playsound(src, 'sound/effects/bubbles.ogg', 50, TRUE)

// Helper proc to check if user is a Raven
/proc/IsRaven(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/datum/job/user_job = H.mind?.assigned_role
	if(!user_job)
		return FALSE
	return istype(user_job, /datum/job/raven) || istype(user_job, /datum/job/raven_messenger) || istype(user_job, /datum/job/raven_mp) || istype(user_job, /datum/job/rcorp_captain/raven)

// FUEL SLOWDOWN COMPONENT
/datum/component/fuel_slowdown
	var/slowdown_amount = 2

/datum/component/fuel_slowdown/Initialize()
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(CheckFuelTank))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(CheckFuelTank))

/datum/component/fuel_slowdown/proc/CheckFuelTank(mob/source, obj/item/I, slot)
	SIGNAL_HANDLER

	var/mob/living/carbon/human/H = source
	if(!istype(H))
		return

	// Check if user is a Raven (immune to slowdown)
	if(istype(H.mind?.assigned_role, /datum/job/raven) || istype(H.mind?.assigned_role, /datum/job/raven_messenger))
		H.remove_movespeed_modifier(/datum/movespeed_modifier/fuel_tank)
		return

	// Check for any RCE resource tank
	var/has_tank = locate(/obj/item/rce_resource_tank) in H.contents

	if(has_tank)
		H.add_movespeed_modifier(/datum/movespeed_modifier/fuel_tank)
	else
		H.remove_movespeed_modifier(/datum/movespeed_modifier/fuel_tank)

/datum/movespeed_modifier/fuel_tank
	multiplicative_slowdown = 2

// Moved to base rce_resource_tank type - no longer needed here

