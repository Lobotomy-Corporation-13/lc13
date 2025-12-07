// Heavy Flamethrower System for RCE
// A powerful flamethrower that requires a fuel tank backpack to operate

// Helper proc to check if user is a Hellfire Rooster (checks for implant directly)
/proc/is_hellfire_rooster(mob/living/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/cyberimp/rce_specialist/hellfire/implant = locate() in H.internal_organs
	return !!implant

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
		fuel_tank.linked_weapon = null
		to_chat(user, span_warning("The flamethrower's fuel line disconnects!"))
		fuel_tank = null

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
		if(is_hellfire_rooster(L))
			return // Hellfire users are immune
		L.apply_lc_overheat(3)

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
		var/enhanced_fire = is_hellfire_rooster(firer)

		if(enhanced_fire)
			if(prob(50)) // 50% chance for Hellfire
				var/turf/T = newloc
				new /obj/effect/persistent_fire(T, 30 SECONDS)
		else
			if(prob(fire_chance))
				var/turf/T = newloc
				if(!locate(/obj/effect/rcorp_fire) in T)
					new /obj/effect/rcorp_fire(T)

// Persistent fire effect
/obj/effect/persistent_fire
	name = "raging flames"
	desc = "Intense flames that won't go out!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	var/damage_per_second = 20
	var/duration

/obj/effect/persistent_fire/Initialize(mapload, fire_duration = 30 SECONDS)
	. = ..()
	duration = fire_duration
	START_PROCESSING(SSobj, src)
	QDEL_IN(src, duration)

/obj/effect/persistent_fire/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/persistent_fire/process()
	for(var/mob/living/L in get_turf(src))
		// Check for Hellfire immunity
		if(is_hellfire_rooster(L))
			continue // Immune to own flames

		L.deal_damage(damage_per_second, FIRE)
		L.apply_lc_overheat(1)

	// Chance to spread
	if(prob(10))
		SpreadFire()

/obj/effect/persistent_fire/proc/SpreadFire()
	for(var/turf/open/T in orange(1, src))
		if(T.density)
			continue // Don't spread to walls
		if(locate(/obj/effect/persistent_fire) in T)
			continue
		if(prob(30))
			new /obj/effect/persistent_fire(T, duration / 2)

/obj/item/grenade/r_corp/pyro
	name = "r-corp pyro grenade"
	desc = "An incendiary grenade that sets everything ablaze. Highly effective against biological targets."
	icon_state = "pyrog"
	explosion_damage = 100 // Half the normal damage
	carbon_damagemod = 0.2 // Still reduced damage to humans

/obj/item/grenade/r_corp/pyro/detonate(mob/living/lanced_by)
	// Apply burn and create fire
	for(var/turf/T in view(explosion_range, src))
		if(!locate(/obj/effect/rcorp_fire) in T)
			new /obj/effect/rcorp_fire(T)
		for(var/mob/living/L in T)
			L.apply_lc_overheat(30)
	. = ..()

/obj/effect/rcorp_fire
	gender = PLURAL
	name = "heavy fire"
	desc = "a burning pyre."
	icon = 'icons/effects/effects.dmi'
	icon_state = "visual_fire"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	base_icon_state = "visual_fire"
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
		L.apply_lc_overheat(2)
		dealt_damage = TRUE
	if(!dealt_damage)
		damaging = FALSE
		return
	addtimer(CALLBACK(src, PROC_REF(DoDamage)), 4)

// Automatic Defense Flamethrower - Suit storage automated defense system
/obj/item/auto_flamethrower
	name = "automatic defense flamethrower"
	desc = "An automated flamethrower system that attaches to your suit storage. When activated, it automatically targets and fires at hostile entities within range."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "kineticgun_h"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_SUITSTORE
	var/active = FALSE
	var/obj/item/rce_resource_tank/fuel_backpack/fuel_tank
	var/fuel_per_shot = 10
	var/scan_range = 6
	var/last_fired = 0
	var/fire_delay = 5 // 0.5 second between shots
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
	wearer.add_overlay(mutable_appearance('icons/effects/effects.dmi', "shield-red", ABOVE_MOB_LAYER))
	return TRUE

/obj/item/auto_flamethrower/proc/deactivate()
	active = FALSE
	STOP_PROCESSING(SSobj, src)
	if(wearer)
		to_chat(wearer, span_notice("Automatic defense system deactivated."))
		playsound(src, 'sound/machines/synth_no.ogg', 50, TRUE)
		wearer.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "shield-red", ABOVE_MOB_LAYER))

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
	icon_state = "fireball"
	damage = 75
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

// Incendiary Mine - Deployable fire trap (works like beartrap)
/obj/item/incendiary_mine
	name = "incendiary mine"
	desc = "A proximity-triggered mine that engulfs enemies in flames when triggered. Use in-hand to arm or disarm."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "beartrap0"
	base_icon_state = "beartrap"
	color = "#ff4400"
	w_class = WEIGHT_CLASS_SMALL
	var/armed = FALSE
	var/overheat_applied = 30
	var/damage = 25
	var/explosion_range = 2

/obj/item/incendiary_mine/Initialize()
	. = ..()
	update_icon()

/obj/item/incendiary_mine/update_icon_state()
	icon_state = "[base_icon_state][armed]"

/obj/item/incendiary_mine/examine(mob/user)
	. = ..()
	. += span_notice("It is currently [armed ? "armed" : "disarmed"].")

/obj/item/incendiary_mine/attack_self(mob/user)
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

/obj/item/incendiary_mine/Crossed(atom/movable/AM)
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

/obj/item/incendiary_mine/proc/detonate()
	armed = FALSE
	update_icon()
	visible_message(span_danger("[src] erupts in a burst of flames!"))
	playsound(src, 'sound/effects/ordeals/green/fire.ogg', 50, TRUE)

	// Create fire and apply overheat to nearby enemies
	for(var/turf/T in range(explosion_range, src))
		if(!locate(/obj/effect/rcorp_fire) in T)
			new /obj/effect/rcorp_fire(T)

	for(var/mob/living/L in range(explosion_range, src))
		// Check for Hellfire immunity
		if(is_hellfire_rooster(L))
			continue

		L.deal_damage(damage, FIRE)
		L.apply_lc_overheat(overheat_applied)
		to_chat(L, span_danger("You're engulfed in flames!"))

	qdel(src)

// Fire Trap Dispenser - Deploys multiple small fire traps
/obj/item/fire_trap_dispenser
	name = "fire trap dispenser"
	desc = "A device that deploys a field of small incendiary traps. Takes time to properly set up."
	icon = 'icons/obj/device.dmi'
	icon_state = "inspector"
	w_class = WEIGHT_CLASS_NORMAL
	var/setup_time = 50 // 5 seconds to deploy
	var/traps_to_deploy = 3
	var/deployed = FALSE

/obj/item/fire_trap_dispenser/attack_self(mob/user)
	if(deployed)
		to_chat(user, span_warning("[src] has already been deployed!"))
		return

	user.visible_message(span_notice("[user] begins setting up [src]..."), span_notice("You begin deploying the fire traps..."))

	if(do_after(user, setup_time, src))
		deployed = TRUE
		var/turf/T = get_turf(user)

		// Deploy multiple small traps in area
		for(var/i = 1 to traps_to_deploy)
			var/turf/trap_loc = pick(RANGE_TURFS(2, T))
			if(trap_loc && !trap_loc.density)
				new /obj/structure/fire_trap_small(trap_loc)

		user.visible_message(span_warning("[user] deploys [src]!"), span_notice("You finish deploying the fire traps."))
		playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
		qdel(src)
	else
		to_chat(user, span_warning("Setup interrupted!"))

// Small fire trap deployed by dispenser
/obj/structure/fire_trap_small
	name = "fire trap"
	desc = "A small concealed incendiary trap."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "dodgeball"
	color = "#ff4400"
	density = FALSE
	anchored = TRUE
	alpha = 50 // Very hard to see
	var/trigger_range = 0 // Must step directly on it
	var/overheat_stacks = 15
	var/armed = FALSE

/obj/structure/fire_trap_small/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(arm)), 20) // 2 seconds to arm

/obj/structure/fire_trap_small/proc/arm()
	armed = TRUE
	icon_state = "dodgeball"

/obj/structure/fire_trap_small/Crossed(atom/movable/AM)
	. = ..()
	if(!armed)
		return
	if(isliving(AM))
		var/mob/living/L = AM
		if(L.stat != DEAD)
			trigger(L)

/obj/structure/fire_trap_small/proc/trigger(mob/living/victim)
	visible_message(span_danger("[src] triggers!"))
	playsound(src, 'sound/effects/ordeals/green/fire.ogg', 30, TRUE)

	// Check for Hellfire immunity
	if(!is_hellfire_rooster(victim))
		victim.apply_lc_overheat(overheat_stacks)
		victim.deal_damage(15, FIRE)
		to_chat(victim, span_danger("A hidden trap ignites beneath you!"))
		new /obj/effect/rcorp_fire(get_turf(victim))

	qdel(src)

// TIER 2 WEAPONS

// Inferno Cloud Generator
/obj/item/inferno_cloud_generator
	name = "inferno cloud generator"
	desc = "Creates a large firestorm that slowly moves forward, incinerating everything in its path."
	icon = 'icons/obj/device.dmi'
	icon_state = "gangtool-red"
	w_class = WEIGHT_CLASS_NORMAL
	var/fuel_cost = 40
	var/cooldown = 0
	var/cooldown_time = 200

/obj/item/inferno_cloud_generator/attack_self(mob/user)
	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still recharging! ([round((cooldown - world.time)/10)] seconds)"))
		return

	var/obj/item/rce_resource_tank/fuel_backpack/tank = locate(/obj/item/rce_resource_tank/fuel_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need a fuel tank to use this device!"))
		return

	if(tank.resource_amount < fuel_cost)
		to_chat(user, span_warning("Not enough fuel! ([tank.resource_amount]/[fuel_cost] needed)"))
		return

	tank.resource_amount -= fuel_cost

	// Create moving fire cloud
	var/turf/T = get_turf(user)
	var/dir = user.dir
	new /obj/effect/moving_fire_cloud(T, dir)

	cooldown = world.time + cooldown_time
	playsound(src, 'sound/effects/ordeals/green/fire.ogg', 75, TRUE)
	user.visible_message(span_danger("[user] deploys a massive firestorm!"))

// Moving fire cloud
/obj/effect/moving_fire_cloud
	name = "firestorm"
	desc = "A massive moving wall of flames."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "smoke"
	pixel_x = -32
	pixel_y = -32
	opacity = TRUE
	density = FALSE
	var/move_dir
	var/moves_remaining = 10
	var/damage_per_tick = 20

/obj/effect/moving_fire_cloud/Initialize(mapload, dir)
	. = ..()
	move_dir = dir
	alpha = 200
	color = "#FF4400"
	START_PROCESSING(SSobj, src)

/obj/effect/moving_fire_cloud/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/moving_fire_cloud/process()
	// Damage everything in the cloud and create fire
	for(var/turf/T in range(2, src))
		if(!locate(/obj/effect/rcorp_fire) in T)
			new /obj/effect/rcorp_fire(T)
		for(var/mob/living/L in T)
			// Check for Hellfire immunity
			if(is_hellfire_rooster(L))
				continue

			L.deal_damage(damage_per_tick, FIRE)
			L.apply_lc_overheat(10)

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

// Thermite Spike Launcher - Deploys burning spike strips
/obj/item/thermite_spike_launcher
	name = "thermite spike strip deployer"
	desc = "Launches adhesive spike strips coated in thermite. Enemies who cross them are set ablaze."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "crossbow"
	force = 12
	var/fuel_cost = 20
	var/setup_time = 40 // 4 seconds
	var/strips_remaining = 3

/obj/item/thermite_spike_launcher/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(strips_remaining <= 0)
		to_chat(user, span_warning("[src] is out of spike strips!"))
		return

	var/obj/item/rce_resource_tank/fuel_backpack/tank = locate(/obj/item/rce_resource_tank/fuel_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need a fuel tank to use this weapon!"))
		return

	if(tank.resource_amount < fuel_cost)
		to_chat(user, span_warning("Not enough fuel! ([tank.resource_amount]/[fuel_cost] needed)"))
		return

	var/turf/T = get_turf(target)
	if(!T || T.density)
		return

	user.visible_message(span_notice("[user] begins deploying a spike strip..."), span_notice("You carefully position the thermite spike strip..."))

	if(do_after(user, setup_time, T))
		tank.resource_amount -= fuel_cost
		new /obj/structure/thermite_spike_strip(T)
		strips_remaining--
		playsound(src, 'sound/weapons/genhit2.ogg', 50, TRUE)
		user.visible_message(span_warning("[user] deploys a thermite spike strip!"), span_notice("You deploy the spike strip. ([strips_remaining] remaining)"))
	else
		to_chat(user, span_warning("Deployment interrupted!"))

// Thermite spike strip structure
/obj/structure/thermite_spike_strip
	name = "thermite spike strip"
	desc = "A strip of thermite-coated spikes. Stepping on this would be a bad idea."
	icon = 'icons/obj/structures.dmi'
	icon_state = "brokenratvargrille"
	density = FALSE
	anchored = TRUE
	alpha = 150
	var/overheat_stacks = 25
	var/damage = 20
	var/uses = 3 // Can trigger 3 times before breaking

/obj/structure/thermite_spike_strip/Initialize()
	. = ..()
	color = "#FF4400"

/obj/structure/thermite_spike_strip/Crossed(atom/movable/AM)
	. = ..()
	if(uses <= 0)
		return

	if(isliving(AM))
		var/mob/living/L = AM
		if(L.stat != DEAD)
			trigger(L)

/obj/structure/thermite_spike_strip/proc/trigger(mob/living/victim)
	visible_message(span_danger("[victim] steps on [src]!"))
	playsound(src, 'sound/weapons/slice.ogg', 50, TRUE)

	// Check for Hellfire immunity
	if(!is_hellfire_rooster(victim))
		// Apply damage and overheat
		victim.deal_damage(damage, BRUTE, pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		victim.deal_damage(damage, FIRE)
		victim.apply_lc_overheat(overheat_stacks)

		to_chat(victim, span_userdanger("The thermite spikes pierce and ignite your legs!"))
		new /obj/effect/rcorp_fire(get_turf(victim))

		// Slow the victim briefly
		victim.Immobilize(10)

	uses--
	if(uses <= 0)
		visible_message(span_notice("[src] breaks apart."))
		qdel(src)

// TIER 3 WEAPONS

// Inferno Bombardment System
/obj/item/ego_weapon/ranged/inferno_bombarder
	name = "inferno bombardment system"
	desc = "Heavy artillery that rains incendiary shells over a large area, creating massive fire zones."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "flora"
	force = 20
	fire_delay = 30
	special = "Calls in an artillery strike of incendiary shells."
	var/fuel_cost = 60
	var/shells_per_volley = 6
	var/cooldown = 0
	var/cooldown_time = 300

/obj/item/ego_weapon/ranged/inferno_bombarder/afterattack(atom/target, mob/living/user, proximity_flag, params)
	if(!CanUseEgo(user))
		return

	if(cooldown > world.time)
		to_chat(user, span_warning("[src] is still reloading!"))
		return

	var/obj/item/rce_resource_tank/fuel_backpack/tank = locate(/obj/item/rce_resource_tank/fuel_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need a fuel tank to use this weapon!"))
		return

	if(tank.resource_amount < fuel_cost)
		to_chat(user, span_warning("Not enough fuel! ([tank.resource_amount]/[fuel_cost] needed)"))
		return

	tank.resource_amount -= fuel_cost

	// Target area
	var/turf/T = get_turf(target)
	if(!T)
		return

	cooldown = world.time + cooldown_time
	user.visible_message(span_danger("[user] calls in an inferno bombardment!"))
	playsound(src, 'sound/weapons/flash.ogg', 100, TRUE)

	// Create bombardment
	for(var/i = 1 to shells_per_volley)
		addtimer(CALLBACK(src, PROC_REF(drop_shell), T), i * 3)

/obj/item/ego_weapon/ranged/inferno_bombarder/proc/drop_shell(turf/target)
	var/turf/T = pick(RANGE_TURFS(2, target))
	if(!T)
		return

	new /obj/effect/temp_visual/target(T)
	playsound(T, 'sound/weapons/mortar_whistle.ogg', 75, TRUE)

	addtimer(CALLBACK(src, PROC_REF(shell_impact), T), 10)

/obj/item/ego_weapon/ranged/inferno_bombarder/proc/shell_impact(turf/T)
	explosion(T, light_impact_range = 2)
	for(var/turf/affected in range(2, T))
		if(!locate(/obj/effect/rcorp_fire) in affected)
			new /obj/effect/rcorp_fire(affected)
		if(!locate(/obj/effect/persistent_fire) in affected)
			new /obj/effect/persistent_fire(affected, 20 SECONDS)
	for(var/mob/living/L in range(3, T))
		// Check for Hellfire immunity
		if(is_hellfire_rooster(L))
			continue

		L.deal_damage(50, FIRE)
		L.apply_lc_overheat(40)
		to_chat(L, span_userdanger("The incendiary bombardment engulfs you in flames!"))

// Inferno Scythe - Melee weapon that spreads flames
/obj/item/ego_weapon/inferno_scythe
	name = "inferno scythe"
	desc = "A blazing scythe wreathed in flames. Consumes fuel to perform devastating fire attacks."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "scythe1"
	force = 45
	damtype = RED_DAMAGE
	reach = 2
	attack_verb_continuous = list("slashes", "incinerates", "cleaves")
	attack_verb_simple = list("slash", "incinerate", "cleave")
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 80
	)
	var/fuel_cost = 20
	var/spin_cooldown = 0
	var/spin_cooldown_time = 100

/obj/item/ego_weapon/inferno_scythe/attack(mob/living/target, mob/living/user)
	. = ..()

	if(. && !is_hellfire_rooster(target))
		// Apply overheat on hit
		target.apply_lc_overheat(10)
		// Chance to create fire trail
		if(prob(30))
			var/turf/T = get_turf(target)
			if(T && !locate(/obj/effect/rcorp_fire) in T)
				new /obj/effect/rcorp_fire(T)

/obj/item/ego_weapon/inferno_scythe/attack_self(mob/user)
	if(spin_cooldown > world.time)
		to_chat(user, span_warning("You're still recovering from the last spin!"))
		return

	var/obj/item/rce_resource_tank/fuel_backpack/tank = locate(/obj/item/rce_resource_tank/fuel_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need a fuel tank to perform this technique!"))
		return

	if(tank.resource_amount < fuel_cost)
		to_chat(user, span_warning("Not enough fuel! ([tank.resource_amount]/[fuel_cost] needed)"))
		return

	tank.resource_amount -= fuel_cost

	// Perform spin attack
	spin_cooldown = world.time + spin_cooldown_time
	user.visible_message(span_danger("[user] begins spinning with [src], trailing flames!"))

	for(var/i = 1 to 4)
		addtimer(CALLBACK(src, PROC_REF(spin_damage), user, i), i * 2)

/obj/item/ego_weapon/inferno_scythe/proc/spin_damage(mob/user, spin_number)
	playsound(src, 'sound/weapons/bladeslice.ogg', 50, TRUE)
	for(var/mob/living/L in range(reach, user))
		if(L == user)
			continue
		// Check for Hellfire immunity
		if(is_hellfire_rooster(L))
			continue

		L.deal_damage(35, BRUTE)
		L.deal_damage(25, FIRE)
		L.apply_lc_overheat(15)
		new /obj/effect/temp_visual/cleave(get_turf(L))

	// Create fire on the ground
	for(var/turf/T in range(reach, user))
		if(prob(40) && !locate(/obj/effect/rcorp_fire) in T)
			new /obj/effect/rcorp_fire(T)

// Inferno Field Generator
/obj/item/inferno_field_generator
	name = "inferno field generator"
	desc = "Creates a massive field of intense heat that incinerates everything within."
	icon = 'icons/obj/device.dmi'
	icon_state = "signmaker_sec"
	w_class = WEIGHT_CLASS_NORMAL
	var/fuel_cost = 100
	var/active = FALSE
	var/obj/effect/inferno_field/current_field

/obj/item/inferno_field_generator/attack_self(mob/user)
	if(active)
		deactivate()
		return

	var/obj/item/rce_resource_tank/fuel_backpack/tank = locate(/obj/item/rce_resource_tank/fuel_backpack) in user.contents
	if(!tank)
		to_chat(user, span_warning("You need a fuel tank to power this device!"))
		return

	if(tank.resource_amount < fuel_cost)
		to_chat(user, span_warning("Not enough fuel! ([tank.resource_amount]/[fuel_cost] needed)"))
		return

	tank.resource_amount -= fuel_cost
	activate(user)

/obj/item/inferno_field_generator/proc/activate(mob/user)
	active = TRUE
	var/turf/T = get_turf(user)
	current_field = new /obj/effect/inferno_field(T)
	user.visible_message(span_danger("[user] activates [src], creating a field of intense flames!"))
	playsound(src, 'sound/effects/ordeals/green/fire.ogg', 100, TRUE)

/obj/item/inferno_field_generator/proc/deactivate()
	active = FALSE
	if(current_field)
		qdel(current_field)
		current_field = null
	visible_message(span_notice("The inferno field dissipates."))

/obj/item/inferno_field_generator/dropped(mob/user)
	. = ..()
	if(active)
		deactivate()

// Inferno field effect
/obj/effect/inferno_field
	name = "inferno field"
	desc = "An intense field of flames that incinerates everything."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	anchored = TRUE
	density = FALSE
	opacity = FALSE
	var/field_range = 5
	var/damage_per_tick = 12
	var/fire_chance = 50

/obj/effect/inferno_field/Initialize()
	. = ..()
	color = "#FF4400"
	alpha = 150
	transform = matrix() * 5
	set_light(field_range, 2, "#FF4400")
	START_PROCESSING(SSobj, src)

/obj/effect/inferno_field/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/inferno_field/process()
	for(var/mob/living/L in range(field_range, src))
		if(L.stat == DEAD)
			continue
		// Check for Hellfire immunity
		if(is_hellfire_rooster(L))
			continue

		L.deal_damage(damage_per_tick, FIRE)
		L.apply_lc_overheat(8)

	// Create fire on random tiles
	for(var/turf/T in range(field_range, src))
		if(prob(fire_chance) && !locate(/obj/effect/rcorp_fire) in T)
			new /obj/effect/rcorp_fire(T)
