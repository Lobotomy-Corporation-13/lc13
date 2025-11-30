dm
// Storm Rams - Electric/Mobility Weapon Systems
// Rush-in burst damage specialists with escape mechanics

// Helper proc to check if user is a Storm Ram
/proc/is_storm_ram(mob/living/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	if(H.has_status_effect(/datum/status_effect/specialist_class))
		var/datum/status_effect/specialist_class/SC = H.has_status_effect(/datum/status_effect/specialist_class)
		if(SC.specialist_type == SPECIALIST_STORM)
			return TRUE
	return FALSE

// Capacitor Pack - Core resource for electric weapons
/obj/item/capacitor_pack
	name = "storm capacitor pack"
	desc = "A high-capacity energy storage system that powers Storm Ram burst attacks. Can be recharged at power stations."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "waterbackpackjank"
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	var/max_charge = 1000  // Large reserve for multiple bursts
	var/current_charge = 1000
	var/speed_boost_active = FALSE
	var/obj/item/ego_weapon/linked_weapon // For weapon connection

/obj/item/capacitor_pack/proc/use_charge(amount)
	if(current_charge >= amount)
		current_charge -= amount
		return TRUE
	return FALSE

/obj/item/capacitor_pack/dropped(mob/user)
	. = ..()
	if(linked_weapon)
		to_chat(user, span_warning("The weapon's power cable disconnects!"))
		linked_weapon = null
	if(speed_boost_active)
		remove_speed_boost(user)

/obj/item/capacitor_pack/attackby(obj/item/I, mob/user, params)
	// Transfer from another capacitor pack
	if(istype(I, /obj/item/capacitor_pack))
		var/obj/item/capacitor_pack/other_pack = I
		if(other_pack.current_charge <= 0)
			to_chat(user, span_warning("[other_pack] is depleted!"))
			return
		if(current_charge >= max_charge)
			to_chat(user, span_warning("[src] is already fully charged!"))
			return
		var/transfer_amount = min(other_pack.current_charge, max_charge - current_charge)
		current_charge += transfer_amount
		other_pack.current_charge -= transfer_amount
		to_chat(user, span_notice("You transfer [transfer_amount] units of charge from [other_pack] to [src]."))
		playsound(src, 'sound/magic/lightningshock.ogg', 30, TRUE)
		return
	// Portable power cell for Ravens
	if(istype(I, /obj/item/power_cell))
		var/obj/item/power_cell/cell = I
		if(cell.charge_amount <= 0)
			to_chat(user, span_warning("[cell] is depleted!"))
			return
		if(current_charge >= max_charge)
			to_chat(user, span_warning("[src] is already fully charged!"))
			return
		var/transfer_amount = min(cell.charge_amount, max_charge - current_charge)
		current_charge += transfer_amount
		cell.charge_amount -= transfer_amount
		to_chat(user, span_notice("You recharge [src] with [transfer_amount] units from [cell]."))
		playsound(src, 'sound/magic/lightningshock.ogg', 30, TRUE)
		return
	return ..()

/obj/item/capacitor_pack/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return

	// Recharge from power stations
	if(istype(target, /obj/structure/power_station))
		if(current_charge >= max_charge)
			to_chat(user, span_warning("[src] is already fully charged!"))
			return
		var/obj/structure/power_station/station = target
		if(station.power_stored <= 0)
			to_chat(user, span_warning("[station] is out of power!"))
			return
		var/charge_needed = max_charge - current_charge
		var/charge_to_transfer = min(charge_needed, station.power_stored, 200)  // Max 200 per recharge
		station.power_stored -= charge_to_transfer
		current_charge += charge_to_transfer
		user.visible_message(span_notice("[user] recharges [src] from [station]."), span_notice("You recharge [src] from [station]. ([current_charge]/[max_charge])"))
		playsound(src, 'sound/magic/lightningshock.ogg', 50, TRUE)
		do_sparks(2, TRUE, target)
		return

/obj/item/capacitor_pack/examine(mob/user)
	. = ..()
	. += span_notice("Charge level: [current_charge]/[max_charge]")
	if(current_charge < 200)
		. += span_warning("Low charge! Find a power station to recharge.")
	if(speed_boost_active)
		. += span_nicegreen("Speed boost active!")

// Grant speed boost after heavy attacks
/obj/item/capacitor_pack/proc/grant_speed_boost(mob/living/user, duration = 30)
	if(speed_boost_active)
		return
	speed_boost_active = TRUE
	user.add_movespeed_modifier(/datum/movespeed_modifier/storm_escape)
	addtimer(CALLBACK(src, PROC_REF(remove_speed_boost), user), duration)
	to_chat(user, span_nicegreen("Capacitor surge grants you enhanced speed!"))

/obj/item/capacitor_pack/proc/remove_speed_boost(mob/living/user)
	speed_boost_active = FALSE
	user.remove_movespeed_modifier(/datum/movespeed_modifier/storm_escape)

/datum/movespeed_modifier/storm_escape
	multiplicative_slowdown = -2 // Speed boost for escape

// Power Station Structure (placed at base)
/obj/structure/power_station
	name = "power station"
	desc = "A high-voltage charging station for recharging R-Corp capacitor packs."
	icon = 'icons/obj/power.dmi'
	icon_state = "smes"
	density = TRUE
	anchored = TRUE
	var/power_stored = 10000
	var/max_power = 10000

/obj/structure/power_station/examine(mob/user)
	. = ..()
	. += span_notice("Power reserves: [power_stored]/[max_power]")
	. += span_nicegreen("Use a capacitor pack on this to recharge.")

// Portable Power Cell (for Ravens)
/obj/item/power_cell
	name = "portable power cell"
	desc = "A compact high-voltage battery for field recharging. Used by Ravens to support Storm Ram specialists."
	icon = 'icons/obj/power.dmi'
	icon_state = "cell"
	w_class = WEIGHT_CLASS_NORMAL
	var/charge_amount = 200
	var/max_charge = 200

/obj/item/power_cell/examine(mob/user)
	. = ..()
	. += span_notice("Charge: [charge_amount]/[max_charge]")
	if(charge_amount > 0)
		. += span_nicegreen("Use on a capacitor pack to transfer charge.")

// Base electric weapon class
/obj/item/ego_weapon/electric_base
	name = "electric weapon"
	desc = "A weapon that uses electrical charge."
	var/electric_charge_cost = 10
	var/obj/item/capacitor_pack/linked_pack

/obj/item/ego_weapon/electric_base/proc/find_capacitor_pack(mob/living/user)
	if(!linked_pack || !user.is_holding(src))
		linked_pack = locate(/obj/item/capacitor_pack) in user.contents
	return linked_pack

/obj/item/ego_weapon/electric_base/proc/use_charge(mob/living/user, amount)
	var/obj/item/capacitor_pack/pack = find_capacitor_pack(user)
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to use this weapon!"))
		return FALSE
	if(!pack.use_charge(amount))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[amount] needed)"))
		return FALSE
	return TRUE

// TIER 1 WEAPONS

// Thunder Gauntlets - Basic rush weapon
/obj/item/ego_weapon/thunder_gauntlets
	name = "R-Corp thunder gauntlets"
	desc = "Electrified gauntlets that deliver devastating punches. Right-click to perform a short dash attack."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "powerfist"
	force = 35  // Higher base damage for melee focus
	attack_verb_continuous = list("thunders", "slams", "electrocutes")
	attack_verb_simple = list("thunder", "slam", "electrocute")
	hitsound = 'sound/weapons/punch3.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 140,  // Storm Ram has +100 Fort
		JUSTICE_ATTRIBUTE = 80   // Storm Ram has +40 Justice
	)
	var/electric_charge_cost = 10
	var/dash_cost = 20
	var/stun_duration = 15
	var/dash_range = 4
	var/dash_cooldown = 0
	var/dash_cooldown_time = 30  // 3 seconds

/obj/item/ego_weapon/thunder_gauntlets/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this weapon!"))
		return FALSE

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to power this weapon!"))
		return FALSE

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[electric_charge_cost] needed)"))
		return FALSE

	. = ..()
	if(.)
		// Apply stun and AoE damage
		target.Paralyze(stun_duration)
		playsound(src, 'sound/magic/lightningshock.ogg', 50, TRUE)
		new /obj/effect/temp_visual/lightning_strike(get_turf(target))

		// AoE thunder damage
		for(var/mob/living/L in range(1, target))
			if(L == user || L == target)
				continue
			L.deal_damage(20, FIRE)
			L.Paralyze(10)
			do_sparks(2, TRUE, L)

/obj/item/ego_weapon/thunder_gauntlets/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(proximity_flag) // Normal melee attack
		return

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this weapon!"))
		return

	if(dash_cooldown > world.time)
		to_chat(user, span_warning("Dash is still recharging! ([round((dash_cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to dash!"))
		return

	if(!pack.use_charge(dash_cost))
		to_chat(user, span_warning("Not enough charge for dash! ([pack.current_charge]/[dash_cost] needed)"))
		return

	// Perform thunder dash
	thunder_dash(target, user, pack)

/obj/item/ego_weapon/thunder_gauntlets/proc/thunder_dash(atom/target, mob/living/user, obj/item/capacitor_pack/pack)
	dash_cooldown = world.time + dash_cooldown_time
	var/turf/T = get_turf(target)
	var/turf/starting = get_turf(user)

	user.visible_message(span_danger("[user] charges forward with thunderous force!"))
	playsound(src, 'sound/magic/lightningshock.ogg', 75, TRUE)

	// Dash through enemies
	var/list/dash_path = getline(starting, T)
	var/distance = 0

	for(var/turf/dash_turf in dash_path)
		if(distance >= dash_range)
			break
		if(dash_turf.density)
			break
		distance++

		user.forceMove(dash_turf)
		new /obj/effect/temp_visual/electric_trail(dash_turf)

		// Damage enemies in path
		for(var/mob/living/L in dash_turf)
			if(L == user)
				continue
			L.deal_damage(30, BRUTE)
			L.deal_damage(15, FIRE)
			L.Paralyze(20)
			do_sparks(3, TRUE, L)

	// Grant escape speed boost
	pack.grant_speed_boost(user, 20)

// Storm Dash - Rush through enemies with chain damage
/obj/item/storm_dash
	name = "R-Corp storm dash module"
	desc = "Electromagnetic propulsion system that launches you through enemies, dealing chain damage. Click to activate dash."
	icon = 'icons/obj/device.dmi'
	icon_state = "powercell"
	w_class = WEIGHT_CLASS_SMALL
	var/electric_charge_cost = 25
	var/dash_range = 6
	var/dash_damage = 40
	var/chain_damage = 20
	var/cooldown = 0
	var/cooldown_time = 50  // 5 seconds

/obj/item/storm_dash/attack_self(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this device!"))
		return

	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to power this device!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[electric_charge_cost] needed)"))
		return

	// Get direction for dash
	var/turf/T = get_step(user, user.dir)
	if(!T)
		return

	storm_dash_attack(T, user, pack)

/obj/item/storm_dash/proc/storm_dash_attack(turf/target, mob/living/user, obj/item/capacitor_pack/pack)
	cooldown = world.time + cooldown_time
	var/turf/starting = get_turf(user)

	user.visible_message(span_danger("[user] transforms into living lightning!"))
	playsound(src, 'sound/magic/lightningbolt.ogg', 75, TRUE)

	// Create afterimage
	var/obj/effect/temp_visual/decoy/D = new(starting, user)
	animate(D, alpha = 0, time = 5)

	// Dash forward
	var/list/hit_mobs = list()
	for(var/i = 1 to dash_range)
		var/turf/dash_turf = get_step(user, user.dir)
		if(!dash_turf || dash_turf.density)
			break

		user.forceMove(dash_turf)
		new /obj/effect/temp_visual/electric_trail(dash_turf)

		// Damage and chain to nearby enemies
		for(var/mob/living/L in dash_turf)
			if(L == user || (L in hit_mobs))
				continue
			hit_mobs += L
			L.deal_damage(dash_damage, BRUTE)
			L.Paralyze(15)
			new /obj/effect/temp_visual/lightning_strike(get_turf(L))

			// Chain to nearby enemies
			for(var/mob/living/chain in range(2, L))
				if(chain == user || chain == L || (chain in hit_mobs))
					continue
				hit_mobs += chain
				chain.deal_damage(chain_damage, FIRE)
				L.Beam(chain, "lightning", time = 3)

	// Grant escape speed
	pack.grant_speed_boost(user, 30)

// Static Burst Generator - Deploy before rush
/obj/item/static_burst_generator
	name = "static burst generator"
	desc = "Creates an electric field that detonates when you pass through it, damaging all nearby enemies."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-blue"
	w_class = WEIGHT_CLASS_SMALL
	var/electric_charge_cost = 20
	var/field_duration = 100  // Shorter duration, meant for setup
	var/cooldown = 0
	var/cooldown_time = 80  // Faster cooldown for rush tactics

/obj/item/static_burst_generator/attack_self(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this device!"))
		return
	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to power this device!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[electric_charge_cost] needed)"))
		return

	// Deploy static burst field
	var/turf/T = get_turf(user)
	var/obj/effect/static_burst_field/field = new(T, field_duration)
	field.owner = user

	cooldown = world.time + cooldown_time
	playsound(src, 'sound/magic/lightningshock.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] deploys a static burst field!"))

/obj/effect/static_burst_field
	name = "static burst field"
	desc = "A crackling field of electricity that will detonate when its owner passes through."
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity"
	density = FALSE
	opacity = FALSE
	anchored = TRUE
	var/burst_damage = 40
	var/burst_range = 3
	var/mob/living/owner
	var/triggered = FALSE

/obj/effect/static_burst_field/Initialize(mapload, duration)
	. = ..()
	START_PROCESSING(SSobj, src)
	QDEL_IN(src, duration)
	animate(src, alpha = 100, time = 5, loop = -1, easing = SINE_EASING)
	animate(alpha = 255, time = 5, easing = SINE_EASING)

/obj/effect/static_burst_field/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/static_burst_field/process()
	if(triggered)
		return

	// Check if owner passes through
	if(owner && get_turf(owner) == get_turf(src))
		trigger_burst()
		return

	// Deal minor damage to enemies standing in it
	for(var/mob/living/L in get_turf(src))
		if(L == owner)
			continue
		L.deal_damage(5, FIRE)
		if(prob(20))
			do_sparks(1, TRUE, L)

/obj/effect/static_burst_field/proc/trigger_burst()
	triggered = TRUE
	visible_message(span_danger("[src] detonates in a burst of electricity!"))
	playsound(src, 'sound/magic/lightningbolt.ogg', 100, TRUE)

	// Create visual explosion
	new /obj/effect/temp_visual/lightning_strike(get_turf(src))

	// Damage all enemies in range
	for(var/mob/living/L in range(burst_range, src))
		if(L == owner)
			continue
		var/distance = get_dist(src, L)
		var/damage = burst_damage * (1 - (distance / (burst_range + 1)))
		L.deal_damage(damage, FIRE)
		L.Paralyze(20)
		do_sparks(3, TRUE, L)
		var/turf/source_turf = get_turf(src)
		source_turf.Beam(L, "lightning", time = 5)

	qdel(src)


// TIER 2 WEAPONS

// Lightning Ram - Massive charge attack
/obj/item/ego_weapon/lightning_ram
	name = "R-Corp lightning ram"
	desc = "Electromagnetic battering ram that delivers devastating charge attacks. Click distant target to charge."
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "thunder_hammer"
	force = 50
	attack_verb_continuous = list("rams", "crashes", "thunders")
	attack_verb_simple = list("ram", "crash", "thunder")
	hitsound = 'sound/weapons/resonator_blast.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 160,  // Storm Ram stats
		JUSTICE_ATTRIBUTE = 80
	)
	var/electric_charge_cost = 40
	var/charge_range = 8
	var/charge_damage = 80
	var/charge_cooldown = 0
	var/charge_cooldown_time = 80  // 8 seconds

/obj/item/ego_weapon/lightning_ram/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can wield this weapon!"))
		return FALSE

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return FALSE

	if(!pack.use_charge(15))  // Normal attack cost
		to_chat(user, span_warning("Not enough charge!"))
		return FALSE

	. = ..()
	if(.)
		// Knockback on hit
		var/atom/throw_target = get_edge_target_turf(target, get_dir(user, target))
		target.throw_at(throw_target, 3, 2)
		playsound(src, 'sound/magic/lightningshock.ogg', 75, TRUE)

/obj/item/ego_weapon/lightning_ram/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(proximity_flag) // Normal melee
		return

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this weapon!"))
		return

	if(charge_cooldown > world.time)
		to_chat(user, span_warning("Ram charge still building! ([round((charge_cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[electric_charge_cost] needed)"))
		return

	// Perform devastating charge
	lightning_charge(target, user, pack)

/obj/item/ego_weapon/lightning_ram/proc/lightning_charge(atom/target, mob/living/user, obj/item/capacitor_pack/pack)
	charge_cooldown = world.time + charge_cooldown_time
	var/turf/T = get_turf(target)
	var/turf/starting = get_turf(user)

	// Charge up
	user.visible_message(span_danger("[user] charges up [src] with crackling energy!"))
	playsound(src, 'sound/magic/lightning_chargeup.ogg', 100, TRUE)
	new /obj/effect/temp_visual/electric_charge(starting)

	// Brief windup
	user.Immobilize(5)
	sleep(5)

	// CHARGE!
	user.visible_message(span_boldannounce("[user] CHARGES FORWARD WITH THUNDEROUS FORCE!"))
	playsound(src, 'sound/weapons/marauder.ogg', 125, TRUE)

	var/list/hit_mobs = list()
	var/list/charge_path = getline(starting, T)
	var/distance = 0

	for(var/turf/charge_turf in charge_path)
		if(distance >= charge_range)
			break
		if(charge_turf.density)
			// Can't pass through walls (dense turfs)
			break
		distance++

		// Pass through structures without damaging them
		user.forceMove(charge_turf)
		new /obj/effect/temp_visual/electric_trail(charge_turf)
		new /obj/effect/temp_visual/kinetic_blast(charge_turf)

		// Devastate everything in path
		for(var/mob/living/L in range(1, charge_turf))  // Wider hit area
			if(L == user || (L in hit_mobs))
				continue
			hit_mobs += L
			L.deal_damage(charge_damage, BRUTE)
			L.deal_damage(30, FIRE)
			var/atom/throw_target = get_edge_target_turf(L, get_dir(starting, charge_turf))
			L.throw_at(throw_target, 5, 3)
			new /obj/effect/temp_visual/lightning_strike(get_turf(L))

	// Knockback at end creates space for escape
	for(var/mob/living/L in range(2, user))
		if(L == user)
			continue
		var/atom/throw_target = get_edge_target_turf(L, get_dir(user, L))
		L.throw_at(throw_target, 4, 2)

	// Grant extended escape speed
	pack.grant_speed_boost(user, 40)

// Thunderclap Gauntlets - AoE burst with escape
/obj/item/ego_weapon/thunderclap_gauntlets
	name = "R-Corp thunderclap gauntlets"
	desc = "Gauntlets that create devastating thunder bursts. Right-click to perform area burst with automatic retreat."
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "thunder_fist"
	force = 45
	attack_verb_continuous = list("thunders", "slams", "devastates")
	attack_verb_simple = list("thunder", "slam", "devastate")
	hitsound = 'sound/weapons/punch3.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 150,
		JUSTICE_ATTRIBUTE = 90
	)
	var/electric_charge_cost = 30
	var/burst_cost = 50
	var/burst_damage = 60
	var/burst_range = 3
	var/burst_cooldown = 0
	var/burst_cooldown_time = 60  // 6 seconds

/obj/item/ego_weapon/thunderclap_gauntlets/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use these gauntlets!"))
		return FALSE

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return FALSE

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge!"))
		return FALSE

	. = ..()
	if(.)
		// Normal attack creates small AoE
		for(var/mob/living/L in range(1, target))
			if(L == user || L == target)
				continue
			L.deal_damage(25, FIRE)
			do_sparks(2, TRUE, L)

/obj/item/ego_weapon/thunderclap_gauntlets/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(proximity_flag) // Normal attack
		return

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use these gauntlets!"))
		return

	if(burst_cooldown > world.time)
		to_chat(user, span_warning("Thunderclap still charging! ([round((burst_cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(burst_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[burst_cost] needed)"))
		return

	// Perform thunderclap burst
	thunderclap_burst(target, user, pack)

/obj/item/ego_weapon/thunderclap_gauntlets/proc/thunderclap_burst(atom/target, mob/living/user, obj/item/capacitor_pack/pack)
	burst_cooldown = world.time + burst_cooldown_time
	var/turf/T = get_turf(target)
	var/turf/starting = get_turf(user)

	// Dash to target
	user.visible_message(span_danger("[user] charges with thunderous power!"))
	playsound(src, 'sound/magic/lightning_chargeup.ogg', 75, TRUE)

	var/list/dash_path = getline(starting, T)
	var/turf/destination
	for(var/turf/dash_turf in dash_path)
		if(get_dist(starting, dash_turf) > 5)
			break
		if(dash_turf.density)
			break
		destination = dash_turf
		user.forceMove(dash_turf)
		new /obj/effect/temp_visual/electric_trail(dash_turf)

	// THUNDERCLAP!
	user.visible_message(span_boldannounce("[user] creates a THUNDERCLAP!"))
	playsound(src, 'sound/magic/lightningbolt.ogg', 125, TRUE)

	// Create massive AoE burst
	for(var/mob/living/L in range(burst_range, user))
		if(L == user)
			continue
		var/distance = get_dist(user, L)
		var/damage = burst_damage * (1 - (distance / (burst_range + 1)))
		L.deal_damage(damage, BRUTE)
		L.deal_damage(20, FIRE)
		L.Paralyze(25)
		var/atom/throw_target = get_edge_target_turf(L, get_dir(user, L))
		L.throw_at(throw_target, burst_range + 1 - distance, 2)
		new /obj/effect/temp_visual/lightning_strike(get_turf(L))

	// Auto-retreat dash
	var/turf/retreat_target = get_step(starting, turn(get_dir(starting, destination), 180))
	for(var/i = 1 to 3)
		retreat_target = get_step(retreat_target, turn(get_dir(starting, destination), 180))

	user.visible_message(span_notice("[user] dashes back to safety!"))
	var/list/retreat_path = getline(user.loc, retreat_target)
	for(var/turf/retreat_turf in retreat_path)
		if(retreat_turf.density)
			break
		user.forceMove(retreat_turf)
		new /obj/effect/temp_visual/electric_trail(retreat_turf)

	// Extended escape speed
	pack.grant_speed_boost(user, 50)

// EMP Grenade
/obj/item/grenade/r_corp/emp
	name = "R-Corp EMP grenade"
	desc = "Releases an electromagnetic pulse that disables machinery and stuns organics."
	icon_state = "emp"
	var/emp_range = 3

/obj/item/grenade/r_corp/emp/detonate(mob/living/lanced_by)
	empulse(src, emp_range, emp_range * 2)

	// Also stun organics
	for(var/mob/living/L in range(emp_range, src))
		L.deal_damage(20, FIRE)
		L.Paralyze(30)
		to_chat(L, span_userdanger("The electromagnetic pulse overwhelms your nervous system!"))

	qdel(src)

// TIER 3 WEAPONS

// Railgun Charge - Ultimate rush attack
/obj/item/ego_weapon/railgun_charge
	name = "railgun charge module"
	desc = "The ultimate Storm Ram weapon - transforms you into a living railgun projectile. Devastating but requires recovery time."
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "thunder_lance"
	force = 70
	reach = 2
	attack_verb_continuous = list("obliterates", "pierces", "devastates")
	attack_verb_simple = list("obliterate", "pierce", "devastate")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 180,
		JUSTICE_ATTRIBUTE = 120
	)
	var/electric_charge_cost = 75
	var/charge_range = 12
	var/charge_damage = 120
	var/charge_cooldown = 0
	var/charge_cooldown_time = 150  // 15 seconds - ultimate ability

/obj/item/ego_weapon/railgun_charge/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this ultimate weapon!"))
		return FALSE

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return FALSE

	if(!pack.use_charge(20))  // Normal melee cost
		to_chat(user, span_warning("Not enough charge!"))
		return FALSE

	. = ..()
	if(.)
		// Piercing electric strike
		playsound(src, 'sound/magic/lightningshock.ogg', 75, TRUE)
		target.deal_damage(20, FIRE)  // Extra electric damage

/obj/item/ego_weapon/railgun_charge/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(proximity_flag)
		return

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can perform the railgun charge!"))
		return

	if(charge_cooldown > world.time)
		to_chat(user, span_warning("Railgun charge still building! ([round((charge_cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[electric_charge_cost] needed)"))
		return

	// Perform ultimate railgun charge
	railgun_ultimate(target, user, pack)

/obj/item/ego_weapon/railgun_charge/proc/railgun_ultimate(atom/target, mob/living/user, obj/item/capacitor_pack/pack)
	charge_cooldown = world.time + charge_cooldown_time
	var/turf/T = get_turf(target)
	var/turf/starting = get_turf(user)

	// Epic charge up
	user.visible_message(span_boldannounce("[user] begins charging the RAILGUN SYSTEM!"))
	playsound(src, 'sound/weapons/flash.ogg', 100, TRUE)
	new /obj/effect/temp_visual/electric_charge(starting)

	// Charge animation
	animate(user, transform = matrix() * 1.2, time = 10, easing = ELASTIC_EASING)
	user.Immobilize(10)
	sleep(10)
	animate(user, transform = null, time = 2)

	// BECOME THE RAILGUN
	user.visible_message(span_boldannounce("[user] BECOMES A LIVING RAILGUN PROJECTILE!"))
	playsound(src, 'sound/weapons/marauder.ogg', 150, TRUE)

	// User gains temporary invulnerability during charge
	user.status_flags |= GODMODE

	var/list/hit_mobs = list()
	var/list/charge_path = getline(starting, T)
	var/distance = 0

	for(var/turf/charge_turf in charge_path)
		if(distance >= charge_range)
			break
		if(charge_turf.density)
			// Can't pass through walls (dense turfs)
			break
		distance++

		// Pass through structures without damaging them
		user.forceMove(charge_turf)
		new /obj/effect/temp_visual/railgun_trail(charge_turf)
		new /obj/effect/temp_visual/kinetic_blast(charge_turf)

		// Devastate everything
		for(var/mob/living/L in range(2, charge_turf))  // Wider devastation
			if(L == user || (L in hit_mobs))
				continue
			hit_mobs += L
			var/dist_mod = max(0.5, 1 - (get_dist(charge_turf, L) / 3))
			L.deal_damage(charge_damage * dist_mod, BRUTE)
			L.deal_damage(50 * dist_mod, FIRE)
			var/atom/throw_target = get_edge_target_turf(L, get_dir(starting, charge_turf))
			L.throw_at(throw_target, 7, 4)
			new /obj/effect/temp_visual/lightning_strike(get_turf(L))

	// Remove invulnerability
	user.status_flags &= ~GODMODE

	// Recovery period - user is briefly stunned
	user.Paralyze(20)
	to_chat(user, span_warning("The railgun charge leaves you momentarily exhausted!"))

	// But then grant massive speed boost for escape
	addtimer(CALLBACK(src, PROC_REF(delayed_speed_boost), user, pack), 20)
	addtimer(CALLBACK(src, PROC_REF(recovery_message), user), 20)

/obj/item/ego_weapon/railgun_charge/proc/recovery_message(mob/user)
	to_chat(user, span_nicegreen("Energy surge propels you to safety!"))

/obj/item/ego_weapon/railgun_charge/proc/delayed_speed_boost(mob/user, obj/item/capacitor_pack/pack)
	if(pack && user)
		pack.grant_speed_boost(user, 60)

// Storm Surge Barrier - Mobile shield that damages on contact
/obj/item/storm_surge_barrier
	name = "storm surge barrier"
	desc = "Creates a mobile electromagnetic barrier that moves with you and damages enemies on contact."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-purple"
	w_class = WEIGHT_CLASS_NORMAL
	var/electric_charge_cost = 30
	var/barrier_duration = 80  // 8 seconds
	var/active = FALSE
	var/obj/effect/storm_surge/current_barrier

/obj/item/storm_surge_barrier/attack_self(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this device!"))
		return

	if(active)
		deactivate()
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to power the barrier!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[electric_charge_cost] needed)"))
		return

	activate(user, pack)

/obj/item/storm_surge_barrier/proc/activate(mob/user, obj/item/capacitor_pack/pack)
	active = TRUE
	current_barrier = new /obj/effect/storm_surge(user)
	current_barrier.generator = src
	current_barrier.follow_target = user
	user.visible_message(span_danger("[user] activates a storm surge barrier!"))
	playsound(src, 'sound/magic/lightningshock.ogg', 75, TRUE)

	// Auto-deactivate after duration
	addtimer(CALLBACK(src, PROC_REF(deactivate)), barrier_duration)

	// Grant speed boost while barrier is active
	pack.grant_speed_boost(user, barrier_duration)

/obj/item/storm_surge_barrier/proc/deactivate()
	active = FALSE
	if(current_barrier)
		qdel(current_barrier)
		current_barrier = null
	visible_message(span_notice("The storm surge dissipates."))

/obj/item/storm_surge_barrier/dropped(mob/user)
	. = ..()
	if(active)
		deactivate()

// Storm surge effect - Mobile barrier
/obj/effect/storm_surge
	name = "storm surge"
	desc = "A swirling vortex of electromagnetic energy."
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity"
	density = FALSE
	opacity = FALSE
	anchored = FALSE
	var/obj/item/storm_surge_barrier/generator
	var/mob/living/follow_target
	var/contact_damage = 30
	var/push_force = 3

/obj/effect/storm_surge/Initialize(mob/living/target)
	. = ..()
	follow_target = target
	color = "#4444FF"
	alpha = 150
	transform = matrix() * 1.5
	START_PROCESSING(SSobj, src)

	// Animated aura effect
	animate(src, transform = matrix() * 1.3, alpha = 100, time = 10, loop = -1, easing = SINE_EASING)
	animate(transform = matrix() * 1.5, alpha = 200, time = 10, easing = SINE_EASING)

/obj/effect/storm_surge/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(generator)
		generator.deactivate()
	return ..()

/obj/effect/storm_surge/process()
	if(!follow_target || QDELETED(follow_target))
		qdel(src)
		return

	// Follow the user
	forceMove(get_turf(follow_target))

	// Damage and push enemies on contact
	for(var/mob/living/L in range(1, src))
		if(L == follow_target)
			continue
		if(L.last_push_time && world.time - L.last_push_time < 10) // Prevent spam
			continue

		L.deal_damage(contact_damage, FIRE)
		var/atom/throw_target = get_edge_target_turf(L, get_dir(src, L))
		L.throw_at(throw_target, push_force, 2)
		L.last_push_time = world.time
		do_sparks(3, TRUE, L)
		to_chat(L, span_danger("The storm surge blasts you away!"))
		playsound(L, 'sound/magic/lightningshock.ogg', 50, TRUE)

	// Block some projectiles
	for(var/obj/projectile/P in range(1, src))
		if(prob(50))  // 50% chance to deflect
			var/new_angle = rand(0, 360)
			P.firer = null  // Remove firer to prevent friendly fire
			P.set_angle(new_angle)
			do_sparks(1, TRUE, P)

// Add variable for tracking push time
/mob/living
	var/last_push_time = 0

// Thunderstorm Slam - Ground pound creates electric field
/obj/item/thunderstorm_slam
	name = "thunderstorm slam module"
	desc = "Leap into the air and slam down, creating a devastating electric storm around you. The ultimate area denial."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-purple"
	w_class = WEIGHT_CLASS_NORMAL
	var/electric_charge_cost = 80
	var/slam_damage = 100
	var/storm_duration = 60  // 6 seconds
	var/cooldown = 0
	var/cooldown_time = 200  // 20 seconds

/obj/item/thunderstorm_slam/attack_self(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can perform the thunderstorm slam!"))
		return

	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/capacitor_pack/pack = locate(/obj/item/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.current_charge]/[electric_charge_cost] needed)"))
		return

	perform_thunderstorm_slam(user, pack)

/obj/item/thunderstorm_slam/proc/perform_thunderstorm_slam(mob/living/user, obj/item/capacitor_pack/pack)
	cooldown = world.time + cooldown_time
	var/turf/starting = get_turf(user)

	// Leap up
	user.visible_message(span_boldannounce("[user] LEAPS INTO THE AIR!"))
	playsound(src, 'sound/weapons/flash.ogg', 100, TRUE)
	animate(user, pixel_y = 32, time = 5, easing = SINE_EASING)
	user.density = FALSE  // Can't be hit while in air
	user.status_flags |= GODMODE
	sleep(5)

	// SLAM DOWN
	user.visible_message(span_boldannounce("[user] SLAMS DOWN WITH THE FORCE OF THUNDER!"))
	playsound(src, 'sound/effects/meteorimpact.ogg', 150, TRUE)
	animate(user, pixel_y = 0, time = 2)
	sleep(2)
	user.density = TRUE
	user.status_flags &= ~GODMODE

	// Create massive impact
	new /obj/effect/temp_visual/kinetic_blast(starting)
	for(var/i = 1 to 3)
		addtimer(CALLBACK(src, PROC_REF(expanding_shockwave), starting, i * 2), i * 2)

	// Initial impact damage
	for(var/mob/living/L in range(4, starting))
		if(L == user)
			continue
		var/distance = get_dist(starting, L)
		var/damage = slam_damage * (1 - (distance / 5))
		L.deal_damage(damage, BRUTE)
		L.Paralyze(30)
		var/atom/throw_target = get_edge_target_turf(L, get_dir(starting, L))
		L.throw_at(throw_target, 5 - distance, 3)
		new /obj/effect/temp_visual/lightning_strike(get_turf(L))

	// Create lingering storm field
	for(var/turf/T in range(3, starting))
		if(prob(60))
			var/obj/effect/thunderstorm_field/field = new(T)
			field.owner = user
			QDEL_IN(field, storm_duration)

	// Grant escape speed after slam
	pack.grant_speed_boost(user, 40)

/obj/item/thunderstorm_slam/proc/expanding_shockwave(turf/center, radius)
	for(var/turf/T in range(radius, center))
		if(get_dist(T, center) == radius)
			new /obj/effect/temp_visual/electric_trail(T)
			for(var/mob/living/L in T)
				if(L.has_status_effect(/datum/status_effect/specialist_class))
					var/datum/status_effect/specialist_class/SC = L.has_status_effect(/datum/status_effect/specialist_class)
					if(SC.specialist_type == SPECIALIST_STORM)
						continue
				L.deal_damage(20, FIRE)
				do_sparks(2, TRUE, L)

/obj/effect/thunderstorm_field
	name = "thunderstorm field"
	desc = "A lingering field of electrical energy."
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity"
	density = FALSE
	anchored = TRUE
	var/mob/living/owner

/obj/effect/thunderstorm_field/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	animate(src, alpha = 100, time = 10, loop = -1, easing = SINE_EASING)
	animate(alpha = 255, time = 10, easing = SINE_EASING)

/obj/effect/thunderstorm_field/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/thunderstorm_field/process()
	for(var/mob/living/L in get_turf(src))
		if(L == owner)
			continue
		L.deal_damage(10, FIRE)
		if(prob(30))
			L.Paralyze(5)
			do_sparks(1, TRUE, L)

// Visual effects
/obj/effect/temp_visual/electric_trail
	name = "electric trail"
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity"
	duration = 5

/obj/effect/temp_visual/electric_trail/Initialize()
	. = ..()
	alpha = 200
	animate(src, alpha = 0, time = duration)

/obj/effect/temp_visual/lightning_strike
	name = "lightning strike"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "lightning"
	pixel_x = -32
	pixel_y = -32
	duration = 10

/obj/effect/temp_visual/lightning_strike/Initialize()
	. = ..()
	transform = matrix() * 2

/obj/effect/temp_visual/electric_charge
	name = "electric charge"
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity"
	duration = 10

/obj/effect/temp_visual/electric_charge/Initialize()
	. = ..()
	animate(src, alpha = 255, transform = matrix() * 2, time = duration)

/obj/effect/temp_visual/railgun_trail
	name = "railgun trail"
	icon = 'icons/effects/effects.dmi'
	icon_state = "bluestream"
	duration = 10

/obj/effect/temp_visual/chain_lightning
	name = "chain lightning"
	icon = 'icons/effects/effects.dmi'
	icon_state = "lightning"
	duration = 3

/obj/effect/temp_visual/chain_lightning/proc/chain_to(atom/target)
	var/datum/beam/B = Beam(target, "lightning", time = duration)
	QDEL_IN(B, duration)
