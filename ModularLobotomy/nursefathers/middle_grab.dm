/// Middle Tattoos - Greater Brother buff.
/// Grants passive damage bonus and determines which powered combo is available.
/// Visual: "watch_this" icon above head with tier-based outline.
/datum/status_effect/middle_tattoos
	id = "middle_tattoos"
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/middle_tattoos
	/// Tattoo tier (1-4)
	var/tier = 1
	/// The visual overlay above the owner's head
	var/mutable_appearance/tattoo_overlay
	/// Whether the flicker loop is running
	var/flickering = FALSE

/atom/movable/screen/alert/status_effect/middle_tattoos
	name = "Middle Tattoos - Greater Brother"
	desc = "Enhancement tattoos surge with power. Your next dash combo will be empowered."
	icon = 'icons/obj/spider_house/middle/middle_spider_icon.dmi'
	icon_state = "watch_this"

/datum/status_effect/middle_tattoos/on_apply()
	. = ..()
	AddTattooVisual()

/datum/status_effect/middle_tattoos/on_remove()
	RemoveTattooVisual()
	. = ..()

/// Returns the passive damage bonus based on tier.
/datum/status_effect/middle_tattoos/proc/GetDamageBonus()
	switch(tier)
		if(1)
			return 5
		if(2)
			return 10
		if(3)
			return 15
		if(4)
			return 20
	return 0

/// Adds the "watch_this" visual above the owner's head with tier-scaled outline.
/datum/status_effect/middle_tattoos/proc/AddTattooVisual()
	if(!owner || QDELETED(owner))
		return
	tattoo_overlay = mutable_appearance('icons/obj/spider_house/middle/middle_spider_icon.dmi', "watch_this", ABOVE_MOB_LAYER)
	tattoo_overlay.pixel_y = 32
	switch(tier)
		if(1)
			tattoo_overlay.alpha = 100
		if(2)
			tattoo_overlay.alpha = 140
		if(3)
			tattoo_overlay.alpha = 180
		if(4)
			tattoo_overlay.alpha = 220
	owner.add_overlay(tattoo_overlay)
	flickering = TRUE
	INVOKE_ASYNC(src, PROC_REF(FlickerTattoo))

	var/outline_size
	var/outline_color
	switch(tier)
		if(1)
			outline_size = 1
			outline_color = "#9932CC80"
		if(2)
			outline_size = 1
			outline_color = "#9932CCA0"
		if(3)
			outline_size = 2
			outline_color = "#9932CCC0"
		if(4)
			outline_size = 2
			outline_color = "#9932CCFF"
	owner.add_filter("middle_tattoo_outline", 3, list("type" = "outline", "color" = outline_color, "size" = outline_size))

/// Removes the tattoo visual and outline filter.
/datum/status_effect/middle_tattoos/proc/RemoveTattooVisual()
	flickering = FALSE
	if(tattoo_overlay && owner && !QDELETED(owner))
		owner.cut_overlay(tattoo_overlay)
	tattoo_overlay = null
	if(owner && !QDELETED(owner))
		owner.remove_filter("middle_tattoo_outline")

/// Flickers the tattoo overlay alpha based on tier.
/datum/status_effect/middle_tattoos/proc/FlickerTattoo()
	var/low_alpha
	var/high_alpha
	switch(tier)
		if(1)
			low_alpha = 60
			high_alpha = 140
		if(2)
			low_alpha = 80
			high_alpha = 180
		if(3)
			low_alpha = 120
			high_alpha = 220
		if(4)
			low_alpha = 160
			high_alpha = 255
	while(flickering && owner && !QDELETED(src) && !QDELETED(owner) && tattoo_overlay)
		owner.cut_overlay(tattoo_overlay)
		tattoo_overlay.alpha = high_alpha
		owner.add_overlay(tattoo_overlay)
		sleep(0.5 SECONDS)
		if(!flickering || QDELETED(src) || !owner || QDELETED(owner) || !tattoo_overlay)
			return
		owner.cut_overlay(tattoo_overlay)
		tattoo_overlay.alpha = low_alpha
		owner.add_overlay(tattoo_overlay)
		sleep(0.5 SECONDS)

/// Helper to apply tattoos with a specific tier.
/mob/living/proc/ApplyMiddleTattoos(tattoo_tier)
	var/datum/status_effect/middle_tattoos/existing = has_status_effect(/datum/status_effect/middle_tattoos)
	if(existing)
		qdel(existing)
	var/datum/status_effect/middle_tattoos/T = apply_status_effect(/datum/status_effect/middle_tattoos)
	if(T)
		T.tier = tattoo_tier
		T.RemoveTattooVisual()
		T.AddTattooVisual()

/// Helper to get current tattoo tier (0 if none).
/mob/living/proc/GetMiddleTattooTier()
	var/datum/status_effect/middle_tattoos/T = has_status_effect(/datum/status_effect/middle_tattoos)
	if(!T)
		return 0
	return T.tier

/// Helper to consume tattoos (remove the buff). Returns the tier that was active.
/mob/living/proc/ConsumeMiddleTattoos()
	var/datum/status_effect/middle_tattoos/T = has_status_effect(/datum/status_effect/middle_tattoos)
	if(!T)
		return 0
	var/consumed_tier = T.tier
	qdel(T)
	return consumed_tier
