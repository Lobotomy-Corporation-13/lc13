#define STATUS_EFFECT_WARMTH /datum/status_effect/warmth

// Warmth Status Effect - Protects from cold exposure
/datum/status_effect/warmth
	id = "warmth"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 1.5 MINUTES
	tick_interval = 2 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/warmth
	var/has_outline = FALSE

/atom/movable/screen/alert/status_effect/warmth
	name = "Warmth"
	desc = "You feel a comforting warmth protecting you from the cold."
	icon_state = "duskndawn"

/datum/status_effect/warmth/on_apply()
	. = ..()
	to_chat(owner, span_nicegreen("You feel a soothing warmth envelop your body!"))

	// Remove any existing cold exposure
	var/datum/status_effect/stacking/cold_exposure/cold = owner.has_status_effect(/datum/status_effect/stacking/cold_exposure)
	if(cold)
		qdel(cold)

	// Add red outline effect
	if(istype(owner, /atom/movable))
		var/atom/movable/M = owner
		M.add_filter("warmth_glow", 2, list("type" = "outline", "color" = "#ff3939ff", "size" = 2))
		has_outline = TRUE
		addtimer(CALLBACK(src, PROC_REF(glow_loop), M), rand(1, 19))

/datum/status_effect/warmth/on_remove()
	to_chat(owner, span_notice("The warmth fades away."))

	// Remove red outline
	if(has_outline && istype(owner, /atom/movable))
		var/atom/movable/M = owner
		M.remove_filter("warmth_glow")

	. = ..()

/datum/status_effect/warmth/proc/glow_loop(atom/movable/master)
	if(QDELETED(src) || QDELETED(master) || !has_outline)
		return

	master.filters = filter(type = "outline", color = "#ff3939[rand(30, 60)]", size = 2)
	addtimer(CALLBACK(src, PROC_REF(glow_loop), master), rand(10, 30))

/datum/status_effect/warmth/tick()
	// Continuously remove any cold exposure that might get applied
	var/datum/status_effect/stacking/cold_exposure/cold = owner.has_status_effect(/datum/status_effect/stacking/cold_exposure)
	if(cold)
		qdel(cold)

// Y Corp Warmth Lantern
/obj/item/flashlight/lantern/ycorp
	name = "Y Corp thermal lantern"
	desc = "A specialized lantern that radiates comforting warmth when activated. Has limited charges."
	icon_state = "lantern"
	inhand_icon_state = "lantern"
	light_range = 6
	light_color = "#ffaa66"
	light_system = MOVABLE_LIGHT
	custom_premium_price = 4000
	var/charges = 3
	var/max_charges = 3

/obj/item/flashlight/lantern/ycorp/Initialize()
	. = ..()
	update_icon()

/obj/item/flashlight/lantern/ycorp/update_icon()
	. = ..()
	if(charges <= 0)
		icon_state = "lantern_empty"
	else
		icon_state = initial(icon_state)

/obj/item/flashlight/lantern/ycorp/attack_self(mob/living/user)
	if(on)
		on = FALSE
		update_brightness(user)
		playsound(user, 'sound/weapons/magout.ogg', 40, TRUE)
		return

	if(charges <= 0)
		to_chat(user, span_warning("[src] has no charges remaining! It needs a battery."))
		return

	// Turn on and consume a charge
	on = TRUE
	update_brightness(user)
	charges--
	update_icon()
	playsound(src, 'sound/magic/fireball.ogg', 50, TRUE)
	visible_message(span_notice("[src] radiates a comforting warmth!"))

	// Apply warmth to all humans in range
	for(var/mob/living/carbon/human/H in view(3, get_turf(src)))
		H.apply_status_effect(STATUS_EFFECT_WARMTH)
		to_chat(H, span_nicegreen("A burst of warmth escapes from [src], filling you with comfort!"))

/obj/item/flashlight/lantern/ycorp/examine(mob/user)
	. = ..()
	. += span_notice("It has [charges]/[max_charges] charges remaining.")
	if(charges == 0)
		. += span_warning("It needs a Y Corp lantern battery to recharge.")

/obj/item/flashlight/lantern/ycorp/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/ycorp_lantern_battery))
		if(charges >= max_charges)
			to_chat(user, span_warning("[src] is already fully charged!"))
			return

		to_chat(user, span_notice("You insert [I] into [src], restoring its charges."))
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		charges = max_charges
		update_icon()
		qdel(I)
		return

	return ..()

// Y Corp Lantern Battery
/obj/item/ycorp_lantern_battery
	name = "Y Corp lantern battery"
	desc = "A specialized battery designed to recharge Y Corp thermal lanterns."
	icon = 'icons/obj/power.dmi'
	icon_state = "cell"
	w_class = WEIGHT_CLASS_SMALL
	custom_premium_price = 2000
	color = "#ffaa66"

/obj/item/ycorp_lantern_battery/examine(mob/user)
	. = ..()
	. += span_notice("Use this on a Y Corp thermal lantern to restore all charges.")

#undef STATUS_EFFECT_WARMTH
