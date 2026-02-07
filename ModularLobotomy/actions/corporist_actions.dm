// Corporist Maestro Actions
// Actions for the Maestro and Apprentice roles

// ================== SCULPT CORPSE ==================
// Primary action to create artwork from a corpse

/datum/action/cooldown/sculpt_corpse
	name = "Sculpt Corpse"
	desc = "Transform a dead creature into a work of corporeal art."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "statue"
	cooldown_time = 10 SECONDS
	check_flags = AB_CHECK_HANDS_BLOCKED | AB_CHECK_CONSCIOUS

/datum/action/cooldown/sculpt_corpse/Trigger(trigger_flags)
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

	to_chat(H, span_notice("You begin sculpting [corpse] into a work of art..."))

	if(!do_after(H, 5 SECONDS, corpse))
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

// ================== DEMONSTRATE ARTISTRY ==================
// Special action to inspire others

/datum/action/cooldown/demonstrate_artistry
	name = "Demonstrate Artistry"
	desc = "Perform an artistic demonstration on a corpse, inspiring all who witness it."
	icon_icon = 'icons/obj/ring_icons.dmi'
	button_icon_state = "demonstration"
	cooldown_time = 5 MINUTES
	check_flags = AB_CHECK_HANDS_BLOCKED | AB_CHECK_CONSCIOUS

/datum/action/cooldown/demonstrate_artistry/Trigger(trigger_flags)
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
		to_chat(H, span_warning("You need to be next to a dead creature for your demonstration."))
		return FALSE

	// Announce the demonstration
	H.visible_message(span_boldnotice("[H] begins an artistic demonstration on [corpse]!"))
	to_chat(H, span_notice("You begin your demonstration. All who watch will be inspired..."))

	if(!do_after(H, 12 SECONDS, corpse))
		to_chat(H, span_warning("Your demonstration was interrupted!"))
		return FALSE

	// Dramatic gib
	playsound(H, 'sound/effects/splat.ogg', 70, TRUE)
	H.visible_message(span_boldnotice("[H] completes their demonstration with a dramatic flourish!"))

	// Inspire all viewers in range
	var/inspired_count = 0
	for(var/mob/living/carbon/human/viewer in view(7, H))
		if(viewer == H)
			continue
		if(viewer.stat != CONSCIOUS)
			continue

		// Don't inspire those who are already Students or have inspiration
		if(viewer.GetComponent(/datum/component/corporist_student))
			to_chat(viewer, span_notice("You appreciate the demonstration, though you've already mastered the basics."))
			continue
		if(viewer.GetComponent(/datum/component/inspired_artist))
			to_chat(viewer, span_notice("Your existing inspiration is renewed!"))
			// Refresh their timer
			var/datum/component/inspired_artist/existing = viewer.GetComponent(/datum/component/inspired_artist)
			qdel(existing)

		// Grant inspiration
		viewer.AddComponent(/datum/component/inspired_artist)

		// Ensure they have EXP tracking
		if(!viewer.GetComponent(/datum/component/artistic_exp))
			viewer.AddComponent(/datum/component/artistic_exp)

		inspired_count++

	to_chat(H, span_nicegreen("You inspired [inspired_count] viewer(s) with your demonstration!"))

	// Gib the corpse
	corpse.gib()

	StartCooldown()
	return TRUE

// ================== JUDGE ARTWORK ==================
// Maestro-only action to assign final grades

/datum/action/cooldown/judge_artwork
	name = "Judge Artwork"
	desc = "Evaluate an artwork and assign a final grade."
	icon_icon = 'icons/obj/ring_icons.dmi'
	button_icon_state = "judgement"
	cooldown_time = 5 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	/// Cooldown tracker for A grade (world.time when available again)
	var/a_grade_cooldown = 0
	/// Cooldown tracker for S grade (world.time when available again)
	var/s_grade_cooldown = 0
	/// A grade cooldown duration
	var/a_grade_cooldown_time = 5 MINUTES
	/// S grade cooldown duration
	var/s_grade_cooldown_time = 30 MINUTES

/datum/action/cooldown/judge_artwork/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner

	// Find an artwork nearby
	var/obj/structure/corporist_artwork/artwork = null
	for(var/obj/structure/corporist_artwork/A in range(1, H))
		artwork = A
		break

	if(!artwork)
		to_chat(H, span_warning("You need to be next to an artwork to judge it."))
		return FALSE

	if(artwork.final_grade)
		to_chat(H, span_warning("This artwork has already been judged."))
		return FALSE

	// Check if this is the Maestro's own artwork
	var/mob/creator = artwork.creator_ref?.resolve()
	if(creator == H)
		to_chat(H, span_warning("You cannot judge your own artwork. A true artist seeks the judgment of others."))
		return FALSE

	// Build list of available grades based on cooldowns
	var/list/available_grades = list()

	// S grade check
	if(s_grade_cooldown <= world.time)
		available_grades += "S"
	else
		var/s_remaining = round((s_grade_cooldown - world.time) / 600) // Convert to minutes
		to_chat(H, span_notice("S grade is on cooldown ([s_remaining] minutes remaining)."))

	// A grade check
	if(a_grade_cooldown <= world.time)
		available_grades += "A"
	else
		var/a_remaining = round((a_grade_cooldown - world.time) / 600) // Convert to minutes
		to_chat(H, span_notice("A grade is on cooldown ([a_remaining] minutes remaining)."))

	// B, C, F are always available
	available_grades += list("B", "C", "F")

	// Ask for grade
	var/grade = tgui_input_list(H, "What grade do you give this artwork?", "Judge Artwork", available_grades)
	if(!grade)
		return FALSE

	// Double-check cooldowns (in case time passed during input)
	if(grade == "S" && s_grade_cooldown > world.time)
		to_chat(H, span_warning("S grade is still on cooldown!"))
		return FALSE
	if(grade == "A" && a_grade_cooldown > world.time)
		to_chat(H, span_warning("A grade is still on cooldown!"))
		return FALSE

	// Optional critique
	var/critique = stripped_input(H, "Add a critique (optional):", "Critique", "", 100)

	// Assign the grade
	artwork.assign_final_grade(H, grade, critique)

	to_chat(H, span_nicegreen("You have judged the artwork: Grade [grade]"))
	H.visible_message(span_notice("[H] has judged an artwork, assigning it a grade of [grade]."))

	// Apply grade-specific cooldowns
	if(grade == "S")
		s_grade_cooldown = world.time + s_grade_cooldown_time
		to_chat(H, span_notice("S grade is now on cooldown for 30 minutes."))
	else if(grade == "A")
		a_grade_cooldown = world.time + a_grade_cooldown_time
		to_chat(H, span_notice("A grade is now on cooldown for 5 minutes."))

	StartCooldown()
	return TRUE

// ================== DESCRIBE ARTWORK ==================
// Action to set custom description on artwork

/datum/action/cooldown/describe_artwork
	name = "Describe Artwork"
	desc = "Write a custom description for an artwork you created (or any, if you're the Maestro)."
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spell_default"
	cooldown_time = 3 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/describe_artwork/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner

	// Find an artwork nearby
	var/obj/structure/corporist_artwork/artwork = null
	for(var/obj/structure/corporist_artwork/A in range(1, H))
		artwork = A
		break

	if(!artwork)
		to_chat(H, span_warning("You need to be next to an artwork to describe it."))
		return FALSE

	// Check permissions
	var/is_maestro = istype(H.dna?.species, /datum/species/corporist_maestro)
	var/mob/creator = artwork.creator_ref?.resolve()

	if(!is_maestro && creator != H)
		to_chat(H, span_warning("You can only describe artwork you created."))
		return FALSE

	// Get description
	var/new_desc = stripped_input(H, "Write your description (max 300 characters):", "Describe Artwork", artwork.custom_desc || "", 300)
	if(!new_desc)
		return FALSE

	artwork.custom_desc = new_desc
	to_chat(H, span_nicegreen("You have set a custom description for the artwork."))

	StartCooldown()
	return TRUE

// ================== RING SKILL TREE ==================
// Action to open the Ring Skill Tree TGUI

/datum/action/innate/ring_skill_tree
	name = "Ring Skill Tree"
	desc = "Open the Ring Skill Tree to spend your skill points on artistic abilities."
	icon_icon = 'icons/obj/ring_icons.dmi'
	button_icon_state = "skill_tree"
	check_flags = AB_CHECK_CONSCIOUS

	var/datum/ring_skill_tree/skill_tree_datum

/datum/action/innate/ring_skill_tree/Activate()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return

	// Check if they have artistic EXP
	var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		to_chat(H, span_warning("You have no artistic experience."))
		return

	// Create or reuse the skill tree datum
	if(!skill_tree_datum)
		skill_tree_datum = new(H)

	skill_tree_datum.ui_interact(H)

/datum/action/innate/ring_skill_tree/Remove(mob/M)
	if(skill_tree_datum)
		QDEL_NULL(skill_tree_datum)
	. = ..()

// ================== RESET ARTISTRY ==================
// Maestro-only action to respec a student's skill tree

/datum/action/cooldown/reset_artistry
	name = "Reset Artistry"
	desc = "Reset a student's skill tree, refunding all their skill points."
	icon_icon = 'icons/obj/ring_icons.dmi'
	button_icon_state = "reset_artistry"
	cooldown_time = 30 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/cooldown/reset_artistry/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner

	// Find a human nearby
	var/mob/living/carbon/human/student = null
	for(var/mob/living/carbon/human/potential in range(1, H))
		if(potential == H)
			continue
		if(potential.GetComponent(/datum/component/artistic_exp))
			student = potential
			break

	if(!student)
		to_chat(H, span_warning("You need to be next to a student with artistic experience."))
		return FALSE

	var/datum/component/artistic_exp/exp_comp = student.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		to_chat(H, span_warning("[student] has no artistic experience to reset."))
		return FALSE

	if(exp_comp.skill_points_spent == 0)
		to_chat(H, span_warning("[student] has not spent any skill points."))
		return FALSE

	// Confirm
	var/confirm = tgui_alert(H, "Reset [student]'s skill tree? This will refund [exp_comp.skill_points_spent] skill points.", "Confirm Reset", list("Yes", "No"))
	if(confirm != "Yes")
		return FALSE

	// Remove all skill components
	for(var/datum/component/ring_skill/skill in student.GetComponents(/datum/component/ring_skill))
		qdel(skill)

	// Refund points
	exp_comp.refund_all_points()

	to_chat(H, span_nicegreen("You have reset [student]'s artistic skill tree."))
	to_chat(student, span_notice("[H] has reset your artistic skill tree. All skill points have been refunded."))

	StartCooldown()
	return TRUE

// ================== VIEW RING RULES ==================
// Action to view Ring rules and tenants

/datum/action/innate/view_ring_rules
	name = "View Ring Rules"
	desc = "Review your artistic rules and tenants."
	icon_icon = 'icons/hud/actions.dmi'
	button_icon_state = "round_end"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/view_ring_rules/Activate()
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !H.mind)
		return

	var/datum/antagonist/ring_artist/artist = H.mind.has_antag_datum(/datum/antagonist/ring_artist)
	if(!artist)
		to_chat(H, span_warning("You are not a Ring artist."))
		return

	var/html = artist.get_rules_html()
	H << browse(html, "window=ring_rules;size=600x500")
