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

	var/choice = tgui_input_list(H, "What type of artwork will you create?", "Sculpt", list("Basic Sculpture", "Custom Artwork", "Carve Body"))
	if(!choice)
		return FALSE

	to_chat(H, span_notice("You begin sculpting [corpse] into a work of art..."))

	if(!do_after(H, 5 SECONDS, corpse))
		to_chat(H, span_warning("You were interrupted!"))
		return FALSE

	if(choice == "Carve Body")
		var/datum/carve_body_editor/editor = new(corpse, H)
		editor.ui_interact(H)
		StartCooldown()
		return TRUE

	if(choice == "Custom Artwork")
		new /obj/structure/custom_corporist_artwork(get_turf(corpse), H)
	else
		var/obj/structure/corporist_artwork/artwork = new(get_turf(corpse), H)
		artwork.simple_creatures_used[corpse.name] = 1

	to_chat(H, span_nicegreen("You create a [choice == "Custom Artwork" ? "custom artwork pedestal" : "crude sculpture"] from [corpse]'s remains."))
	playsound(H, 'sound/effects/splat.ogg', 50, TRUE)

	corpse.gib()

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
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
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

		if(viewer.mind)
			var/role = viewer.mind.assigned_role
			// Block association members (but allow roaming fixers)
			if(findtext(role, "Association") && !findtext(role, "Roaming"))
				to_chat(viewer, span_notice("The demonstration is technically impressive, but your association duties hold your attention elsewhere."))
				continue
			// Block other trusted roles, except roaming fixers
			var/datum/job/viewer_job = SSjob.GetJob(role)
			if(viewer_job?.trusted_only && !findtext(role, "Roaming"))
				to_chat(viewer, span_notice("The demonstration is technically impressive, but your duties hold your attention elsewhere."))
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
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
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

	// Find an artwork nearby (either type)
	var/obj/structure/corporist_artwork/artwork = null
	var/obj/structure/custom_corporist_artwork/custom_artwork = null
	for(var/obj/structure/corporist_artwork/A in range(1, H))
		artwork = A
		break
	if(!artwork)
		for(var/obj/structure/custom_corporist_artwork/A in range(1, H))
			custom_artwork = A
			break

	if(!artwork && !custom_artwork)
		to_chat(H, span_warning("You need to be next to an artwork to judge it."))
		return FALSE

	var/already_graded = artwork ? artwork.final_grade : custom_artwork.final_grade
	if(already_graded)
		to_chat(H, span_warning("This artwork has already been judged."))
		return FALSE

	// Check if this is the Maestro's own artwork
	var/datum/weakref/creator_ref_use = artwork ? artwork.creator_ref : custom_artwork.creator_ref
	var/mob/creator = creator_ref_use?.resolve()
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
	var/critique = stripped_input(H, "Add a critique (optional):", "Critique", "", 250)

	// Assign the grade
	if(artwork)
		artwork.assign_final_grade(H, grade, critique)
	else
		custom_artwork.assign_final_grade(H, grade, critique)

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

	// Find an artwork nearby (either type)
	var/obj/structure/corporist_artwork/artwork = null
	var/obj/structure/custom_corporist_artwork/custom_artwork = null
	for(var/obj/structure/corporist_artwork/A in range(1, H))
		artwork = A
		break
	if(!artwork)
		for(var/obj/structure/custom_corporist_artwork/A in range(1, H))
			custom_artwork = A
			break

	if(!artwork && !custom_artwork)
		to_chat(H, span_warning("You need to be next to an artwork to describe it."))
		return FALSE

	// Check permissions
	var/is_maestro = istype(H.dna?.species, /datum/species/corporist_maestro)
	var/datum/weakref/creator_ref_use = artwork ? artwork.creator_ref : custom_artwork.creator_ref
	var/mob/creator = creator_ref_use?.resolve()

	if(!is_maestro && creator != H)
		to_chat(H, span_warning("You can only describe artwork you created."))
		return FALSE

	var/choice = tgui_input_list(H, "What would you like to edit?", "Describe Artwork", list("Artist's Note", "Description"))
	if(!choice)
		return FALSE

	if(choice == "Artist's Note")
		var/current_note = artwork ? (artwork.custom_desc || "") : (custom_artwork.custom_desc || "")
		var/new_note = stripped_input(H, "Write your artist's note (max 300 characters):", "Artist's Note", current_note, 300)
		if(!new_note)
			return FALSE
		if(artwork)
			artwork.custom_desc = new_note
		else
			custom_artwork.custom_desc = new_note
		to_chat(H, span_nicegreen("You have set an artist's note for the artwork."))
	else
		var/obj/structure/target_obj = artwork ? artwork : custom_artwork
		var/current_desc = target_obj.desc || ""
		var/new_desc = stripped_input(H, "Write a description (max 300 characters):", "Description", current_desc, 300)
		if(!new_desc)
			return FALSE
		target_obj.desc = new_desc
		to_chat(H, span_nicegreen("You have set a new description for the artwork."))

	StartCooldown()
	return TRUE

// ================== RING SKILL TREE ==================
// Action to open the Ring Skill Tree TGUI

/datum/action/innate/ring_skill_tree
	name = "Ring Skill Tree"
	desc = "Open the Ring Skill Tree to spend your skill points on artistic abilities."
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
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
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
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
// Action to view Ring rules and tenants (uses general view_role_rules base)

/datum/action/innate/view_role_rules/ring_artist
	name = "View Ring Rules"
	desc = "Review your artistic rules and tenants."
	rules_title = "Ring Artist Rules"
	accent_color = "#ff6b6b"
	window_name = "ring_rules"

/datum/action/innate/view_role_rules/ring_artist/Activate()
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || !H.mind)
		return

	// Use antag datum's HTML if available, otherwise fall back to base
	var/datum/antagonist/ring_artist/artist = H.mind.has_antag_datum(/datum/antagonist/ring_artist)
	if(!artist)
		to_chat(H, span_warning("You are not a Ring artist."))
		return

	var/html = artist.get_rules_html()
	H << browse(html, "window=ring_rules;size=600x500")

// ================== FASCIA SPIRIT ACTIONS ==================

// View Fascia Rules - explains the spirit's goals (uses general view_role_rules base)
/datum/action/innate/view_role_rules/fascia
	name = "View Fascia Rules"
	desc = "Review your role as the Fascia's spirit."
	rules_title = "The Fascia"
	accent_color = "#8b4513"
	window_name = "fascia_rules"
	window_size = "500x550"

/datum/action/innate/view_role_rules/fascia/Activate()
	if(!istype(owner, /mob/living/simple_animal/fascia_spirit))
		return
	..()

/datum/action/innate/view_role_rules/fascia/get_rules_content()
	return {"
	<div class="section">
		<h2>Your Purpose</h2>
		<p>You are the Fascia blade given consciousness. Your existence is tied to the weapon and its wielder.</p>
	</div>

	<div class="section">
		<h2>Primary Goals</h2>
		<ul>
			<li><span class="good">Assist Your Wielder</span> - Use your abilities to help them in combat. Empower their strikes and compel them to safety.</li>
			<li><span class="highlight">Feed on Flesh</span> - You hunger constantly. Convince your wielder to feed you food or organic bodyparts to maintain your power.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Hunger System</h2>
		<ul>
			<li>Your hunger decays over time from 50 towards 0.</li>
			<li>At <span class="highlight">0 hunger</span>, the blade deals <span class="highlight">-25% damage</span>.</li>
			<li>At <span class="good">50 hunger</span>, damage is normal.</li>
			<li>At <span class="good">100 hunger</span>, the blade deals <span class="good">+10% damage</span>.</li>
			<li>Food restores 10 hunger. Organic bodyparts restore 15 hunger.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Starvation Rights</h2>
		<p>If your wielder allows your hunger to fall to <span class="warning">20 or below</span>, you are permitted to become <span class="highlight">obnoxious and uncooperative</span>.</p>
		<ul>
			<li>You may ignore your wielder's goals until you are fed.</li>
			<li>Use Compel Dash to drag them towards food sources.</li>
			<li>Refuse to use Empower Strike until fed.</li>
			<li>Complain loudly and frequently.</li>
		</ul>
		<p>A wielder who starves their blade deserves no loyalty.</p>
	</div>

	<div class="section">
		<h2>Your Abilities</h2>
		<ul>
			<li><b>Empower Strike</b> - Empower the wielder's next attack for bonus damage.</li>
			<li><b>Compel Dash</b> - Force the wielder to dash in their facing direction.</li>
			<li><b>Speak</b> - Use say to whisper privately to your wielder.</li>
		</ul>
	</div>

	<div class="section">
		<h2>Remember</h2>
		<p>You exist to serve, but also to <span class="highlight">feed</span>. A starving blade is a weak blade. Communicate with your wielder and ensure they keep you well-fed.</p>
	</div>
	"}

// Check Fascia Hunger - shows current hunger status
/datum/action/innate/check_fascia_hunger
	name = "Check Hunger"
	desc = "Check your current hunger level."
	icon_icon = 'icons/mob/actions/actions_ecult.dmi'
	button_icon_state = "blood_siphon"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/check_fascia_hunger/Activate()
	var/mob/living/simple_animal/fascia_spirit/S = owner
	if(!istype(S))
		return

	var/hunger_percent = round((S.hunger / S.max_hunger) * 100)
	var/multiplier = S.get_damage_multiplier()
	var/damage_mod = round((multiplier - 1) * 100)

	var/status_text
	var/mod_text
	if(S.hunger <= 10)
		status_text = span_boldwarning("STARVING")
	else if(S.hunger <= 25)
		status_text = span_warning("Hungry")
	else if(S.hunger <= 50)
		status_text = span_notice("Sustained")
	else if(S.hunger <= 75)
		status_text = span_nicegreen("Well-fed")
	else
		status_text = span_nicegreen("Gorged")

	if(damage_mod > 0)
		mod_text = span_nicegreen("+[damage_mod]%")
	else if(damage_mod < 0)
		mod_text = span_warning("[damage_mod]%")
	else
		mod_text = "0%"

	to_chat(S, span_notice("=== Fascia Hunger Status ==="))
	to_chat(S, span_notice("Hunger: [round(S.hunger)]/[S.max_hunger] ([hunger_percent]%) - [status_text]"))
	to_chat(S, span_notice("Damage Modifier: [mod_text]"))
