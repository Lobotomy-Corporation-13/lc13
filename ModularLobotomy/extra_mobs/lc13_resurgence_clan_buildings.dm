//////////////
// RCE BUILDINGS
//////////////
// Structures and buildings used by the Resurgence Clan units

//////////////
// XCORP BARRICADE
//////////////
// A barricade that allows simple mobs to vault over but blocks other mobs
/obj/structure/xcorp_barricade
	name = "X-Corp Barricade"
	desc = "A bloody barricade with meat growing from the sides... It looks low enough to vault over."
	icon = 'icons/obj/smooth_structures/sandbags.dmi'
	icon_state = "meatbags-0"
	base_icon_state = "meatbags"
	density = FALSE
	anchored = TRUE
	layer = TABLE_LAYER
	max_integrity = 200
	integrity_failure = 0.33
	pass_flags_self = LETPASSTHROW
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_SANDBAGS)
	canSmoothWith = list(SMOOTH_GROUP_SANDBAGS, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_SECURITY_BARRICADE)
	var/last_message_time = 0
	var/message_cooldown = 3 SECONDS

/obj/structure/xcorp_barricade/Initialize()
	. = ..()
	AddElement(/datum/element/climbable)

/obj/structure/xcorp_barricade/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(ishuman(mover))
		return FALSE
	if(ismecha(mover))
		return FALSE
	return ..()

/obj/structure/xcorp_barricade/Crossed(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return

	var/mob/living/L = AM

	// Simple mobs can vault over with a message
	if(istype(L, /mob/living/simple_animal))
		visible_message(span_notice("[L] vaults over [src]."))

//////////////
// XCORP TURRET
//////////////
// Base turret class - DO NOT USE DIRECTLY
/mob/living/simple_animal/hostile/clan/ranged/turret
	name = "X-Corp Turret"
	desc = "An automated defense turret bearing X-Corp markings. It appears to be fused into the ground."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_greed_48x48.dmi'
	faction = list("greed_clan", "hostile")
	icon_state = "greed_turret_v2"
	icon_living = "greed_turret_v2"
	pixel_x = -8
	base_pixel_x = -8
	maxHealth = 1500
	health = 1500
	ranged = TRUE
	retreat_distance = 0
	minimum_distance = 0
	move_to_delay = 100
	ranged_cooldown_time = 2 SECONDS
	projectiletype = /obj/projectile/clan_bullet/turret
	projectilesound = 'sound/weapons/emitter.ogg'
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	melee_damage_lower = 15
	melee_damage_upper = 20
	silk_results = list(/obj/item/stack/sheet/silk/azure_simple = 2,
						/obj/item/stack/sheet/silk/azure_advanced = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 4)
	teleport_away = TRUE
	charge = 15
	max_charge = 30
	special_attack_cost = 10
	special_attack_cooldown_time = 15 SECONDS
	var/barrage_shots = 5
	var/barrage_delay = 2
	var/targeting_laser = FALSE
	var/datum/beam/current_beam = null

// Cannot move
/mob/living/simple_animal/hostile/clan/ranged/turret/Move()
	return FALSE

/mob/living/simple_animal/hostile/clan/ranged/turret/Initialize()
	. = ..()
	anchored = TRUE

/mob/living/simple_animal/hostile/clan/ranged/turret/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire()

// Special attack - rapid barrage
/mob/living/simple_animal/hostile/clan/ranged/turret/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown)
		return FALSE

	special_attack_cooldown = world.time + special_attack_cooldown_time
	charge -= special_attack_cost

	// Store the target for the barrage
	var/atom/barrage_target = target

	// Visual and audio warning
	visible_message(span_danger("[src] begins charging up for a barrage!"))
	playsound(src, 'sound/weapons/beam_sniper.ogg', 75, TRUE)

	// Create targeting laser
	if(isliving(barrage_target))
		targeting_laser = TRUE
		current_beam = Beam(barrage_target, icon_state="blood", time = 2 SECONDS)

	// Charge up time
	SLEEP_CHECK_DEATH(2 SECONDS)

	// Clean up beam
	if(current_beam)
		QDEL_NULL(current_beam)

	targeting_laser = FALSE

	// Fire barrage
	visible_message(span_danger("[src] unleashes a barrage of projectiles!"))
	playsound(src, 'sound/weapons/emitter2.ogg', 75, TRUE)

	for(var/i = 1 to barrage_shots)
		if(stat == DEAD || !barrage_target)
			break

		// Fire directly at target without manual offset calculation
		var/turf/startloc = get_turf(src)
		var/obj/projectile/P = new projectiletype(startloc)
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.original = barrage_target
		P.damage = P.damage * 0.4

		// Let the projectile system handle targeting
		P.preparePixelProjectile(barrage_target, startloc)
		P.fire()
		playsound(src, projectilesound, 50, TRUE)

		SLEEP_CHECK_DEATH(barrage_delay)

	say("Re-echar-ging we-eapons...")
	return TRUE

/mob/living/simple_animal/hostile/clan/ranged/turret/death()
	// Explosion effect on death
	if(current_beam)
		QDEL_NULL(current_beam)
	visible_message(span_danger("[src] overloads and explodes!"))
	playsound(src, 'sound/effects/explosion3.ogg', 40, FALSE, 5)
	new /obj/effect/temp_visual/explosion(get_turf(src))
	return ..()

// Turret projectile - slightly stronger than normal clan bullets
/obj/projectile/clan_bullet/turret
	name = "turret bolt"
	damage = 35
	damage_type = RED_DAMAGE
	color = "#7CFC00"
	icon_state = "toxin"

// Level 1 turret projectile
/obj/projectile/clan_bullet/turret/level1
	damage = 10 // 5 DPS with 2 second cooldown

// Level 2 turret projectile
/obj/projectile/clan_bullet/turret/level2
	damage = 20 // 10 DPS with 2 second cooldown

// Level 3 turret projectile
/obj/projectile/clan_bullet/turret/level3
	damage = 40 // 20 DPS with 2 second cooldown

//////////////
// XCORP TURRET LEVEL VARIANTS
//////////////
// Level 1 Basic Turret - 20 DPS, 1000 HP
/mob/living/simple_animal/hostile/clan/ranged/turret/level1
	name = "X-Corp Turret, Level 1"
	desc = "A basic automated defense turret bearing X-Corp markings."
	maxHealth = 600
	health = 600
	icon_state = "greed_turret_v2"
	icon_living = "greed_turret_v2"
	projectiletype = /obj/projectile/clan_bullet/turret/level1
	ranged_cooldown_time = 2 SECONDS // Fire every 2 seconds for 20 DPS

// Level 2 Basic Turret - 40 DPS, 1500 HP
/mob/living/simple_animal/hostile/clan/ranged/turret/level2
	name = "X-Corp Turret, Level 2"
	desc = "An upgraded automated defense turret with enhanced firepower."
	maxHealth = 900
	health = 900
	icon_state = "greed_turret_v2_2"
	icon_living = "greed_turret_v2_2"
	projectiletype = /obj/projectile/clan_bullet/turret/level2
	ranged_cooldown_time = 2 SECONDS // Fire every 2 seconds for 40 DPS

// Level 3 Basic Turret - 60 DPS, 2000 HP
/mob/living/simple_animal/hostile/clan/ranged/turret/level3
	name = "X-Corp Turret, Level 3"
	desc = "An advanced automated defense turret with maximum firepower."
	icon_state = "greed_turret_v2_3"
	icon_living = "greed_turret_v2_3"
	maxHealth = 1200
	health = 1200
	projectiletype = /obj/projectile/clan_bullet/turret/level3
	ranged_cooldown_time = 2 SECONDS // Fire every 2 seconds for 60 DPS

//////////////
// XCORP ARTILLERY TURRET
//////////////
// Base artillery turret class - DO NOT USE DIRECTLY
/mob/living/simple_animal/hostile/clan/ranged/turret/artillery
	name = "X-Corp Artillery Turret"
	desc = "A heavy artillery turret with X-Corp markings. Its barrel glows with barely contained energy."
	icon_state = "greed_turret_v1"
	maxHealth = 2000
	health = 2000
	ranged_cooldown_time = 6 SECONDS // Much slower fire rate
	projectiletype = null // We handle firing manually
	projectilesound = 'sound/weapons/lasercannonfire.ogg'
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	special_attack_cooldown_time = 20 SECONDS
	var/aoe_damage = 50
	var/aoe_range = 1 // 3x3 area
	var/is_firing = FALSE

/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/OpenFire(atom/A)
	if(is_firing)
		return FALSE

	dir = get_cardinal_dir(src, A)
	// Check for special attack
	if(charge >= special_attack_cost && world.time > special_attack_cooldown)
		if(prob(30))
			SpecialAttack(A)
			return TRUE

	// Normal artillery shot
	ArtilleryShot(A)
	return TRUE

/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/proc/ArtilleryShot(atom/target)
	if(is_firing || !target)
		return FALSE

	is_firing = TRUE
	var/turf/target_turf = get_turf(target)

	if(!target_turf)
		is_firing = FALSE
		return FALSE

	// Visual warning
	visible_message(span_danger("[src] begins targeting [target]!"))
	playsound(src, 'sound/weapons/beam_sniper.ogg', 50, TRUE)

	// Create warning indicator at target location
	new /obj/effect/temp_visual/artillery_warning(target_turf)

	// Create targeting beam
	var/datum/beam/targeting = Beam(target_turf, icon_state="blood", time = 2 SECONDS)

	// Wait for charge time
	SLEEP_CHECK_DEATH(2 SECONDS)

	// Clean up beam
	if(targeting)
		QDEL_NULL(targeting)

	// Check if we're still alive
	if(stat == DEAD)
		is_firing = FALSE
		return FALSE

	// Fire the shot
	visible_message(span_danger("[src] fires an explosive shell!"))
	playsound(src, projectilesound, 75, TRUE)

	// Create explosion effect and deal damage
	new /obj/effect/temp_visual/explosion(target_turf)
	playsound(target_turf, 'sound/effects/explosion2.ogg', 50, TRUE)

	// Deal damage in AoE
	for(var/turf/T in range(aoe_range, target_turf))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			L.deal_damage(aoe_damage, RED_DAMAGE)
			to_chat(L, span_userdanger("You are caught in the explosion!"))

			// Knockback effect
			var/throw_dir = get_dir(target_turf, L)
			if(throw_dir)
				var/throwtarget = get_edge_target_turf(L, throw_dir)
				L.throw_at(throwtarget, 2, 1)

	is_firing = FALSE
	ranged_cooldown = world.time + ranged_cooldown_time
	return TRUE

// Special attack - sustained bombardment
/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/SpecialAttack(atom/target)
	if(charge < special_attack_cost || world.time < special_attack_cooldown || is_firing)
		return FALSE

	special_attack_cooldown = world.time + special_attack_cooldown_time
	charge -= special_attack_cost
	is_firing = TRUE

	// Visual and audio warning
	visible_message(span_danger("[src] begins a sustained bombardment!"))
	playsound(src, 'sound/effects/alert.ogg', 75, TRUE)
	say("Co-mmen-cing ar-til-lery bar-rage!")

	// Fire multiple shots at random locations near target
	var/shots = 3
	for(var/i = 1 to shots)
		if(stat == DEAD)
			break

		// Pick a random turf near the target
		var/turf/T = get_turf(target)
		if(!T)
			break

		var/list/possible_turfs = list()
		for(var/turf/check in range(2, T))
			if(!check.density)
				possible_turfs += check

		if(!possible_turfs.len)
			break

		var/turf/bomb_turf = pick(possible_turfs)

		// Create warning
		new /obj/effect/temp_visual/artillery_warning(bomb_turf)

		// Wait shorter time for barrage
		SLEEP_CHECK_DEATH(1.5 SECONDS)

		// Explosion
		new /obj/effect/temp_visual/explosion(bomb_turf)
		playsound(bomb_turf, 'sound/effects/explosion2.ogg', 50, TRUE)

		// Deal damage
		for(var/turf/damage_turf in range(aoe_range, bomb_turf))
			new /obj/effect/temp_visual/small_smoke/halfsecond(damage_turf)
			for(var/mob/living/L in damage_turf)
				if(faction_check_mob(L))
					continue
				L.deal_damage(aoe_damage, RED_DAMAGE)
				to_chat(L, span_userdanger("Artillery shell lands nearby!"))

		SLEEP_CHECK_DEATH(5) // Brief pause between shots

	is_firing = FALSE
	say("Bar-rage com-plete. Re-load-ing...")
	return TRUE

// Artillery warning indicator
/obj/effect/temp_visual/artillery_warning
	name = "targeted area"
	desc = "This area is being targeted by artillery!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "spreadwarning"
	duration = 2 SECONDS
	layer = POINT_LAYER
	color = "#FF0000"

/obj/effect/temp_visual/artillery_warning/Initialize()
	. = ..()
	// Flashing animation
	animate(src, alpha = 100, time = 5, loop = -1)
	animate(alpha = 255, time = 5)
	QDEL_IN(src, 2 SECONDS)

//////////////
// XCORP ARTILLERY TURRET LEVEL VARIANTS
//////////////
// Level 1 Artillery Turret - 50 damage per shot, 1000 HP
/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level1
	name = "X-Corp Artillery Turret, Level 1"
	desc = "A basic heavy artillery turret with explosive shells."
	maxHealth = 800
	health = 800
	icon_state = "greed_turret_v1"
	icon_living = "greed_turret_v1"
	aoe_damage = 50
	ranged_cooldown_time = 6 SECONDS

// Level 2 Artillery Turret - 80 damage per shot, 2000 HP
/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level2
	name = "X-Corp Artillery Turret, Level 2"
	desc = "An upgraded heavy artillery turret with enhanced explosive power."
	maxHealth = 1400
	health = 1400
	icon_state = "greed_turret_v1_2"
	icon_living = "greed_turret_v1_2"
	aoe_damage = 80 // 80 damage per shot, 6 second cooldown
	ranged_cooldown_time = 6 SECONDS

// Level 3 Artillery Turret - 120 damage per shot, 3000 HP
/mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level3
	name = "X-Corp Artillery Turret, Level 3"
	desc = "An advanced heavy artillery turret with devastating firepower."
	maxHealth = 1800
	health = 1800
	icon_state = "greed_turret_v1_3"
	icon_living = "greed_turret_v1_3"
	aoe_damage = 120 // 120 damage per shot, 6 second cooldown
	ranged_cooldown_time = 6 SECONDS

//////////////
// SHIELD LINK STATUS EFFECT
//////////////
// Status effect that redirects projectile damage to the shield generator
/datum/status_effect/shield_link
	id = "shield_link"
	duration = 8 SECONDS
	alert_type = null // No HUD alert for NPCs
	var/mob/living/simple_animal/hostile/clan/shield_generator/linked_generator

/datum/status_effect/shield_link/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/clan/shield_generator/generator)
	linked_generator = generator
	return ..()

/datum/status_effect/shield_link/on_apply()
	if(!linked_generator || QDELETED(linked_generator))
		return FALSE
	// Visual indicator - create a faint shield overlay
	owner.add_overlay(mutable_appearance('icons/effects/cult_effects.dmi', "shield-cult", -MUTATIONS_LAYER))
	return TRUE

/datum/status_effect/shield_link/on_remove()
	owner.cut_overlay(mutable_appearance('icons/effects/cult_effects.dmi', "shield-cult", -MUTATIONS_LAYER))
	linked_generator = null

// Check and handle projectile redirection - call this from bullet_act
/datum/status_effect/shield_link/proc/redirect_damage(obj/projectile/P)
	if(!linked_generator || QDELETED(linked_generator))
		return FALSE

	// Visual feedback - create a brief beam
	var/datum/beam/shield_beam = owner.Beam(linked_generator, icon_state="blood", time = 3)

	// Transfer damage to generator using deal_damage
	linked_generator.deal_damage(P.damage, P.damage_type)

	// Play shield effect sound
	playsound(owner, 'sound/weapons/resonator_blast.ogg', 50, TRUE)

	// Clean up beam
	QDEL_IN(shield_beam, 3)

	// Block the projectile
	P.on_hit(owner, 0, FALSE)
	return TRUE

//////////////
// XCORP SHIELD GENERATOR
//////////////
// Defensive building that creates a damage-redirecting shield for nearby allies
/mob/living/simple_animal/hostile/clan/shield_generator
	name = "X-Corp Shield Generator"
	desc = "A defensive structure that projects protective energy shields onto nearby units."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_greed_48x48.dmi'
	icon_state = "greed_bullet_shield"
	icon_living = "greed_bullet_shield"
	icon_dead = "greed_bullet_shield"
	pixel_x = -8
	base_pixel_x = -8
	faction = list("greed_clan", "hostile")
	maxHealth = 2000
	health = 2000
	melee_damage_lower = 0
	melee_damage_upper = 0
	ranged = FALSE
	move_to_delay = 100
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	silk_results = list(/obj/item/stack/sheet/silk/azure_simple = 3,
						/obj/item/stack/sheet/silk/azure_advanced = 2)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 3)
	teleport_away = TRUE

	// Shield mechanics
	var/shield_radius = 4
	var/pulse_cooldown = 10 SECONDS
	var/last_pulse = 0

	// Self-healing settings - uses charge/max_charge from base clan
	var/charge_gain_cooldown = 1 SECONDS
	var/last_charge_gain = 0
	var/heal_percent = 0.1 // Heal 10% of max HP
	var/heal_charge_cost = 10 // Charge needed to heal

	// Visual effect
	var/shield_active = FALSE

// Cannot move
/mob/living/simple_animal/hostile/clan/shield_generator/Move()
	return FALSE

/mob/living/simple_animal/hostile/clan/shield_generator/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/clan/shield_generator/Initialize()
	. = ..()
	anchored = TRUE
	START_PROCESSING(SSprocessing, src)

/mob/living/simple_animal/hostile/clan/shield_generator/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/mob/living/simple_animal/hostile/clan/shield_generator/process()
	// Pulse shield effect
	if(world.time >= last_pulse + pulse_cooldown)
		PulseShield()
		last_pulse = world.time

	// Gain charge over time
	if(world.time >= last_charge_gain + charge_gain_cooldown)
		charge = min(charge + 1, max_charge)
		last_charge_gain = world.time

		// Check for self-healing when we have enough charge
		if(charge >= heal_charge_cost && health < maxHealth)
			SelfHeal()

// Apply shield to nearby clan mobs only
/mob/living/simple_animal/hostile/clan/shield_generator/proc/PulseShield()
	visible_message(span_notice("[src] emits a protective pulse!"))
	playsound(src, 'sound/weapons/flash.ogg', 50, TRUE)

	// Visual pulse effect
	new /obj/effect/temp_visual/shield_pulse(get_turf(src))

	// Apply shield to nearby clan mobs only
	for(var/mob/living/simple_animal/hostile/clan/C in range(shield_radius, src))

		if(C == src)
			continue

		// Apply or refresh shield link
		C.apply_status_effect(/datum/status_effect/shield_link, src)

		// Visual feedback on shielded mob
		new /obj/effect/temp_visual/heal(get_turf(C), "#00FFFF")

// Self-healing mechanic
/mob/living/simple_animal/hostile/clan/shield_generator/proc/SelfHeal()
	var/heal_amount = maxHealth * heal_percent
	adjustHealth(-heal_amount)
	charge -= heal_charge_cost

	visible_message(span_notice("[src] repairs itself!"))
	playsound(src, 'sound/items/welder2.ogg', 50, TRUE)
	new /obj/effect/temp_visual/heal(get_turf(src), "#00FF00")

/mob/living/simple_animal/hostile/clan/shield_generator/death()
	// Remove all active shields from clan mobs
	for(var/mob/living/simple_animal/hostile/clan/C in range(shield_radius * 2, src))
		C.remove_status_effect(/datum/status_effect/shield_link)

	// Explosion effect
	visible_message(span_danger("[src] overloads and explodes!"))
	playsound(src, 'sound/effects/explosion1.ogg', 75, FALSE, 5)
	new /obj/effect/temp_visual/explosion(get_turf(src))
	return ..()

// Visual effect for shield pulse
/obj/effect/temp_visual/shield_pulse
	name = "shield pulse"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield_pulse"
	duration = 10
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/shield_pulse/Initialize()
	. = ..()
	transform = matrix() * 0.5
	animate(src, transform = matrix() * 3, alpha = 0, time = duration)

//////////////
// SHIELD GENERATOR LEVEL VARIANTS
//////////////
// Level 1 Shield Generator - 1500 HP, 3 tile radius
/mob/living/simple_animal/hostile/clan/shield_generator/level1
	name = "X-Corp Shield Generator, Level 1"
	desc = "A basic defensive structure that projects protective shields."
	maxHealth = 1500
	health = 1500
	shield_radius = 3

// Level 2 Shield Generator - 2500 HP, 4 tile radius
/mob/living/simple_animal/hostile/clan/shield_generator/level2
	name = "X-Corp Shield Generator, Level 2"
	desc = "An upgraded shield generator with enhanced coverage."
	maxHealth = 2500
	health = 2500
	shield_radius = 4

// Level 3 Shield Generator - 3500 HP, 5 tile radius
/mob/living/simple_animal/hostile/clan/shield_generator/level3
	name = "X-Corp Shield Generator, Level 3"
	desc = "An advanced shield generator with maximum protection range."
	maxHealth = 3500
	health = 3500
	shield_radius = 5

//////////////
// XCORP CHAIN ANCHOR
//////////////
// Spawns and chains a ranged unit to itself, heals it with charge
/mob/living/simple_animal/hostile/clan/chain_anchor
	name = "Greed-Touched Chain Anchor"
	desc = "A corrupted anchor point that deploys and tethers greed-touched ranged units. Flesh pulsates around its mechanical frame."
	icon = 'icons/obj/cult.dmi'
	icon_state = "hole"
	icon_living = "hole"
	icon_dead = "hole"
	faction = list("greed_clan", "hostile")
	maxHealth = 800
	health = 800
	layer = BELOW_OPEN_DOOR_LAYER
	melee_damage_lower = 0
	melee_damage_upper = 0
	ranged = FALSE
	move_to_delay = 100
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	silk_results = list(/obj/item/stack/sheet/silk/azure_simple = 2,
						/obj/item/stack/sheet/silk/azure_advanced = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 3)
	density = FALSE
	teleport_away = TRUE

	// Chain mechanics
	var/mob_type_to_spawn = /mob/living/simple_animal/hostile/clan/ranged/gunner/greed // Default greed type
	var/mob/living/simple_animal/hostile/clan/ranged/chained_unit
	var/datum/beam/chain_visual
	var/max_chain_distance = 2 // How far the unit can move from anchor
	var/respawn_cooldown = 20 SECONDS
	var/respawn_timer

	// Healing mechanics
	var/heal_per_charge = 20 // Amount to heal per charge spent
	var/charge_gain_cooldown = 2 SECONDS // Use base clan charge cooldown
	var/last_charge_gain = 0

// Cannot move
/mob/living/simple_animal/hostile/clan/chain_anchor/Move()
	return FALSE

/mob/living/simple_animal/hostile/clan/chain_anchor/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/clan/chain_anchor/Initialize()
	. = ..()
	anchored = TRUE
	START_PROCESSING(SSprocessing, src)
	// Spawn initial unit
	SpawnChainedUnit()

/mob/living/simple_animal/hostile/clan/chain_anchor/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	if(chained_unit && !QDELETED(chained_unit))
		ReleaseUnit()
	if(respawn_timer)
		deltimer(respawn_timer)
	return ..()

/mob/living/simple_animal/hostile/clan/chain_anchor/process()
	// Gain charge over time
	if(world.time >= last_charge_gain + charge_gain_cooldown)
		charge = min(charge + 1, max_charge)
		last_charge_gain = world.time

		// Check for healing when at FULL charge
		if(charge >= max_charge && chained_unit && !QDELETED(chained_unit))
			if(chained_unit.health < chained_unit.maxHealth)
				HealChainedUnit()

	// Update chain visual
	if(chained_unit && !QDELETED(chained_unit))
		UpdateChainVisual()

// Spawn the chained unit
/mob/living/simple_animal/hostile/clan/chain_anchor/proc/SpawnChainedUnit()
	if(chained_unit && !QDELETED(chained_unit))
		return

	var/turf/spawn_turf = get_turf(src)
	chained_unit = new mob_type_to_spawn(spawn_turf)

	// Make unit aware it's chained
	chained_unit.teleport_away = FALSE // Can't teleport when chained

	visible_message(span_notice("[src] deploys [chained_unit]!"))
	playsound(src, 'sound/effects/phasein.ogg', 50, TRUE)

	// Create chain visual
	UpdateChainVisual()

	// Register for signals
	RegisterSignal(chained_unit, COMSIG_LIVING_DEATH, PROC_REF(OnUnitDeath))
	RegisterSignal(chained_unit, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(CheckChainDistance))

// Check if movement would exceed chain distance
/mob/living/simple_animal/hostile/clan/chain_anchor/proc/CheckChainDistance(datum/source, newloc)
	SIGNAL_HANDLER

	if(!newloc)
		return

	var/dist = get_dist(src, newloc)
	if(dist > max_chain_distance)
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

// Handle unit death
/mob/living/simple_animal/hostile/clan/chain_anchor/proc/OnUnitDeath()
	SIGNAL_HANDLER

	visible_message(span_warning("[src]'s deployed unit has been destroyed!"))

	// Clean up
	UnregisterSignal(chained_unit, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_PRE_MOVE))
	if(chain_visual)
		QDEL_NULL(chain_visual)
	chained_unit = null

	// Start respawn timer
	respawn_timer = addtimer(CALLBACK(src, PROC_REF(SpawnChainedUnit)), respawn_cooldown, TIMER_STOPPABLE)

// Heal the chained unit
/mob/living/simple_animal/hostile/clan/chain_anchor/proc/HealChainedUnit()
	if(!chained_unit || QDELETED(chained_unit))
		return

	// Spend half of current charge
	var/charge_to_spend = round(charge / 2)
	var/heal_amount = charge_to_spend * heal_per_charge

	chained_unit.adjustHealth(-heal_amount)
	charge -= charge_to_spend

	visible_message(span_notice("[src] channels [charge_to_spend] charge to heal [chained_unit] for [heal_amount] damage!"))
	playsound(src, 'sound/magic/staff_healing.ogg', 50, TRUE)
	new /obj/effect/temp_visual/heal(get_turf(chained_unit), "#00FF00")

// Update chain visual
/mob/living/simple_animal/hostile/clan/chain_anchor/proc/UpdateChainVisual()
	if(!chained_unit || QDELETED(chained_unit))
		if(chain_visual)
			QDEL_NULL(chain_visual)
		return

	if(!chain_visual)
		chain_visual = Beam(chained_unit, icon_state = "chain")

// Release the unit (on death)
/mob/living/simple_animal/hostile/clan/chain_anchor/proc/ReleaseUnit()
	if(!chained_unit)
		return

	UnregisterSignal(chained_unit, list(COMSIG_LIVING_DEATH, COMSIG_MOVABLE_PRE_MOVE))
	chained_unit.teleport_away = TRUE // Restore teleport ability

	if(chain_visual)
		QDEL_NULL(chain_visual)

	// Kill the unit when anchor dies
	chained_unit.death()
	chained_unit = null

/mob/living/simple_animal/hostile/clan/chain_anchor/death()
	// Release unit on death
	if(chained_unit && !QDELETED(chained_unit))
		ReleaseUnit()

	// Explosion effect
	visible_message(span_danger("[src] collapses!"))
	playsound(src, 'sound/effects/explosion3.ogg', 40, FALSE, 5)
	new /obj/effect/temp_visual/explosion(get_turf(src))
	return ..()

//////////////
// CHAIN ANCHOR VARIANTS
//////////////
// One for each ranged clan mob type

// Sniper Anchor - spawns greed-touched sniper units
/mob/living/simple_animal/hostile/clan/chain_anchor/sniper
	name = "Greed-Touched Sniper Anchor"
	desc = "Deploys and tethers corrupted long-range sniper units, their forms twisted by greed."
	mob_type_to_spawn = /mob/living/simple_animal/hostile/clan/ranged/sniper/greed
	maxHealth = 600
	health = 600

// Gunner Anchor - spawns greed-touched gunner units (default)
/mob/living/simple_animal/hostile/clan/chain_anchor/gunner
	name = "Greed-Touched Gunner Anchor"
	desc = "Deploys and tethers corrupted gunner units, flesh fused with their weapons."
	mob_type_to_spawn = /mob/living/simple_animal/hostile/clan/ranged/gunner/greed

// Rapid Anchor - spawns greed-touched rapid fire units
/mob/living/simple_animal/hostile/clan/chain_anchor/rapid
	name = "Greed-Touched Rapid Anchor"
	desc = "Deploys and tethers corrupted rapid-fire units, their barrels pulsing with flesh."
	mob_type_to_spawn = /mob/living/simple_animal/hostile/clan/ranged/rapid/greed
	maxHealth = 700
	health = 700

// Warper Anchor - spawns greed-touched warper units
/mob/living/simple_animal/hostile/clan/chain_anchor/warper
	name = "Greed-Touched Warper Anchor"
	desc = "Deploys and tethers corrupted phase-shifting warpers, reality bending around their twisted forms."
	mob_type_to_spawn = /mob/living/simple_animal/hostile/clan/ranged/warper/greed
	maxHealth = 1000
	health = 1000
	max_chain_distance = 4 // Warpers need more mobility

// Harpooner Anchor - spawns greed-touched harpooner units
/mob/living/simple_animal/hostile/clan/chain_anchor/harpooner
	name = "Greed-Touched Harpooner Anchor"
	desc = "Deploys and tethers corrupted harpooner units, their chains dripping with viscous corruption."
	mob_type_to_spawn = /mob/living/simple_animal/hostile/clan/ranged/harpooner/greed
	maxHealth = 1000
	health = 1000
	max_chain_distance = 3
