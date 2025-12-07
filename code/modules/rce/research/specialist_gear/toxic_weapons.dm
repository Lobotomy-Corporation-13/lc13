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

// Miasma Barrier Projector - Creates offensive toxic barriers
/obj/item/ego_weapon/miasma_barrier
	name = "miasma barrier projector"
	desc = "Projects a wall of corrosive miasma that poisons enemies who pass through. Perfect for cutting off retreat routes."
	special = "Use afterattack to create a toxic barrier. Use in hand to toggle wall orientation and connect acid tank."
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
		L.deal_damage(25, TOX)
		L.apply_status_effect(/datum/status_effect/venom_stacks, 3) // Heavy stacks for crossing
		to_chat(L, span_userdanger("The toxic miasma burns your lungs!"))

/obj/effect/miasma_barrier_segment/Bumped(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		if(is_venom_immune(L))
			return
		L.deal_damage(15, TOX)
		L.apply_status_effect(/datum/status_effect/venom_stacks, 2)
		to_chat(L, span_danger("The toxic miasma stings you!"))

/obj/effect/miasma_barrier_segment/attack_hand(mob/living/user)
	. = ..()
	if(is_venom_immune(user))
		to_chat(user, span_notice("The miasma doesn't affect you."))
		return
	user.deal_damage(20, TOX)
	user.apply_status_effect(/datum/status_effect/venom_stacks, 2)
	to_chat(user, span_danger("The toxic miasma burns your hand!"))



// Venom Strike Blade - Toxic melee weapon with dash ability
/obj/item/ego_weapon/venom_strike
	name = "venom strike blade"
	desc = "A blade coated with corrosive venom that can channel acid for devastating toxic dashes. The blade drips with deadly poison."
	special = "Use in hand to connect to an acid tank. Use afterattack to perform a venom dash that applies stacks to all enemies hit."
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
	. = ..()
	if(!. || !target)
		return
	// Apply venom stack on regular attacks
	if(!is_venom_immune(target))
		target.apply_status_effect(/datum/status_effect/venom_stacks)

/obj/item/ego_weapon/venom_strike/afterattack(atom/A, mob/living/user, proximity_flag, params)
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
				if(L.has_status_effect(/datum/status_effect/venom_stacks))
					var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
					damage_mult = 1 + (V.stacks * 0.25) // +25% damage per stack
				L.deal_damage(dash_damage * damage_mult, TOX)
				L.apply_status_effect(/datum/status_effect/venom_stacks, 2) // Apply 2 stacks
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
		if(L.has_status_effect(/datum/status_effect/venom_stacks))
			var/datum/status_effect/venom_stacks/V = L.has_status_effect(/datum/status_effect/venom_stacks)
			damage = damage_per_second * (1 + V.stacks * 0.1) // +10% per stack

		L.deal_damage(damage, TOX)

/obj/effect/acid_pool/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		to_chat(L, span_danger("The acid burns your flesh!"))

// Blight Sprayer - Delayed toxic explosion area denial
/obj/item/ego_weapon/blight_sprayer
	name = "blight sprayer"
	desc = "Sprays volatile toxic sludge that sticks to surfaces and erupts into a toxic cloud after a short delay. Excellent for offensive pushes."
	special = "Use afterattack to spray blight that explodes into toxic clouds after 2 seconds. Use in hand to connect acid tank."
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
			L.deal_damage(60, TOX)
			L.apply_status_effect(/datum/status_effect/venom_stacks, 3) // Apply 3 stacks

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
		L.deal_damage(8, TOX)
		L.apply_status_effect(/datum/status_effect/venom_stacks)
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

/obj/item/ego_weapon/ranged/plague_mortar/before_firing(atom/target, mob/user)
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
	return TRUE

/obj/item/ego_weapon/ranged/plague_mortar/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	if(!can_shoot())
		if(!acid_tank)
			to_chat(user, span_warning("No acid tank connected!"))
		else
			to_chat(user, span_warning("Not enough acid!"))
		return FALSE

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
			L.deal_damage(40, TOX)
			L.apply_status_effect(/datum/status_effect/venom_stacks, 4) // Apply 4 stacks for big hit

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
		L.deal_damage(10, TOX)
		L.apply_status_effect(/datum/status_effect/venom_stacks)
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
	. = ..()
	if(!. || !target)
		return

	// Always apply a venom stack on hit
	if(!is_venom_immune(target))
		target.apply_status_effect(/datum/status_effect/venom_stacks)

	var/create_burst = FALSE

	// Check if we should create a venom burst
	if(toxin_mode && acid_tank && acid_tank.resource_amount >= acid_per_burst)
		// Toxin mode: guaranteed burst, costs acid
		acid_tank.resource_amount -= acid_per_burst
		create_burst = TRUE
		// Bonus damage based on venom stacks
		if(!is_venom_immune(target))
			var/damage_mult = 1
			if(target.has_status_effect(/datum/status_effect/venom_stacks))
				var/datum/status_effect/venom_stacks/V = target.has_status_effect(/datum/status_effect/venom_stacks)
				damage_mult = 1 + (V.stacks * 0.2)
			target.deal_damage(toxin_damage_bonus * damage_mult, TOX)

	if(create_burst)
		VenomBurst(target, user, toxin_mode)

/obj/item/ego_weapon/corrosive_gauntlets/proc/VenomBurst(atom/target, mob/user, empowered = FALSE)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	playsound(target_turf, 'sound/effects/venom.ogg', 50, TRUE)
	new /obj/effect/temp_visual/venom_explosion(target_turf)

	// Create venom burst
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
			L.deal_damage(damage, TOX)
			L.apply_status_effect(/datum/status_effect/venom_stacks, empowered ? 2 : 1)

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
	// DoT based on stacks - 5x damage to simple mobs
	var/damage_mult = 1
	if(isanimal(owner))
		damage_mult = 5
	owner.deal_damage(damage_per_tick * stacks * damage_mult, TOX)
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
