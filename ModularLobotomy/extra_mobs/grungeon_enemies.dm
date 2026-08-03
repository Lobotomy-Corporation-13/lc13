// This file is for enemies meant to be exclusive to the Outskirts Factory (AKA the Grungeon.)

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder //Enemy which makes other simplemobs around it invulnerable
	name = "aegis of answers"
	desc = "A robot rooted to the ground by a teeming mass of cables. The antenna at the top of its frame beeps occasionally, as if sending out some kind of signal."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "green_shielder"
	icon_living = "green_shielder" //Thank you, SumirekoFan, for providing sprites for these
	icon_dead = "green_shielder"
	faction = list("green_ordeal")
	gender = NEUTER
	pixel_x = -8
	base_pixel_x = -8
	mob_biotypes = MOB_ROBOTIC
	maxHealth = 500
	health = 500
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "lashes"
	attack_verb_simple = "lash"
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.4, PALE_DAMAGE = 1.2)
	butcher_results = list(/obj/item/food/meat/slab/robot = 6)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 4)
	silk_results = list(
		/obj/item/stack/sheet/silk/green_advanced = 2,
		/obj/item/stack/sheet/silk/green_simple = 3,
	)
	var/shieldable = FALSE
	var/can_protect = TRUE

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/spawn_gibs()
	new /obj/effect/gibspawner/scrap_metal(drop_location(), src)

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/Move()
	return FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/Initialize()
	. = ..()
	for(var/turf/T in range(4, src))
		var/obj/effect/shielder_field/DF = new(T)
		DF.shielder = src

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/proc/ApplyShield(mob/living/L)
	if(can_protect)
		if(faction_check_mob(L, FALSE))
			// apply status effect
			var/datum/status_effect/grungeon_shield/S = L.has_status_effect(/datum/status_effect/grungeon_shield)
			if(!S)
				S = L.apply_status_effect(/datum/status_effect/grungeon_shield)
			// keep a list of everyone shielded

/obj/effect/shielder_field
	name = "Shield"
	icon = 'icons/turf/floors.dmi'
	icon_state = "binary_tsp"
	anchored = TRUE
	var/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/shielder
	mouse_opacity = 0

/obj/effect/shielder_field/Destroy()
	shielder = null
	return ..()

/obj/effect/shielder_field/Initialize()
	. = ..()
	animate(src, alpha = 200, time = 0.1 SECONDS)

/obj/effect/shielder_field/Crossed(atom/movable/AM)
	. = ..()
	if(isanimal(AM))
		var/mob/living/L = AM
		shielder.ApplyShield(L)

// In case I need it back

/datum/status_effect/grungeon_shield
	id = "grungeon_shield"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/grungeon_shield
	var/mutable_appearance/shield_overlay

/atom/movable/screen/alert/status_effect/grungeon_shield
	name = "Shielded"
	desc = "You are being shielded by a nearby aegis of answers!"
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "protection"



/datum/status_effect/grungeon_shield/on_apply()
	. = ..()
	ApplyShieldOverlay(owner)
	RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(Moved))
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(Damaged))

/datum/status_effect/grungeon_shield/proc/ApplyShieldOverlay(mob/living/owner)
	shield_overlay = mutable_appearance('icons/effects/effects.dmi', "shield-red", ABOVE_MOB_LAYER)
	var/icon/owner_icon = icon(owner.icon, owner.icon_state, owner.dir)
	var/icon_height = owner_icon.Height()
	var/icon_width = owner_icon.Width()
	var/height_diff = 32 - icon_height
	var/width_diff = 32 - icon_width

	shield_overlay.pixel_x -= (width_diff * 0.5)
	shield_overlay.pixel_y -= (height_diff * 0.5)

	owner.add_overlay(shield_overlay)



/datum/status_effect/grungeon_shield/proc/Moved(mob/user, atom/new_location)
	SIGNAL_HANDLER
	var/turf/newloc_turf = get_turf(new_location)
	var/turf/oldloc_turf = get_turf(user)
	var/valid_tile = FALSE
	var/standing_on_shielded = FALSE

	for(var/obj/effect/shielder_field/GR in oldloc_turf.contents)
		standing_on_shielded = TRUE

	if (!standing_on_shielded)
		qdel(src)

	for(var/obj/effect/shielder_field/GR in newloc_turf.contents)
		valid_tile = TRUE

	if(!valid_tile)
		qdel(src)

/datum/status_effect/grungeon_shield/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	owner.cut_overlay(shield_overlay)
	return ..()

/datum/status_effect/grungeon_shield/proc/Damaged(datum/source, damage, damagetype, def_zone, atom/damage_source, flags, attack_type)
	SIGNAL_HANDLER
	return COMPONENT_MOB_DENY_DAMAGE

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/death(gibbed)
	for(var/obj/effect/shielder_field/F in range(4, src))
		qdel(F)
		continue
	for(var/mob/living/S in range (4, src))
		S.remove_status_effect(/datum/status_effect/grungeon_shield)
	. = ..()
	if(!gibbed)
		gib()

