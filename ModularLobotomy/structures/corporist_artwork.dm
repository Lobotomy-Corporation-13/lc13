// Corporist Artwork System
// Artworks created by The Ring's Corporist school from flesh and bone

/obj/structure/corporist_artwork
	name = "crude sculpture"
	desc = "A basic arrangement of flesh and bone. The artist's vision is barely visible."
	icon = 'icons/obj/mannequin.dmi'
	icon_state = "mannequin_human_wood" // Tier 1-2 placeholder
	anchored = TRUE
	density = FALSE
	can_buckle = TRUE
	buckle_lying = 0
	max_integrity = 200
	// Placeholder icon states by tier (using cult icons until custom sprites are made)
	var/static/list/tier_icon_states = list(
		"mannequin_human_wood",      // Tier 1 - small
		"mannequin_human_red",    // Tier 2
		"mannequin_human_white", // Tier 3
		"mannequin_human_purple",   // Tier 4
		"mannequin_human_pale"       // Tier 5 - largest
	)

	/// Current tier of the artwork (1-5)
	var/tier = 1
	/// Number of materials used for tier calculation (bodyparts + simple creatures)
	var/materials_count = 0
	/// List tracking bodypart types used - e.g., list("head" = 2, "chest" = 1, "l_arm" = 3)
	var/list/bodyparts_used = list()
	/// List tracking simple creatures incorporated - e.g., list("mouse" = 2, "chicken" = 1)
	var/list/simple_creatures_used = list()
	/// Reference to the mob who created this artwork
	var/datum/weakref/creator_ref
	/// Whether the artwork needs refinement before more bodies can be added
	var/needs_refinement = FALSE
	/// Custom description set by the artist
	var/custom_desc
	/// Technique grade from refinement minigame (F/C/B/A/S) - calculated as average of all minigames
	var/technique_grade
	/// List of all technique scores from minigames (stored as numbers for averaging)
	var/list/technique_scores = list()
	/// Final grade from Maestro (F/C/B/A/S)
	var/final_grade
	/// Maestro's critique text
	var/final_grade_critique
	/// Reference to Maestro who graded it
	var/datum/weakref/graded_by_ref

	/// SP damage dealt to non-artists on examine (scales with tier)
	var/list/examine_sp_damage = list(5, 10, 15, 25, 40)
	/// SP healed for artists on examine (scales with tier)
	var/list/examine_sp_heal = list(3, 6, 10, 15, 25)

/obj/structure/corporist_artwork/Initialize(mapload, mob/creator)
	. = ..()
	if(creator)
		creator_ref = WEAKREF(creator)
	update_icon()

/obj/structure/corporist_artwork/examine(mob/user)
	. = ..()

	// Show custom description or default
	if(custom_desc)
		. += span_notice("\"[custom_desc]\"")

	// Show bodyparts used
	if(length(bodyparts_used))
		var/parts_text = ""
		for(var/part_type in bodyparts_used)
			if(parts_text != "")
				parts_text += ", "
			parts_text += "[bodyparts_used[part_type]]x [part_type]"
		. += span_notice("Incorporated remains: [parts_text]")

	// Show simple creatures used
	if(length(simple_creatures_used))
		var/creatures_text = ""
		for(var/creature_name in simple_creatures_used)
			if(creatures_text != "")
				creatures_text += ", "
			creatures_text += "[simple_creatures_used[creature_name]]x [creature_name]"
		. += span_notice("Simple-minded creatures: [creatures_text]")

	// Show final grade (visible to everyone)
	if(final_grade)
		var/grader_name = "Unknown"
		var/mob/grader = graded_by_ref?.resolve()
		if(grader)
			grader_name = grader.name
		. += span_purple("Final Grade: [final_grade][final_grade_critique ? " - '[final_grade_critique]'" : ""] - [grader_name]")
	else
		. += span_purple("Awaiting judgment.")

	// Check if examiner can create art
	var/is_artist = can_create_art(user)

	// Show tier and technique grade (only to artists)
	if(is_artist)
		. += span_notice("Tier: [tier]/5 ([materials_count] materials)")
		if(technique_grade)
			var/technique_desc = get_technique_description(technique_grade)
			. += span_notice("Technique: [technique_grade] - [technique_desc]")

	// Show refinement status
	if(needs_refinement)
		. += span_warning("This artwork needs refinement before more can be added.")

	// Apply SP effects based on viewer type
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(is_artist)
			// Artists heal SP
			var/heal_amount = examine_sp_heal[tier]
			H.adjustSanityLoss(-heal_amount)
			to_chat(user, span_nicegreen("You appreciate the craftsmanship. The artistic vision soothes your mind."))
		else
			// Non-artists take SP damage
			var/damage_amount = examine_sp_damage[tier]
			H.adjustSanityLoss(damage_amount)
			to_chat(user, span_warning("The artwork disturbs you deeply. You feel your sanity slipping..."))

/// Returns the technique grade description
/obj/structure/corporist_artwork/proc/get_technique_description(grade)
	switch(grade)
		if("F")
			return "The craftsmanship is crude and amateurish."
		if("C")
			return "Basic competence, but lacking refinement."
		if("B")
			return "Solid technique with clear artistic intent."
		if("A")
			return "Masterful technique, every cut deliberate."
		if("S")
			return "Transcendent skill that defies comprehension."
	return "Unknown"

/// Check if a mob can create/interact with art
/obj/structure/corporist_artwork/proc/can_create_art(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user

	// Check for Maestro/Apprentice species
	if(istype(H.dna?.species, /datum/species/corporist_maestro) || istype(H.dna?.species, /datum/species/corporist_apprentice))
		return TRUE

	// Check for Student or Inspired component
	if(H.GetComponent(/datum/component/corporist_student) || H.GetComponent(/datum/component/inspired_artist))
		return TRUE

	return FALSE

/// Clicking with empty hand to refine
/obj/structure/corporist_artwork/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user

	// Check if they can create art
	if(!can_create_art(H))
		to_chat(H, span_notice("You examine the disturbing artwork..."))
		return

	// If it needs refinement, start the minigame
	if(needs_refinement)
		to_chat(H, span_notice("You begin refining the artwork..."))
		var/datum/sculpting_minigame/minigame = new(H, src)
		minigame.ui_interact(H)
		return

	// Otherwise just examine
	to_chat(H, span_notice("The artwork is refined and ready for more materials or judgment."))

/// Adding bodyparts by hitting the artwork
/obj/structure/corporist_artwork/attackby(obj/item/I, mob/living/user, params)
	// Check if it's a bodypart
	if(istype(I, /obj/item/bodypart))
		if(!can_create_art(user))
			to_chat(user, span_warning("You have no idea how to incorporate this into the artwork."))
			return

		if(needs_refinement)
			to_chat(user, span_warning("The artwork needs refinement before more can be added."))
			return

		var/obj/item/bodypart/BP = I
		add_bodypart(BP, user)
		return

	return ..()

/// Wrench to anchor/unanchor the artwork
/obj/structure/corporist_artwork/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(anchored)
		to_chat(user, span_notice("You begin loosening the bolts on [src]..."))
	else
		to_chat(user, span_notice("You begin securing [src] to the floor..."))

	if(!do_after(user, 2 SECONDS, src))
		to_chat(user, span_warning("You were interrupted!"))
		return TRUE

	anchored = !anchored
	if(anchored)
		to_chat(user, span_notice("You secure [src] to the floor."))
	else
		to_chat(user, span_notice("You unanchor [src] from the floor."))
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	return TRUE

/// Add a bodypart to the artwork
/obj/structure/corporist_artwork/proc/add_bodypart(obj/item/bodypart/BP, mob/user)
	to_chat(user, span_notice("You begin incorporating the [BP.name] into your work..."))

	if(!do_after(user, 3 SECONDS, src))
		to_chat(user, span_warning("You were interrupted!"))
		return

	// Track the bodypart type
	var/part_type = BP.body_zone
	if(!bodyparts_used[part_type])
		bodyparts_used[part_type] = 0
	bodyparts_used[part_type]++

	materials_count++
	needs_refinement = TRUE

	to_chat(user, span_nicegreen("You carefully incorporate the [BP.name] into the artwork."))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	// Store the bodypart inside the artwork
	if(user.transferItemToLoc(BP, src))
		BP.forceMove(src)
	else
		BP.forceMove(src)

	// Add EXP for adding a body part
	var/datum/component/artistic_exp/exp_comp = user.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("add_body")

	check_tier_upgrade()
	update_icon()

/// Buckle a dead mob to add its corpse
/obj/structure/corporist_artwork/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(!can_create_art(user))
		to_chat(user, span_warning("You have no idea how to incorporate this into the artwork."))
		return FALSE

	if(M.stat != DEAD)
		to_chat(user, span_warning("The subject must be dead first."))
		return FALSE

	if(!istype(M, /mob/living/simple_animal))
		to_chat(user, span_warning("Only simple creatures can be incorporated into artwork."))
		return FALSE

	if(needs_refinement)
		to_chat(user, span_warning("The artwork needs refinement before more can be added."))
		return FALSE

	to_chat(user, span_notice("You begin incorporating [M]'s remains into the artwork..."))

	if(!do_after(user, 5 SECONDS, src))
		to_chat(user, span_warning("You were interrupted!"))
		return FALSE

	add_corpse(M, user)
	return TRUE

/// Calculate material contribution based on mob's max health
/obj/structure/corporist_artwork/proc/get_health_contribution(mob/living/M)
	var/mob_health = M.maxHealth
	if(mob_health >= 4000)
		return 6
	if(mob_health >= 2000)
		return 5
	if(mob_health >= 1500)
		return 4
	if(mob_health >= 1000)
		return 3
	if(mob_health >= 500)
		return 2
	if(mob_health >= 100)
		return 1
	return 1 // Minimum contribution

/// Add a full corpse to the artwork
/obj/structure/corporist_artwork/proc/add_corpse(mob/living/simple_animal/M, mob/user)
	// Track the creature by name
	var/creature_name = M.name
	if(!simple_creatures_used[creature_name])
		simple_creatures_used[creature_name] = 0
	simple_creatures_used[creature_name]++

	// Creatures contribute based on their max health
	var/contribution = get_health_contribution(M)
	materials_count += contribution
	needs_refinement = TRUE

	to_chat(user, span_nicegreen("You incorporate [M]'s remains into the artwork."))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	// Gib the corpse dramatically
	M.gib()

	check_tier_upgrade()
	update_icon()

/// Check if the artwork should upgrade to a higher tier
/obj/structure/corporist_artwork/proc/check_tier_upgrade()
	var/new_tier = 1
	if(materials_count >= 27)
		new_tier = 5
	else if(materials_count >= 19)
		new_tier = 4
	else if(materials_count >= 12)
		new_tier = 3
	else if(materials_count >= 5)
		new_tier = 2

	if(new_tier > tier)
		tier = new_tier
		update_tier_appearance()

/// Update appearance based on tier
/obj/structure/corporist_artwork/proc/update_tier_appearance()
	icon_state = tier_icon_states[tier]
	switch(tier)
		if(1)
			name = "crude sculpture"
			desc = "A basic arrangement of flesh and bone. The artist's vision is barely visible."
		if(2)
			name = "developing piece"
			desc = "Multiple forms intertwined. The artwork begins to take shape."
		if(3)
			name = "refined work"
			desc = "A disturbing yet captivating arrangement. Clear artistic intent."
			density = TRUE
		if(4)
			name = "masterpiece"
			desc = "A horrifying opus of flesh and bone. Those who gaze upon it feel... something."
			density = TRUE
		if(5)
			name = "magnum opus"
			desc = "A transcendent work of corporeal art. It seems almost alive."
			density = TRUE

/// Convert letter grade to numeric value for averaging
/obj/structure/corporist_artwork/proc/grade_to_number(grade)
	switch(grade)
		if("F")
			return 1
		if("C")
			return 2
		if("B")
			return 3
		if("A")
			return 4
		if("S")
			return 5
	return 1

/// Convert numeric average to letter grade
/obj/structure/corporist_artwork/proc/number_to_grade(value)
	if(value >= 4.5)
		return "S"
	if(value >= 3.5)
		return "A"
	if(value >= 2.5)
		return "B"
	if(value >= 1.5)
		return "C"
	return "F"

/// Called when refinement is completed
/obj/structure/corporist_artwork/proc/complete_refinement(grade)
	// Add this grade to the list and calculate the average
	technique_scores += grade_to_number(grade)

	var/total = 0
	for(var/score in technique_scores)
		total += score
	var/average = total / length(technique_scores)
	technique_grade = number_to_grade(average)

	needs_refinement = FALSE
	to_chat(get_turf(src), span_notice("The artwork has been refined. This session: [grade] | Overall: [technique_grade]"))

/// Called when Maestro assigns a final grade
/obj/structure/corporist_artwork/proc/assign_final_grade(mob/grader, grade, critique)
	final_grade = grade
	final_grade_critique = critique
	graded_by_ref = WEAKREF(grader)

	// Find the creator and apply EXP effects
	var/mob/creator = creator_ref?.resolve()
	if(creator && ishuman(creator))
		apply_grade_exp(creator, grade)

/// Apply EXP gain/loss based on grade
/obj/structure/corporist_artwork/proc/apply_grade_exp(mob/living/carbon/human/artist, grade)
	var/datum/component/artistic_exp/exp_comp = artist.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		return

	var/next_threshold = exp_comp.get_next_threshold()
	var/exp_change = 0

	switch(grade)
		if("F")
			exp_change = -round(next_threshold * 0.5)
			to_chat(artist, span_boldwarning("Your work has been judged harshly. You lose artistic experience."))
		if("C")
			exp_change = -round(next_threshold * 0.25)
			to_chat(artist, span_warning("Your work was deemed mediocre. You lose some artistic experience."))
		if("B")
			exp_change = round(next_threshold * 0.25)
			to_chat(artist, span_notice("Your work was judged favorably. You gain artistic experience."))
		if("A")
			exp_change = round(next_threshold * 0.5)
			to_chat(artist, span_nicegreen("Your work was deemed excellent! You gain significant artistic experience."))
		if("S")
			exp_change = next_threshold
			to_chat(artist, span_greentext("Your work is a masterpiece! You gain a full skill point worth of experience!"))

	exp_comp.modify_exp(exp_change)
