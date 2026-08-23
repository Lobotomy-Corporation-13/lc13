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
	// Deactivate thermal blade active sprites
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		for(var/obj/item/ego_weapon/city/thermal_blade/blade in H.held_items)
			blade.UpdateActiveVisuals(FALSE)
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
	var/mutable_appearance/old_overlay = tattoo_overlay
	tattoo_overlay = null
	if(owner && !QDELETED(owner))
		if(old_overlay)
			owner.cut_overlay(old_overlay)
		owner.remove_filter("middle_tattoo_outline")
		// Multiple delayed cleanups to catch the flicker loop re-adding the overlay between sleeps
		addtimer(CALLBACK(src, PROC_REF(FinalCleanupOverlay), old_overlay), 0.3 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(FinalCleanupOverlay), old_overlay), 0.7 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(FinalCleanupOverlay), old_overlay), 1.2 SECONDS)

/datum/status_effect/middle_tattoos/proc/FinalCleanupOverlay(mutable_appearance/old_overlay)
	if(owner && !QDELETED(owner))
		if(old_overlay)
			owner.cut_overlay(old_overlay)
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
		if(!flickering || !tattoo_overlay)
			return
		tattoo_overlay.alpha = high_alpha
		owner.add_overlay(tattoo_overlay)
		sleep(0.5 SECONDS)
		if(!flickering || QDELETED(src) || !owner || QDELETED(owner) || !tattoo_overlay)
			return
		owner.cut_overlay(tattoo_overlay)
		if(!flickering || !tattoo_overlay)
			return
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

/// Combo protection - reduces all incoming damage to 1 during combo animations.
/// Does NOT deny damage (mobs keep aggro). Auto-removes after duration.
/datum/status_effect/middle_combo_protection
	id = "middle_combo_protection"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	/// Component that intercepts damage
	var/datum/component/middle_combo_shield/shield_comp

/datum/status_effect/middle_combo_protection/on_creation(mob/living/new_owner, duration_override)
	if(duration_override)
		src.duration = duration_override
	return ..()

/datum/status_effect/middle_combo_protection/on_apply()
	. = ..()
	shield_comp = owner.AddComponent(/datum/component/middle_combo_shield)

/datum/status_effect/middle_combo_protection/on_remove()
	if(shield_comp && !QDELETED(shield_comp))
		qdel(shield_comp)
	shield_comp = null
	. = ..()

/// Component that reduces outside damage to 1 during combos.
/// Uses the Dieci shield pattern - denies original damage, deals 1 as forced.
/datum/component/middle_combo_shield
	dupe_mode = COMPONENT_DUPE_UNIQUE

/datum/component/middle_combo_shield/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/middle_combo_shield/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))

/datum/component/middle_combo_shield/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)

/datum/component/middle_combo_shield/proc/on_damage(datum/source, damage, damagetype, def_zone, atom/damage_source, flags, attack_type)
	SIGNAL_HANDLER
	if(flags & DAMAGE_FORCED)
		return
	if(!damage || damage <= 1)
		return
	// Reduce to 1 damage - deal it as forced so we don't recurse
	var/mob/living/owner = parent
	INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob/living, deal_damage), 1, damagetype, damage_source, DAMAGE_FORCED, null, null, def_zone)
	return COMPONENT_MOB_DENY_DAMAGE

// MIRROR WEAKENED

/// Applied to both the mirror shard user and their grab target.
/// Both are pinned (immobilized) and flash RED. After 3s, damage to either breaks the pin and the effect.
/// Laevateinn can trigger a free execution dash on weakened targets.
/datum/status_effect/mirror_weakened
	id = "mirror_weakened"
	duration = -1
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	/// The linked partner (relic user <-> grab target)
	var/mob/living/partner
	/// Whether this effect is on the relic user (TRUE) or the pinned target (FALSE)
	var/is_relic_user = FALSE
	/// Whether damage can break this effect (set TRUE after 3s pin grace period)
	var/breakable = FALSE
	/// Whether we're currently removing the partner's effect (prevents infinite loop)
	var/removing_partner = FALSE

/datum/status_effect/mirror_weakened/on_apply()
	. = ..()
	if(!.)
		return
	owner.color = "#ff0000"
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnWeakenedDamage))
	INVOKE_ASYNC(src, PROC_REF(PulseRed))

/// Cross-links the two halves of a mirror grab and follows the partner's deletion
/datum/status_effect/mirror_weakened/proc/SetPartner(mob/living/new_partner)
	ClearPartner()
	partner = new_partner
	RegisterSignal(partner, COMSIG_PARENT_QDELETING, PROC_REF(OnPartnerDeleted))

/datum/status_effect/mirror_weakened/proc/ClearPartner()
	if(!partner)
		return
	UnregisterSignal(partner, COMSIG_PARENT_QDELETING)
	partner = null

/datum/status_effect/mirror_weakened/proc/OnPartnerDeleted(datum/source)
	SIGNAL_HANDLER
	partner = null

/datum/status_effect/mirror_weakened/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	if(owner && !QDELETED(owner))
		REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, "mirror_shard")
		owner.alpha = 255
		animate(owner, color = null, time = 0.5 SECONDS)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/atom, update_atom_colour)), 0.5 SECONDS)
	if(partner && !QDELETED(partner) && !removing_partner)
		var/datum/status_effect/mirror_weakened/partner_effect = partner.has_status_effect(/datum/status_effect/mirror_weakened)
		if(partner_effect)
			partner_effect.removing_partner = TRUE
			qdel(partner_effect)
	ClearPartner()
	. = ..()

/datum/status_effect/mirror_weakened/Destroy()
	ClearPartner()
	return ..()

/// Damage breaks the effect once the immobilize ends.
/datum/status_effect/mirror_weakened/proc/OnWeakenedDamage(datum/source, damage, damagetype)
	SIGNAL_HANDLER
	if(!breakable)
		return
	if(!damage || damage <= 0)
		return
	INVOKE_ASYNC(src, PROC_REF(BreakWeakened))

/datum/status_effect/mirror_weakened/proc/BreakWeakened()
	if(owner && !QDELETED(owner))
		to_chat(owner, span_warning("The mirror's grip shatters!"))
	qdel(src)

/// Pulses the owner's color between bright and dim red.
/datum/status_effect/mirror_weakened/proc/PulseRed()
	while(!QDELETED(src) && !QDELETED(owner))
		animate(owner, color = "#ff0000", time = 0.5 SECONDS)
		sleep(0.5 SECONDS)
		if(QDELETED(src) || QDELETED(owner))
			return
		animate(owner, color = "#cc000080", time = 0.5 SECONDS)
		sleep(0.5 SECONDS)
