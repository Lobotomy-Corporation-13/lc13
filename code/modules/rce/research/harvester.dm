// RCE Harvester Tool - Marks enemies for body part drops

/obj/item/gun/energy/rce_harvester
	name = "R-Corp biological harvester"
	desc = "A specialized tool that marks living organisms for biological sample extraction upon termination. The marking effect lasts for 60 seconds."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "xray"
	inhand_icon_state = "xray"
	w_class = WEIGHT_CLASS_NORMAL
	slot_flags = ITEM_SLOT_BELT
	ammo_type = list(/obj/item/ammo_casing/energy/harvester)
	cell_type = /obj/item/stock_parts/cell/infinite
	can_charge = FALSE
	fire_delay = 10 // 1 second cooldown between shots
	fire_sound = 'sound/weapons/taser.ogg'
	resistance_flags = INDESTRUCTIBLE

/obj/item/gun/energy/rce_harvester/examine(mob/user)
	. = ..()
	. += span_notice("Marks enemies for biological sample extraction.")
	. += span_notice("Marked enemies will drop body parts when killed.")
	. += span_notice("Marks last for 60 seconds.")

// Harvester projectile
/obj/item/ammo_casing/energy/harvester
	projectile_type = /obj/projectile/harvester
	e_cost = 100
	fire_sound = 'sound/weapons/taser.ogg'

/obj/projectile/harvester
	name = "harvester beam"
	icon_state = "omnilaser"
	damage = 0
	damage_type = STAMINA
	nodamage = TRUE
	hitsound = 'sound/weapons/tap.ogg'
	hitsound_wall = 'sound/weapons/tap.ogg'
	impact_effect_type = /obj/effect/temp_visual/impact_effect/blue_laser

/obj/projectile/harvester/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		// Check if it's a valid target (X-Corp or Clan mob)
		if(istype(L, /mob/living/simple_animal/hostile/greed) || \
		   istype(L, /mob/living/simple_animal/hostile/clan))
			// Add harvest component if not already marked
			if(!L.GetComponent(/datum/component/rce_harvest_mark))
				L.AddComponent(/datum/component/rce_harvest_mark)
				to_chat(firer, span_notice("[L] has been marked for harvesting."))
				// Visual effect
				new /obj/effect/temp_visual/harvest_mark(get_turf(L))
			else
				to_chat(firer, span_warning("[L] is already marked for harvesting."))
		else
			to_chat(firer, span_warning("[L] is not a valid harvesting target."))

// Visual effect for marking
/obj/effect/temp_visual/harvest_mark
	name = "harvest mark"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield2"
	layer = ABOVE_MOB_LAYER
	duration = 10

/obj/effect/temp_visual/harvest_mark/Initialize()
	. = ..()
	animate(src, alpha = 0, time = duration)
