// Corporist Artwork System
// Artworks created by The Ring's Corporist school from flesh and bone

/obj/structure/corporist_artwork
	name = "crude sculpture"
	desc = "A basic arrangement of flesh and bone. The artist's vision is barely visible."
	icon = 'icons/mob/blob.dmi'
	icon_state = "still_blobpod"
	anchored = TRUE
	density = FALSE
	can_buckle = TRUE
	buckle_lying = 0
	max_integrity = 200

	/// Icon files for each tier
	var/static/list/tier_icons = list(
		'icons/mob/blob.dmi',                              // Tier 1
		'icons/mob/cult.dmi',                              // Tier 2
		'ModularLobotomy/_Lobotomyicons/32x32.dmi',        // Tier 3
		'ModularLobotomy/_Lobotomyicons/32x48.dmi',        // Tier 4
		'ModularLobotomy/_Lobotomyicons/48x48.dmi',        // Tier 5
		'ModularLobotomy/_Lobotomyicons/64x96.dmi'         // Tier 6 (hidden)
	)
	/// Icon states for each tier
	var/static/list/tier_icon_states = list(
		"still_blobpod",    // Tier 1
		"meat_bomb",        // Tier 2
		"meatboi",          // Tier 3
		"meatboi_rifle",    // Tier 4
		"last_shot",        // Tier 5
		"flesh_idol"        // Tier 6 (hidden)
	)
	/// Pixel X offset for each tier (for larger sprites)
	var/static/list/tier_pixel_x = list(0, 0, 0, 0, -8, -16)

	/// Current tier of the artwork (1-6)
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
	var/list/examine_sp_damage = list(5, 10, 15, 25, 40, 60)
	/// SP healed for artists on examine (scales with tier)
	var/list/examine_sp_heal = list(3, 6, 10, 15, 25, 40)
	/// Whether the artwork has been vandalized with spray paint
	var/vandalized = FALSE

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
		. += span_notice("Tier: [tier]/6 ([materials_count] materials)")
		if(technique_grade)
			var/technique_desc = get_technique_description(technique_grade)
			. += span_notice("Technique: [technique_grade] - [technique_desc]")

	// Show vandalism status
	if(vandalized)
		. += span_boldwarning("This artwork has been vandalized! Its technique has been ruined.")

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
	// Check if it's a spray bottle - vandalism!
	if(istype(I, /obj/item/reagent_containers/spray))
		if(vandalized)
			to_chat(user, span_warning("This artwork has already been vandalized."))
			return

		to_chat(user, span_warning("You begin spraying black paint over the artwork..."))

		if(!do_after(user, 3 SECONDS, src))
			to_chat(user, span_warning("You were interrupted!"))
			return

		vandalize_artwork(user)
		return

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

/// Vandalize the artwork with spray paint - ruins technique and turns it black
/obj/structure/corporist_artwork/proc/vandalize_artwork(mob/user)
	vandalized = TRUE

	// Ruin the technique grade
	technique_grade = "F"
	technique_scores = list(1) // Reset to just an F score

	// Turn the artwork black
	add_atom_colour("#1a1a1a", FIXED_COLOUR_PRIORITY)

	// Update description to reflect vandalism
	desc = "This artwork has been defaced with black spray paint. The original craftsmanship is ruined."

	playsound(src, 'sound/effects/spray.ogg', 50, TRUE)
	to_chat(user, span_boldwarning("You vandalize the artwork, ruining its technique!"))

	// Visible message for others
	if(user)
		visible_message(span_warning("[user] sprays black paint all over [src]!"), ignored_mobs = list(user))

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
	if(materials_count >= 60)
		new_tier = 6
	else if(materials_count >= 27)
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
	icon = tier_icons[tier]
	icon_state = tier_icon_states[tier]
	pixel_x = tier_pixel_x[tier]
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
			name = "opus"
			desc = "A transcendent work of corporeal art. It seems almost alive."
			density = TRUE
		if(6)
			name = "magnum opus"
			desc = "A towering monument of flesh and bone that seems to pulse with unnatural life. Those who behold it are forever changed."
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

	// Record the grade for round end tracking
	exp_comp.record_grade(grade)

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

// ================== CUSTOM ARTWORK ==================
// Player-composed artwork using a 48x48 grid editor
// Standalone structure (not a subtype of corporist_artwork)

GLOBAL_LIST_EMPTY(bodypart_icon_cache)

/// Cache and return base64-encoded body part icon for TGUI
/proc/get_bodypart_base64(icon_file, icon_state_name, dir = SOUTH, rotation = 0)
	var/key = "[icon_file]:[icon_state_name]:[dir]:[rotation]"
	if(GLOB.bodypart_icon_cache[key])
		return GLOB.bodypart_icon_cache[key]
	var/icon/I = icon(icon_file, icon_state_name, dir)
	if(rotation)
		I.Turn(rotation)
	var/base64 = icon2base64(I)
	GLOB.bodypart_icon_cache[key] = base64
	return base64

/// Helper: check if a mob can create/interact with corporist art
/proc/is_corporist_artist(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	if(istype(H.dna?.species, /datum/species/corporist_maestro) || istype(H.dna?.species, /datum/species/corporist_apprentice))
		return TRUE
	if(H.GetComponent(/datum/component/corporist_student) || H.GetComponent(/datum/component/inspired_artist))
		return TRUE
	return FALSE

/obj/structure/custom_corporist_artwork
	name = "custom artwork"
	desc = "An empty pedestal awaiting an artist's vision."
	icon = 'icons/obj/statue.dmi'
	icon_state = "base"
	anchored = TRUE
	density = TRUE
	max_integrity = 200

	/// Stored body parts: id -> list("body_zone", "icon_file", "icon_state")
	var/list/stored_parts = list()
	/// Placement data: id -> list("grid_x", "grid_y", "rotation", "tint")
	var/list/placed_parts = list()
	/// Vein pixels: keyed as "x,y" -> TRUE, representing painted cells
	var/list/vein_pixels = list()
	/// Next unique ID for stored parts
	var/next_part_id = 1
	/// Active TGUI editor datum
	var/datum/custom_artwork_editor/editor
	/// Whether veins render above body parts
	var/veins_above = FALSE
	/// Number of body parts added (for examine)
	var/body_part_count = 0
	/// Reference to the artist who created this artwork
	var/datum/weakref/creator_ref
	/// Custom description set by the artist (via Describe Artwork action)
	var/custom_desc
	/// Final grade from Maestro (F/C/B/A/S)
	var/final_grade
	/// Maestro's critique text
	var/final_grade_critique
	/// Reference to Maestro who graded it
	var/datum/weakref/graded_by_ref
	/// SP damage to non-artists on examine
	var/examine_sp_damage = 15
	/// SP heal to artists on examine
	var/examine_sp_heal = 10

/obj/structure/custom_corporist_artwork/Initialize(mapload, mob/creator)
	. = ..()
	if(creator)
		creator_ref = WEAKREF(creator)

/obj/structure/custom_corporist_artwork/Destroy()
	if(editor)
		QDEL_NULL(editor)
	return ..()

/obj/structure/custom_corporist_artwork/examine(mob/user)
	. = ..()

	if(custom_desc)
		. += span_notice("\"[custom_desc]\"")

	if(body_part_count)
		. += span_notice("It incorporates [body_part_count] body part[body_part_count == 1 ? "" : "s"].")

	if(final_grade)
		var/grader_name = "Unknown"
		var/mob/grader = graded_by_ref?.resolve()
		if(grader)
			grader_name = grader.name
		. += span_purple("Final Grade: [final_grade][final_grade_critique ? " - '[final_grade_critique]'" : ""] - [grader_name]")
	else
		. += span_purple("Awaiting judgment.")

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(is_corporist_artist(H))
			H.adjustSanityLoss(-examine_sp_heal)
			to_chat(user, span_nicegreen("You appreciate the craftsmanship. The artistic vision soothes your mind."))
		else
			H.adjustSanityLoss(examine_sp_damage)
			to_chat(user, span_warning("The artwork disturbs you deeply. You feel your sanity slipping..."))

/obj/structure/custom_corporist_artwork/attack_hand(mob/living/user, list/modifiers)
	if(!ishuman(user))
		return ..()

	var/mob/living/carbon/human/H = user
	if(!is_corporist_artist(H))
		to_chat(H, span_notice("You examine the disturbing artwork..."))
		return

	if(!length(stored_parts))
		to_chat(H, span_warning("The artwork has no body parts to arrange. Hit it with body parts first."))
		return

	to_chat(H, span_notice("You begin arranging the artwork..."))
	if(!editor)
		editor = new(src)
	editor.ui_interact(H)

/obj/structure/custom_corporist_artwork/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/bodypart))
		if(!is_corporist_artist(user))
			to_chat(user, span_warning("You have no idea how to incorporate this into the artwork."))
			return

		var/obj/item/bodypart/BP = I
		add_bodypart_custom(BP, user)
		return

	return ..()

/// Add a bodypart to the custom artwork's storage
/obj/structure/custom_corporist_artwork/proc/add_bodypart_custom(obj/item/bodypart/BP, mob/user)
	var/part_id = "[next_part_id]"
	next_part_id++

	stored_parts[part_id] = list(
		"body_zone" = BP.body_zone,
		"icon_file" = "[BP.icon]",
		"icon_state" = BP.icon_state
	)

	body_part_count++

	to_chat(user, span_nicegreen("You incorporate the [BP.name] into the artwork's collection."))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	if(user.transferItemToLoc(BP, src))
		BP.forceMove(src)
	else
		BP.forceMove(src)

	var/datum/component/artistic_exp/exp_comp = user.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("add_body")

	if(editor)
		SStgui.update_static_data(user, editor)

/// Assign a final grade (called by Maestro's judge_artwork action)
/obj/structure/custom_corporist_artwork/proc/assign_final_grade(mob/grader, grade, critique)
	final_grade = grade
	final_grade_critique = critique
	graded_by_ref = WEAKREF(grader)

	var/mob/creator = creator_ref?.resolve()
	if(creator && ishuman(creator))
		apply_grade_exp(creator, grade)

/// Apply EXP gain/loss based on grade
/obj/structure/custom_corporist_artwork/proc/apply_grade_exp(mob/living/carbon/human/artist, grade)
	var/datum/component/artistic_exp/exp_comp = artist.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		return

	exp_comp.record_grade(grade)

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

/obj/structure/custom_corporist_artwork/update_overlays()
	. = ..()

	if(!veins_above)
		. += generate_vein_overlay()

	for(var/part_id in placed_parts)
		var/list/placement = placed_parts[part_id]
		var/list/part_data = stored_parts[part_id]
		if(!part_data || !placement)
			continue

		var/icon/part_icon = icon(file(part_data["icon_file"]), part_data["icon_state"], SOUTH)
		var/rotation = placement["rotation"]
		if(rotation)
			part_icon.Turn(rotation)
		var/tint = placement["tint"]
		if(tint && tint != "#ffffff")
			part_icon.Blend(tint, ICON_MULTIPLY)

		var/mutable_appearance/MA = mutable_appearance(part_icon)
		MA.pixel_x = placement["grid_x"] - 24
		MA.pixel_y = 23 - placement["grid_y"]
		. += MA

	if(veins_above)
		. += generate_vein_overlay()

/// Generate the vein overlay icon from vein_pixels
/obj/structure/custom_corporist_artwork/proc/generate_vein_overlay()
	if(!length(vein_pixels))
		return list()

	// Build 48x48 color grid: transparent by default, dark red where veins painted
	var/list/data = list()
	for(var/y in 1 to 48)
		for(var/x in 1 to 48)
			if(vein_pixels["[x],[y]"])
				data += "#8b0000ff"
			else
				data += "#00000000"

	var/data_string = data.Join("")
	var/png_path = "data/tmp/custom_artwork_[REF(src)].png"
	var/result = rustg_dmi_create_png(png_path, "48", "48", data_string)
	if(result)
		return list()

	var/icon/vein_icon = new(png_path)
	var/mutable_appearance/MA = mutable_appearance(vein_icon)
	MA.pixel_x = -8
	MA.pixel_y = -8
	return list(MA)

/// Check if all placed parts form a connected, grounded structure
/obj/structure/custom_corporist_artwork/proc/validate_placement()
	if(!length(placed_parts))
		return TRUE

	var/has_grounded = FALSE
	for(var/part_id in placed_parts)
		var/list/placement = placed_parts[part_id]
		if(placement["grid_y"] + 32 >= 48)
			has_grounded = TRUE
			break

	if(!has_grounded)
		return FALSE

	return check_connectivity()

/// BFS connectivity check - all placed parts must be reachable from a grounded part
/obj/structure/custom_corporist_artwork/proc/check_connectivity()
	if(length(placed_parts) <= 1)
		return TRUE

	var/list/nodes = list()
	for(var/part_id in placed_parts)
		nodes += part_id

	var/list/visited = list()
	var/list/queue = list(nodes[1])
	visited[nodes[1]] = TRUE

	while(length(queue))
		var/current = queue[1]
		queue.Cut(1, 2)

		for(var/other_id in nodes)
			if(visited[other_id])
				continue
			if(parts_adjacent(current, other_id))
				visited[other_id] = TRUE
				queue += other_id

	return length(visited) == length(nodes)

/// Check if two placed parts are adjacent (bounding boxes overlap or touch within 1px)
/obj/structure/custom_corporist_artwork/proc/parts_adjacent(part_id_a, part_id_b)
	var/list/a = placed_parts[part_id_a]
	var/list/b = placed_parts[part_id_b]
	if(!a || !b)
		return FALSE

	var/ax1 = a["grid_x"]
	var/ay1 = a["grid_y"]
	var/ax2 = ax1 + 31
	var/ay2 = ay1 + 31

	var/bx1 = b["grid_x"]
	var/by1 = b["grid_y"]
	var/bx2 = bx1 + 31
	var/by2 = by1 + 31

	// Check if bounding boxes overlap or are within 1px
	if(ax1 > bx2 + 1 || bx1 > ax2 + 1)
		return FALSE
	if(ay1 > by2 + 1 || by1 > ay2 + 1)
		return FALSE

	return TRUE

/// Check if a part is adjacent to any vein pixel
/obj/structure/custom_corporist_artwork/proc/part_touches_vein(part_id)
	var/list/placement = placed_parts[part_id]
	if(!placement)
		return FALSE

	var/px1 = placement["grid_x"]
	var/py1 = placement["grid_y"]
	var/px2 = px1 + 31
	var/py2 = py1 + 31

	// Expand by 1 for adjacency
	for(var/key in vein_pixels)
		var/list/coords = splittext(key, ",")
		var/vx = text2num(coords[1])
		var/vy = text2num(coords[2])
		if(vx >= px1 - 1 && vx <= px2 + 1 && vy >= py1 - 1 && vy <= py2 + 1)
			return TRUE
	return FALSE

/// Full connectivity check including veins as connectors
/obj/structure/custom_corporist_artwork/proc/check_full_connectivity()
	if(length(placed_parts) <= 1)
		return TRUE

	var/list/nodes = list()
	for(var/part_id in placed_parts)
		nodes += part_id

	var/list/visited = list()
	var/list/queue = list(nodes[1])
	visited[nodes[1]] = TRUE

	while(length(queue))
		var/current = queue[1]
		queue.Cut(1, 2)

		for(var/other_id in nodes)
			if(visited[other_id])
				continue
			if(parts_adjacent(current, other_id))
				visited[other_id] = TRUE
				queue += other_id
			else if(parts_connected_via_veins(current, other_id))
				visited[other_id] = TRUE
				queue += other_id

	return length(visited) == length(nodes)

/// Check if two parts are connected through vein segments
/obj/structure/custom_corporist_artwork/proc/parts_connected_via_veins(part_id_a, part_id_b)
	if(part_touches_vein(part_id_a) && part_touches_vein(part_id_b))
		return TRUE
	return FALSE

// ================== CUSTOM ARTWORK EDITOR ==================

/datum/custom_artwork_editor
	/// The artwork being edited
	var/obj/structure/custom_corporist_artwork/artwork
	/// Last time arrangement EXP was granted
	var/last_arrange_exp = 0

/datum/custom_artwork_editor/New(obj/structure/custom_corporist_artwork/parent)
	artwork = parent

/datum/custom_artwork_editor/Destroy()
	if(artwork?.editor == src)
		artwork.editor = null
	artwork = null
	return ..()

/datum/custom_artwork_editor/ui_state(mob/user)
	return GLOB.conscious_state

/datum/custom_artwork_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CustomArtworkEditor")
		ui.open()

/datum/custom_artwork_editor/ui_static_data(mob/user)
	var/list/data = list()
	data["gridSize"] = 48

	var/list/part_icons = list()
	for(var/part_id in artwork.stored_parts)
		var/list/part_data = artwork.stored_parts[part_id]
		var/list/rotations = list()
		for(var/rot in list(0, 90, 180, 270))
			rotations["[rot]"] = get_bodypart_base64(
				file(part_data["icon_file"]),
				part_data["icon_state"],
				SOUTH,
				rot
			)
		part_icons[part_id] = rotations
	data["partIcons"] = part_icons

	return data

/datum/custom_artwork_editor/ui_data(mob/user)
	var/list/data = list()

	var/list/stored = list()
	for(var/part_id in artwork.stored_parts)
		var/list/part_data = artwork.stored_parts[part_id]
		stored += list(list(
			"id" = part_id,
			"bodyZone" = part_data["body_zone"],
			"placed" = !!artwork.placed_parts[part_id]
		))
	data["storedParts"] = stored

	var/list/placed = list()
	for(var/part_id in artwork.placed_parts)
		var/list/placement = artwork.placed_parts[part_id]
		placed += list(list(
			"id" = part_id,
			"gridX" = placement["grid_x"],
			"gridY" = placement["grid_y"],
			"rotation" = placement["rotation"],
			"tint" = placement["tint"]
		))
	data["placedParts"] = placed

	// Send vein pixels as flat list of {x, y}
	var/list/vein_list = list()
	for(var/key in artwork.vein_pixels)
		var/list/coords = splittext(key, ",")
		vein_list += list(list(
			"x" = text2num(coords[1]),
			"y" = text2num(coords[2])
		))
	data["veinPixels"] = vein_list
	data["veinsAbove"] = artwork.veins_above

	return data

/datum/custom_artwork_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	var/mob/living/carbon/human/user = usr
	if(!istype(user))
		return

	switch(action)
		if("place_part")
			var/part_id = params["id"]
			var/grid_x = clamp(text2num(params["x"]), 0, 16)
			var/grid_y = clamp(text2num(params["y"]), 0, 16)
			if(!artwork.stored_parts[part_id])
				return
			if(artwork.placed_parts[part_id])
				return

			artwork.placed_parts[part_id] = list(
				"grid_x" = grid_x,
				"grid_y" = grid_y,
				"rotation" = 0,
				"tint" = "#ffffff"
			)

			if(!artwork.validate_placement())
				artwork.placed_parts -= part_id
				return

			grant_arrange_exp(user)
			. = TRUE

		if("move_part")
			var/part_id = params["id"]
			var/grid_x = clamp(text2num(params["x"]), 0, 16)
			var/grid_y = clamp(text2num(params["y"]), 0, 16)
			if(!artwork.placed_parts[part_id])
				return

			var/list/current = artwork.placed_parts[part_id]
			var/list/old_placement = current.Copy()
			artwork.placed_parts[part_id]["grid_x"] = grid_x
			artwork.placed_parts[part_id]["grid_y"] = grid_y

			if(!artwork.validate_placement())
				artwork.placed_parts[part_id] = old_placement
				return

			grant_arrange_exp(user)
			. = TRUE

		if("rotate_part")
			var/part_id = params["id"]
			if(!artwork.placed_parts[part_id])
				return

			var/old_rotation = artwork.placed_parts[part_id]["rotation"]
			artwork.placed_parts[part_id]["rotation"] = (old_rotation + 90) % 360

			if(!artwork.validate_placement())
				artwork.placed_parts[part_id]["rotation"] = old_rotation
				return

			grant_arrange_exp(user)
			. = TRUE

		if("set_tint")
			var/part_id = params["id"]
			var/tint = params["tint"]
			if(!artwork.placed_parts[part_id])
				return

			var/list/valid_tints = list("#ffffff", "#ff4444", "#888888", "#ddcccc", "#445544")
			if(!(tint in valid_tints))
				return

			artwork.placed_parts[part_id]["tint"] = tint
			. = TRUE

		if("remove_part")
			var/part_id = params["id"]
			if(!artwork.placed_parts[part_id])
				return

			var/list/current_place = artwork.placed_parts[part_id]
			var/list/old_placement = current_place.Copy()
			artwork.placed_parts -= part_id

			if(length(artwork.placed_parts) && !artwork.validate_placement())
				artwork.placed_parts[part_id] = old_placement
				return

			. = TRUE

		if("paint_veins")
			// Params: list of cells to paint
			var/list/cells = params["cells"]
			if(!islist(cells))
				return
			for(var/list/cell in cells)
				var/cx = clamp(text2num(cell["x"]), 1, 48)
				var/cy = clamp(text2num(cell["y"]), 1, 48)
				artwork.vein_pixels["[cx],[cy]"] = TRUE
			. = TRUE

		if("erase_veins")
			var/list/cells = params["cells"]
			if(!islist(cells))
				return
			var/list/old_pixels = artwork.vein_pixels.Copy()
			for(var/list/cell in cells)
				var/cx = clamp(text2num(cell["x"]), 1, 48)
				var/cy = clamp(text2num(cell["y"]), 1, 48)
				artwork.vein_pixels -= "[cx],[cy]"

			if(length(artwork.placed_parts) > 1 && !artwork.check_full_connectivity())
				artwork.vein_pixels = old_pixels
				return

			. = TRUE

		if("clear_veins")
			if(!length(artwork.vein_pixels))
				return

			var/list/old_pixels = artwork.vein_pixels.Copy()
			artwork.vein_pixels = list()

			if(length(artwork.placed_parts) > 1 && !artwork.check_full_connectivity())
				artwork.vein_pixels = old_pixels
				return

			. = TRUE

		if("toggle_veins_layer")
			artwork.veins_above = !artwork.veins_above
			. = TRUE

		if("submit")
			if(!artwork.validate_placement())
				to_chat(user, span_warning("The artwork's structure is invalid. Ensure parts are connected and grounded."))
				return

			artwork.update_icon()

			var/datum/component/artistic_exp/exp_comp = user.GetComponent(/datum/component/artistic_exp)
			if(exp_comp)
				exp_comp.add_activity_exp("submit_custom")

			to_chat(user, span_nicegreen("You finalize the arrangement of your custom artwork."))
			playsound(artwork, 'sound/effects/splat.ogg', 50, TRUE)
			. = TRUE

/// Grant arrangement EXP with 5-second throttle
/datum/custom_artwork_editor/proc/grant_arrange_exp(mob/living/carbon/human/user)
	if(world.time < last_arrange_exp + 5 SECONDS)
		return
	last_arrange_exp = world.time
	var/datum/component/artistic_exp/exp_comp = user.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("arrange_part")

