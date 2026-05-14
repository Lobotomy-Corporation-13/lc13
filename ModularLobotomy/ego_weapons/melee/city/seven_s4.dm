// ============================================================
// Seven Association Section 4 — Rupture + Adaptive Damage
// ============================================================
// Sidearms (foils/dagger) build Rupture stacks with diminishing returns.
// Main weapons (blades/cane) adapt damage type to target's weakest resistance
// when the target has 10+ active Rupture stacks.

// ============================================================
// Sidearms — Rupture Builders
// ============================================================

/// Seven Section 4 fencing foil. Applies Rupture with diminishing returns based on existing stacks.
/obj/item/ego_weapon/city/seven_s4_foil
	name = "Seven Association Section 4 fencing foil"
	desc = "A fencing foil used by Seven Association Section 4 fixers. Inflicts Rupture on targets with diminishing returns."
	special = "Applies Rupture stacks on hit. Rupture applied decreases as stacks build up."
	icon = 'icons/obj/clothing/ego_gear/seven_4_icon.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/seven_4_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/seven_4_right.dmi'
	icon_state = "sevenfencing"
	inhand_icon_state = "sevenfencing"
	hitsound = 'sound/weapons/rapierhit.ogg'
	force = 38
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_THRUST
	/// Base rupture applied per hit
	var/base_rupture = 6
	/// How many existing stacks before rupture applied drops by 1
	var/falloff_rate = 5
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 60,
	)

/obj/item/ego_weapon/city/seven_s4_foil/examine(mob/user)
	. = ..()
	. += span_notice("Applies up to [base_rupture] Rupture per hit, decreasing as stacks build.")

/obj/item/ego_weapon/city/seven_s4_foil/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	. = ..()
	// Apply Rupture with diminishing returns
	var/current_stacks = 0
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(R)
		current_stacks = R.stacks
	var/rupture_amount = max(1, base_rupture - round(current_stacks / falloff_rate))
	target.apply_lc_rupture(rupture_amount)

/// Veteran foil — slower falloff allows pushing stacks higher.
/obj/item/ego_weapon/city/seven_s4_foil/vet
	name = "Seven Association Section 4 veteran fencing foil"
	desc = "A fencing foil used by Seven Association Section 4 veteran fixers. Inflicts Rupture with slower diminishing returns."
	icon_state = "sevenfencing_vet"
	inhand_icon_state = "sevenfencing_vet"
	force = 45
	falloff_rate = 7
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 80,
	)

/// Director dagger — slowest falloff, belt-fit, fast attack speed.
/obj/item/ego_weapon/city/seven_s4_foil/dagger
	name = "Seven Association Section 4 fencing dagger"
	desc = "A small dagger used by Seven Association Section 4 directors. Inflicts Rupture with the slowest diminishing returns. Fits in an EGO belt."
	special = "Applies Rupture stacks on hit with slow diminishing returns. This weapon fits in an EGO belt."
	icon_state = "sevenfencing_dagger"
	inhand_icon_state = "sevenfencing"
	force = 32
	attack_speed = 0.5
	falloff_rate = 10
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 120,
		JUSTICE_ATTRIBUTE = 100,
	)

// ============================================================
// Main Weapons — Adaptive Damage Type
// ============================================================

/// Seven Section 4 blade. Adapts damage type to target's weakest resistance when they have 10+ Rupture.
/obj/item/ego_weapon/city/seven_s4_blade
	name = "Seven Association Section 4 blade"
	desc = "A blade used by Seven Association Section 4 fixers. Adapts its damage type to exploit target weaknesses when Rupture is active."
	special = "When the target has 10+ Rupture stacks, this weapon's damage type adapts to their weakest resistance."
	icon = 'icons/obj/clothing/ego_gear/seven_4_icon.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/seven_4_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/seven_4_right.dmi'
	icon_state = "sevenassociation"
	inhand_icon_state = "sevenassociation"
	force = 36
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP
	/// Whether this weapon can adapt to PALE damage
	var/can_adapt_pale = FALSE
	/// Force penalty multiplier when adapting to PALE
	var/pale_penalty = 0.85
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 60,
	)

/obj/item/ego_weapon/city/seven_s4_blade/examine(mob/user)
	. = ..()
	if(can_adapt_pale)
		. += span_notice("Can adapt to PALE damage at a 15% force penalty.")

/obj/item/ego_weapon/city/seven_s4_blade/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	// Adaptive damage type — requires 10+ Active (activated) Rupture on target
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	var/adapted = FALSE
	if(R && R.activated && R.stacks >= 10)
		var/best_type = get_weakest_resistance(target)
		if(best_type)
			damtype = best_type
			adapted = TRUE
			if(best_type == PALE_DAMAGE)
				force *= pale_penalty

	. = ..()

	// If we adapted to WHITE/PALE, manually trigger rupture since it only fires on RED/BLACK
	if(. && adapted && (damtype == WHITE_DAMAGE || damtype == PALE_DAMAGE))
		if(R && !QDELETED(R) && R.stacks > 0)
			R.trigger_rupture()

	// Reset after attack
	force = initial(force)
	damtype = BLACK_DAMAGE

/// Determine the target's weakest damage resistance.
/obj/item/ego_weapon/city/seven_s4_blade/proc/get_weakest_resistance(mob/living/target)
	var/list/candidates = list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE)
	if(can_adapt_pale)
		candidates += PALE_DAMAGE

	var/best_type = null
	var/best_value = INFINITY

	if(ishuman(target))
		// For humans: check worn suit armor values (lower = weaker)
		var/mob/living/carbon/human/H = target
		if(H.wear_suit && length(H.wear_suit.armor))
			for(var/dtype in candidates)
				var/armor_val = H.wear_suit.armor[dtype] || 0
				if(armor_val < best_value)
					best_value = armor_val
					best_type = dtype
	else if(isanimal(target))
		// For simple mobs: check damage_coeff (higher = more vulnerable)
		var/mob/living/simple_animal/S = target
		best_value = 0
		for(var/dtype in candidates)
			var/coeff = S.damage_coeff.getCoeff(dtype)
			if(coeff > best_value)
				best_value = coeff
				best_type = dtype

	return best_type

/// Veteran blade — higher force.
/obj/item/ego_weapon/city/seven_s4_blade/vet
	name = "Seven Association Section 4 veteran blade"
	desc = "A blade used by Seven Association Section 4 veteran fixers. Adapts its damage type to exploit target weaknesses."
	icon_state = "sevenassociation_vet"
	inhand_icon_state = "sevenassociation_vet"
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	force = 45
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 80,
	)

/// Director blade — can adapt to PALE damage at a force penalty.
/obj/item/ego_weapon/city/seven_s4_blade/director
	name = "Seven Association Section 4 director's blade"
	desc = "A blade used by Seven Association Section 4 branch directors. Full spectrum analysis — can adapt to any damage type including PALE."
	icon_state = "sevenassociation_director"
	inhand_icon_state = "sevenassociation_director"
	hitsound = 'sound/weapons/rapierhit.ogg'
	attack_verb_continuous = list("attacks", "slashes", "stabs", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "stab", "slice", "tear", "lacerate", "rip", "dice", "cut")
	force = 63
	can_adapt_pale = TRUE
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 120,
		JUSTICE_ATTRIBUTE = 100,
	)

/// Director cane — can adapt to PALE, lower force but faster attack speed.
/obj/item/ego_weapon/city/seven_s4_blade/cane
	name = "Seven Association Section 4 director's cane"
	desc = "A cane used by Seven Association Section 4 branch directors. Full spectrum analysis with faster strike speed."
	icon_state = "sevenassociation_cane"
	inhand_icon_state = "sevenassociation_cane"
	force = 56
	can_adapt_pale = TRUE
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 120,
		JUSTICE_ATTRIBUTE = 100,
	)
