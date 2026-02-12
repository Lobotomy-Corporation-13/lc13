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
	desc = "Sprays a cone of corrosive acid that inflicts it's targets with venom."
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

	if(!is_venom_rattlesnake(user))
		to_chat(user, span_warning("You need the Venom Rattlesnake combat implant to use this weapon!"))
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
	var/is_diagonal = (facing & (facing - 1)) // Check if diagonal (has multiple direction bits)

	// Get cone pattern
	for(var/i = 1 to cone_range)
		var/turf/T = get_step(origin, facing)
		if(!T)
			break
		origin = T
		affected_turfs |= T

		// Add side tiles for cone effect
		if(i > 1)
			var/turf/left = get_step(T, turn(facing, 90))
			var/turf/right = get_step(T, turn(facing, -90))
			if(left)
				affected_turfs |= left
			if(right)
				affected_turfs |= right

			// For diagonal directions, fill in the gaps by adding adjacent cardinal tiles
			if(is_diagonal)
				// Get the two cardinal components of the diagonal
				var/cardinal1 = facing & (NORTH|SOUTH)
				var/cardinal2 = facing & (EAST|WEST)
				// Add tiles adjacent to center in cardinal directions
				var/turf/adj1 = get_step(T, cardinal1)
				var/turf/adj2 = get_step(T, cardinal2)
				if(adj1)
					affected_turfs |= adj1
				if(adj2)
					affected_turfs |= adj2
				// Also fill gaps next to side tiles
				if(left)
					var/turf/left_fill = get_step(left, cardinal1)
					if(left_fill)
						affected_turfs |= left_fill
				if(right)
					var/turf/right_fill = get_step(right, cardinal2)
					if(right_fill)
						affected_turfs |= right_fill

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
			if(L.has_status_effect(/datum/status_effect/stacking/venom_stacks))
				var/datum/status_effect/stacking/venom_stacks/V = L.has_status_effect(/datum/status_effect/stacking/venom_stacks)
				damage_mult = 1 + (V.stacks * 0.2) // +20% damage per stack
				to_chat(user, span_nicegreen("Enhanced damage from venom stacks!"))

			L.adjustToxLoss(damage_amount * damage_mult)
			L.deal_damage(damage_amount * 0.5 * damage_mult, FIRE)
			// Apply a venom stack
			L.apply_venom_stacks()

// Miasma Barrier Projector - Creates offensive toxic barriers
/obj/item/ego_weapon/miasma_barrier
	name = "miasma barrier projector"
	desc = "Projects a wall of corrosive miasma that poisons enemies who pass through. Perfect for weaking incoming greed monsters."
	special = "Click on a turf to create a toxic barrier. Use in hand to toggle wall orientation and connect acid tank."
	icon = 'icons/obj/device.dmi'
	icon_state = "firing_pin_loyalty"
	force = 15
	throwforce = 10
	var/acid_per_wall = 80
	var/obj/item/rce_resource_tank/acid_backpack/acid_tank
	var/wall_cooldown = 0
	var/wall_cooldown_time = 8 SECONDS // Faster cooldown for offensive use
	var/wall_orientation = "horizontal" // horizontal or vertical
	var/wall_length = 5

/obj/item/ego_weapon/miasma_barrier/examine(mob/user)
	. = ..()
	. += span_notice("Current orientation: [wall_orientation]")
	if(acid_tank)
		. += span_notice("Connected to acid tank: [acid_tank.resource_amount]/[acid_tank.max_resource] acid remaining.")
		. += span_notice("Each barrier consumes [acid_per_wall] acid.")
	else
		. += span_warning("No acid tank connected!")

/obj/item/ego_weapon/miasma_barrier/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(acid_tank)
		to_chat(user, span_notice("You disconnect [acid_tank] from [src]."))
		acid_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/acid_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear an acid tank backpack first!"))
		return FALSE

	acid_tank = tank
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/miasma_barrier/attack_self(mob/user)
	. = ..()
	if(!acid_tank)
		connect_tank(user)
	else
		// Toggle orientation
		if(wall_orientation == "horizontal")
			wall_orientation = "vertical"
		else
			wall_orientation = "horizontal"
		to_chat(user, span_notice("Barrier orientation set to [wall_orientation]."))
		playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)

/obj/item/ego_weapon/miasma_barrier/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/miasma_barrier/dropped(mob/user)
	. = ..()
	if(acid_tank)
		to_chat(user, span_warning("The projector's acid line disconnects!"))
		acid_tank = null

/obj/item/ego_weapon/miasma_barrier/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(!is_venom_rattlesnake(user))
		to_chat(user, span_warning("You need the Venom Rattlesnake combat implant to use this weapon!"))
		return ..()

	if(wall_cooldown > world.time)
		to_chat(user, span_warning("Barrier projector is recharging! ([round((wall_cooldown - world.time) / 10)] seconds remaining)"))
		return ..()

	if(!acid_tank || acid_tank.resource_amount < acid_per_wall)
		if(!acid_tank)
			to_chat(user, span_warning("No acid tank connected!"))
		else
			to_chat(user, span_warning("Not enough acid! Need [acid_per_wall] acid."))
		return ..()

	var/turf/target_turf = get_turf(target)
	if(!istype(target_turf))
		return ..()

	if(get_dist(user, target_turf) > 6) // Longer range for offensive use
		to_chat(user, span_warning("Target is too far!"))
		return ..()

	// Create toxic barrier
	acid_tank.resource_amount -= acid_per_wall
	wall_cooldown = world.time + wall_cooldown_time

	playsound(user, 'sound/effects/venom.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] projects a barrier of toxic miasma!"), span_notice("You project a barrier of toxic miasma!"))

	// Calculate wall tiles
	var/list/wall_tiles = list()
	if(wall_orientation == "horizontal")
		for(var/i in -2 to 2)
			var/turf/T = locate(target_turf.x + i, target_turf.y, target_turf.z)
			if(T && !T.density)
				wall_tiles += T
	else // vertical
		for(var/i in -2 to 2)
			var/turf/T = locate(target_turf.x, target_turf.y + i, target_turf.z)
			if(T && !T.density)
				wall_tiles += T

	// Create miasma barrier segments
	for(var/turf/T in wall_tiles)
		new /obj/effect/miasma_barrier_segment(T)

// Toxic barrier segment - doesn't block but applies heavy venom stacks
/obj/effect/miasma_barrier_segment
	name = "miasma barrier"
	desc = "A wall of corrosive toxic gas that poisons anything passing through."
	icon = 'icons/effects/effects.dmi'
	icon_state = "atmos_resin"
	anchored = TRUE
	density = FALSE // Doesn't block movement - offensive tool to punish passage
	opacity = FALSE
	layer = ABOVE_MOB_LAYER
	var/damaging = FALSE

/obj/effect/miasma_barrier_segment/Initialize()
	. = ..()
	color = "#00FF44"
	alpha = 180
	set_light(2, 1, "#00FF00")
	QDEL_IN(src, 12 SECONDS)

/obj/effect/miasma_barrier_segment/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		if(is_venom_immune(L))
			return
		L.adjustToxLoss(25)
		L.apply_venom_stacks(3) // Heavy stacks for crossing
		to_chat(L, span_userdanger("The toxic miasma burns your lungs!"))

/obj/effect/miasma_barrier_segment/Bumped(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		if(is_venom_immune(L))
			return
		L.adjustToxLoss(15)
		L.apply_venom_stacks(2)
		to_chat(L, span_danger("The toxic miasma stings you!"))

/obj/effect/miasma_barrier_segment/attack_hand(mob/living/user)
	. = ..()
	if(is_venom_immune(user))
		to_chat(user, span_notice("The miasma doesn't affect you."))
		return
	user.adjustToxLoss(20)
	user.apply_venom_stacks(2)
	to_chat(user, span_danger("The toxic miasma burns your hand!"))

// Venom Strike Blade - Toxic melee weapon with dash ability
/obj/item/ego_weapon/venom_strike
	name = "venom strike blade"
	desc = "A blade coated with corrosive venom that can channel acid for devastating toxic dashes. The blade drips with deadly poison."
	special = "Use in hand to connect to an acid tank. Click on a far away target to perform a venom dash towards them. That dash applies stacks to all enemies hit."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "contractor_baton_1"
	inhand_icon_state = "contractor_baton_1"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 35
	damtype = BLACK_DAMAGE
	attack_verb_continuous = list("slashes", "injects", "poisons")
	attack_verb_simple = list("slash", "inject", "poison")
	hitsound = 'sound/weapons/fixer/generic/sword3.ogg'
	var/acid_per_dash = 50
	var/obj/item/rce_resource_tank/acid_backpack/acid_tank
	var/dash_cooldown = 0
	var/dash_cooldown_time = 1 SECONDS
	var/dash_damage = 50
	var/dash_range = 7
	var/dashing = FALSE
	var/list/been_hit = list()

/obj/item/ego_weapon/venom_strike/examine(mob/user)
	. = ..()
	if(acid_tank)
		. += span_notice("Connected to acid tank: [acid_tank.resource_amount]/[acid_tank.max_resource] acid remaining.")
		. += span_notice("Each venom dash consumes [acid_per_dash] acid.")
	else
		. += span_warning("No acid tank connected! Use in-hand to connect to a worn acid tank.")

/obj/item/ego_weapon/venom_strike/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	// Check if already connected
	if(acid_tank)
		// Disconnect current tank
		to_chat(user, span_notice("You disconnect [acid_tank] from [src]."))
		acid_tank = null
		return TRUE

	// Try to connect to worn tank
	var/obj/item/rce_resource_tank/acid_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear an acid tank backpack first!"))
		return FALSE

	// Connect to tank
	acid_tank = tank
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/venom_strike/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/venom_strike/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/venom_strike/dropped(mob/user)
	. = ..()
	if(acid_tank)
		to_chat(user, span_warning("The blade's acid line disconnects!"))
		acid_tank = null

/obj/item/ego_weapon/venom_strike/attack(mob/living/target, mob/living/user)
	if(!is_venom_rattlesnake(user))
		to_chat(user, span_warning("You need the Venom Rattlesnake combat implant to use this weapon!"))
		return
	. = ..()
	if(!. || !target)
		return
	// Apply venom stack on regular attacks
	if(!is_venom_immune(target))
		target.apply_venom_stacks()

/obj/item/ego_weapon/venom_strike/afterattack(atom/A, mob/living/user, proximity_flag, params)
	if(!is_venom_rattlesnake(user))
		return ..()

	// Don't dash if we're already dashing or on cooldown
	if(dashing || dash_cooldown > world.time)
		return ..()

	// Check for acid
	if(!acid_tank || acid_tank.resource_amount < acid_per_dash)
		if(!acid_tank)
			to_chat(user, span_warning("No acid tank connected!"))
		else
			to_chat(user, span_warning("Not enough acid! Need [acid_per_dash] acid."))
		return ..()

	var/turf/target_turf = get_turf(A)
	if(!istype(target_turf))
		return ..()

	// Check distance
	var/distance = get_dist(user, target_turf)
	if(distance < 2 || distance > dash_range)
		if(distance < 2)
			return ..()
		to_chat(user, span_warning("Target is too far! Maximum dash range is [dash_range] tiles."))
		return

	// Start the dash
	acid_tank.resource_amount -= acid_per_dash
	dash_cooldown = world.time + dash_cooldown_time
	VenomDash(user, target_turf)

/obj/item/ego_weapon/venom_strike/proc/VenomDash(mob/living/user, turf/target)
	if(!user || !target)
		return

	dashing = TRUE
	been_hit = list()
	var/dir_to_target = get_dir(user, target)

	// Visual and audio feedback
	playsound(user, 'sound/effects/venom.ogg', 75, TRUE)
	user.visible_message(span_danger("[user] surges forward in a trail of corrosive venom!"), span_notice("You channel the acid into a venomous dash!"))

	// Calculate path
	var/turf/current_turf = get_turf(user)
	var/list/path = list()
	for(var/i in 1 to dash_range)
		var/turf/next_turf = get_step(current_turf, dir_to_target)
		if(!next_turf || next_turf.density)
			break
		if(locate(/obj/structure/area_blocker) in next_turf)
			break
		if(locate(/obj/structure/resource_gate) in next_turf)
			break
		if(locate(/obj/structure/player_blocker) in next_turf)
			break
		path += next_turf
		current_turf = next_turf
		if(current_turf == target)
			break

	// Perform the dash
	for(var/turf/T in path)
		// Move the user
		user.forceMove(T)

		// Create acid pool trail
		if(!locate(/obj/effect/acid_pool) in T)
			new /obj/effect/acid_pool(T)

		// Damage enemies in the turf and adjacent turfs
		for(var/turf/adjacent in view(1, T))
			new /obj/effect/temp_visual/acid_splash(T)
			for(var/mob/living/L in adjacent)
				if(L == user || (L in been_hit))
					continue
				// Check for Venom immunity
				if(is_venom_immune(L))
					continue
				L.visible_message(span_boldwarning("[user] slashes through [L] with venomous fury!"))
				// Check for existing venom stacks for bonus damage
				var/damage_mult = 1
				if(L.has_status_effect(/datum/status_effect/stacking/venom_stacks))
					var/datum/status_effect/stacking/venom_stacks/V = L.has_status_effect(/datum/status_effect/stacking/venom_stacks)
					damage_mult = 1 + (V.stacks * 0.25) // +25% damage per stack
				L.adjustToxLoss(dash_damage * damage_mult)
				L.apply_venom_stacks(2) // Apply 2 stacks
				new /obj/effect/temp_visual/venom_mark(get_turf(L))
				been_hit += L

		// Small delay between movements for visual effect
		sleep(1)

	// End dash
	playsound(user, 'sound/effects/bamf.ogg', 50, TRUE)
	dashing = FALSE
	been_hit = list()

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
		if(L.has_status_effect(/datum/status_effect/stacking/venom_stacks))
			var/datum/status_effect/stacking/venom_stacks/V = L.has_status_effect(/datum/status_effect/stacking/venom_stacks)
			damage = damage_per_second * (1 + V.stacks * 0.1) // +10% per stack

		L.adjustToxLoss(damage)

/obj/effect/acid_pool/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		to_chat(L, span_danger("The acid burns your flesh!"))

// Blight Sprayer - Delayed toxic explosion area denial
/obj/item/ego_weapon/blight_sprayer
	name = "blight sprayer"
	desc = "Sprays volatile toxic sludge that sticks to surfaces and erupts into a toxic cloud after a short delay. Excellent for offensive pushes."
	special = "Click on a target to spray blight that explodes into toxic clouds after 2 seconds. Use in hand to connect acid tank."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "misteratmos"
	inhand_icon_state = "misteratmos"
	lefthand_file = 'icons/mob/inhands/equipment/mister_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/mister_righthand.dmi'
	force = 10
	throwforce = 5
	var/acid_per_spray = 20
	var/obj/item/rce_resource_tank/acid_backpack/acid_tank
	var/spray_cooldown = 0
	var/spray_cooldown_time = 1 SECONDS
	var/spray_range = 4

/obj/item/ego_weapon/blight_sprayer/examine(mob/user)
	. = ..()
	if(acid_tank)
		. += span_notice("Connected to acid tank: [acid_tank.resource_amount]/[acid_tank.max_resource] acid remaining.")
		. += span_notice("Each blight spray consumes [acid_per_spray] acid.")
	else
		. += span_warning("No acid tank connected! Use in-hand to connect to a worn acid tank.")

/obj/item/ego_weapon/blight_sprayer/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(acid_tank)
		to_chat(user, span_notice("You disconnect [acid_tank] from [src]."))
		acid_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/acid_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear an acid tank backpack first!"))
		return FALSE

	acid_tank = tank
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/blight_sprayer/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/blight_sprayer/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/blight_sprayer/dropped(mob/user)
	. = ..()
	if(acid_tank)
		to_chat(user, span_warning("The sprayer's acid line disconnects!"))
		acid_tank = null

/obj/item/ego_weapon/blight_sprayer/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(!is_venom_rattlesnake(user))
		to_chat(user, span_warning("You need the Venom Rattlesnake combat implant to use this weapon!"))
		return ..()

	if(spray_cooldown > world.time)
		return ..()

	if(!acid_tank || acid_tank.resource_amount < acid_per_spray)
		if(!acid_tank)
			to_chat(user, span_warning("No acid tank connected!"))
		else
			to_chat(user, span_warning("Not enough acid! Need [acid_per_spray] acid."))
		return ..()

	var/turf/target_turf = get_turf(target)
	if(!istype(target_turf))
		return ..()

	if(get_dist(user, target_turf) > spray_range)
		to_chat(user, span_warning("Target is too far! Maximum range is [spray_range] tiles."))
		return ..()

	// Spray blight
	acid_tank.resource_amount -= acid_per_spray
	spray_cooldown = world.time + spray_cooldown_time

	playsound(user, 'sound/effects/spray2.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] sprays toxic blight at [target]!"), span_notice("You spray toxic blight at [target]."))

	// Create blight glob
	new /obj/effect/blight_glob(target_turf, user)

// Blight glob effect - toxic delayed explosion
/obj/effect/blight_glob
	name = "toxic blight"
	desc = "A glob of highly volatile toxic sludge. It's bubbling ominously..."
	icon = 'icons/effects/effects.dmi'
	icon_state = "mech_toxin"
	anchored = TRUE
	var/detonate_time = 2 SECONDS
	var/mob/living/owner

/obj/effect/blight_glob/Initialize(mapload, mob/living/user)
	. = ..()
	owner = user
	color = "#00FF00"
	addtimer(CALLBACK(src, PROC_REF(detonate)), detonate_time)
	animate(src, alpha = 255, color = "#88FF00", time = detonate_time - 5)

/obj/effect/blight_glob/proc/detonate()
	playsound(src, 'sound/effects/venom.ogg', 75, TRUE)
	new /obj/effect/temp_visual/venom_explosion(loc)

	// Create 3x3 toxic zone and apply venom stacks
	for(var/turf/T in range(1, src))
		new /obj/effect/blight_cloud(T)
		for(var/mob/living/L in T)
			if(is_venom_immune(L))
				continue
			L.adjustToxLoss(60)
			L.apply_venom_stacks(3) // Apply 3 stacks

	qdel(src)

// Long-lasting blight cloud
/obj/effect/blight_cloud
	name = "blight cloud"
	desc = "A toxic cloud that corrodes everything it touches."
	icon = 'icons/effects/effects.dmi'
	icon_state = "mustard"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	var/damaging = FALSE

/obj/effect/blight_cloud/Initialize()
	. = ..()
	color = "#44FF44"
	alpha = 180
	QDEL_IN(src, 15 SECONDS)

/obj/effect/blight_cloud/Crossed(atom/movable/AM)
	. = ..()
	if(!damaging)
		damaging = TRUE
		DoDamage()

/obj/effect/blight_cloud/proc/DoDamage()
	var/dealt_damage = FALSE
	for(var/mob/living/L in get_turf(src))
		if(is_venom_immune(L))
			continue
		L.adjustToxLoss(8)
		L.apply_venom_stacks()
		dealt_damage = TRUE
	if(!dealt_damage)
		damaging = FALSE
		return
	addtimer(CALLBACK(src, PROC_REF(DoDamage)), 5)

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
	if(!is_venom_rattlesnake(user))
		to_chat(user, span_warning("You need the Venom Rattlesnake combat implant to use this weapon!"))
		return FALSE

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
	damage = 75
	damage_type = TOX

/obj/projectile/venom_shell/on_hit(atom/target, blocked)
	. = ..()
	// Massive damage to venom-marked targets
	if(isliving(target))
		var/mob/living/L = target
		if(L.has_status_effect(/datum/status_effect/stacking/venom_stacks))
			var/datum/status_effect/stacking/venom_stacks/V = L.has_status_effect(/datum/status_effect/stacking/venom_stacks)
			var/bonus_damage = V.stacks * 15 // +15 damage per stack
			L.adjustToxLoss(bonus_damage)
			to_chat(L, span_userdanger("The venom shell reacts violently with your venom marks!"))
			new /obj/effect/temp_visual/venom_explosion(get_turf(L))
		else
			// Only 1 stack if not marked
			L.apply_venom_stacks()

	// Create acid explosion
	var/turf/T = get_turf(target)
	if(T)
		new /obj/effect/temp_visual/acid_splash(T)
		for(var/turf/affected in range(1, T))
			new /obj/effect/acid_pool(affected)

// Plague Mortar - Long range toxic bombardment weapon
/obj/item/ego_weapon/ranged/plague_mortar
	name = "plague mortar"
	desc = "A heavy launcher that fires arcing plague shells, creating persistent toxic zones and applying massive venom stacks. Built for aggressive pushes."
	special = "Click far targets to fire arcing shells. Minimum range 5 tiles. Use in hand to connect acid tank."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "rocketlauncher"
	inhand_icon_state = "rocketlauncher"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	force = 20
	projectile_path = /obj/projectile/plague_shell
	fire_sound = 'sound/weapons/gun/general/rocket_launch.ogg'
	zoomable = TRUE
	zoom_amt = 10
	zoom_out_amt = 13
	var/acid_per_shot = 75
	var/obj/item/rce_resource_tank/acid_backpack/acid_tank
	var/setup_time = 1.5 SECONDS // Faster setup for offensive play
	var/min_range = 4
	var/max_range = 15

/obj/item/ego_weapon/ranged/plague_mortar/examine(mob/user)
	. = ..()
	if(acid_tank)
		. += span_notice("Connected to acid tank: [acid_tank.resource_amount]/[acid_tank.max_resource] acid remaining.")
		. += span_notice("Each shell consumes [acid_per_shot] acid.")
	else
		. += span_warning("No acid tank connected! Use in-hand to connect to a worn acid tank.")

/obj/item/ego_weapon/ranged/plague_mortar/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(acid_tank)
		to_chat(user, span_notice("You disconnect [acid_tank] from [src]."))
		acid_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/acid_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear an acid tank backpack first!"))
		return FALSE

	acid_tank = tank
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/ranged/plague_mortar/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/ranged/plague_mortar/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/ranged/plague_mortar/dropped(mob/user)
	. = ..()
	if(acid_tank)
		to_chat(user, span_warning("The launcher's acid line disconnects!"))
		acid_tank = null

/obj/item/ego_weapon/ranged/plague_mortar/can_shoot()
	if(!acid_tank)
		return FALSE
	if(acid_tank.resource_amount < acid_per_shot)
		return FALSE
	return TRUE

/obj/item/ego_weapon/ranged/plague_mortar/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	if(!is_venom_rattlesnake(user))
		to_chat(user, span_warning("You need the Venom Rattlesnake combat implant to use this weapon!"))
		return FALSE

	if(!can_shoot())
		if(!acid_tank)
			to_chat(user, span_warning("No acid tank connected!"))
		else
			to_chat(user, span_warning("Not enough acid!"))
		return FALSE

	var/distance = get_dist(user, target)
	if(distance < min_range)
		to_chat(user, span_warning("Target is too close! Minimum range is [min_range] tiles."))
		return FALSE
	if(distance > max_range)
		to_chat(user, span_warning("Target is too far! Maximum range is [max_range] tiles."))
		return FALSE

	if(!do_after(user, setup_time, target = user))
		to_chat(user, span_warning("You fail to set up the mortar."))
		return FALSE

	to_chat(user, span_notice("Mortar ready to fire!"))
	acid_tank.resource_amount -= acid_per_shot
	return ..()

// Plague shell projectile
/obj/projectile/plague_shell
	name = "plague shell"
	icon_state = "dvirus"
	damage = 70
	damage_type = TOX
	speed = 2
	range = 15

/obj/projectile/plague_shell/on_hit(atom/target, blocked = FALSE)
	. = ..()
	// Create 5x5 plague zone
	for(var/turf/T in range(2, target))
		new /obj/effect/plague_zone(T)
		for(var/mob/living/L in T)
			if(is_venom_immune(L))
				continue
			// 5x damage to simple mobs
			var/damage_mult = 1
			if(isanimal(L))
				damage_mult = 5
			// +15% damage per venom stack
			if(L.has_status_effect(/datum/status_effect/stacking/venom_stacks))
				var/datum/status_effect/stacking/venom_stacks/V = L.has_status_effect(/datum/status_effect/stacking/venom_stacks)
				damage_mult *= (1 + (V.stacks * 0.15))
			L.adjustToxLoss(40 * damage_mult)
			L.apply_venom_stacks(3) // Apply 3 stacks

// Long-lasting plague zone
/obj/effect/plague_zone
	name = "plague zone"
	desc = "A festering pool of toxic plague that corrupts all it touches."
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "cloud_swirl"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	var/damaging = FALSE

/obj/effect/plague_zone/Initialize()
	. = ..()
	color = "#00AA00"
	alpha = 200
	set_light(2, 1, "#00FF00")
	QDEL_IN(src, 25 SECONDS)

/obj/effect/plague_zone/Crossed(atom/movable/AM)
	. = ..()
	if(!damaging)
		damaging = TRUE
		DoDamage()

/obj/effect/plague_zone/proc/DoDamage()
	var/dealt_damage = FALSE
	for(var/mob/living/L in get_turf(src))
		if(is_venom_immune(L))
			continue
		// 5x damage to simple mobs
		var/damage_mult = 1
		if(isanimal(L))
			damage_mult = 5
		// +15% damage per venom stack
		if(L.has_status_effect(/datum/status_effect/stacking/venom_stacks))
			var/datum/status_effect/stacking/venom_stacks/V = L.has_status_effect(/datum/status_effect/stacking/venom_stacks)
			damage_mult *= (1 + (V.stacks * 0.15))
		L.adjustToxLoss(10 * damage_mult)
		L.apply_venom_stacks()
		dealt_damage = TRUE
	if(!dealt_damage)
		damaging = FALSE
		return
	addtimer(CALLBACK(src, PROC_REF(DoDamage)), 3)

// Corrosive Burst Gauntlets - Melee weapon with toxic AoE bursts
/obj/item/ego_weapon/corrosive_gauntlets
	name = "corrosive burst gauntlets"
	desc = "Heavy gauntlets coated with corrosive compounds that channel acid into explosive toxic bursts. Built for aggressive close combat."
	special = "Use in hand to toggle Toxin Mode. In Toxin Mode, attacks create venom bursts and apply stacks but consume acid."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "concussive_gauntlets"
	worn_icon = 'icons/mob/clothing/hands.dmi'
	inhand_icon_state = "concussive_gauntlets"
	force = 30
	damtype = BLACK_DAMAGE
	attack_verb_continuous = list("corrodes", "melts", "dissolves")
	attack_verb_simple = list("corrode", "melt", "dissolve")
	hitsound = 'sound/weapons/punch3.ogg'
	var/acid_per_burst = 25
	var/obj/item/rce_resource_tank/acid_backpack/acid_tank
	var/toxin_mode = FALSE
	var/toxin_damage_bonus = 20

/obj/item/ego_weapon/corrosive_gauntlets/examine(mob/user)
	. = ..()
	. += span_notice("Current mode: [toxin_mode ? "TOXIN" : "Normal"]")
	if(acid_tank)
		. += span_notice("Connected to acid tank: [acid_tank.resource_amount]/[acid_tank.max_resource] acid remaining.")
		if(toxin_mode)
			. += span_notice("Toxin Mode: Each attack consumes [acid_per_burst] acid for guaranteed venom burst.")
	else
		. += span_warning("No acid tank connected! Use in-hand to connect to a worn acid tank.")

/obj/item/ego_weapon/corrosive_gauntlets/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(acid_tank)
		to_chat(user, span_notice("You disconnect [acid_tank] from [src]."))
		acid_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/acid_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear an acid tank backpack first!"))
		return FALSE

	acid_tank = tank
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/corrosive_gauntlets/attack_self(mob/user)
	. = ..()
	if(!acid_tank)
		connect_tank(user)
	else
		// Toggle toxin mode
		toxin_mode = !toxin_mode
		if(toxin_mode)
			to_chat(user, span_danger("TOXIN MODE ACTIVATED! Your attacks will create venom bursts!"))
			playsound(src, 'sound/effects/venom.ogg', 50, TRUE)
		else
			to_chat(user, span_notice("Toxin mode deactivated."))
			playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)

/obj/item/ego_weapon/corrosive_gauntlets/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/corrosive_gauntlets/dropped(mob/user)
	. = ..()
	if(acid_tank)
		to_chat(user, span_warning("The gauntlets' acid line disconnects!"))
		acid_tank = null
	toxin_mode = FALSE

/obj/item/ego_weapon/corrosive_gauntlets/attack(mob/living/target, mob/living/user)
	if(!is_venom_rattlesnake(user))
		to_chat(user, span_warning("You need the Venom Rattlesnake combat implant to use this weapon!"))
		return
	. = ..()
	if(!. || !target)
		return

	// Always apply a venom stack on hit
	if(!is_venom_immune(target))
		target.apply_venom_stacks()

	var/create_burst = FALSE

	// Check if we should create a venom burst
	// VENOM BURST: An AoE toxic explosion that damages all nearby enemies, applies venom stacks, and creates acid pools
	if(toxin_mode && acid_tank && acid_tank.resource_amount >= acid_per_burst)
		// Toxin mode: guaranteed burst, costs acid
		acid_tank.resource_amount -= acid_per_burst
		create_burst = TRUE
		// Bonus damage based on venom stacks
		if(!is_venom_immune(target))
			var/damage_mult = 1
			if(target.has_status_effect(/datum/status_effect/stacking/venom_stacks))
				var/datum/status_effect/stacking/venom_stacks/V = target.has_status_effect(/datum/status_effect/stacking/venom_stacks)
				damage_mult = 1 + (V.stacks * 0.2)
			target.adjustToxLoss(toxin_damage_bonus * damage_mult)

	if(create_burst)
		VenomBurst(target, user, toxin_mode)

/// Creates a venom burst - an AoE toxic explosion that damages nearby enemies and applies venom stacks
/// When empowered (Toxin Mode active): 3x3 area (1 tile radius), creates acid pools, deals 25 toxin damage, applies 2 venom stacks
/// When not empowered: single tile only, no acid pools, deals 10 toxin damage, applies 1 venom stack
/obj/item/ego_weapon/corrosive_gauntlets/proc/VenomBurst(atom/target, mob/user, empowered = FALSE)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	playsound(target_turf, 'sound/effects/venom.ogg', 50, TRUE)
	new /obj/effect/temp_visual/venom_explosion(target_turf)

	// Create venom burst - empowered mode has 1 tile radius (3x3 area), normal mode only affects target tile
	var/burst_range = empowered ? 1 : 0
	for(var/turf/T in range(burst_range, target_turf))
		new /obj/effect/temp_visual/acid_splash(T)
		if(empowered && !locate(/obj/effect/acid_pool) in T)
			new /obj/effect/acid_pool(T)

		for(var/mob/living/L in T)
			if(L == user)
				continue
			if(is_venom_immune(L))
				continue
			var/damage = empowered ? 25 : 10
			L.adjustToxLoss(damage)
			L.apply_venom_stacks(empowered ? 2 : 1)

// Status Effects
#define STATUS_EFFECT_VENOM_STACKS /datum/status_effect/stacking/venom_stacks

/datum/status_effect/stacking/venom_stacks
	id = "venom_stacks"
	alert_type = /atom/movable/screen/alert/status_effect/venom_stacks
	max_stacks = 10
	tick_interval = 1 SECONDS
	consumed_on_threshold = FALSE
	var/damage_per_tick = 2
	var/new_stack = FALSE

/atom/movable/screen/alert/status_effect/venom_stacks
	name = "Venom Stacks"
	desc = "You've been marked with venom! Toxic weapons will deal increased damage to you."
	icon_state = "convulsing"

/datum/status_effect/stacking/venom_stacks/on_apply()
	. = ..()
	owner.add_overlay(mutable_appearance('icons/effects/effects.dmi', "greenglow"))

/datum/status_effect/stacking/venom_stacks/add_stacks(stacks_added)
	. = ..()
	new_stack = TRUE

/datum/status_effect/stacking/venom_stacks/tick()
	// DoT based on stacks - 5x damage to simple mobs
	var/damage_mult = 1
	if(isanimal(owner))
		damage_mult = 5
	owner.adjustToxLoss(damage_per_tick * stacks * damage_mult)
	if(prob(stacks * 5)) // Higher stacks = more chance to message
		to_chat(owner, span_danger("The venom courses through your veins!"))

	// Decay stacks if no new stacks were added
	if(new_stack)
		new_stack = FALSE
	else
		stacks -= 1
		if(stacks <= 0)
			qdel(src)

/datum/status_effect/stacking/venom_stacks/on_remove()
	owner.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "greenglow"))
	return ..()

/// Apply venom stacks to a mob. If they already have venom stacks, add to them instead.
/mob/living/proc/apply_venom_stacks(stacks_to_add = 1)
	var/datum/status_effect/stacking/venom_stacks/V = has_status_effect(/datum/status_effect/stacking/venom_stacks)
	if(!V)
		apply_status_effect(/datum/status_effect/stacking/venom_stacks, stacks_to_add)
	else
		V.add_stacks(stacks_to_add)

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

// ACID GRENADE - Tier 1 Factory Item
/obj/item/grenade/r_corp/acid
	name = "r-corp acid grenade"
	desc = "A grenade filled with corrosive acid that creates toxic puddles and applies venom stacks."
	icon_state = "grenade"
	color = "#00FF00"
	explosion_damage = 40

/obj/item/grenade/r_corp/acid/detonate(mob/living/lanced_by)
	// Create acid pools and apply venom stacks
	for(var/turf/T in view(explosion_range, src))
		if(!locate(/obj/effect/acid_pool) in T)
			new /obj/effect/acid_pool(T)
		for(var/mob/living/L in T)
			if(is_venom_immune(L))
				continue
			L.apply_venom_stacks(2)
	. = ..()

// TOXIC MINE - Tier 1 Factory Item
/obj/item/toxic_mine
	name = "toxic mine"
	desc = "A proximity-triggered mine that sprays corrosive acid when enemies approach. Use in-hand to arm or disarm."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "beartrap0"
	base_icon_state = "beartrap"
	color = "#00FF00"
	w_class = WEIGHT_CLASS_SMALL
	var/armed = FALSE
	var/venom_stacks_applied = 4
	var/damage = 30
	var/explosion_range = 2

/obj/item/toxic_mine/Initialize()
	. = ..()
	update_icon()

/obj/item/toxic_mine/update_icon_state()
	icon_state = "[base_icon_state][armed]"

/obj/item/toxic_mine/examine(mob/user)
	. = ..()
	. += span_notice("It is currently [armed ? "armed" : "disarmed"].")

/obj/item/toxic_mine/attack_self(mob/user)
	. = ..()
	if(!ishuman(user) || user.stat != CONSCIOUS || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return
	armed = !armed
	anchored = armed
	update_icon()
	to_chat(user, span_notice("[src] is now [armed ? "armed" : "disarmed"]."))
	if(armed)
		user.visible_message(span_warning("[user] arms [src]!"), span_warning("You arm [src]!"))
	else
		user.visible_message(span_notice("[user] disarms [src]."), span_notice("You disarm [src]."))

/obj/item/toxic_mine/Crossed(atom/movable/AM)
	. = ..()
	if(!armed || !isturf(loc))
		return
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	if(L.stat == DEAD)
		return
	if(L.movement_type & (FLYING|FLOATING))
		return
	// Detonate
	detonate()

/obj/item/toxic_mine/proc/detonate()
	armed = FALSE
	update_icon()
	visible_message(span_danger("[src] erupts in a spray of corrosive acid!"))
	playsound(src, 'sound/effects/venom.ogg', 50, TRUE)

	// Create brief acid mist cloud
	for(var/turf/T in range(explosion_range, src))
		new /obj/effect/temp_visual/acid_splash(T)

	for(var/mob/living/L in range(explosion_range, src))
		// Check for Venom immunity
		if(is_venom_immune(L))
			continue

		L.adjustToxLoss(damage)
		L.apply_venom_stacks(venom_stacks_applied)
		to_chat(L, span_danger("You're sprayed with corrosive acid!"))

	qdel(src)

// CORROSIVE SPRAY TURRET - Tier 2 Deployable
// Projectile that applies acid damage and venom stacks
/obj/projectile/acid_spray
	name = "acid spray"
	icon_state = "toxin"
	damage = 25
	damage_type = TOX
	color = "#00FF00"

/obj/projectile/acid_spray/on_hit(atom/target, blocked)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		if(!is_venom_immune(L))
			L.apply_venom_stacks()

/obj/item/corrosive_turret_deployable
	name = "corrosive spray turret module"
	desc = "A deployable automatic turret that shoots acid at hostile simple mobs. Use in-hand to deploy."
	icon = 'icons/obj/device.dmi'
	icon_state = "signaller"
	color = "#00FF00"
	w_class = WEIGHT_CLASS_NORMAL
	var/stored_acid = 200  // Acid stored in the deployable

/obj/item/corrosive_turret_deployable/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to deploy the turret.")
	. += span_notice("Stored acid: [stored_acid]/200")

/obj/item/corrosive_turret_deployable/attack_self(mob/user)
	. = ..()
	var/turf/T = get_turf(user)
	if(!istype(T))
		to_chat(user, span_warning("You can't deploy [src] here!"))
		return

	to_chat(user, span_notice("You deploy [src]..."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)

	if(!do_after(user, 2 SECONDS, target = user))
		to_chat(user, span_warning("You stop deploying [src]."))
		return

	// Create turret with stored acid
	var/obj/machinery/porta_turret/corrosive/turret = new(T)
	turret.acid_storage = stored_acid
	to_chat(user, span_notice("You deploy the turret!"))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	qdel(src)

// Simple turret that only shoots hostile simple mobs
/obj/machinery/porta_turret/corrosive
	name = "corrosive spray turret"
	desc = "An automatic turret that sprays acid at hostile creatures."
	icon_state = "syndie_lethal"
	base_icon_state = "syndie"
	color = "#00FF00"
	max_integrity = 150

	// Turret configuration - no cover, always up, no power needed
	has_cover = FALSE
	always_up = TRUE
	use_power = NO_POWER_USE
	uses_stored = FALSE

	// Targeting - only shoot hostile simple mobs
	turret_flags = TURRET_FLAG_SHOOT_ANOMALOUS
	faction = list("neutral")

	// Weapon configuration
	scan_range = 5
	shot_delay = 20  // 2 seconds between shots
	lethal_projectile = /obj/projectile/acid_spray
	lethal_projectile_sound = 'sound/effects/spray2.ogg'
	mode = TURRET_LETHAL

	var/acid_storage = 200
	var/max_acid_storage = 200
	var/acid_per_shot = 15

/obj/machinery/porta_turret/corrosive/examine(mob/user)
	. = ..()
	. += span_notice("Acid: [acid_storage]/[max_acid_storage]")
	. += span_notice("Automatically targets hostile creatures within [scan_range] tiles.")

/obj/machinery/porta_turret/corrosive/shootAt(atom/movable/target)
	// Check if we have enough acid
	if(acid_storage < acid_per_shot)
		return

	// Consume acid instead of power
	acid_storage -= acid_per_shot

	// Fire the projectile
	if(!raised)
		return

	if(last_fired + shot_delay > world.time)
		return
	last_fired = world.time

	var/turf/T = get_turf(src)
	var/turf/U = get_turf(target)
	if(!istype(T) || !istype(U))
		return

	update_icon()
	var/obj/projectile/A = new lethal_projectile(T)
	playsound(loc, lethal_projectile_sound, 75, TRUE)

	A.preparePixelProjectile(target, T)
	A.firer = src
	A.fired_from = src
	A.fire()
	return A

/obj/machinery/porta_turret/corrosive/attackby(obj/item/I, mob/user, params)
	// Refill with acid canister
	if(istype(I, /obj/item/rce_canister/acid))
		var/obj/item/rce_canister/acid/can = I
		var/transfer = min(can.current_amount, max_acid_storage - acid_storage)
		if(transfer <= 0)
			to_chat(user, span_warning("[src]'s acid tank is full!"))
			return TRUE

		can.current_amount -= transfer
		acid_storage += transfer
		to_chat(user, span_notice("You refill [src] with [transfer] acid."))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
		return TRUE

	// Dismantle with crowbar
	if(I.tool_behaviour == TOOL_CROWBAR)
		to_chat(user, span_notice("You begin dismantling [src]..."))
		playsound(src, 'sound/items/crowbar.ogg', 50, TRUE)

		if(!do_after(user, 3 SECONDS, target = src))
			to_chat(user, span_warning("You stop dismantling [src]."))
			return TRUE

		to_chat(user, span_notice("You dismantle [src]."))
		// Preserve acid storage in the deployable
		var/obj/item/corrosive_turret_deployable/deployable = new(get_turf(src))
		deployable.stored_acid = acid_storage
		qdel(src)
		return TRUE

	return ..()

// AUTO ACID SPRAYER - Tier 2 Automatic Defense (Venom Branch)
// Projectile for automatic acid sprayer
/obj/projectile/acid_shot
	name = "acid spray"
	icon_state = "toxin"
	damage = 75
	damage_type = TOX
	color = "#00FF00"
	range = 6

/obj/projectile/acid_shot/on_hit(atom/target, blocked)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		if(!is_venom_immune(L))
			L.apply_venom_stacks()

/obj/item/auto_acid_sprayer
	name = "automatic defense acid sprayer"
	desc = "An automated acid sprayer system that attaches to your suit storage. When activated, it automatically targets and sprays acid at hostile entities within range."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "kineticgun_h"
	color = "#00FF00"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_SUITSTORE
	var/active = FALSE
	var/obj/item/rce_resource_tank/acid_backpack/acid_tank
	var/acid_per_shot = 10
	var/scan_range = 6
	var/last_fired = 0
	var/fire_delay = 5 // 0.5 second between shots
	var/datum/action/item_action/toggle_auto_acid_sprayer/toggle_action
	var/mob/living/carbon/human/wearer

/obj/item/auto_acid_sprayer/Initialize()
	. = ..()
	toggle_action = new(src)

/obj/item/auto_acid_sprayer/Destroy()
	if(active)
		deactivate()
	QDEL_NULL(toggle_action)
	return ..()

/obj/item/auto_acid_sprayer/examine(mob/user)
	. = ..()
	. += span_notice("Status: [active ? "ACTIVE" : "Inactive"]")
	if(acid_tank)
		. += span_notice("Connected to acid tank: [acid_tank.resource_amount]/[acid_tank.max_resource] acid remaining.")
		. += span_notice("Each shot consumes [acid_per_shot] acid.")
	else
		. += span_warning("No acid tank connected! Equip to suit storage to auto-connect.")
	. += span_notice("When worn in suit storage, grants an action button to toggle automatic defense mode.")

/obj/item/auto_acid_sprayer/equipped(mob/user, slot)
	. = ..()
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user

	if(slot == ITEM_SLOT_SUITSTORE)
		wearer = H
		connect_tank()
		toggle_action.Grant(H)
		to_chat(H, span_notice("[src] is ready. Use the action button to activate automatic defense mode."))
	else
		if(wearer)
			if(active)
				deactivate()
			disconnect_tank()
			toggle_action.Remove(wearer)
			wearer = null

/obj/item/auto_acid_sprayer/dropped(mob/user)
	. = ..()
	if(active)
		deactivate()
	if(acid_tank)
		disconnect_tank()
	if(toggle_action && wearer)
		toggle_action.Remove(wearer)
	wearer = null

/obj/item/auto_acid_sprayer/proc/connect_tank()
	if(!wearer)
		return FALSE

	// Try to connect to worn tank
	var/obj/item/rce_resource_tank/acid_backpack/tank = wearer.back
	if(!istype(tank))
		return FALSE

	acid_tank = tank
	to_chat(wearer, span_notice("[src] connects to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/auto_acid_sprayer/proc/disconnect_tank()
	if(acid_tank)
		to_chat(wearer, span_notice("[src] disconnects from [acid_tank]."))
		acid_tank = null

/obj/item/auto_acid_sprayer/proc/activate()
	if(!wearer || !acid_tank)
		if(!acid_tank)
			to_chat(wearer, span_warning("No acid tank connected!"))
		return FALSE

	active = TRUE
	START_PROCESSING(SSobj, src)
	to_chat(wearer, span_danger("Automatic defense system ACTIVATED!"))
	playsound(src, 'sound/machines/synth_yes.ogg', 50, TRUE)
	wearer.add_overlay(mutable_appearance('icons/effects/effects.dmi', "shield-green", ABOVE_MOB_LAYER))
	return TRUE

/obj/item/auto_acid_sprayer/proc/deactivate()
	active = FALSE
	STOP_PROCESSING(SSobj, src)
	if(wearer)
		to_chat(wearer, span_notice("Automatic defense system deactivated."))
		playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE)
		wearer.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "shield-green", ABOVE_MOB_LAYER))

/obj/item/auto_acid_sprayer/process()
	if(!active || !wearer || !acid_tank)
		deactivate()
		return

	// Check if wearer is conscious and able
	if(wearer.stat != CONSCIOUS)
		return

	// Check acid
	if(acid_tank.resource_amount < acid_per_shot)
		if(prob(20)) // Don't spam the message
			to_chat(wearer, span_warning("[src] clicks empty - out of acid!"))
		return

	// Check fire delay
	if(last_fired + fire_delay > world.time)
		return

	// Find targets
	var/list/possible_targets = list()
	for(var/mob/living/simple_animal/hostile/M in range(scan_range, wearer))
		if(M.stat == DEAD)
			continue
		if(!can_see(wearer, M, scan_range))
			continue

		// Check if it's a valid hostile target
		if(istype(M, /mob/living/simple_animal/hostile/greed) || \
		   istype(M, /mob/living/simple_animal/hostile/clan))
			possible_targets += M

	if(!length(possible_targets))
		return

	// Get closest target
	var/mob/living/closest_target = null
	var/closest_distance = INFINITY
	for(var/mob/living/L in possible_targets)
		var/distance = get_dist(wearer, L)
		if(distance < closest_distance)
			closest_distance = distance
			closest_target = L

	if(!closest_target)
		return

	// Fire at target
	fire_at_target(closest_target)

/obj/item/auto_acid_sprayer/proc/fire_at_target(mob/living/target)
	if(!target || !acid_tank || acid_tank.resource_amount < acid_per_shot)
		return

	// Consume acid
	acid_tank.resource_amount -= acid_per_shot
	last_fired = world.time

	// Create projectile
	var/turf/start_turf = get_turf(wearer)
	var/obj/projectile/acid_shot/P = new(start_turf)

	// Fire projectile
	playsound(src, 'sound/effects/spray2.ogg', 30, TRUE)
	P.preparePixelProjectile(target, start_turf)
	P.firer = wearer
	P.fired_from = src
	P.fire()

	// Visual feedback
	wearer.visible_message(
		span_danger("[src] automatically sprays acid at [target]!"),
		span_notice("Your automatic defense system sprays acid at [target]!")
	)

// Toggle action for the automatic acid sprayer
/datum/action/item_action/toggle_auto_acid_sprayer
	name = "Toggle Automatic Defense"
	desc = "Activate or deactivate the automatic acid sprayer defense system."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"

/datum/action/item_action/toggle_auto_acid_sprayer/Trigger()
	if(!istype(target, /obj/item/auto_acid_sprayer))
		return

	var/obj/item/auto_acid_sprayer/sprayer = target
	if(sprayer.active)
		sprayer.deactivate()
	else
		sprayer.activate()
	return TRUE
