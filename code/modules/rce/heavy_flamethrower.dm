// Heavy Flamethrower System for RCE
// A powerful flamethrower that requires a fuel tank backpack to operate

// Fuel Tank Backpack
/obj/item/rce_resource_tank/fuel_backpack
	name = "heavy fuel tank"
	desc = "A large fuel tank designed to be worn on the back. Powers heavy flamethrower weapons."
	icon = 'icons/obj/tank.dmi'
	icon_state = "rce_fuel"
	worn_icon = 'icons/mob/clothing/back.dmi'

	// Resource configuration
	resource_name = "fuel"
	resource_unit = "units"
	resource_amount = 1000
	max_resource = 1000

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
	var/fuel_amount = 1000
	var/max_fuel = 1000
	var/obj/item/ego_weapon/ranged/heavy_flamethrower/linked_weapon

/obj/item/fuel_tank_backpack/Destroy()
	Unlink()
	return ..()

/obj/item/fuel_tank_backpack/examine(mob/user)
	. = ..()
	. += span_notice("Fuel: [fuel_amount]/[max_fuel]")
	if(fuel_amount < max_fuel)
		. += span_notice("It can be refilled at a fuel tank.")

/obj/item/fuel_tank_backpack/dropped(mob/user)
	. = ..()
	if(linked_weapon)
		to_chat(user, span_warning("The flamethrower's fuel line disconnects!"))
		Unlink()

/obj/item/fuel_tank_backpack/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/fuel_tank_backpack))
		var/obj/item/fuel_tank_backpack/other_tank = I
		if(other_tank.fuel_amount <= 0)
			to_chat(user, span_warning("[other_tank] is empty!"))
			return
		if(fuel_amount >= max_fuel)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/transfer_amount = min(other_tank.fuel_amount, max_fuel - fuel_amount)
		fuel_amount += transfer_amount
		other_tank.fuel_amount -= transfer_amount
		to_chat(user, span_notice("You transfer [transfer_amount] units of fuel from [other_tank] to [src]."))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
		return
	return ..()

/obj/item/fuel_tank_backpack/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!proximity)
		return

	// Refill from fuel dispensers
	if(istype(target, /obj/structure/reagent_dispensers/fueltank))
		if(fuel_amount >= max_fuel)
			to_chat(user, span_warning("[src] is already full!"))
			return
		var/obj/structure/reagent_dispensers/fueltank/F = target
		if(!F.reagents.has_reagent(/datum/reagent/fuel))
			to_chat(user, span_warning("[F] is out of fuel!"))
			return
		var/fuel_needed = max_fuel - fuel_amount
		var/fuel_available = F.reagents.get_reagent_amount(/datum/reagent/fuel)
		var/fuel_to_transfer = min(fuel_needed, fuel_available)
		F.reagents.remove_reagent(/datum/reagent/fuel, fuel_to_transfer)
		fuel_amount += fuel_to_transfer
		user.visible_message(span_notice("[user] refills [src] from [F]."), span_notice("You refill [src] from [F]."))
		playsound(src, 'sound/effects/refill.ogg', 50, TRUE)

/obj/item/fuel_tank_backpack/proc/Link(atom/linkee)
	if(linked_weapon)
		Unlink(linked_weapon)
	RegisterSignal(linkee, COMSIG_PARENT_QDELETING, PROC_REF(Unlink))
	linked_weapon = linkee

/obj/item/fuel_tank_backpack/proc/Unlink()
	if(linked_weapon)
		UnregisterSignal(linked_weapon, COMSIG_PARENT_QDELETING)
		linked_weapon.fuel_tank = null
		linked_weapon = null

// Heavy Flamethrower Weapon
/obj/item/ego_weapon/ranged/heavy_flamethrower
	name = "heavy flamethrower"
	desc = "An industrial-grade flamethrower that requires a fuel tank backpack to operate. Sprays burning fuel that ignites everything in its path."
	special = "Requires a fuel tank backpack to fire. Projectiles pierce through targets and have a chance to ignite the ground."
	icon = 'icons/obj/flamethrower.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/flamethrower_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/flamethrower_righthand.dmi'
	icon_state = "flamethrower1"
	inhand_icon_state = "flamethrower_1"
	projectile_path = /obj/projectile/ego_bullet/heavy_flame
	weapon_weight = WEAPON_HEAVY
	spread = 40
	fire_sound = 'sound/effects/burn.ogg'
	autofire = 0.08 SECONDS
	fire_sound_volume = 10
	var/fuel_per_shot = 5
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank

/obj/item/ego_weapon/ranged/heavy_flamethrower/Destroy()
	if(fuel_tank)
		Disconnect()
	return ..()

/obj/item/ego_weapon/ranged/heavy_flamethrower/Destroy()
	if(fuel_tank)
		Disconnect()
	return ..()

/obj/item/ego_weapon/ranged/heavy_flamethrower/examine(mob/user)
	. = ..()
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.resource_amount]/[fuel_tank.max_resource] fuel remaining.")
	else
		. += span_warning("No fuel tank connected! Use in-hand to connect to a worn fuel tank.")

/obj/item/ego_weapon/ranged/heavy_flamethrower/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	// Check if already connected
	if(fuel_tank)
		// Disconnect current tank
		fuel_tank.linked_weapon = null
		to_chat(user, span_notice("You disconnect [fuel_tank] from [src]."))
		fuel_tank = null
		return TRUE

	// Try to connect to worn tank
	var/obj/item/rce_resource_tank/fuel_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear a fuel tank backpack first!"))
		return FALSE

	if(tank.linked_weapon && tank.linked_weapon != src)
		to_chat(user, span_warning("[tank] is already connected to another weapon!"))
		return FALSE

	// Connect to tank
	fuel_tank = tank
	tank.linked_weapon = src
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/ranged/heavy_flamethrower/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/ranged/heavy_flamethrower/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/ranged/heavy_flamethrower/dropped(mob/user)
	. = ..()
	if(fuel_tank)
		Disconnect()
		to_chat(user, span_warning("The flamethrower's fuel line disconnects!"))


/obj/item/ego_weapon/ranged/heavy_flamethrower/can_shoot()
	if(!fuel_tank)
		return FALSE
	if(fuel_tank.resource_amount < fuel_per_shot)
		return FALSE
	return TRUE

/obj/item/ego_weapon/ranged/heavy_flamethrower/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	if(!can_shoot())
		if(!fuel_tank)
			to_chat(user, span_warning("You need to wear a fuel tank backpack!"))
		else
			to_chat(user, span_warning("The fuel tank is empty!"))
		return FALSE

	fuel_tank.resource_amount -= fuel_per_shot
	return ..()

/obj/item/ego_weapon/ranged/heavy_flamethrower/proc/Disconnect()
	if(fuel_tank)
		fuel_tank.Unlink()

// Heavy Flame Projectile
/obj/projectile/ego_bullet/heavy_flame
	name = "heavy flames"
	icon_state = "flamethrower_fire"
	damage = 8
	damage_type = FIRE
	speed = 1.5
	range = 7
	hitsound_wall = 'sound/weapons/tap.ogg'
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser
	projectile_piercing = PASSMOB
	var/fire_chance = 20

/obj/projectile/ego_bullet/heavy_flame/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		// Check for Hellfire immunity
		if(L.has_status_effect(/datum/status_effect/specialist_class))
			var/datum/status_effect/specialist_class/SC = L.has_status_effect(/datum/status_effect/specialist_class)
			if(SC.specialist_type == SPECIALIST_HELLFIRE)
				return // Hellfire users are immune
		L.apply_lc_burn(3)

	// Enhanced fire for structures
	if(isstructure(target))
		var/obj/structure/S = target
		S.take_damage(damage * 2, FIRE) // Double damage vs structures
		if(istype(S, /obj/structure/seed_of_greed))
			S.take_damage(damage * 3, FIRE) // Triple vs Seed of Greed

/obj/projectile/ego_bullet/heavy_flame/Move(atom/newloc, dir = 0)
	. = ..()
	if(. && isturf(newloc))
		// Higher chance and longer duration for Hellfire users
		var/enhanced_fire = FALSE
		if(firer && ishuman(firer))
			var/mob/living/carbon/human/H = firer
			if(H.has_status_effect(/datum/status_effect/specialist_class))
				var/datum/status_effect/specialist_class/SC = H.has_status_effect(/datum/status_effect/specialist_class)
				if(SC.specialist_type == SPECIALIST_HELLFIRE)
					enhanced_fire = TRUE

		if(enhanced_fire)
			if(prob(50)) // 50% chance for Hellfire
				var/turf/T = newloc
				new /obj/effect/persistent_fire(T, 30 SECONDS)
		else
			if(prob(fire_chance))
				var/turf/T = newloc
				if(!locate(/obj/effect/rcorp_fire) in T)
					new /obj/effect/rcorp_fire(T)

/obj/item/clothing/suit/armor/ego_gear/hellfire
	name = "r-corp hellfire rooster suit"
	desc = "Custom armor made for the hellfire units, perfect at protecting the user from flames. Requires Hellfire Rooster combat implant."
	slowdown = 0.5
	icon = 'icons/obj/clothing/suits.dmi'
	worn_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "hunter"
	inhand_icon_state = "hostrench"
	armor = list(RED_DAMAGE = 50, WHITE_DAMAGE = 30, BLACK_DAMAGE = 30, PALE_DAMAGE = 30, FIRE = 100)
	hat = /obj/item/clothing/head/ego_hat/helmet/hellfire

/obj/item/clothing/suit/armor/ego_gear/hellfire/mob_can_equip(mob/living/M, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(!ishuman(M))
		return FALSE

	var/mob/living/carbon/human/H = M
	// Check for Hellfire Rooster implant
	if(!locate(/obj/item/organ/cyberimp/rce_specialist/hellfire) in H.internal_organs)
		if(!disable_warning)
			to_chat(H, span_warning("You need the Hellfire Rooster combat implant to use this armor!"))
		return FALSE

	return ..()

/obj/item/clothing/head/ego_hat/helmet/hellfire
	name = "r-corp hellfire rooster helmet"
	desc = "A custom made helmet worn by hellfire roosters."
	icon = 'icons/obj/clothing/masks.dmi'
	worn_icon = 'icons/mob/clothing/mask.dmi'
	icon_state = "hunter"
	inhand_icon_state = "hunter"
	resistance_flags = FIRE_PROOF | ACID_PROOF
	flags_inv = HIDEFACIALHAIR|HIDEFACE|HIDEEYES|HIDEEARS|HIDEHAIR|HIDESNOUT

/obj/item/grenade/r_corp/pyro
	name = "r-corp pyro grenade"
	desc = "An incendiary grenade that sets everything ablaze. Highly effective against biological targets."
	explosion_damage = 100 // Half the normal damage
	carbon_damagemod = 0.2 // Still reduced damage to humans

/obj/item/grenade/r_corp/pyro/detonate(mob/living/lanced_by)
	// Apply burn and create fire
	for(var/turf/T in view(explosion_range, src))
		if(!locate(/obj/effect/rcorp_fire) in T)
			new /obj/effect/rcorp_fire(T)
		for(var/mob/living/L in T)
			L.apply_lc_burn(30)
	. = ..()

/obj/effect/rcorp_fire
	gender = PLURAL
	name = "heavy fire"
	desc = "a burning pyre."
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	base_icon_state = "turf_fire"
	var/damaging = FALSE

/obj/effect/rcorp_fire/Initialize()
	. = ..()
	QDEL_IN(src, 15 SECONDS)

//Red and not burn, burn is a special damage type.
/obj/effect/rcorp_fire/Crossed(atom/movable/AM)
	. = ..()
	if(!damaging)
		damaging = TRUE
		DoDamage()

/obj/effect/rcorp_fire/proc/DoDamage()
	var/dealt_damage = FALSE
	for(var/mob/living/L in get_turf(src))
		L.deal_damage(6, FIRE)
		L.apply_lc_burn(2)
		dealt_damage = TRUE
	if(!dealt_damage)
		damaging = FALSE
		return
	addtimer(CALLBACK(src, PROC_REF(DoDamage)), 4)

// Inferno Rush Blade - Pyro melee weapon with dash ability
/obj/item/ego_weapon/inferno_rush
	name = "inferno rush blade"
	desc = "A superheated blade that can channel fuel for devastating fire dashes. The blade glows with an inner heat that never fades."
	special = "Use in hand to connect to a fuel tank. Use afterattack to perform a fire dash that consumes fuel."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "contractor_baton_1"
	inhand_icon_state = "contractor_baton_1"
	lefthand_file = 'icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/melee_righthand.dmi'
	force = 35
	damtype = RED_DAMAGE
	attack_verb_continuous = list("burns", "sears", "scorches")
	attack_verb_simple = list("burn", "sear", "scorch")
	hitsound = 'sound/weapons/fixer/generic/sword3.ogg'
	var/fuel_per_dash = 50
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank
	var/dash_cooldown = 0
	var/dash_cooldown_time = 1 SECONDS
	var/dash_damage = 60
	var/dash_range = 7
	var/dashing = FALSE
	var/list/been_hit = list()

/obj/item/ego_weapon/inferno_rush/examine(mob/user)
	. = ..()
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.resource_amount]/[fuel_tank.max_resource] fuel remaining.")
		. += span_notice("Each fire dash consumes [fuel_per_dash] fuel.")
	else
		. += span_warning("No fuel tank connected! Use in-hand to connect to a worn fuel tank.")

/obj/item/ego_weapon/inferno_rush/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	// Check if already connected
	if(fuel_tank)
		// Disconnect current tank
		fuel_tank.linked_weapon = null
		to_chat(user, span_notice("You disconnect [fuel_tank] from [src]."))
		fuel_tank = null
		return TRUE

	// Try to connect to worn tank
	var/obj/item/rce_resource_tank/fuel_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear a fuel tank backpack first!"))
		return FALSE

	if(tank.linked_weapon && tank.linked_weapon != src)
		to_chat(user, span_warning("[tank] is already connected to another weapon!"))
		return FALSE

	// Connect to tank
	fuel_tank = tank
	tank.linked_weapon = src
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/inferno_rush/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/inferno_rush/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/inferno_rush/dropped(mob/user)
	. = ..()
	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_warning("The blade's fuel line disconnects!"))
		fuel_tank = null

/obj/item/ego_weapon/inferno_rush/afterattack(atom/A, mob/living/user, proximity_flag, params)
	// Don't dash if we're already dashing or on cooldown
	if(dashing || dash_cooldown > world.time)
		return ..()

	// Check for fuel
	if(!fuel_tank || fuel_tank.resource_amount < fuel_per_dash)
		if(!fuel_tank)
			to_chat(user, span_warning("No fuel tank connected!"))
		else
			to_chat(user, span_warning("Not enough fuel! Need [fuel_per_dash] fuel."))
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
	fuel_tank.resource_amount -= fuel_per_dash
	dash_cooldown = world.time + dash_cooldown_time
	FireDash(user, target_turf)

/obj/item/ego_weapon/inferno_rush/proc/FireDash(mob/living/user, turf/target)
	if(!user || !target)
		return

	dashing = TRUE
	been_hit = list()
	var/dir_to_target = get_dir(user, target)

	// Visual and audio feedback
	playsound(user, 'sound/effects/burn.ogg', 75, TRUE)
	user.visible_message(span_danger("[user] ignites and rushes forward in a blaze of fire!"), span_notice("You channel the fuel into a burning dash!"))

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

		// Create enhanced fire effects for Hellfire users
		if(user.has_status_effect(/datum/status_effect/specialist_class))
			var/datum/status_effect/specialist_class/SC = user.has_status_effect(/datum/status_effect/specialist_class)
			if(SC.specialist_type == SPECIALIST_HELLFIRE)
				new /obj/effect/persistent_fire(T, 30 SECONDS) // Long lasting fire
				// Create wider fire spread
				for(var/turf/spread in orange(1, T))
					if(prob(40))
						new /obj/effect/persistent_fire(spread, 15 SECONDS)
		else
			if(!locate(/obj/effect/rcorp_fire) in T)
				new /obj/effect/rcorp_fire(T)

		// Damage enemies in the turf and adjacent turfs
		for(var/turf/adjacent in view(1, T))
			new /obj/effect/temp_visual/fire/fast(T)
			for(var/mob/living/L in adjacent)
				if(L == user || (L in been_hit))
					continue
				// Check for Hellfire immunity
				if(L.has_status_effect(/datum/status_effect/specialist_class))
					var/datum/status_effect/specialist_class/SC = L.has_status_effect(/datum/status_effect/specialist_class)
					if(SC.specialist_type == SPECIALIST_HELLFIRE)
						continue // Hellfire users are immune
				L.visible_message(span_boldwarning("[user] blazes through [L]!"))
				L.deal_damage(dash_damage, FIRE)
				L.apply_lc_burn(10)
				new /obj/effect/temp_visual/cleave(get_turf(L))
				been_hit += L

		// Small delay between movements for visual effect
		sleep(1)

	// End dash
	playsound(user, 'sound/effects/bamf.ogg', 50, TRUE)
	dashing = FALSE
	been_hit = list()

// Thermite Sprayer - Delayed explosion area denial
/obj/item/ego_weapon/thermite_sprayer
	name = "thermite sprayer"
	desc = "Sprays volatile thermite gel that sticks to surfaces and detonates after a short delay. Excellent for area denial."
	special = "Use afterattack to spray thermite that explodes after 2 seconds. Use in hand to connect fuel tank."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "mister"
	inhand_icon_state = "mister"
	lefthand_file = 'icons/mob/inhands/equipment/mister_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/mister_righthand.dmi'
	force = 10
	throwforce = 5
	var/fuel_per_spray = 20
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank
	var/spray_cooldown = 0
	var/spray_cooldown_time = 1 SECONDS
	var/spray_range = 3

/obj/item/ego_weapon/thermite_sprayer/examine(mob/user)
	. = ..()
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.resource_amount]/[fuel_tank.max_resource] fuel remaining.")
		. += span_notice("Each thermite spray consumes [fuel_per_spray] fuel.")
	else
		. += span_warning("No fuel tank connected! Use in-hand to connect to a worn fuel tank.")

/obj/item/ego_weapon/thermite_sprayer/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_notice("You disconnect [fuel_tank] from [src]."))
		fuel_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/fuel_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear a fuel tank backpack first!"))
		return FALSE

	if(tank.linked_weapon && tank.linked_weapon != src)
		to_chat(user, span_warning("[tank] is already connected to another weapon!"))
		return FALSE

	fuel_tank = tank
	tank.linked_weapon = src
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/thermite_sprayer/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/thermite_sprayer/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/thermite_sprayer/dropped(mob/user)
	. = ..()
	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_warning("The sprayer's fuel line disconnects!"))
		fuel_tank = null

/obj/item/ego_weapon/thermite_sprayer/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(spray_cooldown > world.time)
		return ..()

	if(!fuel_tank || fuel_tank.resource_amount < fuel_per_spray)
		if(!fuel_tank)
			to_chat(user, span_warning("No fuel tank connected!"))
		else
			to_chat(user, span_warning("Not enough fuel! Need [fuel_per_spray] fuel."))
		return ..()

	var/turf/target_turf = get_turf(target)
	if(!istype(target_turf))
		return ..()

	if(get_dist(user, target_turf) > spray_range)
		to_chat(user, span_warning("Target is too far! Maximum range is [spray_range] tiles."))
		return ..()

	// Spray thermite
	fuel_tank.resource_amount -= fuel_per_spray
	spray_cooldown = world.time + spray_cooldown_time

	playsound(user, 'sound/effects/spray2.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] sprays thermite gel at [target]!"), span_notice("You spray thermite gel at [target]."))

	// Create thermite glob
	new /obj/effect/thermite_glob(target_turf, user)

// Thermite glob effect
/obj/effect/thermite_glob
	name = "thermite gel"
	desc = "A glob of highly volatile thermite gel. It's sparking ominously..."
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"
	anchored = TRUE
	var/detonate_time = 2 SECONDS
	var/mob/living/owner

/obj/effect/thermite_glob/Initialize(mapload, mob/living/user)
	. = ..()
	owner = user
	addtimer(CALLBACK(src, PROC_REF(detonate)), detonate_time)
	animate(src, alpha = 255, color = "#FF4444", time = detonate_time - 5)

/obj/effect/thermite_glob/proc/detonate()
	playsound(src, 'sound/effects/explosion1.ogg', 75, TRUE)
	new /obj/effect/temp_visual/explosion(loc)

	// Create 3x3 fire zone
	for(var/turf/T in range(1, src))
		new /obj/effect/thermite_fire(T)
		for(var/mob/living/L in T)
			L.deal_damage(80, FIRE)
			L.apply_lc_burn(15)

	qdel(src)

// Long-lasting thermite fire
/obj/effect/thermite_fire
	name = "thermite fire"
	desc = "Intensely hot thermite fire that burns through anything."
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	var/damaging = FALSE

/obj/effect/thermite_fire/Initialize()
	. = ..()
	color = "#FF6600"
	QDEL_IN(src, 20 SECONDS)

/obj/effect/thermite_fire/Crossed(atom/movable/AM)
	. = ..()
	if(!damaging)
		damaging = TRUE
		DoDamage()

/obj/effect/thermite_fire/proc/DoDamage()
	var/dealt_damage = FALSE
	for(var/mob/living/L in get_turf(src))
		L.deal_damage(10, FIRE)
		L.apply_lc_burn(3)
		dealt_damage = TRUE
	if(!dealt_damage)
		damaging = FALSE
		return
	addtimer(CALLBACK(src, PROC_REF(DoDamage)), 3)

// Inferno Wall Projector - Creates defensive fire barriers
/obj/item/ego_weapon/inferno_wall
	name = "inferno wall projector"
	desc = "Projects a wall of intense flames to block enemy advance. The wall orientation can be toggled."
	special = "Use afterattack to create a fire wall. Use in hand to toggle wall orientation and connect fuel tank."
	icon = 'icons/obj/device.dmi'
	icon_state = "firing_pin_loyalty"
	force = 15
	throwforce = 10
	var/fuel_per_wall = 100
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank
	var/wall_cooldown = 0
	var/wall_cooldown_time = 10 SECONDS
	var/wall_orientation = "horizontal" // horizontal or vertical
	var/wall_length = 5

/obj/item/ego_weapon/inferno_wall/examine(mob/user)
	. = ..()
	. += span_notice("Current orientation: [wall_orientation]")
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.resource_amount]/[fuel_tank.max_resource] fuel remaining.")
		. += span_notice("Each wall consumes [fuel_per_wall] fuel.")
	else
		. += span_warning("No fuel tank connected!")

/obj/item/ego_weapon/inferno_wall/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_notice("You disconnect [fuel_tank] from [src]."))
		fuel_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/fuel_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear a fuel tank backpack first!"))
		return FALSE

	if(tank.linked_weapon && tank.linked_weapon != src)
		to_chat(user, span_warning("[tank] is already connected to another weapon!"))
		return FALSE

	fuel_tank = tank
	tank.linked_weapon = src
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/inferno_wall/attack_self(mob/user)
	. = ..()
	if(!fuel_tank)
		connect_tank(user)
	else
		// Toggle orientation
		if(wall_orientation == "horizontal")
			wall_orientation = "vertical"
		else
			wall_orientation = "horizontal"
		to_chat(user, span_notice("Wall orientation set to [wall_orientation]."))
		playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)

/obj/item/ego_weapon/inferno_wall/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/inferno_wall/dropped(mob/user)
	. = ..()
	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_warning("The projector's fuel line disconnects!"))
		fuel_tank = null

/obj/item/ego_weapon/inferno_wall/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(wall_cooldown > world.time)
		to_chat(user, span_warning("Wall projector is recharging! ([round((wall_cooldown - world.time) / 10)] seconds remaining)"))
		return ..()

	if(!fuel_tank || fuel_tank.resource_amount < fuel_per_wall)
		if(!fuel_tank)
			to_chat(user, span_warning("No fuel tank connected!"))
		else
			to_chat(user, span_warning("Not enough fuel! Need [fuel_per_wall] fuel."))
		return ..()

	var/turf/target_turf = get_turf(target)
	if(!istype(target_turf))
		return ..()

	if(get_dist(user, target_turf) > 5)
		to_chat(user, span_warning("Target is too far!"))
		return ..()

	// Create fire wall
	fuel_tank.resource_amount -= fuel_per_wall
	wall_cooldown = world.time + wall_cooldown_time

	playsound(user, 'sound/magic/fireball.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] projects a wall of fire!"), span_notice("You project a wall of fire!"))

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

	// Create fire wall segments
	for(var/turf/T in wall_tiles)
		new /obj/effect/inferno_wall_segment(T)

// Fire wall segment
/obj/effect/inferno_wall_segment
	name = "wall of flames"
	desc = "An intense wall of fire that blocks passage."
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	anchored = TRUE
	density = TRUE
	opacity = FALSE
	layer = ABOVE_MOB_LAYER
	var/damaging = FALSE

/obj/effect/inferno_wall_segment/Initialize()
	. = ..()
	color = "#FF3300"
	set_light(3, 2, "#FF6600")
	QDEL_IN(src, 10 SECONDS)

/obj/effect/inferno_wall_segment/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		L.deal_damage(30, FIRE)
		L.apply_lc_burn(5)
		to_chat(L, span_userdanger("You are burned by the wall of flames!"))

/obj/effect/inferno_wall_segment/Bumped(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		L.deal_damage(20, FIRE)
		L.apply_lc_burn(3)
		to_chat(L, span_danger("The wall of flames burns you!"))

/obj/effect/inferno_wall_segment/attack_hand(mob/living/user)
	. = ..()
	user.deal_damage(25, FIRE)
	user.apply_lc_burn(3)
	to_chat(user, span_danger("You burn your hand on the wall of flames!"))

// Napalm Launcher - Long range bombardment weapon
/obj/item/ego_weapon/ranged/napalm_launcher
	name = "napalm launcher"
	desc = "A heavy launcher that fires arcing napalm shells, creating persistent fire zones. Requires setup before firing."
	special = "Click far targets to fire arcing shells. Minimum range 5 tiles. Use in hand to connect fuel tank."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "rocketlauncher"
	inhand_icon_state = "rocketlauncher"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	force = 20
	projectile_path = /obj/projectile/napalm_shell
	fire_sound = 'sound/weapons/gun/general/rocket_launch.ogg'
	zoomable = TRUE
	zoom_amt = 10
	zoom_out_amt = 13
	var/fuel_per_shot = 75
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank
	var/setup_time = 2 SECONDS
	var/min_range = 5
	var/max_range = 15

/obj/item/ego_weapon/ranged/napalm_launcher/examine(mob/user)
	. = ..()
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.resource_amount]/[fuel_tank.max_resource] fuel remaining.")
		. += span_notice("Each shell consumes [fuel_per_shot] fuel.")
	else
		. += span_warning("No fuel tank connected! Use in-hand to connect to a worn fuel tank.")

/obj/item/ego_weapon/ranged/napalm_launcher/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_notice("You disconnect [fuel_tank] from [src]."))
		fuel_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/fuel_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear a fuel tank backpack first!"))
		return FALSE

	if(tank.linked_weapon && tank.linked_weapon != src)
		to_chat(user, span_warning("[tank] is already connected to another weapon!"))
		return FALSE

	fuel_tank = tank
	tank.linked_weapon = src
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/ranged/napalm_launcher/attack_self(mob/user)
	. = ..()
	connect_tank(user)

/obj/item/ego_weapon/ranged/napalm_launcher/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/ranged/napalm_launcher/dropped(mob/user)
	. = ..()
	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_warning("The launcher's fuel line disconnects!"))
		fuel_tank = null

/obj/item/ego_weapon/ranged/napalm_launcher/can_shoot()
	if(!fuel_tank)
		return FALSE
	if(fuel_tank.resource_amount < fuel_per_shot)
		return FALSE
	return TRUE

/obj/item/ego_weapon/ranged/napalm_launcher/before_firing(atom/target, mob/user)
	var/distance = get_dist(user, target)
	if(distance < min_range)
		to_chat(user, span_warning("Target is too close! Minimum range is [min_range] tiles."))
		return FALSE
	if(distance > max_range)
		to_chat(user, span_warning("Target is too far! Maximum range is [max_range] tiles."))
		return FALSE

	if(!do_after(user, setup_time, target = user))
		to_chat(user, span_warning("You fail to set up the launcher."))
		return FALSE

	to_chat(user, span_notice("launcher ready to fire!"))
	return TRUE

/obj/item/ego_weapon/ranged/napalm_launcher/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	if(!can_shoot())
		if(!fuel_tank)
			to_chat(user, span_warning("No fuel tank connected!"))
		else
			to_chat(user, span_warning("Not enough fuel!"))
		return FALSE

	fuel_tank.resource_amount -= fuel_per_shot
	return ..()

// Napalm shell projectile
/obj/projectile/napalm_shell
	name = "napalm shell"
	icon_state = "missile"
	damage = 80
	damage_type = FIRE
	speed = 2
	range = 15

/obj/projectile/napalm_shell/on_hit(atom/target, blocked = FALSE)
	. = ..()
	// Create 5x5 napalm fire zone
	for(var/turf/T in range(2, target))
		new /obj/effect/napalm_fire(T)
		for(var/mob/living/L in T)
			L.deal_damage(50, FIRE)
			L.apply_lc_burn(15)

// Long-lasting napalm fire
/obj/effect/napalm_fire
	name = "napalm fire"
	desc = "Sticky napalm that burns for a very long time."
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	var/damaging = FALSE

/obj/effect/napalm_fire/Initialize()
	. = ..()
	color = "#FF9900"
	set_light(2, 1, "#FF6600")
	QDEL_IN(src, 30 SECONDS)

/obj/effect/napalm_fire/Crossed(atom/movable/AM)
	. = ..()
	if(!damaging)
		damaging = TRUE
		DoDamage()

/obj/effect/napalm_fire/proc/DoDamage()
	var/dealt_damage = FALSE
	for(var/mob/living/L in get_turf(src))
		L.deal_damage(8, FIRE)
		L.apply_lc_burn(4)
		dealt_damage = TRUE
	if(!dealt_damage)
		damaging = FALSE
		return
	addtimer(CALLBACK(src, PROC_REF(DoDamage)), 2)

// Pyroclastic Burst Gauntlets - Melee weapon with fiery AoE bursts
/obj/item/ego_weapon/pyroclastic_gauntlets
	name = "pyroclastic burst gauntlets"
	desc = "Heavy gauntlets that channel fuel into explosive fire bursts. Each strike has a chance to ignite the area."
	special = "Use in hand to toggle Ignition Mode. In Ignition Mode, attacks create fire bursts but consume fuel."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "concussive_gauntlets"
	worn_icon = 'icons/mob/clothing/hands.dmi'
	inhand_icon_state = "concussive_gauntlets"
	force = 25
	damtype = RED_DAMAGE
	attack_verb_continuous = list("punches", "smashes", "crushes")
	attack_verb_simple = list("punch", "smash", "crush")
	hitsound = 'sound/weapons/punch3.ogg'
	var/fuel_per_burst = 30
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank
	var/ignition_mode = FALSE
	var/ignition_damage_bonus = 15

/obj/item/ego_weapon/pyroclastic_gauntlets/examine(mob/user)
	. = ..()
	. += span_notice("Current mode: [ignition_mode ? "IGNITION" : "Normal"]")
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.resource_amount]/[fuel_tank.max_resource] fuel remaining.")
		if(ignition_mode)
			. += span_notice("Ignition Mode: Each attack consumes [fuel_per_burst] fuel for guaranteed fire burst.")
	else
		. += span_warning("No fuel tank connected! Use in-hand to connect to a worn fuel tank.")

/obj/item/ego_weapon/pyroclastic_gauntlets/proc/connect_tank(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("You can't use this!"))
		return FALSE

	var/mob/living/carbon/human/H = user

	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_notice("You disconnect [fuel_tank] from [src]."))
		fuel_tank = null
		return TRUE

	var/obj/item/rce_resource_tank/fuel_backpack/tank = H.back
	if(!istype(tank))
		to_chat(user, span_warning("You need to wear a fuel tank backpack first!"))
		return FALSE

	if(tank.linked_weapon && tank.linked_weapon != src)
		to_chat(user, span_warning("[tank] is already connected to another weapon!"))
		return FALSE

	fuel_tank = tank
	tank.linked_weapon = src
	to_chat(user, span_notice("You connect [src] to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/ego_weapon/pyroclastic_gauntlets/attack_self(mob/user)
	. = ..()
	if(!fuel_tank)
		connect_tank(user)
	else
		// Toggle ignition mode
		ignition_mode = !ignition_mode
		if(ignition_mode)
			to_chat(user, span_danger("IGNITION MODE ACTIVATED! Your attacks will create fire bursts!"))
			playsound(src, 'sound/effects/burn.ogg', 50, TRUE)
		else
			to_chat(user, span_notice("Ignition mode deactivated."))
			playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)

/obj/item/ego_weapon/pyroclastic_gauntlets/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		connect_tank(user)

/obj/item/ego_weapon/pyroclastic_gauntlets/dropped(mob/user)
	. = ..()
	if(fuel_tank)
		fuel_tank.linked_weapon = null
		to_chat(user, span_warning("The gauntlets' fuel line disconnects!"))
		fuel_tank = null
	ignition_mode = FALSE

/obj/item/ego_weapon/pyroclastic_gauntlets/attack(mob/living/target, mob/living/user)
	. = ..()
	if(!. || !target)
		return

	var/create_burst = FALSE

	// Check if we should create a fire burst
	if(ignition_mode && fuel_tank && fuel_tank.resource_amount >= fuel_per_burst)
		// Ignition mode: guaranteed burst, costs fuel
		fuel_tank.resource_amount -= fuel_per_burst
		create_burst = TRUE
		target.deal_damage(ignition_damage_bonus, FIRE)

	if(create_burst)
		FireBurst(target, user, ignition_mode)

/obj/item/ego_weapon/pyroclastic_gauntlets/proc/FireBurst(atom/target, mob/user, empowered = FALSE)
	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return

	playsound(target_turf, 'sound/effects/explosion2.ogg', 50, TRUE)
	new /obj/effect/temp_visual/explosion/fast(target_turf)

	// Create fire burst
	var/burst_range = empowered ? 1 : 0
	for(var/turf/T in range(burst_range, target_turf))
		new /obj/effect/temp_visual/fire/fast(T)
		if(empowered && !locate(/obj/effect/rcorp_fire) in T)
			new /obj/effect/rcorp_fire(T)

		for(var/mob/living/L in T)
			if(L == user)
				continue
			var/damage = empowered ? 30 : 15
			L.deal_damage(damage, FIRE)
			L.apply_lc_burn(empowered ? 5 : 2)

// Automatic Defense Flamethrower - Suit storage automated defense system
/obj/item/auto_flamethrower
	name = "automatic defense flamethrower"
	desc = "An automated flamethrower system that attaches to your suit storage. When activated, it automatically targets and fires at hostile entities within range."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "sentry"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_SUITSTORE
	var/active = FALSE
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank
	var/fuel_per_shot = 3
	var/scan_range = 6
	var/last_fired = 0
	var/fire_delay = 10 // 1 second between shots
	var/datum/action/item_action/toggle_auto_flamethrower/toggle_action
	var/mob/living/carbon/human/wearer

/obj/item/auto_flamethrower/Initialize()
	. = ..()
	toggle_action = new(src)

/obj/item/auto_flamethrower/Destroy()
	if(active)
		deactivate()
	QDEL_NULL(toggle_action)
	return ..()

/obj/item/auto_flamethrower/examine(mob/user)
	. = ..()
	. += span_notice("Status: [active ? "ACTIVE" : "Inactive"]")
	if(fuel_tank)
		. += span_notice("Connected to fuel tank: [fuel_tank.resource_amount]/[fuel_tank.max_resource] fuel remaining.")
		. += span_notice("Each shot consumes [fuel_per_shot] fuel.")
	else
		. += span_warning("No fuel tank connected! Equip to suit storage to auto-connect.")
	. += span_notice("When worn in suit storage, grants an action button to toggle automatic defense mode.")

/obj/item/auto_flamethrower/equipped(mob/user, slot)
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

/obj/item/auto_flamethrower/dropped(mob/user)
	. = ..()
	if(active)
		deactivate()
	if(fuel_tank)
		disconnect_tank()
	if(toggle_action && wearer)
		toggle_action.Remove(wearer)
	wearer = null

/obj/item/auto_flamethrower/proc/connect_tank()
	if(!wearer)
		return FALSE

	// Try to connect to worn tank
	var/obj/item/rce_resource_tank/fuel_backpack/tank = wearer.back
	if(!istype(tank))
		return FALSE

	fuel_tank = tank
	to_chat(wearer, span_notice("[src] connects to [tank]."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/obj/item/auto_flamethrower/proc/disconnect_tank()
	if(fuel_tank)
		to_chat(wearer, span_notice("[src] disconnects from [fuel_tank]."))
		fuel_tank = null

/obj/item/auto_flamethrower/proc/activate()
	if(!wearer || !fuel_tank)
		if(!fuel_tank)
			to_chat(wearer, span_warning("No fuel tank connected!"))
		return FALSE

	active = TRUE
	START_PROCESSING(SSobj, src)
	to_chat(wearer, span_danger("Automatic defense system ACTIVATED!"))
	playsound(src, 'sound/machines/synth_yes.ogg', 50, TRUE)
	wearer.add_overlay(mutable_appearance('icons/effects/effects.dmi', "shield2", ABOVE_MOB_LAYER))
	return TRUE

/obj/item/auto_flamethrower/proc/deactivate()
	active = FALSE
	STOP_PROCESSING(SSobj, src)
	if(wearer)
		to_chat(wearer, span_notice("Automatic defense system deactivated."))
		playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE)
		wearer.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "shield2", ABOVE_MOB_LAYER))

/obj/item/auto_flamethrower/process()
	if(!active || !wearer || !fuel_tank)
		deactivate()
		return

	// Check if wearer is conscious and able
	if(wearer.stat != CONSCIOUS)
		return

	// Check fuel
	if(fuel_tank.resource_amount < fuel_per_shot)
		if(prob(20)) // Don't spam the message
			to_chat(wearer, span_warning("[src] clicks empty - out of fuel!"))
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
		if(istype(M, /mob/living/simple_animal/hostile/xcorp) || \
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

/obj/item/auto_flamethrower/proc/fire_at_target(mob/living/target)
	if(!target || !fuel_tank || fuel_tank.resource_amount < fuel_per_shot)
		return

	// Consume fuel
	fuel_tank.resource_amount -= fuel_per_shot
	last_fired = world.time

	// Create projectile
	var/turf/start_turf = get_turf(wearer)
	var/obj/projectile/ego_bullet/heavy_flame/auto/P = new(start_turf)

	// Fire projectile
	playsound(src, 'sound/effects/burn.ogg', 30, TRUE)
	P.preparePixelProjectile(target, start_turf)
	P.firer = wearer
	P.fired_from = src
	P.fire()

	// Visual feedback
	wearer.visible_message(
		span_danger("[src] automatically fires at [target]!"),
		span_notice("Your automatic defense system fires at [target]!")
	)

// Lighter flame projectile for automatic system
/obj/projectile/ego_bullet/heavy_flame/auto
	damage = 5
	fire_chance = 10
	range = 6

// Toggle action for the automatic flamethrower
/datum/action/item_action/toggle_auto_flamethrower
	name = "Toggle Automatic Defense"
	desc = "Activate or deactivate the automatic flamethrower defense system."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"

/datum/action/item_action/toggle_auto_flamethrower/Trigger()
	if(!istype(target, /obj/item/auto_flamethrower))
		return

	var/obj/item/auto_flamethrower/AF = target
	if(AF.active)
		AF.deactivate()
	else
		AF.activate()
