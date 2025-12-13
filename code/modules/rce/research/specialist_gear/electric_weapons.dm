// Storm Rams - Electric/Mobility Weapon Systems
// Rush-in burst damage specialists with escape mechanics

// Helper proc to check if user is a Storm Ram (checks for implant directly)
/proc/is_storm_ram(mob/living/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/cyberimp/rce_specialist/storm/implant = locate() in H.internal_organs
	return !!implant

// TIER 1 WEAPONS

// Thunder Hammer - Basic rush weapon
/obj/item/ego_weapon/thunder_hammer
	name = "R-Corp thunder hammer"
	desc = "An electrified hammer that delivers devastating strikes. Use in hand to toggle power. Right-click to perform a short dash attack when powered on."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "hammeroff"
	force = 35  // Higher base damage for melee focus
	attack_verb_continuous = list("thunders", "slams", "smashes")
	attack_verb_simple = list("thunder", "slam", "smash")
	hitsound = 'sound/weapons/punch3.ogg'
	var/electric_charge_cost = 10
	var/dash_cost = 20
	var/dash_range = 4
	var/dash_cooldown = 0
	var/dash_cooldown_time = 30  // 3 seconds
	var/powered = FALSE  // Whether the hammer is powered on

// Toggle hammer on/off
/obj/item/ego_weapon/thunder_hammer/attack_self(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this weapon!"))
		return

	powered = !powered
	icon_state = powered ? "hammeron" : "hammeroff"

	if(powered)
		to_chat(user, span_notice("You activate [src]. The hammer crackles with electricity!"))
		playsound(src, 'sound/magic/lightningshock.ogg', 30, TRUE)
	else
		to_chat(user, span_notice("You deactivate [src]. The electricity fades."))

	update_appearance()

/obj/item/ego_weapon/thunder_hammer/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this weapon!"))
		return FALSE

	// Check if hammer is powered on for AoE effect
	if(powered)
		var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
		if(!pack)
			to_chat(user, span_warning("You need a capacitor pack to power this weapon!"))
			return FALSE

		if(!pack.use_charge(electric_charge_cost))
			to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[electric_charge_cost] needed)"))
			return FALSE

		// Perform attack with AoE
		. = ..()
		if(.)
			// Apply AoE damage
			playsound(src, 'sound/magic/lightningshock.ogg', 50, TRUE)
			new /obj/effect/temp_visual/lightning_strike(get_turf(target))

			// AoE thunder damage based on weapon force
			var/turf/target_turf = get_turf(target)
			for(var/mob/living/L in hearers(1, target_turf))
				if(L == user || ishuman(L))
					continue
				var/aoe = force
				var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
				var/justicemod = 1 + userjust / 100
				aoe *= justicemod
				aoe *= force_multiplier
				L.deal_damage(aoe, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE))
				new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(L))
	else
		// Basic attack without AoE when unpowered
		. = ..()

/obj/item/ego_weapon/thunder_hammer/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(proximity_flag) // Normal melee attack
		return

	if(!powered)
		to_chat(user, span_warning("The hammer must be powered on to dash!"))
		return

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this weapon!"))
		return

	if(dash_cooldown > world.time)
		to_chat(user, span_warning("Dash is still recharging! ([round((dash_cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to dash!"))
		return

	if(!pack.use_charge(dash_cost))
		to_chat(user, span_warning("Not enough charge for dash! ([pack.resource_amount]/[dash_cost] needed)"))
		return

	// Perform thunder dash
	thunder_dash(target, user, pack)

/obj/item/ego_weapon/thunder_hammer/proc/thunder_dash(atom/target, mob/living/user, obj/item/rce_resource_tank/capacitor_pack/pack)
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

	// Overcharge system automatically provides speed boost

// Storm Dash - Rush through enemies with chain damage
/obj/item/storm_dash
	name = "R-Corp storm dash module"
	desc = "Electromagnetic propulsion system that launches you through enemies, dealing chain damage. Equip to gain an action button to activate."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-blue"
	w_class = WEIGHT_CLASS_SMALL
	var/electric_charge_cost = 25
	var/dash_range = 6
	var/dash_damage = 40
	var/chain_damage = 20
	var/cooldown = 0
	var/cooldown_time = 50  // 5 seconds
	var/datum/action/item_action/storm_dash/dash_action

/obj/item/storm_dash/Initialize()
	. = ..()
	dash_action = new(src)

/obj/item/storm_dash/Destroy()
	QDEL_NULL(dash_action)
	return ..()

/obj/item/storm_dash/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		dash_action.Grant(user)
		to_chat(user, span_notice("[src] is ready. Use the action button to activate storm dash."))

/obj/item/storm_dash/dropped(mob/user)
	. = ..()
	if(dash_action)
		dash_action.Remove(user)

/obj/item/storm_dash/proc/activate(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this device!"))
		return

	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to power this device!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[electric_charge_cost] needed)"))
		return

	// Get direction for dash
	var/turf/T = get_step(user, user.dir)
	if(!T)
		return

	storm_dash_attack(T, user, pack)

/obj/item/storm_dash/proc/storm_dash_attack(turf/target, mob/living/user, obj/item/rce_resource_tank/capacitor_pack/pack)
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
			new /obj/effect/temp_visual/lightning_strike(get_turf(L))

			// Chain to nearby enemies
			for(var/mob/living/chain in range(2, L))
				if(chain == user || chain == L || (chain in hit_mobs))
					continue
				hit_mobs += chain
				chain.deal_damage(chain_damage, FIRE)
				L.Beam(chain, "lightning", time = 3)

	// Overcharge system automatically provides speed boost

// Static Burst Generator - Teleport back after delay
/obj/item/static_burst_generator
	name = "static burst recall"
	desc = "Marks your current location. After 8 seconds, teleports you back to the marked position. Equip to gain an action button to activate."
	icon = 'icons/obj/device.dmi'
	icon_state = "nanite_scanner"
	w_class = WEIGHT_CLASS_SMALL
	var/electric_charge_cost = 20
	var/recall_delay = 80  // 8 seconds until teleport
	var/cooldown = 0
	var/cooldown_time = 100  // 10 seconds cooldown
	var/datum/action/item_action/static_burst_generator/burst_action
	var/turf/recall_location
	var/obj/effect/recall_marker/marker
	var/recall_timer

/obj/item/static_burst_generator/Initialize()
	. = ..()
	burst_action = new(src)

/obj/item/static_burst_generator/Destroy()
	QDEL_NULL(burst_action)
	return ..()

/obj/item/static_burst_generator/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		burst_action.Grant(user)
		to_chat(user, span_notice("[src] is ready. Use the action button to mark a recall point."))

/obj/item/static_burst_generator/dropped(mob/user)
	. = ..()
	if(burst_action)
		burst_action.Remove(user)

/obj/item/static_burst_generator/proc/activate(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this device!"))
		return

	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to power this device!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[electric_charge_cost] needed)"))
		return

	// Mark current location
	recall_location = get_turf(user)

	// Create visual marker
	if(marker)
		qdel(marker)
	marker = new(recall_location)
	marker.owner = user

	// Set up teleport timer
	recall_timer = addtimer(CALLBACK(src, PROC_REF(recall_teleport), user), recall_delay, TIMER_STOPPABLE)

	cooldown = world.time + cooldown_time
	playsound(src, 'sound/magic/lightningshock.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] marks their position with crackling energy!"))
	to_chat(user, span_notice("You will be recalled to this position in [recall_delay/10] seconds."))

/obj/item/static_burst_generator/proc/recall_teleport(mob/living/user)
	if(!user || QDELETED(user) || user.stat == DEAD)
		cleanup_recall()
		return

	if(!recall_location)
		to_chat(user, span_warning("[src] fails to recall you - location lost!"))
		cleanup_recall()
		return

	// Teleport effects
	playsound(user, 'sound/magic/lightningbolt.ogg', 75, TRUE)
	user.visible_message(span_danger("[user] vanishes in a flash of electricity!"))

	// Teleport
	user.forceMove(recall_location)

	// Arrival effects
	playsound(recall_location, 'sound/magic/lightningbolt.ogg', 75, TRUE)
	new /obj/effect/temp_visual/lightning_strike(recall_location)
	user.visible_message(span_danger("[user] reappears in a burst of lightning!"))

	cleanup_recall()

/obj/item/static_burst_generator/proc/cleanup_recall()
	recall_location = null
	if(marker)
		qdel(marker)
		marker = null
	if(recall_timer)
		deltimer(recall_timer)
		recall_timer = null

/obj/item/static_burst_generator/dropped(mob/user)
	. = ..()
	cleanup_recall()
	if(burst_action)
		burst_action.Remove(user)

// Visual marker for recall location
/obj/effect/recall_marker
	name = "recall marker"
	desc = "A crackling marker indicating a recall point."
	icon = 'icons/effects/effects.dmi'
	icon_state = "electricity"
	density = FALSE
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	var/mob/living/owner

/obj/effect/recall_marker/Initialize()
	. = ..()
	animate(src, alpha = 150, time = 5, loop = -1, easing = SINE_EASING)
	animate(alpha = 255, time = 5, easing = SINE_EASING)
	// Auto-delete after maximum duration
	QDEL_IN(src, 100)

// Old static burst field - kept for compatibility but no longer used
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

/obj/effect/static_burst_field/crossed(atom/movable/AM)
	. = ..()
	if(triggered)
		return

	// Check if owner crosses through
	if(AM == owner)
		trigger_burst()

/obj/effect/static_burst_field/process()
	if(triggered)
		return

	// Deal minor damage to enemies standing in it
	for(var/mob/living/L in get_turf(src))
		if(L == owner)
			continue
		L.deal_damage(5, FIRE)

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
		var/turf/source_turf = get_turf(src)
		source_turf.Beam(L, "lightning", time = 5)

	qdel(src)


// TIER 2 WEAPONS

// Lightning Ram - Massive charge attack
/obj/item/ego_weapon/lightning_ram
	name = "R-Corp lightning ram"
	desc = "Electromagnetic battering ram that delivers devastating charge attacks. Click distant target to charge."
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "adjustment"
	force = 50
	attack_verb_continuous = list("rams", "crashes", "thunders")
	attack_verb_simple = list("ram", "crash", "thunder")
	hitsound = 'sound/weapons/resonator_blast.ogg'
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

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
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

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[electric_charge_cost] needed)"))
		return

	// Perform devastating charge
	lightning_charge(target, user, pack)

/obj/item/ego_weapon/lightning_ram/proc/lightning_charge(atom/target, mob/living/user, obj/item/rce_resource_tank/capacitor_pack/pack)
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

	// Overcharge system automatically provides speed boost

// Thunderclap Gauntlets - AoE burst with escape
/obj/item/ego_weapon/thunderclap_gauntlets
	name = "R-Corp thunderclap gauntlets"
	desc = "Gauntlets that create devastating thunder bursts. Click on to a distant target to perform area burst with automatic retreat."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "captain"
	force = 45
	attack_verb_continuous = list("thunders", "slams", "devastates")
	attack_verb_simple = list("thunder", "slam", "devastate")
	hitsound = 'sound/weapons/punch3.ogg'
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

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
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

/obj/item/ego_weapon/thunderclap_gauntlets/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(proximity_flag) // Normal attack
		return

	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use these gauntlets!"))
		return

	if(burst_cooldown > world.time)
		to_chat(user, span_warning("Thunderclap still charging! ([round((burst_cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(burst_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[burst_cost] needed)"))
		return

	// Perform thunderclap burst
	thunderclap_burst(target, user, pack)

/obj/item/ego_weapon/thunderclap_gauntlets/proc/thunderclap_burst(atom/target, mob/living/user, obj/item/rce_resource_tank/capacitor_pack/pack)
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
	// Overcharge system automatically provides speed boost

// EMP Grenade
/obj/item/grenade/r_corp/emp
	name = "R-Corp EMP grenade"
	desc = "Releases an electromagnetic pulse that disables machinery and stuns organics."
	icon_state = "emp"
	var/emp_range = 3

/obj/item/grenade/r_corp/emp/detonate(mob/living/lanced_by)
	// Drain charge from Clan mobs and damage others
	for(var/mob/living/L in range(emp_range, src))
		if(istype(L, /mob/living/simple_animal/hostile/clan))
			var/mob/living/simple_animal/hostile/clan/C = L
			C.charge = 0
			to_chat(C, span_userdanger("The electromagnetic pulse drains your charge!"))
		else
			L.deal_damage(20, FIRE)
			to_chat(L, span_userdanger("The electromagnetic pulse overwhelms your nervous system!"))

	playsound(src, 'sound/magic/lightningshock.ogg', 100, TRUE)
	qdel(src)

// TIER 3 WEAPONS

// Railgun Charge - Ultimate rush attack
/obj/item/ego_weapon/railgun_charge
	name = "railgun charge module"
	desc = "The ultimate Storm Ram weapon - transforms you into a living railgun projectile. Devastating but requires recovery time."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "instagibblue"
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

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
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

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[electric_charge_cost] needed)"))
		return

	// Perform ultimate railgun charge
	railgun_ultimate(target, user, pack)

/obj/item/ego_weapon/railgun_charge/proc/railgun_ultimate(atom/target, mob/living/user, obj/item/rce_resource_tank/capacitor_pack/pack)
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

	// Recovery period - user is briefly exhausted
	to_chat(user, span_warning("The railgun charge leaves you momentarily exhausted!"))

	// But then grant massive speed boost for escape
	addtimer(CALLBACK(src, PROC_REF(delayed_speed_boost), user, pack), 20)
	addtimer(CALLBACK(src, PROC_REF(recovery_message), user), 20)

/obj/item/ego_weapon/railgun_charge/proc/recovery_message(mob/user)
	to_chat(user, span_nicegreen("Energy surge propels you to safety!"))

/obj/item/ego_weapon/railgun_charge/proc/delayed_speed_boost(mob/user, obj/item/rce_resource_tank/capacitor_pack/pack)
	if(pack && user)
		// Overcharge system automatically provides speed boost

// Storm Surge Barrier - Mobile shield that damages on contact
/obj/item/storm_surge_barrier
	name = "storm surge barrier"
	desc = "Creates a mobile electromagnetic barrier that moves with you and damages enemies on contact. Equip to gain an action button to activate."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-purple"
	w_class = WEIGHT_CLASS_NORMAL
	var/electric_charge_cost = 30
	var/barrier_duration = 80  // 8 seconds
	var/active = FALSE
	var/datum/action/item_action/storm_surge_barrier/barrier_action
	var/mob/living/barrier_user
	var/contact_damage = 30
	var/push_force = 3
	var/mutable_appearance/barrier_overlay

/obj/item/storm_surge_barrier/Initialize()
	. = ..()
	barrier_action = new(src)
	// Create barrier overlay
	barrier_overlay = mutable_appearance('icons/effects/effects.dmi', "electricity")
	barrier_overlay.color = "#4444FF"
	barrier_overlay.alpha = 150
	barrier_overlay.layer = ABOVE_MOB_LAYER

/obj/item/storm_surge_barrier/Destroy()
	if(active)
		deactivate()
	QDEL_NULL(barrier_action)
	QDEL_NULL(barrier_overlay)
	return ..()

/obj/item/storm_surge_barrier/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		barrier_action.Grant(user)
		to_chat(user, span_notice("[src] is ready. Use the action button to toggle barrier."))

/obj/item/storm_surge_barrier/dropped(mob/user)
	. = ..()
	if(active)
		deactivate()
	if(barrier_action)
		barrier_action.Remove(user)

/obj/item/storm_surge_barrier/proc/toggle(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can use this device!"))
		return

	if(active)
		deactivate()
		return

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack to power the barrier!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[electric_charge_cost] needed)"))
		return

	activate(user, pack)

/obj/item/storm_surge_barrier/proc/activate(mob/user, obj/item/rce_resource_tank/capacitor_pack/pack)
	active = TRUE
	barrier_user = user

	// Add barrier overlay to user
	user.add_overlay(barrier_overlay)

	// Register bullet_act for projectile reflection
	RegisterSignal(user, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_projectile_hit))

	// Start processing for damage/push
	START_PROCESSING(SSobj, src)

	user.visible_message(span_danger("[user] activates a storm surge barrier!"))
	playsound(src, 'sound/magic/lightningshock.ogg', 75, TRUE)

	// Auto-deactivate after duration
	addtimer(CALLBACK(src, PROC_REF(deactivate)), barrier_duration)

/obj/item/storm_surge_barrier/proc/deactivate()
	if(!active)
		return

	active = FALSE

	if(barrier_user)
		// Remove overlay
		barrier_user.cut_overlay(barrier_overlay)

		// Unregister signal
		UnregisterSignal(barrier_user, COMSIG_ATOM_BULLET_ACT)

		barrier_user.visible_message(span_notice("The storm surge around [barrier_user] dissipates."))
		barrier_user = null

	// Stop processing
	STOP_PROCESSING(SSobj, src)

/obj/item/storm_surge_barrier/process()
	if(!active || !barrier_user || QDELETED(barrier_user))
		deactivate()
		return

	// Damage and push enemies near user
	for(var/mob/living/L in range(1, barrier_user))
		if(L == barrier_user)
			continue
		if(L.last_push_time && world.time - L.last_push_time < 10) // Prevent spam
			continue

		L.deal_damage(contact_damage, FIRE)
		var/atom/throw_target = get_edge_target_turf(L, get_dir(barrier_user, L))
		L.throw_at(throw_target, push_force, 2)
		L.last_push_time = world.time
		to_chat(L, span_danger("The storm surge blasts you away!"))
		playsound(L, 'sound/magic/lightningshock.ogg', 50, TRUE)

/obj/item/storm_surge_barrier/proc/on_projectile_hit(mob/user, obj/projectile/P)
	SIGNAL_HANDLER

	if(!active || P.reflectable == NONE)
		return

	// 50% chance to reflect
	if(!prob(50))
		return

	visible_message(span_userdanger("[user]'s storm surge deflects [P]!"))

	// Reflect projectile (based on Black Swan's code)
	if(P.starting)
		var/new_x = P.starting.x + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
		var/new_y = P.starting.y + pick(0, 0, 0, 0, 0, -1, 1, -2, 2)
		P.firer = null  // Remove firer to prevent friendly fire
		P.preparePixelProjectile(locate(clamp(new_x, 1, world.maxx), clamp(new_y, 1, world.maxy), user.z), user)

	return COMPONENT_BULLET_BLOCKED

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

	// Register signal to follow target
	if(follow_target)
		RegisterSignal(follow_target, COMSIG_MOVABLE_MOVED, PROC_REF(target_moved))
		forceMove(get_turf(follow_target))  // Initial position

	// Animated aura effect
	animate(src, transform = matrix() * 1.3, alpha = 100, time = 10, loop = -1, easing = SINE_EASING)
	animate(transform = matrix() * 1.5, alpha = 200, time = 10, easing = SINE_EASING)

/obj/effect/storm_surge/proc/target_moved(mob/user, atom/old_location, direction, forced)
	SIGNAL_HANDLER
	var/turf/new_turf = get_turf(follow_target)
	if(new_turf)
		forceMove(new_turf)

/obj/effect/storm_surge/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(follow_target)
		UnregisterSignal(follow_target, COMSIG_MOVABLE_MOVED)
		follow_target = null
	if(generator)
		generator.deactivate()
	return ..()

/obj/effect/storm_surge/process()
	if(!follow_target || QDELETED(follow_target))
		qdel(src)
		return

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
		to_chat(L, span_danger("The storm surge blasts you away!"))
		playsound(L, 'sound/magic/lightningshock.ogg', 50, TRUE)

	// Block some projectiles
	for(var/obj/projectile/P in range(1, src))
		if(prob(50))  // 50% chance to deflect
			var/new_angle = rand(0, 360)
			P.firer = null  // Remove firer to prevent friendly fire
			P.set_angle(new_angle)

// Add variable for tracking push time
/mob/living
	var/last_push_time = 0

// Thunderstorm Slam - Ground pound creates electric field
/obj/item/thunderstorm_slam
	name = "thunderstorm slam module"
	desc = "Leap into the air and slam down, creating a devastating electric storm around you. The ultimate area denial. Equip to gain an action button to activate."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-purple"
	w_class = WEIGHT_CLASS_NORMAL
	var/electric_charge_cost = 80
	var/slam_damage = 100
	var/storm_duration = 60  // 6 seconds
	var/cooldown = 0
	var/cooldown_time = 200  // 20 seconds
	var/datum/action/item_action/thunderstorm_slam/slam_action

/obj/item/thunderstorm_slam/Initialize()
	. = ..()
	slam_action = new(src)

/obj/item/thunderstorm_slam/Destroy()
	QDEL_NULL(slam_action)
	return ..()

/obj/item/thunderstorm_slam/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user))
		slam_action.Grant(user)
		to_chat(user, span_notice("[src] is ready. Use the action button to perform thunderstorm slam."))

/obj/item/thunderstorm_slam/dropped(mob/user)
	. = ..()
	if(slam_action)
		slam_action.Remove(user)

/obj/item/thunderstorm_slam/proc/activate(mob/user)
	if(!is_storm_ram(user))
		to_chat(user, span_warning("Only Storm Rams can perform the thunderstorm slam!"))
		return

	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/rce_resource_tank/capacitor_pack/pack = locate(/obj/item/rce_resource_tank/capacitor_pack) in user.contents
	if(!pack)
		to_chat(user, span_warning("You need a capacitor pack!"))
		return

	if(!pack.use_charge(electric_charge_cost))
		to_chat(user, span_warning("Not enough charge! ([pack.resource_amount]/[electric_charge_cost] needed)"))
		return

	perform_thunderstorm_slam(user, pack)

/obj/item/thunderstorm_slam/proc/perform_thunderstorm_slam(mob/living/user, obj/item/rce_resource_tank/capacitor_pack/pack)
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
	// Overcharge system automatically provides speed boost

/obj/item/thunderstorm_slam/proc/expanding_shockwave(turf/center, radius)
	for(var/turf/T in range(radius, center))
		if(get_dist(T, center) == radius)
			new /obj/effect/temp_visual/electric_trail(T)
			for(var/mob/living/L in T)
				if(is_storm_ram(L))
					continue
				L.deal_damage(20, FIRE)

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

// Action buttons for Storm Ram equipment
/datum/action/item_action/storm_dash
	name = "Storm Dash"
	desc = "Transform into living lightning and dash forward through enemies."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "berserk_mode"

/datum/action/item_action/storm_dash/Trigger()
	if(!istype(target, /obj/item/storm_dash))
		return
	var/obj/item/storm_dash/dash = target
	dash.activate(owner)
	return TRUE

/datum/action/item_action/static_burst_generator
	name = "Mark Recall Point"
	desc = "Mark your current location and teleport back after 8 seconds."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "rcl_gui"

/datum/action/item_action/static_burst_generator/Trigger()
	if(!istype(target, /obj/item/static_burst_generator))
		return
	var/obj/item/static_burst_generator/burst = target
	burst.activate(owner)
	return TRUE

/datum/action/item_action/storm_surge_barrier
	name = "Toggle Storm Surge"
	desc = "Toggle the mobile electromagnetic barrier."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "kindleKicks"

/datum/action/item_action/storm_surge_barrier/Trigger()
	if(!istype(target, /obj/item/storm_surge_barrier))
		return
	var/obj/item/storm_surge_barrier/barrier = target
	barrier.toggle(owner)
	return TRUE

/datum/action/item_action/thunderstorm_slam
	name = "Thunderstorm Slam"
	desc = "Leap and slam down, creating a devastating electric storm."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "jetboot"

/datum/action/item_action/thunderstorm_slam/Trigger()
	if(!istype(target, /obj/item/thunderstorm_slam))
		return
	var/obj/item/thunderstorm_slam/slam = target
	slam.activate(owner)
	return TRUE
