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
	var/current_fuel = 5000
	var/refill_rate = 10 // Fuel per resource consumed
	var/resource_cost = 5 // Resources needed per refill cycle
	var/refilling = FALSE

/obj/machinery/rce_fuel_storage/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/machinery/rce_fuel_storage/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/machinery/rce_fuel_storage/process()
	if(!refilling)
		return

	// Check for nearby factory items to consume
	var/items_consumed = 0

	for(var/obj/item/factoryitem/item in range(2, src))
		if(items_consumed >= resource_cost)
			break
		qdel(item)
		items_consumed++

	if(items_consumed == 0)
		refilling = FALSE
		visible_message(span_warning("[src] stops refilling - no factory materials nearby!"))
		return

	// Generate fuel from consumed items
	current_fuel = min(current_fuel + (refill_rate * items_consumed), max_fuel)
	visible_message(span_notice("[src] processes [items_consumed] factory materials into fuel."))

/obj/machinery/rce_fuel_storage/examine(mob/user)
	. = ..()
	. += span_notice("Fuel level: [current_fuel]/[max_fuel]")
	. += span_notice("Refilling: [refilling ? "ACTIVE" : "INACTIVE"]")
	. += span_notice("Place factory materials nearby and Alt-click to toggle automatic refilling.")
	. += span_notice("Consumes up to [resource_cost] materials per cycle.")

/obj/machinery/rce_fuel_storage/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return

	refilling = !refilling
	to_chat(user, span_notice("You [refilling ? "enable" : "disable"] automatic refilling."))
	update_icon()

/obj/machinery/rce_fuel_storage/update_icon_state()
	if(refilling)
		icon_state = "circ-off-1"
	else
		icon_state = "circ-off-0"

/obj/machinery/rce_fuel_storage/attackby(obj/item/I, mob/user, params)
	// Refill fuel tanks
	if(istype(I, /obj/item/fuel_tank_backpack))
		var/obj/item/fuel_tank_backpack/tank = I
		RefillTank(tank, user)
		return

	if(istype(I, /obj/item/acid_tank_backpack))
		var/obj/item/acid_tank_backpack/tank = I
		RefillAcidTank(tank, user)
		return

	if(istype(I, /obj/item/capacitor_pack))
		var/obj/item/capacitor_pack/pack = I
		RefillCapacitor(pack, user)
		return

	if(istype(I, /obj/item/rce_fuel_canister))
		var/obj/item/rce_fuel_canister/canister = I
		RefillCanister(canister, user)
		return

	return ..()

/obj/machinery/rce_fuel_storage/proc/RefillTank(obj/item/fuel_tank_backpack/tank, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/fuel_needed = tank.max_fuel - tank.fuel_amount
	if(fuel_needed <= 0)
		to_chat(user, span_notice("[tank] is already full."))
		return

	user.visible_message(span_notice("[user] begins refilling [tank]..."))

	if(do_after(user, 5 SECONDS, src))
		var/fuel_transferred = min(fuel_needed, current_fuel)
		tank.fuel_amount += fuel_transferred
		current_fuel -= fuel_transferred
		to_chat(user, span_notice("You refill [tank]. ([fuel_transferred] fuel transferred)"))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
		update_icon()

/obj/machinery/rce_fuel_storage/proc/RefillAcidTank(obj/item/acid_tank_backpack/tank, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/acid_needed = tank.max_acid - tank.current_acid
	if(acid_needed <= 0)
		to_chat(user, span_notice("[tank] is already full."))
		return

	user.visible_message(span_notice("[user] begins refilling [tank]..."))

	if(do_after(user, 5 SECONDS, src))
		var/acid_transferred = min(acid_needed, current_fuel)
		tank.current_acid += acid_transferred
		current_fuel -= acid_transferred
		to_chat(user, span_notice("You refill [tank]. ([acid_transferred] acid transferred)"))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
		update_icon()

/obj/machinery/rce_fuel_storage/proc/RefillCapacitor(obj/item/capacitor_pack/pack, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/charge_needed = pack.max_charge - pack.current_charge
	if(charge_needed <= 0)
		to_chat(user, span_notice("[pack] is already fully charged."))
		return

	user.visible_message(span_notice("[user] begins recharging [pack]..."))

	if(do_after(user, 5 SECONDS, src))
		var/charge_transferred = min(charge_needed, current_fuel)
		pack.current_charge += charge_transferred
		current_fuel -= charge_transferred
		to_chat(user, span_notice("You recharge [pack]. ([charge_transferred] charge transferred)"))
		playsound(src, 'sound/weapons/emitter2.ogg', 50, TRUE)
		update_icon()

/obj/machinery/rce_fuel_storage/proc/RefillCanister(obj/item/rce_fuel_canister/canister, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/fuel_needed = canister.max_fuel - canister.current_fuel
	if(fuel_needed <= 0)
		to_chat(user, span_notice("[canister] is already full."))
		return

	user.visible_message(span_notice("[user] begins filling [canister]..."))

	if(do_after(user, 3 SECONDS, src))
		var/fuel_transferred = min(fuel_needed, current_fuel, 100) // Canisters fill quickly but hold less
		canister.current_fuel += fuel_transferred
		current_fuel -= fuel_transferred
		to_chat(user, span_notice("You fill [canister]. ([fuel_transferred] fuel transferred)"))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
		update_icon()

// PORTABLE FUEL CANISTER FOR RAVENS
/obj/item/rce_fuel_canister
	name = "R-Corp fuel canister"
	desc = "A portable fuel canister used by Ravens to refuel specialists in the field."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "fuel"
	w_class = WEIGHT_CLASS_NORMAL
	var/max_fuel = 100
	var/current_fuel = 100

/obj/item/rce_fuel_canister/examine(mob/user)
	. = ..()
	. += span_notice("Fuel level: [current_fuel]/[max_fuel]")

/obj/item/rce_fuel_canister/afterattack(atom/target, mob/user, proximity_flag, params)
	if(!proximity_flag)
		return

	// Check if user is a Raven
	if(!istype(user.mind?.assigned_role, /datum/job/raven) && !istype(user.mind?.assigned_role, /datum/job/raven_messenger))
		to_chat(user, span_warning("Only Ravens are trained in field refueling procedures!"))
		return

	// Refuel fuel tanks
	if(ishuman(target))
		var/mob/living/carbon/human/H = target

		// Try to find a fuel tank
		var/obj/item/fuel_tank = locate(/obj/item/fuel_tank_backpack) in H.contents
		if(!fuel_tank)
			fuel_tank = locate(/obj/item/acid_tank_backpack) in H.contents
		if(!fuel_tank)
			fuel_tank = locate(/obj/item/capacitor_pack) in H.contents

		if(!fuel_tank)
			to_chat(user, span_warning("[H] doesn't have a fuel tank!"))
			return

		RefuelTarget(fuel_tank, H, user)

/obj/item/rce_fuel_canister/proc/RefuelTarget(obj/item/tank, mob/living/carbon/human/target, mob/user)
	if(current_fuel <= 0)
		to_chat(user, span_warning("[src] is empty!"))
		return

	var/fuel_needed = 0

	if(istype(tank, /obj/item/fuel_tank_backpack))
		var/obj/item/fuel_tank_backpack/T = tank
		fuel_needed = T.max_fuel - T.fuel_amount
	else if(istype(tank, /obj/item/acid_tank_backpack))
		var/obj/item/acid_tank_backpack/T = tank
		fuel_needed = T.max_acid - T.current_acid
	else if(istype(tank, /obj/item/capacitor_pack))
		var/obj/item/capacitor_pack/T = tank
		fuel_needed = T.max_charge - T.current_charge

	if(fuel_needed <= 0)
		to_chat(user, span_notice("[target]'s tank is already full."))
		return

	user.visible_message(span_notice("[user] begins refueling [target]'s tank..."))

	if(do_after(user, 10 SECONDS, target)) // Takes longer in the field
		var/fuel_transferred = min(fuel_needed, current_fuel)

		if(istype(tank, /obj/item/fuel_tank_backpack))
			var/obj/item/fuel_tank_backpack/T = tank
			T.fuel_amount += fuel_transferred
		else if(istype(tank, /obj/item/acid_tank_backpack))
			var/obj/item/acid_tank_backpack/T = tank
			T.current_acid += fuel_transferred
		else if(istype(tank, /obj/item/capacitor_pack))
			var/obj/item/capacitor_pack/T = tank
			T.current_charge += fuel_transferred

		current_fuel -= fuel_transferred
		to_chat(user, span_notice("You refuel [target]'s tank. ([fuel_transferred] fuel transferred)"))
		to_chat(target, span_nicegreen("[user] refuels your tank!"))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)

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

	// Check for fuel tanks
	var/has_tank = FALSE
	if(locate(/obj/item/fuel_tank_backpack) in H.contents)
		has_tank = TRUE
	else if(locate(/obj/item/acid_tank_backpack) in H.contents)
		has_tank = TRUE
	else if(locate(/obj/item/capacitor_pack) in H.contents)
		has_tank = TRUE

	if(has_tank)
		H.add_movespeed_modifier(/datum/movespeed_modifier/fuel_tank)
	else
		H.remove_movespeed_modifier(/datum/movespeed_modifier/fuel_tank)

/datum/movespeed_modifier/fuel_tank
	multiplicative_slowdown = 2

// Apply component to all fuel tanks on equip
/obj/item/fuel_tank_backpack/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		user.AddComponent(/datum/component/fuel_slowdown)

/obj/item/fuel_tank_backpack/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		var/datum/component/fuel_slowdown/C = user.GetComponent(/datum/component/fuel_slowdown)
		if(C)
			C.CheckFuelTank(user)

/obj/item/acid_tank_backpack/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		user.AddComponent(/datum/component/fuel_slowdown)

/obj/item/acid_tank_backpack/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		var/datum/component/fuel_slowdown/C = user.GetComponent(/datum/component/fuel_slowdown)
		if(C)
			C.CheckFuelTank(user)

/obj/item/capacitor_pack/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		user.AddComponent(/datum/component/fuel_slowdown)

/obj/item/capacitor_pack/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		var/datum/component/fuel_slowdown/C = user.GetComponent(/datum/component/fuel_slowdown)
		if(C)
			C.CheckFuelTank(user)

// FUEL STATION (smaller refueling point)
/obj/structure/fuel_station
	name = "fuel refilling station"
	desc = "A smaller fuel station connected to the main storage tank. Used for quick refills."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "holdingTank"
	density = TRUE
	anchored = TRUE
	var/refill_time = 3 SECONDS

/obj/structure/fuel_station/attackby(obj/item/I, mob/user, params)
	// Find main fuel storage
	var/obj/machinery/rce_fuel_storage/main_storage
	for(var/obj/machinery/rce_fuel_storage/storage in GLOB.machines)
		if(get_dist(src, storage) <= 20) // Must be reasonably close
			main_storage = storage
			break

	if(!main_storage)
		to_chat(user, span_warning("No fuel storage tank in range!"))
		return

	if(istype(I, /obj/item/fuel_tank_backpack))
		var/obj/item/fuel_tank_backpack/tank = I
		if(main_storage.current_fuel <= 0)
			to_chat(user, span_warning("The main fuel storage is empty!"))
			return

		var/fuel_needed = tank.max_fuel - tank.fuel_amount
		if(fuel_needed <= 0)
			to_chat(user, span_notice("[tank] is already full."))
			return

		user.visible_message(span_notice("[user] begins refilling [tank]..."))
		if(do_after(user, refill_time, src))
			var/fuel_transferred = min(fuel_needed, main_storage.current_fuel)
			tank.fuel_amount += fuel_transferred
			main_storage.current_fuel -= fuel_transferred
			to_chat(user, span_notice("You refill [tank]."))
			playsound(src, 'sound/effects/refill.ogg', 50, TRUE)

	// Similar for other tank types...
	else if(istype(I, /obj/item/acid_tank_backpack))
		var/obj/item/acid_tank_backpack/tank = I
		if(main_storage.current_fuel <= 0)
			to_chat(user, span_warning("The main fuel storage is empty!"))
			return

		var/acid_needed = tank.max_acid - tank.current_acid
		if(acid_needed <= 0)
			to_chat(user, span_notice("[tank] is already full."))
			return

		user.visible_message(span_notice("[user] begins refilling [tank]..."))
		if(do_after(user, refill_time, src))
			var/acid_transferred = min(acid_needed, main_storage.current_fuel)
			tank.current_acid += acid_transferred
			main_storage.current_fuel -= acid_transferred
			to_chat(user, span_notice("You refill [tank]."))
			playsound(src, 'sound/effects/refill.ogg', 50, TRUE)

	else if(istype(I, /obj/item/capacitor_pack))
		var/obj/item/capacitor_pack/pack = I
		if(main_storage.current_fuel <= 0)
			to_chat(user, span_warning("The main fuel storage is empty!"))
			return

		var/charge_needed = pack.max_charge - pack.current_charge
		if(charge_needed <= 0)
			to_chat(user, span_notice("[pack] is already fully charged."))
			return

		user.visible_message(span_notice("[user] begins recharging [pack]..."))
		if(do_after(user, refill_time, src))
			var/charge_transferred = min(charge_needed, main_storage.current_fuel)
			pack.current_charge += charge_transferred
			main_storage.current_fuel -= charge_transferred
			to_chat(user, span_notice("You recharge [pack]."))
			playsound(src, 'sound/weapons/emitter2.ogg', 50, TRUE)
