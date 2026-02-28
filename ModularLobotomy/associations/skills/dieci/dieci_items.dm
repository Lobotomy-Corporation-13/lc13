// ============================================================
// Dieci Association — Charity Items
// ============================================================
// Healing Kits (tiered, consumable medical supplies) and Sacred Seasoning (food blessing).

// ============================================================
// Healing Kit
// ============================================================

/// Dieci Healing Kit — click on a living carbon to heal brute+burn damage. Auto-chains heals until empty.
/obj/item/dieci_healing_kit
	name = "Basic Healing Kit"
	desc = "A basic Dieci medical kit. Click on a living person to begin healing. 20 uses."
	icon = 'icons/obj/storage.dmi'
	icon_state = "firstaid"
	w_class = WEIGHT_CLASS_SMALL
	/// Weakref to the owning Dieci fixer (for EXP tracking)
	var/datum/weakref/owner_ref
	/// Number of heal uses remaining
	var/uses_remaining = 20
	/// EXP awarded per heal
	var/heal_exp = 2
	/// Medical knowledge level awarded per heal
	var/knowledge_level = 1
	/// Whether currently in a heal loop
	var/healing = FALSE

/obj/item/dieci_healing_kit/examine(mob/user)
	. = ..()
	. += span_notice("Uses remaining: [uses_remaining]")

/obj/item/dieci_healing_kit/attack(mob/living/target, mob/living/user)
	if(!iscarbon(target) || target.stat == DEAD)
		return ..()
	if(!ishuman(user))
		return ..()
	if(healing)
		to_chat(user, span_warning("Already healing someone."))
		return
	INVOKE_ASYNC(src, PROC_REF(heal_loop), target, user)

/// Main healing loop. Repeats until uses run out, target dies, or do_after is interrupted.
/obj/item/dieci_healing_kit/proc/heal_loop(mob/living/carbon/target, mob/living/carbon/human/user)
	healing = TRUE
	while(uses_remaining > 0 && !QDELETED(target) && target.stat != DEAD && !QDELETED(user) && user.stat != DEAD && !QDELETED(src))
		to_chat(user, span_notice("Healing [target]... ([uses_remaining] uses left)"))
		if(!do_after(user, 3 SECONDS, target))
			break
		// Verify state after do_after
		if(QDELETED(target) || target.stat == DEAD || QDELETED(user) || QDELETED(src))
			break
		// Heal
		target.heal_bodypart_damage(10, 10)
		uses_remaining--
		to_chat(target, span_nicegreen("[user] treats your wounds."))
		playsound(get_turf(user), 'sound/machines/ping.ogg', 30, TRUE)
		// Award EXP and knowledge to owner (not for healing Dieci squad members)
		award_heal_exp(target)
	healing = FALSE
	if(uses_remaining <= 0)
		to_chat(user, span_warning("The healing kit is depleted."))
		qdel(src)

/// Award EXP and Medical knowledge for a successful heal. No EXP from healing Dieci squad members.
/obj/item/dieci_healing_kit/proc/award_heal_exp(mob/living/carbon/target)
	var/mob/living/owner_mob = owner_ref?.resolve()
	if(!owner_mob)
		return
	// No EXP from healing Dieci squad members
	var/datum/component/association_exp/target_exp = target.GetComponent(/datum/component/association_exp)
	if(target_exp && target_exp.association_type == ASSOCIATION_DIECI)
		return
	var/datum/component/association_exp/exp = owner_mob.GetComponent(/datum/component/association_exp)
	if(exp)
		exp.modify_exp(heal_exp)
	var/datum/component/dieci_knowledge/dk = owner_mob.GetComponent(/datum/component/dieci_knowledge)
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_MEDICAL, knowledge_level, null, "Healing")
	// Notify active Dieci contracts of heal
	for(var/datum/association_squad/S in GLOB.association_squads)
		if(!(owner_mob in S.members))
			continue
		for(var/datum/association_contract/C in S.active_contracts)
			if(C.state != CONTRACT_STATE_ACTIVE)
				continue
			// Medical Relief: report unique patient healed
			if(istype(C, /datum/association_contract/medical_relief))
				var/datum/association_contract/medical_relief/MR = C
				MR.on_heal(target)
			// Tend to Person: flag heal bonus if target matches
			if(istype(C, /datum/association_contract/tend_to_person))
				var/datum/association_contract/tend_to_person/TP = C
				if(TP.target_mob == target)
					TP.healed_recently = TRUE
		break

// ============================================================
// Healing Kit Tiers
// ============================================================

/// Standard Healing Kit — 40 uses, 3 EXP per heal, Medical L2.
/obj/item/dieci_healing_kit/standard
	name = "Standard Healing Kit"
	desc = "A standard Dieci medical kit with improved potency. 40 uses."
	icon_state = "brute"
	uses_remaining = 40
	heal_exp = 3
	knowledge_level = 2

/// Advanced Healing Kit — 80 uses, 5 EXP per heal, Medical L3.
/obj/item/dieci_healing_kit/advanced
	name = "Advanced Healing Kit"
	desc = "An advanced Dieci medical kit with maximum potency. 80 uses."
	icon_state = "bezerk"
	uses_remaining = 80
	heal_exp = 5
	knowledge_level = 3

// ============================================================
// Sacred Seasoning
// ============================================================

/// Dieci Sacred Seasoning — use on food to bless it. Blessed food heals SP when eaten and awards EXP.
/obj/item/dieci_sacred_seasoning
	name = "Sacred Seasoning"
	desc = "A blessed spice of the Dieci Association. Apply to food to grant spiritual healing when consumed."
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "flour"
	w_class = WEIGHT_CLASS_TINY
	/// Weakref to the owning Dieci fixer (for EXP tracking)
	var/datum/weakref/owner_ref
	/// Number of uses remaining
	var/uses_remaining = 3

/obj/item/dieci_sacred_seasoning/examine(mob/user)
	. = ..()
	. += span_notice("Uses remaining: [uses_remaining]")

/obj/item/dieci_sacred_seasoning/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return
	if(!istype(target, /obj/item/food))
		to_chat(user, span_warning("You can only bless food with this."))
		return
	// Check if already blessed
	if(target.GetComponent(/datum/component/dieci_blessing))
		to_chat(user, span_warning("That food is already blessed."))
		return
	// Bless the food
	target.AddComponent(/datum/component/dieci_blessing, owner_ref)
	uses_remaining--
	to_chat(user, span_nicegreen("You bless [target] with sacred seasoning."))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)
	if(uses_remaining <= 0)
		to_chat(user, span_warning("The seasoning is used up."))
		qdel(src)

// ============================================================
// Dieci Blessing Component (attached to blessed food)
// ============================================================

/// Component that blesses food. When eaten, heals 15 SP and awards 2 EXP to the Dieci owner.
/datum/component/dieci_blessing
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Weakref to the Dieci fixer who blessed this food
	var/datum/weakref/dieci_ref
	/// Whether the blessing has already triggered (one-time per food)
	var/triggered = FALSE

/datum/component/dieci_blessing/Initialize(datum/weakref/_dieci_ref)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	dieci_ref = _dieci_ref
	RegisterSignal(parent, COMSIG_FOOD_EATEN, PROC_REF(on_food_eaten))

/datum/component/dieci_blessing/Destroy()
	dieci_ref = null
	return ..()

/datum/component/dieci_blessing/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_FOOD_EATEN)
	return ..()

/// Signal handler: food was eaten. Heal SP and award EXP on first bite.
/datum/component/dieci_blessing/proc/on_food_eaten(datum/source, mob/living/eater, mob/feeder, bitecount, bite_consumption)
	SIGNAL_HANDLER
	if(triggered)
		return
	triggered = TRUE
	// Heal 15 SP
	if(ishuman(eater))
		var/mob/living/carbon/human/H_eater = eater
		H_eater.adjustSanityLoss(-15)
		to_chat(H_eater, span_nicegreen("The blessed food fills you with spiritual warmth."))
	// Award EXP to the Dieci owner
	INVOKE_ASYNC(src, PROC_REF(award_blessing_exp), eater)

/// Async proc to award blessing EXP (since signal handlers can't sleep).
/datum/component/dieci_blessing/proc/award_blessing_exp(mob/living/eater)
	var/mob/living/dieci_mob = dieci_ref?.resolve()
	if(!dieci_mob || dieci_mob.stat == DEAD)
		return
	// No EXP from Dieci members eating
	if(ishuman(eater))
		var/datum/component/association_exp/eater_exp = eater.GetComponent(/datum/component/association_exp)
		if(eater_exp && eater_exp.association_type == ASSOCIATION_DIECI)
			return
	// Must be able to see the eater
	if(!(eater in view(7, dieci_mob)))
		return
	var/datum/component/association_exp/exp = dieci_mob.GetComponent(/datum/component/association_exp)
	if(exp)
		exp.modify_exp(2)
	var/datum/component/dieci_knowledge/dk = dieci_mob.GetComponent(/datum/component/dieci_knowledge)
	if(dk)
		dk.add_active_knowledge(DIECI_KNOWLEDGE_TYPE_SPIRITUAL, 1, null, "Blessing")
	to_chat(dieci_mob, span_nicegreen("Someone ate your blessed food. Spiritual L1 knowledge gained."))

// ============================================================
// Knowledge Books (Consumable — grant random Active Knowledge)
// ============================================================

/// A consumable book that grants a random level of Active Knowledge of a specific type when used in hand.
/obj/item/dieci_knowledge_book
	name = "Behavioral Knowledge Book"
	desc = "A worn book of behavioral observations. Reading it grants a random level of Behavioral knowledge."
	icon = 'icons/obj/library.dmi'
	icon_state = "book"
	w_class = WEIGHT_CLASS_SMALL
	/// The knowledge type this book grants
	var/knowledge_type = DIECI_KNOWLEDGE_TYPE_BEHAVIORAL

/obj/item/dieci_knowledge_book/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/datum/component/dieci_knowledge/dk = H.GetComponent(/datum/component/dieci_knowledge)
	if(!dk)
		to_chat(H, span_warning("You lack the training to understand this book."))
		return
	to_chat(H, span_notice("You begin reading the book..."))
	if(!do_after(H, 1 SECONDS, src))
		to_chat(H, span_warning("Reading interrupted."))
		return
	// Weighted random level: L1=50%, L2=25%, L3=15%, L4=7%, L5=3%
	var/level = pickweight(list(1 = 50, 2 = 25, 3 = 15, 4 = 7, 5 = 3))
	if(!dk.add_active_knowledge(knowledge_type, level, null, "Knowledge Book"))
		to_chat(H, span_warning("Failed to gain knowledge. Your Active Knowledge may be full."))
		return
	to_chat(H, span_nicegreen("You read the book and gain [knowledge_type] L[level] knowledge."))
	playsound(get_turf(H), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)
	qdel(src)

/// Medical Knowledge Book — grants random Medical knowledge.
/obj/item/dieci_knowledge_book/medical
	name = "Medical Knowledge Book"
	desc = "A medical reference text. Reading it grants a random level of Medical knowledge."
	knowledge_type = DIECI_KNOWLEDGE_TYPE_MEDICAL

/// Spiritual Knowledge Book — grants random Spiritual knowledge.
/obj/item/dieci_knowledge_book/spiritual
	name = "Spiritual Knowledge Book"
	desc = "A book of spiritual writings. Reading it grants a random level of Spiritual knowledge."
	knowledge_type = DIECI_KNOWLEDGE_TYPE_SPIRITUAL

// ============================================================
// Debug Knowledge Book (Unlimited — pick any type and level)
// ============================================================

/// Debug tool that grants any chosen knowledge type and level on demand. Unlimited uses, no delay.
/obj/item/dieci_knowledge_book/debug
	name = "Debug Knowledge Book"
	desc = "A debug tool. Grants any knowledge type and level on demand. Unlimited uses."

/obj/item/dieci_knowledge_book/debug/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/datum/component/dieci_knowledge/dk = H.GetComponent(/datum/component/dieci_knowledge)
	if(!dk)
		dk = H.AddComponent(/datum/component/dieci_knowledge)
	var/chosen_type = tgui_input_list(H, "Select knowledge type:", "Debug Knowledge", list(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL, DIECI_KNOWLEDGE_TYPE_MEDICAL, DIECI_KNOWLEDGE_TYPE_SPIRITUAL))
	if(!chosen_type)
		return
	var/chosen_level = tgui_input_list(H, "Select knowledge level:", "Debug Knowledge", list("1", "2", "3", "4", "5"))
	if(!chosen_level)
		return
	var/level = text2num(chosen_level)
	if(!level || level < 1 || level > 5)
		return
	if(dk.add_active_knowledge(chosen_type, level, null, "Debug"))
		to_chat(H, span_nicegreen("Debug: Added [chosen_type] L[level] knowledge."))
	else
		to_chat(H, span_warning("Debug: Failed to add knowledge (full or duplicate)."))
