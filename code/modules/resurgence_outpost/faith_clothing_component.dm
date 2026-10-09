/**
 * Resurgence Outpost - Faith Clothing Component
 *
 * A component that adds passive faith bonuses to clothing items when worn.
 * Attached to clothing crafted at the Loom.
 */

/// Maximum total faith bonus from all worn clothing combined
#define MAX_CLOTHING_FAITH_BONUS 15

/datum/component/faith_clothing
	/// Faith bonus provided by this clothing item
	var/faith_bonus = 0
	/// Category key for the faith event (unique per item)
	var/faith_category

/datum/component/faith_clothing/Initialize(bonus = 0)
	if(!istype(parent, /obj/item/clothing))
		return COMPONENT_INCOMPATIBLE
	faith_bonus = bonus
	faith_category = "clothing_[REF(parent)]"
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/faith_clothing/Destroy()
	UnregisterSignal(parent, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED, COMSIG_PARENT_EXAMINE))
	return ..()

/datum/component/faith_clothing/proc/on_equipped(datum/source, mob/user, slot)
	SIGNAL_HANDLER

	// Check if equipped in a valid clothing slot (not just held in hands)
	var/obj/item/clothing/C = parent
	if(!(slot & C.slot_flags))
		return

	apply_faith_bonus(user)

/datum/component/faith_clothing/proc/on_dropped(datum/source, mob/user)
	SIGNAL_HANDLER

	remove_faith_bonus(user)

/datum/component/faith_clothing/proc/apply_faith_bonus(mob/living/carbon/human/H)
	if(!istype(H))
		return

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	var/obj/item/I = parent
	// Use the clothing faith event subtype - permanent until manually removed
	var/datum/faith_event/clothing/E = new("Wearing [I.name]", faith_bonus, faith_category)
	core.add_faith_event(faith_category, E)

/datum/component/faith_clothing/proc/remove_faith_bonus(mob/living/carbon/human/H)
	if(!istype(H))
		return

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	core.clear_faith_event(faith_category)

/datum/component/faith_clothing/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_notice("This garment was crafted by the Resurgence Clan. (+[faith_bonus] faith)")

#undef MAX_CLOTHING_FAITH_BONUS
