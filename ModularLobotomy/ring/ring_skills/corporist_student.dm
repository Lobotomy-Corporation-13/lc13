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

	// Add student antagonist datum for rules/round end tracking
	if(H.mind)
		H.mind.add_antag_datum(/datum/antagonist/ring_artist/student)

	// Give toolkit if they don't already have one
	if(!locate(/obj/item/storage/box/corporist_toolkit) in H.contents)
		var/obj/item/storage/box/corporist_toolkit/toolkit = new(get_turf(H))
		H.put_in_hands(toolkit)

	to_chat(H, span_nicegreen("You are now a Student of The Ring's artistic schools."))

/datum/component/corporist_student/RegisterWithParent()
	. = ..()
	var/mob/living/carbon/human/H = parent

	RegisterSignal(parent, COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE, PROC_REF(on_nursefather_override))

	// Register for organ insertions to block skill augment organs
	RegisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN, PROC_REF(on_organ_gained))

	// Register for examine to show student status
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

	// Grant artwork creation action
	var/datum/action/cooldown/create_artwork_student/create_action = new(H)
	create_action.Grant(H)

	// Grant describe artwork action
	var/datum/action/cooldown/describe_artwork/describe_action = new(H)
	describe_action.Grant(H)

	// Grant skill tree action
	var/datum/action/innate/ring_skill_tree/tree_action = new(H)
	tree_action.Grant(H)

/datum/component/corporist_student/UnregisterFromParent()
	var/mob/living/carbon/human/H = parent

	// Remove Ring artist trait
	REMOVE_TRAIT(H, TRAIT_RING_ARTIST, "corporist_student")

	// Unregister signals
	UnregisterSignal(parent, COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE)
	UnregisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN)
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)

	// Remove actions
	for(var/datum/action/cooldown/create_artwork_student/action in H.actions)
		action.Remove(H)
	for(var/datum/action/cooldown/describe_artwork/action in H.actions)
		action.Remove(H)
	for(var/datum/action/innate/ring_skill_tree/action in H.actions)
		action.Remove(H)

	return ..()

/// Show student status when examined
/datum/component/corporist_student/proc/on_examine(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER

	var/mob/living/carbon/human/H = parent
	// Just show "Student of The Ring" - the school is shown by artistic_exp component
	examine_list += span_notice("[H.p_they(TRUE)] [H.p_are()] a Student of The Ring.")

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
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "statue"
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

	var/choice = tgui_input_list(H, "What type of artwork will you create?", "Create Artwork", list("Basic Sculpture", "Custom Artwork", "Carve Body"))
	if(!choice)
		return FALSE

	to_chat(H, span_notice("You begin sculpting [corpse] into artwork..."))

	if(!do_after(H, 7 SECONDS, corpse))
		to_chat(H, span_warning("You were interrupted!"))
		return FALSE

	if(choice == "Carve Body")
		var/datum/carve_body_editor/editor = new(corpse, H)
		editor.ui_interact(H)
		StartCooldown()
		return TRUE

	if(choice == "Custom Artwork")
		new /obj/structure/custom_corporist_artwork(get_turf(corpse), H)
		to_chat(H, span_nicegreen("You create a custom artwork pedestal from [corpse]'s remains."))
	else
		var/obj/structure/corporist_artwork/artwork = new(get_turf(corpse), H)
		artwork.simple_creatures_used[corpse.name] = 1
		to_chat(H, span_nicegreen("You create a crude sculpture from [corpse]'s remains."))

	playsound(H, 'sound/effects/splat.ogg', 50, TRUE)
	corpse.gib()

	var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("create_artwork")

	StartCooldown()
	return TRUE

/datum/component/corporist_student/proc/on_nursefather_override(datum/source, mob/living/recruiter, obj/item/apprentice_recruitment/scroll)
	SIGNAL_HANDLER
	qdel(src)
