// Corporist Student Component
// Permanent status for players who have proven their artistic dedication

/datum/component/corporist_student

/datum/component/corporist_student/Initialize()
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/carbon/human/H = parent

	// Mark as Ring artist - incompatible with skill augments
	ADD_TRAIT(H, TRAIT_RING_ARTIST, "corporist_student")

	// Remove any existing skill augments
	remove_existing_skill_augments(H)

	// Ensure they have the artistic EXP component
	if(!H.GetComponent(/datum/component/artistic_exp))
		H.AddComponent(/datum/component/artistic_exp)

	to_chat(H, span_nicegreen("You are now a Student of The Ring's artistic schools."))

/datum/component/corporist_student/RegisterWithParent()
	. = ..()
	var/mob/living/carbon/human/H = parent

	// Register for organ insertions to block skill augment organs
	RegisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN, PROC_REF(on_organ_gained))

	// Grant artwork creation action
	var/datum/action/cooldown/create_artwork_student/create_action = new(H)
	create_action.Grant(H)

	// Grant skill tree action
	var/datum/action/innate/ring_skill_tree/tree_action = new(H)
	tree_action.Grant(H)

/datum/component/corporist_student/UnregisterFromParent()
	var/mob/living/carbon/human/H = parent

	// Remove Ring artist trait
	REMOVE_TRAIT(H, TRAIT_RING_ARTIST, "corporist_student")

	// Unregister organ signal
	UnregisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN)

	// Remove actions
	for(var/datum/action/cooldown/create_artwork_student/action in H.actions)
		action.Remove(H)
	for(var/datum/action/innate/ring_skill_tree/action in H.actions)
		action.Remove(H)

	return ..()

/// Removes any existing skill augments from the target
/datum/component/corporist_student/proc/remove_existing_skill_augments(mob/living/carbon/human/H)
	// Remove implanted skill modification organ
	var/obj/item/organ/cyberimp/chest/body_modification/organ = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(organ && istype(organ))
		organ.Remove(H)
		qdel(organ)
		to_chat(H, span_warning("Your skill modification is incompatible with Ring artistry and has been removed!"))

	// Remove injectable skill modifications
	for(var/obj/item/body_modification_injectable/inj in H.contents)
		if(inj.used)
			inj.forceMove(get_turf(H))
			inj.used = FALSE
			to_chat(H, span_warning("Your injectable skill modification is incompatible with Ring artistry and has been ejected!"))

/// Signal handler for organ insertions - rejects skill augment organs
/datum/component/corporist_student/proc/on_organ_gained(datum/source, obj/item/organ/O)
	SIGNAL_HANDLER

	if(istype(O, /obj/item/organ/cyberimp/chest/body_modification))
		addtimer(CALLBACK(src, PROC_REF(reject_skill_organ), O, parent), 1)

/// Removes a skill augment organ after insertion completes
/datum/component/corporist_student/proc/reject_skill_organ(obj/item/organ/O, mob/living/carbon/human/H)
	if(QDELETED(O) || QDELETED(H))
		return
	O.Remove(H)
	O.forceMove(get_turf(H))
	to_chat(H, span_warning("The skill modification is rejected by your body! Ring artists cannot use skill augments."))

// Student's artwork creation action (faster than Inspired, no time limit)
/datum/action/cooldown/create_artwork_student
	name = "Create Artwork"
	desc = "Sculpt a corpse into artwork using your artistic training."
	button_icon_state = "yourarthere"
	cooldown_time = 15 SECONDS
	check_flags = AB_CHECK_HANDS_BLOCKED | AB_CHECK_CONSCIOUS

/datum/action/cooldown/create_artwork_student/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner

	// Find a dead simple_animal nearby
	var/mob/living/simple_animal/corpse = null
	for(var/mob/living/simple_animal/SA in range(1, H))
		if(SA.stat == DEAD)
			corpse = SA
			break

	if(!corpse)
		to_chat(H, span_warning("You need to be next to a dead creature to sculpt it."))
		return FALSE

	to_chat(H, span_notice("You begin sculpting [corpse] into artwork..."))

	if(!do_after(H, 7 SECONDS, corpse)) // Faster than inspired
		to_chat(H, span_warning("You were interrupted!"))
		return FALSE

	// Create the artwork
	var/obj/structure/corporist_artwork/artwork = new(get_turf(corpse), H)

	// Track the simple creature used (not as bodyparts)
	artwork.simple_creatures_used[corpse.name] = 1

	to_chat(H, span_nicegreen("You create a crude sculpture from [corpse]'s remains."))
	playsound(H, 'sound/effects/splat.ogg', 50, TRUE)

	// Gib the corpse
	corpse.gib()

	// Add EXP
	var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("create_artwork")

	StartCooldown()
	return TRUE
