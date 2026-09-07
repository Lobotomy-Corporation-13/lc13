/// Coreflame - Special item that grants "Will of Humanity" abilities
/obj/item/coreflame
	name = "Coreflame"
	desc = "A brilliant flame that burns with the collective will of humanity. Those who hold it gain the power to inspire hope and strike down threats to humanity."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "bough_bough"
	light_system = MOVABLE_LIGHT
	light_range = 6
	light_power = 3
	light_color = LIGHT_COLOR_ORANGE
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT
	/// Has this coreflame been claimed by someone?
	var/claimed = FALSE
	/// Reference to current holder with Will of Humanity
	var/mob/living/carbon/human/current_holder

/obj/item/coreflame/Initialize()
	. = ..()
	set_light_on(TRUE)

/obj/item/coreflame/attack_hand(mob/living/user)
	// Only check for humans
	if(!ishuman(user))
		return ..()

	var/mob/living/carbon/human/H = user

	// Calculate stat average
	var/stat_average = (get_attribute_level(H, /datum/attribute/fortitude) + get_attribute_level(H, /datum/attribute/prudence) + get_attribute_level(H, /datum/attribute/temperance) + get_attribute_level(H, /datum/attribute/justice)) / 4

	// Check if they have too much potential (stat average > 60)
	if(stat_average > 60)
		to_chat(H, span_warning("You reach for [src], but it rejects you. You have not enough potential to wield it."))
		return

	// Start pickup attempt
	to_chat(H, span_notice("You begin to reach for [src]..."))
	if(!do_after(H, 30, target = src)) // 3 seconds
		return

	// Pickup successful
	return ..()

/obj/item/coreflame/equipped(mob/user, slot)
	. = ..()
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user

	// Only grant Will of Humanity if picked up for the first time or if previous holder died
	if(!claimed || !current_holder || current_holder.stat == DEAD)
		claimed = TRUE
		current_holder = H

		// Apply Will of Humanity status effect
		H.apply_status_effect(/datum/status_effect/will_of_humanity, src)

		// Register signal to drop on death
		RegisterSignal(H, COMSIG_LIVING_DEATH, PROC_REF(OnHolderDeath))

		visible_message(span_userdanger("[H] claims the Coreflame! They are now the Will of Humanity!"))
		playsound(src, 'sound/magic/staff_healing.ogg', 75, TRUE)

/obj/item/coreflame/dropped(mob/user)
	. = ..()

	// If the Will of Humanity drops the Coreflame, remove the status
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/datum/status_effect/will_of_humanity/will_effect = H.has_status_effect(/datum/status_effect/will_of_humanity)
		if(will_effect)
			H.remove_status_effect(/datum/status_effect/will_of_humanity)

		// Unregister death signal
		UnregisterSignal(H, COMSIG_LIVING_DEATH)

	// Reset claim if dropped voluntarily (not by death)
	if(user.stat != DEAD)
		claimed = FALSE
		current_holder = null

/obj/item/coreflame/Destroy()
	// Unregister death signal if holder exists
	if(current_holder)
		UnregisterSignal(current_holder, COMSIG_LIVING_DEATH)
	current_holder = null
	return ..()

/// Called when the holder dies - drops the Coreflame
/obj/item/coreflame/proc/OnHolderDeath(datum/source)
	SIGNAL_HANDLER

	if(!current_holder || QDELETED(current_holder))
		return

	// Drop the Coreflame
	current_holder.dropItemToGround(src)

/// Hope Blade - EGO weapon granted by Hope status effect
/obj/item/ego_weapon/hope_blade
	name = "hope blade"
	desc = "A blade forged from hope itself. It shimmers with golden light."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "spellblade"
	force = 34
	damtype = PALE_DAMAGE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	hitsound = 'sound/weapons/bladeslice.ogg'
	attribute_requirements = list()
	w_class = WEIGHT_CLASS_NORMAL
