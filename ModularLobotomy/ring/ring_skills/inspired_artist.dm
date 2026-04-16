// Inspired Artist Component
// Temporary status granted by watching a Maestro's demonstration

/datum/component/inspired_artist
	/// How long the inspiration lasts (in deciseconds)
	var/duration = 10 MINUTES
	/// Timer ID for expiration
	var/timerid
	/// Artistic progress toward becoming a Student
	var/artistic_progress = 0
	/// Progress needed to become a Student
	var/progress_threshold = 4

/datum/component/inspired_artist/Initialize(duration_override)
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

	if(duration_override)
		duration = duration_override

	// Start the expiration timer
	timerid = addtimer(CALLBACK(src, PROC_REF(expire)), duration, TIMER_STOPPABLE)

	to_chat(parent, span_nicegreen("You feel inspired by the artistic demonstration! You can now create basic artwork."))
	to_chat(parent, span_notice("This inspiration will last for [duration / (1 MINUTES)] minutes. Create art to become a permanent Student!"))

/datum/component/inspired_artist/Destroy()
	if(timerid)
		deltimer(timerid)
	return ..()

/datum/component/inspired_artist/RegisterWithParent()
	. = ..()
	var/mob/living/carbon/human/H = parent

	RegisterSignal(parent, COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE, PROC_REF(on_nursefather_override))

	// Grant the create artwork action
	var/datum/action/cooldown/create_basic_artwork/action = new(H)
	action.Grant(H)

	// Grant describe artwork action
	var/datum/action/cooldown/describe_artwork/describe_action = new(H)
	describe_action.Grant(H)

/datum/component/inspired_artist/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE)
	var/mob/living/carbon/human/H = parent

	// Remove the create artwork action
	for(var/datum/action/cooldown/create_basic_artwork/action in H.actions)
		action.Remove(H)

	// Remove describe artwork action
	for(var/datum/action/cooldown/describe_artwork/action in H.actions)
		action.Remove(H)

	return ..()

/// Called when inspiration expires
/datum/component/inspired_artist/proc/expire()
	to_chat(parent, span_warning("Your artistic inspiration fades..."))
	qdel(src)

/// Add artistic progress
/datum/component/inspired_artist/proc/add_progress(amount = 1)
	artistic_progress += amount
	to_chat(parent, span_notice("Artistic progress: [artistic_progress]/[progress_threshold]"))

	if(artistic_progress >= progress_threshold)
		become_student()

/// Convert to permanent Student status
/datum/component/inspired_artist/proc/become_student()
	var/mob/living/carbon/human/H = parent
	to_chat(H, span_greentext("Your dedication to art has paid off! You are now a Student of The Ring!"))

	// Remove inspiration and add student component
	H.AddComponent(/datum/component/corporist_student)

	// Transfer any EXP component or create one
	var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		exp_comp = H.AddComponent(/datum/component/artistic_exp)

	qdel(src)

// Action for inspired players to create basic artwork
/datum/action/cooldown/create_basic_artwork
	name = "Create Basic Artwork"
	desc = "Use your inspiration to sculpt a corpse into basic artwork."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "statue"
	cooldown_time = 15 SECONDS
	check_flags = AB_CHECK_HANDS_BLOCKED | AB_CHECK_CONSCIOUS

/datum/action/cooldown/create_basic_artwork/Trigger(trigger_flags)
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

	if(!do_after(H, 8 SECONDS, corpse))
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

	// Add artistic progress
	var/datum/component/inspired_artist/inspiration = H.GetComponent(/datum/component/inspired_artist)
	if(inspiration)
		inspiration.add_progress(1)

	// Add EXP if they have the component
	var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("create_artwork")

	StartCooldown()
	return TRUE

/datum/component/inspired_artist/proc/on_nursefather_override(datum/source, mob/living/recruiter, obj/item/apprentice_recruitment/scroll)
	SIGNAL_HANDLER
	qdel(src)
