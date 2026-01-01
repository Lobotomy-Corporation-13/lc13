/**
 * Resurgence Outpost - Faith Fabrics
 *
 * Three tiers of special fabrics that can be attached to resurgence clothing
 * to grant passive faith bonuses. Fabrics are reversible - they can be
 * detached and reused on different clothing items.
 */

/obj/item/resurgence_fabric
	name = "faith fabric"
	desc = "A piece of fabric infused with faith energy. Can be attached to clan-woven clothing."
	icon = 'icons/obj/carnival_silk.dmi'
	icon_state = "simple_azure_silk"
	w_class = WEIGHT_CLASS_TINY

	/// Faith bonus granted when attached to clothing
	var/faith_bonus = 0
	/// Tier name for display purposes
	var/tier_name = "unknown"

/obj/item/resurgence_fabric/examine(mob/user)
	. = ..()
	. += span_notice("This [tier_name] fabric grants +[faith_bonus] faith when attached to clan-woven clothing.")
	. += span_notice("Use it on resurgence clothing to attach. Alt-click the clothing to detach.")

// === SIMPLE TIER (Weakest - 0.1 faith) ===

/obj/item/resurgence_fabric/simple
	name = "simple azure faith fabric"
	desc = "A simple fabric woven with care and infused with a small amount of faith energy."
	icon_state = "simple_azure_silk"
	faith_bonus = 0.1
	tier_name = "simple"

// === ADVANCED TIER (Medium - 0.5 faith) ===

/obj/item/resurgence_fabric/advanced
	name = "advanced azure faith fabric"
	desc = "An intricate fabric carefully woven with moderate faith energy. The craftsmanship is evident."
	icon_state = "advanced_azure_silk"
	faith_bonus = 0.5
	tier_name = "advanced"

// === ELEGANT TIER (Strongest - 1.0 faith) ===

/obj/item/resurgence_fabric/elegant
	name = "elegant azure faith fabric"
	desc = "A masterwork fabric radiating powerful faith energy. Only the most skilled weavers can create such beauty."
	icon_state = "elegant_azure_silk"
	faith_bonus = 1.0
	tier_name = "elegant"
