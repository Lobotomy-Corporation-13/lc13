//--------------------------------------
// The Body Modification Organ
//--------------------------------------

/obj/item/organ/cyberimp/chest/body_modification
	name = "body modification"
	desc = "A cybernetic chest implant that grants access to various combat skills."
	icon_state = "chest_implant"
	implant_color = "#FFD700"
	slot = ORGAN_SLOT_HEART_AID

	var/rank = 1
	var/max_slots = 1
	var/max_charge = 40
	var/current_charge = 40
	var/recharge_rate = 0.5 // Charge per second, scales with rank
	var/list/attached_skills = list()
	var/list/granted_actions = list()
	var/list/skill_charge_costs = list()

	// Stat requirements from modifications.dm
	var/list/rankAttributeReqs = list(20, 40, 60, 80, 100)
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE
	)

/obj/item/organ/cyberimp/chest/body_modification/Initialize()
	. = ..()
	// Scale recharge rate with rank
	recharge_rate = 0.5 + (rank * 0.1)

/obj/item/organ/cyberimp/chest/body_modification/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()

	// Check stat requirements
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/stattotal = 0
		for(var/attribute in stats)
			stattotal += get_attribute_level(H, attribute)
		stattotal /= 4 // Average of stats

		if(stattotal < rankAttributeReqs[rank])
			to_chat(H, span_warning("Your stats are too low for this Rank [rank] modification! (Required: [rankAttributeReqs[rank]], Current: [stattotal])"))
			Remove(H)
			return FALSE

	// Grant all attached skills
	for(var/skill_type in attached_skills)
		var/datum/action/A = new skill_type()
		A.Grant(M)
		granted_actions += A

		// Hook into the action's Trigger to consume charge
		if(istype(A, /datum/action/cooldown))
			var/datum/action/cooldown/CA = A
			RegisterSignal(CA, COMSIG_ACTION_TRIGGER, PROC_REF(on_skill_used))

	to_chat(M, span_notice("The skill modification integrates with your body, granting you new abilities."))

/obj/item/organ/cyberimp/chest/body_modification/Remove(mob/living/carbon/M, special = FALSE)
	// Remove all granted skills
	for(var/datum/action/A in granted_actions)
		UnregisterSignal(A, COMSIG_ACTION_TRIGGER)
		A.Remove(M)
		qdel(A)
	granted_actions.Cut()

	return ..()

// Removed passive charge regeneration - charge must be restored manually

/obj/item/organ/cyberimp/chest/body_modification/proc/on_skill_used(datum/action/source)
	SIGNAL_HANDLER

	var/skill_type = source.type
	if(!(skill_type in skill_charge_costs))
		return

	var/cost = skill_charge_costs[skill_type]

	// Check charge - if insufficient, deal BURN damage instead of blocking
	if(current_charge < cost)
		var/shortfall = cost - current_charge
		var/burn_damage = shortfall * 4 // 4 BURN damage per missing charge point

		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.deal_damage(burn_damage, FIRE)
			to_chat(owner, span_boldwarning("CRITICAL AUGMENT OVERLOAD! Your skill modification tears at your skin!"))

			// Dramatic visual effect (removed emote due to signal handler constraints)
			playsound(get_turf(H), 'sound/weapons/ego/devyat_overclock.ogg', 25, 0, 4)

		// Still consume what charge we have
		current_charge = 0
		to_chat(owner, span_danger("Modification charge: [current_charge]/[max_charge] - DEPLETED!"))
		return

	// Normal operation - consume charge
	current_charge -= cost
	to_chat(owner, span_notice("Modification charge: [current_charge]/[max_charge]"))

	// Low charge warning
	if(current_charge < max_charge * 0.2)
		to_chat(owner, span_warning("Modification charge critical!"))

/obj/item/organ/cyberimp/chest/body_modification/examine(mob/user)
	. = ..()
	. += span_notice("Rank: [rank]")
	. += span_notice("Slots: [max_slots]")
	. += span_notice("Max Charge: [max_charge]")
	. += span_notice("Attached Skills:")
	for(var/skill_type in attached_skills)
		var/datum/action/A = skill_type
		. += span_notice("- [initial(A.name)]")

//--------------------------------------
// Note: Skill charge costs are handled through
// the skill_data list in the fabricator machine
// to avoid modifying base skill definitions
//--------------------------------------

//--------------------------------------
// Injectable Body Modification Items
//--------------------------------------

/obj/item/body_modification_injectable
	name = "injectable body modification"
	desc = "An injectable body modification that can be administered by hitting a target."
	icon = 'icons/obj/syringe.dmi'
	icon_state = "maintenance"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

	var/rank = 1
	var/max_slots = 1
	var/max_charge = 40
	var/current_charge = 40
	var/list/attached_skills = list()
	var/list/skill_charge_costs = list()
	var/used = FALSE

	// Stat requirements
	var/list/rankAttributeReqs = list(20, 40, 60, 80, 100)
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE
	)

/obj/item/body_modification_injectable/examine(mob/user)
	. = ..()
	if(used)
		. += span_warning("This modification has already been used.")
		return
	. += span_notice("Rank: [rank]")
	. += span_notice("Slots: [max_slots]")
	. += span_notice("Max Charge: [max_charge]")
	. += span_notice("Attached Skills: [length(attached_skills)]")
	for(var/skill_type in attached_skills)
		var/datum/action/A = skill_type
		. += span_notice("- [initial(A.name)]")
	. += span_notice("Use on a human to inject this skill modification.")

/obj/item/body_modification_injectable/attack(mob/target, mob/user)
	. = ..()
	if(used)
		to_chat(user, span_warning("[src] has already been used!"))
		return

	if(!ishuman(target))
		to_chat(user, span_warning("You can only use this on humans!"))
		return

	var/mob/living/carbon/human/H = target

	// Check if target already has a skill modification
	var/obj/item/organ/cyberimp/chest/body_modification/existing_SA = H.getorganslot(ORGAN_SLOT_HEART_AID)
	var/obj/item/body_modification_injectable/existing_inj = null

	// Check for existing injectable modifications in inventory
	for(var/obj/item/body_modification_injectable/inj in H.contents)
		if(inj.used)
			existing_inj = inj
			break

	if(existing_SA && istype(existing_SA, /obj/item/organ/cyberimp/chest/body_modification))
		to_chat(user, span_warning("[H] already has a skill modification installed!"))
		return

	if(existing_inj)
		to_chat(user, span_warning("[H] already has an injectable skill modification!"))
		return

	// Check stat requirements
	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	stattotal /= 4 // Average of stats

	if(stattotal < rankAttributeReqs[rank])
		to_chat(user, span_warning("[H]'s stats are too low for this Rank [rank] modification! (Required: [rankAttributeReqs[rank]], Current: [stattotal])"))
		return

	to_chat(user, span_notice("You begin injecting [src] into [H]..."))

	if(!do_after(user, 3 SECONDS, target = H))
		to_chat(user, span_warning("You stop the injection process."))
		return

	// Move the modification into the target and mark as used
	forceMove(H)
	used = TRUE

	// Grant all attached skills
	for(var/skill_type in attached_skills)
		var/datum/action/A = new skill_type()
		A.Grant(H)

		// Hook into the action's Trigger to consume charge
		if(istype(A, /datum/action/cooldown))
			var/datum/action/cooldown/CA = A
			RegisterSignal(CA, COMSIG_ACTION_TRIGGER, PROC_REF(on_skill_used))

	to_chat(user, span_notice("You successfully inject [src] into [H]!"))
	to_chat(H, span_notice("You feel new abilities coursing through your body!"))
	playsound(get_turf(H), 'sound/items/syringeproj.ogg', 50, FALSE)

/obj/item/body_modification_injectable/proc/on_skill_used(datum/action/source)
	SIGNAL_HANDLER

	// Get charge cost
	var/cost = skill_charge_costs[source.type] || 10

	// Check charge - if insufficient, deal BURN damage instead of blocking
	if(current_charge < cost)
		var/shortfall = cost - current_charge
		var/burn_damage = shortfall * 4 // 4 BURN damage per missing charge point

		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			H.deal_damage(burn_damage, FIRE)
			to_chat(H, span_boldwarning("CRITICAL AUGMENT OVERLOAD! Your skill modification tears at your skin!"))

			// Dramatic visual effect
			playsound(get_turf(H), 'sound/weapons/ego/devyat_overclock.ogg', 25, 0, 4)

		// Still consume what charge we have
		current_charge = 0
		if(ishuman(loc))
			to_chat(loc, span_danger("Modification charge: [current_charge]/[max_charge] - DEPLETED!"))
		return

	// Normal operation - consume charge
	current_charge -= cost
	if(ishuman(loc))
		to_chat(loc, span_notice("Modification charge: [current_charge]/[max_charge]"))

		// Low charge warning
		if(current_charge < max_charge * 0.2)
			to_chat(loc, span_warning("Modification charge critical!"))
