// Venom Rattlesnakes - Toxic/Decay Weapon Systems
// Area denial and damage over time specialists

// Helper proc to check if user is a Venom Rattlesnake (checks for implant directly)
/proc/is_venom_rattlesnake(mob/living/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/cyberimp/rce_specialist/venom/implant = locate() in H.internal_organs
	return !!implant

// Helper proc to check if target has venom immunity (wearing venom armor or is a Venom Rattlesnake)
/proc/is_venom_immune(mob/living/target)
	if(!ishuman(target))
		return FALSE
	var/mob/living/carbon/human/H = target
	// Venom Rattlesnakes are immune to venom
	if(is_venom_rattlesnake(H))
		return TRUE
	var/obj/item/clothing/suit/armor/ego_gear/venom/suit = H.wear_suit
	if(istype(suit) && suit.venom_immune)
		return TRUE
	return FALSE

// Acid Tank Backpack - Core resource for toxic weapons
/obj/item/rce_resource_tank/acid_backpack
	name = "heavy acid tank"
	desc = "A reinforced tank containing highly corrosive acids. Powers various R-Corp toxic weapon systems."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "waterbackpack"

	// Resource configuration
	resource_name = "acid"
	resource_unit = "units"
	resource_amount = 500
	max_resource = 500

	// Compatible refill sources
	compatible_dispensers = list(/obj/structure/acid_dispenser, /obj/structure/reagent_dispensers/watertank)

/obj/item/rce_resource_tank/acid_backpack/proc/use_acid(amount)
	return use_resource(amount)

/obj/item/rce_resource_tank/acid_backpack/attackby(obj/item/I, mob/user, params)
	// Portable acid canister for Ravens
	if(istype(I, /obj/item/acid_canister))
		var/obj/item/acid_canister/canister = I
		if(canister.acid_amount <= 0)
			to_chat(user, span_warning("[canister] is empty!"))
			return
		if(resource_amount >= max_resource)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/transfer_amount = min(canister.acid_amount, max_resource - resource_amount)
		resource_amount += transfer_amount
		canister.acid_amount -= transfer_amount
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

// Acid Dispenser Structure (placed at base)
/obj/structure/acid_dispenser
	name = "acid dispenser"
	desc = "A reinforced chemical dispenser containing industrial-grade acid for refilling R-Corp equipment."
	icon = 'icons/obj/chemical_tanks.dmi'
	icon_state = "tank_red"
	density = TRUE
	anchored = TRUE
	var/acid_stored = 5000
	var/max_acid = 5000

/obj/structure/acid_dispenser/examine(mob/user)
	. = ..()
	. += span_notice("Acid reserves: [acid_stored]/[max_acid]")
	. += span_nicegreen("Use an acid tank on this to refill.")

// Portable Acid Canister (for Ravens)
/obj/item/acid_canister
	name = "portable acid canister"
	desc = "A small canister of concentrated acid for field refueling. Used by Ravens to support Venom specialists."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bottle"
	w_class = WEIGHT_CLASS_NORMAL
	var/acid_amount = 100
	var/max_acid = 100

/obj/item/acid_canister/examine(mob/user)
	. = ..()
	. += span_notice("Acid: [acid_amount]/[max_acid]")
	if(acid_amount > 0)
		. += span_nicegreen("Use on an acid tank to transfer.")

// Base toxic weapon class
/obj/item/ego_weapon/toxic_base
	name = "toxic weapon"
	desc = "A weapon that uses acid."
	var/acid_cost = 10
	var/obj/item/rce_resource_tank/acid_backpack/linked_tank

/obj/item/ego_weapon/toxic_base/proc/find_acid_tank(mob/living/user)
	if(!linked_tank || !user.is_holding(src))
		linked_tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	return linked_tank

/obj/item/ego_weapon/toxic_base/proc/use_acid(mob/living/user, amount)
	var/obj/item/rce_resource_tank/acid_backpack/tank = find_acid_tank(user)
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to use this weapon!"))
		return FALSE
	if(!tank.use_acid(amount))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[amount] needed)"))
		return FALSE
	return TRUE

// TIER 1 WEAPONS

// Dummy projectile for acid sprayer (required by parent but not actually fired)
/obj/projectile/acid_spray_dummy
	name = "acid spray"
	icon_state = "dvirus"
	damage = 0
	nodamage = TRUE

// Acid Sprayer - Basic toxic spray weapon
/obj/item/ego_weapon/ranged/acid_sprayer
	name = "R-Corp acid sprayer"
	desc = "Sprays a cone of corrosive acid that melts through armor and flesh."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "mister"
	inhand_icon_state = "mister"
	lefthand_file = 'icons/mob/inhands/equipment/mister_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/mister_righthand.dmi'
	projectile_path = /obj/projectile/acid_spray_dummy
	force = 10
	special = "This weapon requires an acid tank backpack to function."
	var/acid_cost = 10
	var/cone_range = 4
	var/damage_amount = 35
	var/spray_cooldown = 0
	var/spray_cooldown_time = 0.5 SECONDS

/obj/item/ego_weapon/ranged/acid_sprayer/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(!CanUseEgo(user))
		return

	// Check cooldown
	if(spray_cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging!"))
		return

	var/obj/item/rce_resource_tank/acid_backpack/tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to use this weapon!"))
		return

	if(!tank.use_acid(acid_cost))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[acid_cost] needed)"))
		return

	// Set cooldown
	spray_cooldown = world.time + spray_cooldown_time

	// Create acid spray cone
	var/turf/origin = get_turf(user)
	var/list/affected_turfs = list()
	var/facing = get_dir(user, target)

	// Get cone pattern
	for(var/i = 1 to cone_range)
		var/turf/T = get_step(origin, facing)
		if(!T)
			break
		origin = T
		affected_turfs += T

		// Add side tiles for cone effect
		if(i > 1)
			var/turf/left = get_step(T, turn(facing, 90))
			var/turf/right = get_step(T, turn(facing, -90))
			if(left)
				affected_turfs += left
			if(right)
				affected_turfs += right

	// Apply effects
	playsound(src, 'sound/effects/venom.ogg', 50, TRUE)
	for(var/turf/T in affected_turfs)
		new /obj/effect/temp_visual/acid_splash(T)
		for(var/mob/living/L in T)
			if(L == user)
				continue

			// Check for venom immunity
			if(is_venom_immune(L))
				continue

			// Check for venom stacks for bonus damage
			var/damage_mult = 1
			if(L.has_status_effect(/datum/status_effect/venom_stacks))
				var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
				damage_mult = 1 + (V.stacks * 0.2) // +20% damage per stack
				to_chat(user, span_nicegreen("Enhanced damage from venom stacks!"))

			L.deal_damage(damage_amount * damage_mult, TOX)
			L.deal_damage(damage_amount * 0.5 * damage_mult, FIRE)
			// Apply a venom stack
			L.apply_status_effect(/datum/status_effect/venom_stacks)

// Toxic Mine - Deployable acid trap
/obj/item/toxic_mine
	name = "toxic proximity mine"
	desc = "A proximity-triggered mine that marks enemies with venom stacks when triggered."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "beartrap"
	color = "#00ff04"
	w_class = WEIGHT_CLASS_SMALL
	var/armed = FALSE
	var/trigger_range = 1
	var/setup_time = 30 // 3 seconds to set up
	var/venom_stacks_applied = 5
	var/damage = 20

/obj/item/toxic_mine/attack_self(mob/user)
	if(!armed)
		user.visible_message(span_notice("[user] begins setting up [src]..."), span_notice("You begin setting up [src]..."))
		if(do_after(user, setup_time, src))
			user.visible_message(span_warning("[user] arms [src]!"), span_warning("You arm [src]!"))
			armed = TRUE
			anchored = TRUE
			START_PROCESSING(SSobj, src)
			addtimer(CALLBACK(src, PROC_REF(activate)), 20) // 2 second activation delay after setup
		else
			to_chat(user, span_warning("Setup interrupted!"))

/obj/item/toxic_mine/proc/activate()
	if(!armed)
		return
	icon_state = "beartrap1"

/obj/item/toxic_mine/process()
	if(!armed)
		return
	for(var/mob/living/L in range(trigger_range, src))
		if(L.stat == DEAD)
			continue
		detonate()
		return

/obj/item/toxic_mine/proc/detonate()
	visible_message(span_danger("[src] releases a burst of venom!"))
	playsound(src, 'sound/effects/smoke.ogg', 50, TRUE)

	// Apply venom stacks to nearby enemies
	for(var/mob/living/L in range(2, src))
		// Check for venom immunity
		if(is_venom_immune(L))
			continue

		L.deal_damage(damage, TOX)
		// Apply multiple venom stacks
		for(var/i = 1 to venom_stacks_applied)
			L.apply_status_effect(/datum/status_effect/venom_stacks)
		to_chat(L, span_danger("You've been marked with venom!"))
		new /obj/effect/temp_visual/venom_mark(get_turf(L))

	STOP_PROCESSING(SSobj, src)
	qdel(src)

// Venom Trap Dispenser - Deploys multiple small venom traps
/obj/item/venom_trap_dispenser
	name = "venom trap dispenser"
	desc = "A device that deploys a field of small venom traps. Takes time to properly set up."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-purple"
	w_class = WEIGHT_CLASS_NORMAL
	var/setup_time = 50 // 5 seconds to deploy
	var/traps_to_deploy = 3
	var/deployed = FALSE

/obj/item/venom_trap_dispenser/attack_self(mob/user)
	if(deployed)
		to_chat(user, span_warning("[src] has already been deployed!"))
		return

	user.visible_message(span_notice("[user] begins setting up [src]..."), span_notice("You begin deploying the venom traps..."))

	if(do_after(user, setup_time, src))
		deployed = TRUE
		var/turf/T = get_turf(user)

		// Deploy multiple small traps in area
		for(var/i = 1 to traps_to_deploy)
			var/turf/trap_loc = pick(RANGE_TURFS(2, T))
			if(trap_loc && !trap_loc.density)
				new /obj/structure/venom_trap_small(trap_loc)

		user.visible_message(span_warning("[user] deploys [src]!"), span_notice("You finish deploying the venom traps."))
		playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
		qdel(src)
	else
		to_chat(user, span_warning("Setup interrupted!"))

// Small venom trap deployed by dispenser
/obj/structure/venom_trap_small
	name = "venom trap"
	desc = "A small concealed trap filled with venom."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "dodgeball"
	color = "#00ff04"
	density = FALSE
	anchored = TRUE
	alpha = 50 // Very hard to see
	var/trigger_range = 0 // Must step directly on it
	var/venom_stacks = 3
	var/armed = FALSE

/obj/structure/venom_trap_small/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(arm)), 20) // 2 seconds to arm

/obj/structure/venom_trap_small/proc/arm()
	armed = TRUE
	icon_state = "beacon_active"

/obj/structure/venom_trap_small/Crossed(atom/movable/AM)
	. = ..()
	if(!armed)
		return
	if(isliving(AM))
		var/mob/living/L = AM
		if(L.stat != DEAD)
			trigger(L)

/obj/structure/venom_trap_small/proc/trigger(mob/living/victim)
	visible_message(span_danger("[src] triggers!"))
	playsound(src, 'sound/effects/smoke.ogg', 30, TRUE)

	// Check for venom immunity
	if(!is_venom_immune(victim))
		// Apply venom stacks
		for(var/i = 1 to venom_stacks)
			victim.apply_status_effect(/datum/status_effect/venom_stacks)
		victim.deal_damage(10, TOX)
		to_chat(victim, span_danger("A hidden trap marks you with venom!"))
		new /obj/effect/temp_visual/venom_mark(get_turf(victim))

	qdel(src)

// Acid pool effect
/obj/effect/acid_pool
	name = "acid pool"
	desc = "A bubbling pool of corrosive acid."
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"
	density = FALSE
	opacity = FALSE
	anchored = TRUE
	var/damage_per_second = 5
	var/duration = 150

/obj/effect/acid_pool/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	QDEL_IN(src, duration)

/obj/effect/acid_pool/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/acid_pool/process()
	for(var/mob/living/L in get_turf(src))
		// Check for venom immunity
		if(is_venom_immune(L))
			continue

		// More damage if target has venom stacks
		var/damage = damage_per_second
		if(L.has_status_effect(/datum/status_effect/venom_stacks))
			var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
			damage = damage_per_second * (1 + V.stacks * 0.1) // +10% per stack

		L.deal_damage(damage, TOX)

/obj/effect/acid_pool/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		to_chat(L, span_danger("The acid burns your flesh!"))

// TIER 2 WEAPONS

// Venom Launcher - Now a siege weapon for marked targets
/obj/item/ego_weapon/ranged/venom_launcher
	name = "R-Corp venom launcher"
	desc = "Fires toxic shells that deal massive damage to venom-marked targets."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "gravity_gun"
	force = 15
	projectile_path = /obj/projectile/venom_shell
	fire_delay = 15
	special = "Deals massive bonus damage to enemies with venom stacks."
	var/acid_cost = 10

/obj/item/ego_weapon/ranged/venom_launcher/before_firing(atom/target, mob/living/user)
	var/obj/item/rce_resource_tank/acid_backpack/tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to use this weapon!"))
		return FALSE

	if(!tank.use_acid(acid_cost))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[acid_cost] needed)"))
		return FALSE

	return ..()

/obj/projectile/venom_shell
	name = "venom shell"
	icon_state = "toxin"
	damage = 30
	damage_type = TOX

/obj/projectile/venom_shell/on_hit(atom/target, blocked)
	. = ..()
	// Massive damage to venom-marked targets
	if(isliving(target))
		var/mob/living/L = target
		if(L.has_status_effect(/datum/status_effect/venom_stacks))
			var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
			var/bonus_damage = V.stacks * 15 // +15 damage per stack
			L.deal_damage(bonus_damage, TOX)
			to_chat(L, span_userdanger("The venom shell reacts violently with your venom marks!"))
			new /obj/effect/temp_visual/venom_explosion(get_turf(L))
		else
			// Only 1 stack if not marked
			L.apply_status_effect(/datum/status_effect/venom_stacks)

	// Create acid explosion
	var/turf/T = get_turf(target)
	if(T)
		new /obj/effect/temp_visual/acid_splash(T)
		for(var/turf/affected in range(1, T))
			new /obj/effect/acid_pool(affected)

// Decay Cloud Generator
/obj/item/decay_cloud_generator
	name = "decay cloud generator"
	desc = "Creates a large toxic cloud that slowly moves forward, decaying everything in its path."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-yellow"
	w_class = WEIGHT_CLASS_NORMAL
	var/acid_cost = 20
	var/cooldown = 0
	var/cooldown_time = 200

/obj/item/decay_cloud_generator/attack_self(mob/user)
	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/rce_resource_tank/acid_backpack/tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to use this device!"))
		return

	if(!tank.use_acid(acid_cost))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[acid_cost] needed)"))
		return

	// Create moving toxic cloud
	var/turf/T = get_turf(user)
	var/dir = user.dir
	new /obj/effect/moving_toxic_cloud(T, dir)

	cooldown = world.time + cooldown_time
	playsound(src, 'sound/effects/smoke.ogg', 75, TRUE)
	user.visible_message(span_danger("[user] deploys a massive toxic cloud!"))

// Moving toxic cloud
/obj/effect/moving_toxic_cloud
	name = "toxic cloud"
	desc = "A massive cloud of corrosive gas."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "smoke"
	pixel_x = -32
	pixel_y = -32
	opacity = TRUE
	density = FALSE
	var/move_dir
	var/moves_remaining = 10
	var/damage_per_tick = 15

/obj/effect/moving_toxic_cloud/Initialize(mapload, dir)
	. = ..()
	move_dir = dir
	alpha = 150
	color = "#00FF00"
	START_PROCESSING(SSobj, src)

/obj/effect/moving_toxic_cloud/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/moving_toxic_cloud/process()
	// Damage everything in the cloud
	for(var/turf/T in range(2, src))
		for(var/mob/living/L in T)
			// Check for venom stacks
			var/damage_mult = 1
			if(L.has_status_effect(/datum/status_effect/venom_stacks))
				var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
				damage_mult = 1 + (V.stacks * 0.15) // +15% per stack

			L.deal_damage(damage_per_tick * damage_mult, TOX)
			L.apply_status_effect(/datum/status_effect/venom_stacks)

	// Move forward
	if(moves_remaining > 0)
		var/turf/next = get_step(src, move_dir)
		if(next && !next.density)
			forceMove(next)
			moves_remaining--
		else
			moves_remaining = 0
	else
		// Fade out
		animate(src, alpha = 0, time = 20)
		QDEL_IN(src, 20)

// Venom Spike Launcher - Deploys venomous spike strips
/obj/item/venom_spike_launcher
	name = "venom spike strip deployer"
	desc = "Launches adhesive spike strips that must be carefully positioned. Enemies who cross them are marked with venom."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "crossbow"
	force = 12
	var/acid_cost = 10
	var/setup_time = 40 // 4 seconds
	var/strips_remaining = 3

/obj/item/venom_spike_launcher/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(strips_remaining <= 0)
		to_chat(user, span_warning("[src] is out of spike strips!"))
		return

	var/obj/item/rce_resource_tank/acid_backpack/tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to use this weapon!"))
		return

	if(!tank.use_acid(acid_cost))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[acid_cost] needed)"))
		return

	var/turf/T = get_turf(target)
	if(!T || T.density)
		return

	user.visible_message(span_notice("[user] begins deploying a spike strip..."), span_notice("You carefully position the venomous spike strip..."))

	if(do_after(user, setup_time, T))
		new /obj/structure/venom_spike_strip(T)
		strips_remaining--
		playsound(src, 'sound/weapons/genhit2.ogg', 50, TRUE)
		user.visible_message(span_warning("[user] deploys a venomous spike strip!"), span_notice("You deploy the spike strip. ([strips_remaining] remaining)"))
	else
		to_chat(user, span_warning("Deployment interrupted!"))
		tank.resource_amount += acid_cost // Refund acid on interrupt

// Venom spike strip structure
/obj/structure/venom_spike_strip
	name = "venomous spike strip"
	desc = "A strip of venomous spikes. Stepping on this would be a bad idea."
	icon = 'icons/obj/structures.dmi'
	icon_state = "brokenratvargrille"
	density = FALSE
	anchored = TRUE
	alpha = 150
	var/venom_stacks = 4
	var/damage = 15
	var/uses = 3 // Can trigger 3 times before breaking

/obj/structure/venom_spike_strip/Initialize()
	. = ..()
	color = "#00FF00"

/obj/structure/venom_spike_strip/Crossed(atom/movable/AM)
	. = ..()
	if(uses <= 0)
		return

	if(isliving(AM))
		var/mob/living/L = AM
		if(L.stat != DEAD)
			trigger(L)

/obj/structure/venom_spike_strip/proc/trigger(mob/living/victim)
	visible_message(span_danger("[victim] steps on [src]!"))
	playsound(src, 'sound/weapons/slice.ogg', 50, TRUE)

	// Apply damage and venom
	victim.deal_damage(damage, BRUTE, pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
	for(var/i = 1 to venom_stacks)
		victim.apply_status_effect(/datum/status_effect/venom_stacks)

	to_chat(victim, span_userdanger("The venomous spikes pierce your legs!"))
	new /obj/effect/temp_visual/venom_mark(get_turf(victim))

	// Slow the victim briefly
	victim.Immobilize(10)

	uses--
	if(uses <= 0)
		visible_message(span_notice("[src] breaks apart."))
		qdel(src)

// TIER 3 WEAPONS

// Toxic Bombardment System
/obj/item/ego_weapon/ranged/toxic_bombarder
	name = "toxic bombardment system"
	desc = "Heavy artillery that rains acid shells over a large area."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "flora"
	force = 20
	fire_delay = 30
	special = "Calls in an artillery strike of toxic shells."
	var/acid_cost = 30
	var/shells_per_volley = 6
	var/cooldown = 0
	var/cooldown_time = 300

/obj/item/ego_weapon/ranged/toxic_bombarder/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(!CanUseEgo(user))
		return

	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still reloading!"))
		return

	var/obj/item/rce_resource_tank/acid_backpack/tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to use this weapon!"))
		return

	if(!tank.use_acid(acid_cost))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[acid_cost] needed)"))
		return

	// Target area
	var/turf/T = get_turf(target)
	if(!T)
		return

	cooldown = world.time + cooldown_time
	user.visible_message(span_danger("[user] calls in a toxic bombardment!"))
	playsound(src, 'sound/weapons/flash.ogg', 100, TRUE)

	// Create bombardment
	for(var/i = 1 to shells_per_volley)
		addtimer(CALLBACK(src, PROC_REF(drop_shell), T), i * 3)

/obj/item/ego_weapon/ranged/toxic_bombarder/proc/drop_shell(turf/target)
	var/turf/T = pick(RANGE_TURFS(2, target))
	if(!T)
		return

	new /obj/effect/temp_visual/target(T)
	playsound(T, 'sound/weapons/mortar_whistle.ogg', 75, TRUE)

	addtimer(CALLBACK(src, PROC_REF(shell_impact), T), 10)

/obj/item/ego_weapon/ranged/toxic_bombarder/proc/shell_impact(turf/T)
	explosion(T, light_impact_range = 2)
	for(var/turf/affected in range(2, T))
		new /obj/effect/acid_pool(affected)
	for(var/mob/living/L in range(3, T))
		// Massive damage to venom-marked targets
		var/damage = 40
		if(L.has_status_effect(/datum/status_effect/venom_stacks))
			var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
			damage = 40 + (V.stacks * 10) // +10 damage per stack
			to_chat(L, span_userdanger("The bombardment tears through your venom-weakened body!"))

		L.deal_damage(damage, TOX)
		L.apply_status_effect(/datum/status_effect/venom_stacks, 3) // Apply 3 stacks

// Plague Scythe - Melee weapon that spreads decay
/obj/item/ego_weapon/plague_scythe
	name = "plague scythe"
	desc = "A wicked scythe that spreads decay with every swing. Consumes acid to perform special attacks."
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "despair"
	force = 45
	reach = 2
	attack_verb_continuous = list("slashes", "reaps", "cleaves")
	attack_verb_simple = list("slash", "reap", "cleave")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 80
	)
	var/acid_cost = 10
	var/spin_cooldown = 0
	var/spin_cooldown_time = 100

/obj/item/ego_weapon/plague_scythe/attack(mob/living/target, mob/living/user)
	// Check for venom stacks before the attack
	var/bonus_damage = 0
	if(target.has_status_effect(/datum/status_effect/venom_stacks))
		var/datum/status_effect/venom_stacks/V = target.has_status_effect(/datum/status_effect/venom_stacks)
		bonus_damage = V.stacks * 5 // +5 damage per stack
		to_chat(user, span_nicegreen("Your scythe cuts deeper into the venomed target! (+[bonus_damage] damage)"))

	force = initial(force) + bonus_damage
	. = ..()
	force = initial(force) // Reset force

	if(.)
		// Apply venom stack on hit
		target.apply_status_effect(/datum/status_effect/venom_stacks)
		// Chance to spread venom to nearby mobs
		if(prob(30))
			for(var/mob/living/L in range(1, target))
				if(L == user || L == target)
					continue
				L.apply_status_effect(/datum/status_effect/venom_stacks)

/obj/item/ego_weapon/plague_scythe/attack_self(mob/user)
	if(spin_cooldown > world.time)
		to_chat(user, span_warning("You're still recovering from the last spin!"))
		return

	var/obj/item/rce_resource_tank/acid_backpack/tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to perform this technique!"))
		return

	if(!tank.use_acid(acid_cost))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[acid_cost] needed)"))
		return

	// Perform spin attack
	spin_cooldown = world.time + spin_cooldown_time
	user.visible_message(span_danger("[user] begins spinning with [src]!"))

	for(var/i = 1 to 4)
		addtimer(CALLBACK(src, PROC_REF(spin_damage), user, i), i * 2)

/obj/item/ego_weapon/plague_scythe/proc/spin_damage(mob/user, spin_number)
	playsound(src, 'sound/weapons/bladeslice.ogg', 50, TRUE)
	for(var/mob/living/L in range(reach, user))
		if(L == user)
			continue
		// Bonus damage for venom stacks
		var/venom_bonus = 0
		if(L.has_status_effect(/datum/status_effect/venom_stacks))
			var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
			venom_bonus = V.stacks * 3

		L.deal_damage(30 + venom_bonus, BRUTE)
		L.deal_damage(20 + venom_bonus, TOX)
		L.apply_status_effect(/datum/status_effect/venom_stacks, 2) // Apply 2 stacks
		new /obj/effect/temp_visual/cleave(get_turf(L))

// Miasma Field Generator
/obj/item/miasma_field_generator
	name = "miasma field generator"
	desc = "Creates a massive field of toxic miasma that slowly drains life from everything within."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-green"
	w_class = WEIGHT_CLASS_NORMAL
	var/acid_cost = 50
	var/active = FALSE
	var/obj/effect/miasma_field/current_field

/obj/item/miasma_field_generator/attack_self(mob/user)
	if(active)
		deactivate()
		return

	var/obj/item/rce_resource_tank/acid_backpack/tank = locate(/obj/item/rce_resource_tank/acid_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need an acid tank to power this device!"))
		return

	if(!tank.use_acid(acid_cost))
		to_chat(user, span_warning("Not enough acid! ([tank.resource_amount]/[acid_cost] needed)"))
		return

	activate(user)

/obj/item/miasma_field_generator/proc/activate(mob/user)
	active = TRUE
	var/turf/T = get_turf(user)
	current_field = new /obj/effect/miasma_field(T)
	user.visible_message(span_danger("[user] activates [src], creating a field of toxic miasma!"))
	playsound(src, 'sound/effects/smoke.ogg', 100, TRUE)

/obj/item/miasma_field_generator/proc/deactivate()
	active = FALSE
	if(current_field)
		qdel(current_field)
		current_field = null
	visible_message(span_notice("The miasma field dissipates."))

/obj/item/miasma_field_generator/dropped(mob/user)
	. = ..()
	if(active)
		deactivate()

// Miasma field effect
/obj/effect/miasma_field
	name = "miasma field"
	desc = "A toxic field that drains life force."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	var/field_range = 5
	var/damage_per_tick = 8
	var/decay_chance = 50

/obj/effect/miasma_field/Initialize()
	. = ..()
	color = "#00FF00"
	alpha = 100
	transform = matrix() * 5
	START_PROCESSING(SSobj, src)

/obj/effect/miasma_field/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/miasma_field/process()
	for(var/mob/living/L in range(field_range, src))
		if(L.stat == DEAD)
			continue
		// Enhanced damage with venom stacks
		var/damage_mult = 1
		if(L.has_status_effect(/datum/status_effect/venom_stacks))
			var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
			damage_mult = 1 + (V.stacks * 0.25) // +25% per stack

		L.deal_damage(damage_per_tick * damage_mult, TOX)
		if(prob(decay_chance))
			L.apply_status_effect(/datum/status_effect/venom_stacks)
		// Visual effect
		new /obj/effect/temp_visual/acid_splash(get_turf(L))

// Status Effects

/datum/status_effect/acid_decay
	id = "acid_decay"
	duration = 100
	alert_type = /atom/movable/screen/alert/status_effect/acid_decay
	var/damage_per_tick = 3
	tick_interval = 10

/atom/movable/screen/alert/status_effect/acid_decay
	name = "Acid Decay"
	desc = "Your body is being eaten away by acid!"
	icon_state = "dna_melt"

/datum/status_effect/acid_decay/tick()
	owner.deal_damage(damage_per_tick, TOX)
	// Visual feedback
	if(prob(30))
		to_chat(owner, span_danger("The acid burns!"))

/datum/status_effect/venom_stacks
	id = "venom_stacks"
	duration = 200 // 20 seconds
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = /atom/movable/screen/alert/status_effect/venom_stacks
	var/damage_per_tick = 2
	tick_interval = 10
	var/stacks = 1
	var/max_stacks = 10

/atom/movable/screen/alert/status_effect/venom_stacks
	name = "Venom Stacks"
	desc = "You've been marked with venom! Toxic weapons will deal increased damage to you."
	icon_state = "convulsing"

/datum/status_effect/venom_stacks/on_creation(mob/living/new_owner, stacks_to_add = 1)
	. = ..()
	stacks = min(stacks_to_add, max_stacks)
	// Merge with existing stacks
	for(var/datum/status_effect/venom_stacks/V in new_owner.status_effects)
		if(V != src)
			stacks = min(stacks + V.stacks, max_stacks)
			qdel(V)
	owner.add_overlay(mutable_appearance('icons/effects/effects.dmi', "greenglow"))

/datum/status_effect/venom_stacks/tick()
	// DoT based on stacks
	owner.deal_damage(damage_per_tick * stacks, TOX)
	if(prob(stacks * 5)) // Higher stacks = more chance to spread
		to_chat(owner, span_danger("The venom courses through your veins!"))

/datum/status_effect/venom_stacks/on_remove()
	owner.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "greenglow"))
	return ..()

// Visual effects
/obj/effect/temp_visual/acid_splash
	name = "acid splash"
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"
	duration = 10

/obj/effect/temp_visual/venom_mark
	name = "venom mark"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mech_toxin"
	duration = 10
	color = "#00FF00"

/obj/effect/temp_visual/venom_explosion
	name = "venom explosion"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "explosion"
	pixel_x = -32
	pixel_y = -32
	duration = 10
	color = "#00FF00"
