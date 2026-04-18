// Corporist Artwork System
// Artworks created by The Ring's Corporist school from flesh and bone

// ================== ARTIST'S TOOLKIT ==================

/obj/item/storage/box/corporist_toolkit
	name = "artist's toolkit"
	desc = "A box containing the essential tools of the Corporist trade."
	icon_state = "secbox"
	illustration = null

/obj/item/storage/box/corporist_toolkit/PopulateContents()
	new /obj/item/shears(src)
	new /obj/item/reagent_containers/syringe(src)
	new /obj/item/reagent_containers/blood(src)
	new /obj/item/reagent_containers/blood(src)
	new /obj/item/wrench(src)

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
	if(istype(I, /obj/item/reagent_containers/spray) || istype(I, /obj/item/toy/crayon))
		if(vandalized)
			to_chat(user, span_warning("This artwork has already been vandalized."))
			return

		if(istype(I, /obj/item/toy/crayon/spraycan))
			to_chat(user, span_warning("You begin spraying graffiti over the artwork..."))
		else if(istype(I, /obj/item/reagent_containers/spray))
			to_chat(user, span_warning("You begin spraying paint over the artwork..."))
		else
			to_chat(user, span_warning("You begin scrawling over the artwork..."))

		if(!do_after(user, 3 SECONDS, src))
			to_chat(user, span_warning("You were interrupted!"))
			return

		vandalize_artwork(user, I)
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
/obj/structure/corporist_artwork/proc/vandalize_artwork(mob/user, obj/item/tool)
	vandalized = TRUE

	technique_grade = "F"
	technique_scores = list(1)

	add_atom_colour("#1a1a1a", FIXED_COLOUR_PRIORITY)
	playsound(src, 'sound/effects/spray.ogg', 50, TRUE)

	if(istype(tool, /obj/item/toy/crayon/spraycan))
		desc = "This artwork has been covered in spray-painted graffiti. The original craftsmanship is ruined."
		to_chat(user, span_boldwarning("You tag the artwork with graffiti, ruining its technique!"))
		visible_message(span_warning("[user] sprays graffiti all over [src]!"), ignored_mobs = list(user))
	else if(istype(tool, /obj/item/toy/crayon))
		desc = "This artwork has been scrawled over with crayon. The original craftsmanship is ruined."
		to_chat(user, span_boldwarning("You deface the artwork with crayon, ruining its technique!"))
		visible_message(span_warning("[user] scrawls all over [src] with a crayon!"), ignored_mobs = list(user))
	else
		desc = "This artwork has been defaced with spray paint. The original craftsmanship is ruined."
		to_chat(user, span_boldwarning("You vandalize the artwork, ruining its technique!"))
		visible_message(span_warning("[user] sprays paint all over [src]!"), ignored_mobs = list(user))

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

/// Calculate non-transparent bounding box of an icon (returns list("ox", "oy", "w", "h"))
/proc/get_icon_crop_bounds(icon_file, icon_state_name, dir = SOUTH, rotation = 0)
	var/icon/I = icon(icon_file, icon_state_name, dir)
	if(rotation)
		I.Turn(rotation)
	return get_icon_crop_bounds_from_icon(I)

/// Calculate non-transparent bounding box from a pre-built icon object
/proc/get_icon_crop_bounds_from_icon(icon/I)
	var/iw = I.Width()
	var/ih = I.Height()
	var/min_x = iw
	var/min_y = ih
	var/max_x = -1
	var/max_y = -1
	for(var/y in 1 to ih)
		for(var/x in 1 to iw)
			var/pixel = I.GetPixel(x, y)
			if(pixel)
				if(x - 1 < min_x)
					min_x = x - 1
				if(x - 1 > max_x)
					max_x = x - 1
				var/ty = ih - y
				if(ty < min_y)
					min_y = ty
				if(ty > max_y)
					max_y = ty
	if(max_x == -1)
		return list("ox" = 0, "oy" = 0, "w" = iw, "h" = ih)
	return list("ox" = min_x, "oy" = min_y, "w" = max_x - min_x + 1, "h" = max_y - min_y + 1)

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
	/// Whether the artwork has been vandalized with spray paint
	var/vandalized = FALSE

	/// Stored body parts: id -> list("body_zone", "icon_file", "icon_state")
	var/list/stored_parts = list()
	/// Placement data: id -> list("grid_x", "grid_y", "rotation", "tint")
	var/list/placed_parts = list()
	/// Vein pixels: keyed as "x,y" -> TRUE, representing painted cells
	var/list/vein_pixels = list()
	/// Number of vein pixels that have been paid for (from last submit)
	var/submitted_vein_count = 0
	/// Blood cost per vein pixel
	var/blood_per_vein = 1
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
	create_reagents(500)
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

	var/stored_blood = reagents?.get_reagent_amount(/datum/reagent/blood) || 0
	if(stored_blood > 0)
		. += span_notice("It has [stored_blood]u of blood stored.")

	if(vandalized)
		. += span_boldwarning("This artwork has been vandalized! It has been ruined.")

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

	var/list/choices = list("Arrange Parts", "Rename Artwork")
	var/choice = tgui_input_list(H, "What would you like to do?", "Custom Artwork", choices)
	if(!choice)
		return

	if(choice == "Rename Artwork")
		var/new_name = stripped_input(H, "Name your artwork (max 60 characters):", "Rename Artwork", name, 60)
		if(!new_name)
			return
		name = new_name
		to_chat(H, span_nicegreen("You rename the artwork to '[new_name]'."))
		return

	if(!length(stored_parts))
		to_chat(H, span_warning("The artwork has no body parts to arrange. Hit it with body parts first."))
		return

	to_chat(H, span_notice("You begin arranging the artwork..."))
	if(!editor)
		editor = new(src)
	editor.ui_interact(H)

/obj/structure/custom_corporist_artwork/wrench_act(mob/living/user, obj/item/I)
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

/obj/structure/custom_corporist_artwork/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/reagent_containers/spray) || istype(I, /obj/item/toy/crayon))
		if(vandalized)
			to_chat(user, span_warning("This artwork has already been vandalized."))
			return

		if(istype(I, /obj/item/toy/crayon/spraycan))
			to_chat(user, span_warning("You begin spraying graffiti over the artwork..."))
		else if(istype(I, /obj/item/reagent_containers/spray))
			to_chat(user, span_warning("You begin spraying paint over the artwork..."))
		else
			to_chat(user, span_warning("You begin scrawling over the artwork..."))

		if(!do_after(user, 3 SECONDS, src))
			to_chat(user, span_warning("You were interrupted!"))
			return

		vandalized = TRUE
		add_atom_colour("#1a1a1a", FIXED_COLOUR_PRIORITY)
		if(istype(I, /obj/item/toy/crayon/spraycan))
			desc = "This artwork has been covered in spray-painted graffiti."
			to_chat(user, span_boldwarning("You tag the artwork with graffiti!"))
			visible_message(span_warning("[user] sprays graffiti all over [src]!"), ignored_mobs = list(user))
		else if(istype(I, /obj/item/reagent_containers/spray))
			desc = "This artwork has been defaced with spray paint."
			to_chat(user, span_boldwarning("You vandalize the artwork!"))
			visible_message(span_warning("[user] sprays paint all over [src]!"), ignored_mobs = list(user))
		else
			desc = "This artwork has been scrawled over with crayon."
			to_chat(user, span_boldwarning("You deface the artwork with crayon!"))
			visible_message(span_warning("[user] scrawls all over [src] with a crayon!"), ignored_mobs = list(user))
		playsound(src, 'sound/effects/spray.ogg', 50, TRUE)
		return

	if(istype(I, /obj/item/reagent_containers))
		if(!is_corporist_artist(user))
			to_chat(user, span_warning("You have no idea how to use this on the artwork."))
			return
		var/obj/item/reagent_containers/RC = I
		if(!RC.reagents?.has_reagent(/datum/reagent/blood))
			to_chat(user, span_warning("The container has no blood in it."))
			return
		var/transferred = RC.reagents.trans_id_to(src, /datum/reagent/blood, RC.amount_per_transfer_from_this)
		if(transferred > 0)
			to_chat(user, span_nicegreen("You add [transferred]u of blood to [src]. ([reagents.get_reagent_amount(/datum/reagent/blood)]u stored)"))
			playsound(src, 'sound/effects/splat.ogg', 30, TRUE)
		else
			to_chat(user, span_warning("You couldn't transfer any blood."))
		return

	if(istype(I, /obj/item/bodypart))
		if(!is_corporist_artist(user))
			to_chat(user, span_warning("You have no idea how to incorporate this into the artwork."))
			return

		var/obj/item/bodypart/BP = I
		add_bodypart_custom(BP, user)
		return

	if(istype(I, /obj/item/carved_piece))
		if(!is_corporist_artist(user))
			to_chat(user, span_warning("You have no idea how to incorporate this into the artwork."))
			return

		var/obj/item/carved_piece/CP = I
		add_carved_piece(CP, user)
		return

	if(istype(I, /obj/item/organ))
		if(!is_corporist_artist(user))
			to_chat(user, span_warning("You have no idea how to incorporate this into the artwork."))
			return

		var/obj/item/organ/O = I
		add_organ_custom(O, user)
		return

	return ..()

/// Add a bodypart to the custom artwork's storage
/obj/structure/custom_corporist_artwork/proc/add_bodypart_custom(obj/item/bodypart/BP, mob/user)
	var/part_id = "[next_part_id]"
	next_part_id++

	// BP.icon_state is "" after dismemberment (get_limb_icon clears it), use initial values
	var/use_icon = "[initial(BP.icon)]"
	var/use_state = initial(BP.icon_state)
	var/list/crop = get_icon_crop_bounds(file(use_icon), use_state)
	stored_parts[part_id] = list(
		"body_zone" = BP.body_zone,
		"icon_file" = use_icon,
		"icon_state" = use_state,
		"crop_ox" = crop["ox"],
		"crop_oy" = crop["oy"],
		"crop_w" = crop["w"],
		"crop_h" = crop["h"]
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

/// Add a carved piece to the custom artwork's storage
/obj/structure/custom_corporist_artwork/proc/add_carved_piece(obj/item/carved_piece/CP, mob/user)
	var/part_id = "[next_part_id]"
	next_part_id++

	stored_parts[part_id] = list(
		"body_zone" = "carved_[CP.source_mob_name]",
		"icon_file" = null,
		"icon_state" = null,
		"is_carved" = TRUE,
		"carved_base64" = CP.carved_base64,
		"carved_icon" = CP.carved_icon,
		"crop_ox" = CP.crop_ox,
		"crop_oy" = CP.crop_oy,
		"crop_w" = CP.crop_w,
		"crop_h" = CP.crop_h
	)

	body_part_count++
	to_chat(user, span_nicegreen("You incorporate the [CP.name] into the artwork's collection."))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	if(user.transferItemToLoc(CP, src))
		CP.forceMove(src)
	else
		CP.forceMove(src)

	var/datum/component/artistic_exp/exp_comp = user.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("add_body")

	if(editor)
		SStgui.update_static_data(user, editor)

/// Add an organ to the custom artwork's storage
/obj/structure/custom_corporist_artwork/proc/add_organ_custom(obj/item/organ/O, mob/user)
	var/part_id = "[next_part_id]"
	next_part_id++

	var/use_icon = "[initial(O.icon)]"
	var/use_state = O.icon_state || initial(O.icon_state)
	var/list/crop = get_icon_crop_bounds(file(use_icon), use_state)
	stored_parts[part_id] = list(
		"body_zone" = "organ_[O.name]",
		"icon_file" = use_icon,
		"icon_state" = use_state,
		"crop_ox" = crop["ox"],
		"crop_oy" = crop["oy"],
		"crop_w" = crop["w"],
		"crop_h" = crop["h"]
	)

	body_part_count++
	to_chat(user, span_nicegreen("You incorporate the [O.name] into the artwork's collection."))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	if(user.transferItemToLoc(O, src))
		O.forceMove(src)
	else
		O.forceMove(src)

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

		var/icon/part_icon
		if(part_data["is_carved"])
			part_icon = icon(part_data["carved_icon"])
		else
			var/icon_state_name = part_data["icon_state"]
			if(!icon_state_name || icon_state_name == "")
				icon_state_name = "default_human_[part_data["body_zone"]]"
			part_icon = icon(file(part_data["icon_file"]), icon_state_name, SOUTH)
		var/rotation = placement["rotation"]
		if(rotation)
			part_icon.Turn(rotation)
		var/tint = placement["tint"]
		if(tint && tint != "#ffffff")
			part_icon.Blend(tint, ICON_MULTIPLY)

		var/mutable_appearance/MA = mutable_appearance(part_icon)
		MA.pixel_x = placement["grid_x"] - 8
		MA.pixel_y = 8 - placement["grid_y"]
		. += MA

	if(veins_above)
		. += generate_vein_overlay()

/// Generate the vein overlay icon from vein_pixels
/obj/structure/custom_corporist_artwork/proc/generate_vein_overlay()
	if(!length(vein_pixels))
		return list()

	var/icon/vein_icon = icon('icons/effects/effects.dmi', "nothing")
	vein_icon.Scale(48, 48)

	for(var/key in vein_pixels)
		var/list/coords = splittext(key, ",")
		var/vx = text2num(coords[1])
		var/vy = text2num(coords[2])
		// Vein y=1 is top-down, BYOND y=1 is bottom
		vein_icon.DrawBox("#8b0000", vx, 49 - vy)

	var/mutable_appearance/MA = mutable_appearance(vein_icon)
	MA.pixel_x = -8
	MA.pixel_y = -8
	return list(MA)

/// Count cardinal (4-dir) vein neighbors at a position
/obj/structure/custom_corporist_artwork/proc/count_vein_neighbors(cx, cy)
	var/n = 0
	if(vein_pixels["[cx-1],[cy]"])
		n++
	if(vein_pixels["[cx+1],[cy]"])
		n++
	if(vein_pixels["[cx],[cy-1]"])
		n++
	if(vein_pixels["[cx],[cy+1]"])
		n++
	return n

/// Check if a vein cell can be placed without making any cell exceed 2 cardinal neighbors
/obj/structure/custom_corporist_artwork/proc/can_place_vein(cx, cy)
	if(vein_pixels["[cx],[cy]"])
		return FALSE
	var/my_neighbors = 0
	var/list/dirs = list(list(-1, 0), list(1, 0), list(0, -1), list(0, 1))
	for(var/list/d in dirs)
		var/nx = cx + d[1]
		var/ny = cy + d[2]
		if(vein_pixels["[nx],[ny]"])
			my_neighbors++
			if(count_vein_neighbors(nx, ny) >= 2)
				return FALSE
	if(my_neighbors > 2)
		return FALSE
	return TRUE

/// Check if any bodypart or vein touches the pedestal area (grid x:14-33, y:36-39)
/obj/structure/custom_corporist_artwork/proc/touches_pedestal()
	// Pedestal bounds (matching statue.dmi "base" in the 48-cell grid)
	var/ped_x1 = 14
	var/ped_y1 = 36
	var/ped_x2 = 33
	var/ped_y2 = 39

	// Check body parts (using crop bounds, adjacent = touching within 1px)
	for(var/part_id in placed_parts)
		var/list/placement = placed_parts[part_id]
		var/list/part_data = stored_parts[part_id]
		var/c_ox = part_data ? part_data["crop_ox"] : 0
		var/c_oy = part_data ? part_data["crop_oy"] : 0
		var/c_w = part_data ? part_data["crop_w"] : 32
		var/c_h = part_data ? part_data["crop_h"] : 32

		var/px1 = placement["grid_x"] + c_ox
		var/py1 = placement["grid_y"] + c_oy
		var/px2 = px1 + c_w - 1
		var/py2 = py1 + c_h - 1

		if(px1 <= ped_x2 + 1 && px2 >= ped_x1 - 1 && py1 <= ped_y2 + 1 && py2 >= ped_y1 - 1)
			return TRUE

	// Check veins
	for(var/key in vein_pixels)
		var/list/coords = splittext(key, ",")
		var/vx = text2num(coords[1])
		var/vy = text2num(coords[2])
		if(vx >= ped_x1 - 1 && vx <= ped_x2 + 1 && vy >= ped_y1 - 1 && vy <= ped_y2 + 1)
			return TRUE

	return FALSE

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

/// Check if two placed parts are adjacent (content bounding boxes overlap or touch within 1px)
/obj/structure/custom_corporist_artwork/proc/parts_adjacent(part_id_a, part_id_b)
	var/list/a = placed_parts[part_id_a]
	var/list/b = placed_parts[part_id_b]
	if(!a || !b)
		return FALSE

	var/list/da = stored_parts[part_id_a]
	var/list/db = stored_parts[part_id_b]

	var/a_ox = da ? da["crop_ox"] : 0
	var/a_oy = da ? da["crop_oy"] : 0
	var/a_w = da ? da["crop_w"] : 32
	var/a_h = da ? da["crop_h"] : 32

	var/b_ox = db ? db["crop_ox"] : 0
	var/b_oy = db ? db["crop_oy"] : 0
	var/b_w = db ? db["crop_w"] : 32
	var/b_h = db ? db["crop_h"] : 32

	var/ax1 = a["grid_x"] + a_ox
	var/ay1 = a["grid_y"] + a_oy
	var/ax2 = ax1 + a_w - 1
	var/ay2 = ay1 + a_h - 1

	var/bx1 = b["grid_x"] + b_ox
	var/by1 = b["grid_y"] + b_oy
	var/bx2 = bx1 + b_w - 1
	var/by2 = by1 + b_h - 1

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

	var/list/part_data = stored_parts[part_id]
	var/c_ox = part_data ? part_data["crop_ox"] : 0
	var/c_oy = part_data ? part_data["crop_oy"] : 0
	var/c_w = part_data ? part_data["crop_w"] : 32
	var/c_h = part_data ? part_data["crop_h"] : 32

	var/px1 = placement["grid_x"] + c_ox
	var/py1 = placement["grid_y"] + c_oy
	var/px2 = px1 + c_w - 1
	var/py2 = py1 + c_h - 1

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
		if(part_data["is_carved"])
			var/icon/carved = part_data["carved_icon"]
			rotations["0"] = part_data["carved_base64"]
			for(var/rot in list(90, 180, 270))
				var/icon/rotated = icon(carved)
				rotated.Turn(rot)
				rotations["[rot]"] = icon2base64(rotated)
		else
			var/icon_state_name = part_data["icon_state"]
			if(!icon_state_name || icon_state_name == "")
				icon_state_name = "default_human_[part_data["body_zone"]]"
			for(var/rot in list(0, 90, 180, 270))
				rotations["[rot]"] = get_bodypart_base64(
					file(part_data["icon_file"]),
					icon_state_name,
					SOUTH,
					rot
				)
		part_icons[part_id] = rotations
	data["partIcons"] = part_icons

	var/list/crop_data = list()
	for(var/part_id in artwork.stored_parts)
		var/list/part_data = artwork.stored_parts[part_id]
		var/list/rot_crops = list()
		if(part_data["is_carved"])
			var/icon/carved = part_data["carved_icon"]
			rot_crops["0"] = list("ox" = part_data["crop_ox"], "oy" = part_data["crop_oy"], "w" = part_data["crop_w"], "h" = part_data["crop_h"])
			for(var/rot in list(90, 180, 270))
				var/icon/rotated = icon(carved)
				rotated.Turn(rot)
				rot_crops["[rot]"] = get_icon_crop_bounds_from_icon(rotated)
		else
			var/use_state = part_data["icon_state"]
			if(!use_state || use_state == "")
				use_state = "default_human_[part_data["body_zone"]]"
			for(var/rot in list(0, 90, 180, 270))
				rot_crops["[rot]"] = get_icon_crop_bounds(
					file(part_data["icon_file"]),
					use_state,
					SOUTH,
					rot
				)
		crop_data[part_id] = rot_crops
	data["cropData"] = crop_data

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

	var/current_veins = length(artwork.vein_pixels)
	var/vein_diff = current_veins - artwork.submitted_vein_count
	var/stored_blood = artwork.reagents?.get_reagent_amount(/datum/reagent/blood) || 0
	data["storedBlood"] = stored_blood
	data["bloodCost"] = max(0, vein_diff) * artwork.blood_per_vein
	data["bloodRefund"] = max(0, -vein_diff) * artwork.blood_per_vein

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
			var/grid_x = clamp(text2num(params["x"]), -32, 47)
			var/grid_y = clamp(text2num(params["y"]), -32, 47)
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

			. = TRUE

		if("move_part")
			var/part_id = params["id"]
			var/grid_x = clamp(text2num(params["x"]), -32, 47)
			var/grid_y = clamp(text2num(params["y"]), -32, 47)
			if(!artwork.placed_parts[part_id])
				return

			artwork.placed_parts[part_id]["grid_x"] = grid_x
			artwork.placed_parts[part_id]["grid_y"] = grid_y
			. = TRUE

		if("rotate_part")
			var/part_id = params["id"]
			if(!artwork.placed_parts[part_id])
				return

			artwork.placed_parts[part_id]["rotation"] = (artwork.placed_parts[part_id]["rotation"] + 90) % 360
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

			artwork.placed_parts -= part_id
			. = TRUE

		if("paint_veins")
			var/list/cells = params["cells"]
			if(!islist(cells))
				return
			for(var/list/cell in cells)
				var/cx = clamp(text2num(cell["x"]), 1, 48)
				var/cy = clamp(text2num(cell["y"]), 1, 48)
				if(artwork.vein_pixels["[cx],[cy]"])
					continue
				if(!artwork.can_place_vein(cx, cy))
					continue
				artwork.vein_pixels["[cx],[cy]"] = TRUE
			. = TRUE

		if("erase_veins")
			var/list/cells = params["cells"]
			if(!islist(cells))
				return
			for(var/list/cell in cells)
				var/cx = clamp(text2num(cell["x"]), 1, 48)
				var/cy = clamp(text2num(cell["y"]), 1, 48)
				artwork.vein_pixels -= "[cx],[cy]"
			. = TRUE

		if("clear_veins")
			if(!length(artwork.vein_pixels))
				return
			artwork.vein_pixels = list()
			. = TRUE

		if("toggle_veins_layer")
			artwork.veins_above = !artwork.veins_above
			. = TRUE

		if("submit")
			if(!length(artwork.placed_parts))
				to_chat(user, span_warning("Place at least one body part before submitting."))
				return

			if(length(artwork.placed_parts) > 1 && !artwork.check_full_connectivity())
				to_chat(user, span_warning("All body parts must be connected to each other, either directly or through veins."))
				return

			if(!artwork.touches_pedestal())
				to_chat(user, span_warning("At least one body part or vein must touch the pedestal."))
				return

			// Calculate blood cost for vein changes
			var/current_veins = length(artwork.vein_pixels)
			var/vein_diff = current_veins - artwork.submitted_vein_count
			if(vein_diff > 0)
				// Need to pay for new veins
				var/blood_cost = vein_diff * artwork.blood_per_vein
				var/stored_blood = artwork.reagents?.get_reagent_amount(/datum/reagent/blood) || 0
				if(stored_blood < blood_cost)
					to_chat(user, span_warning("Not enough blood stored! Need [blood_cost]u but only [stored_blood]u available. ([vein_diff] new vein pixels)"))
					return
				artwork.reagents.remove_reagent(/datum/reagent/blood, blood_cost)
				to_chat(user, span_notice("Used [blood_cost]u of blood for [vein_diff] new vein pixels."))
			else if(vein_diff < 0)
				// Refund blood for removed veins
				var/refund = -vein_diff * artwork.blood_per_vein
				artwork.reagents.add_reagent(/datum/reagent/blood, refund)
				to_chat(user, span_notice("Recovered [refund]u of blood from [abs(vein_diff)] removed vein pixels."))

			artwork.submitted_vein_count = current_veins
			artwork.update_icon()

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

// ================== CARVED PIECE ITEM ==================

/obj/item/carved_piece
	name = "carved flesh piece"
	desc = "A piece of flesh carefully carved from a creature's body."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "yourorgans"
	w_class = WEIGHT_CLASS_SMALL
	/// The dynamically generated icon of the carved pixels
	var/icon/carved_icon
	/// Pre-computed base64 of the carved icon
	var/carved_base64
	/// Width of the source mob sprite
	var/source_width = 32
	/// Height of the source mob sprite
	var/source_height = 32
	/// Name of the source mob
	var/source_mob_name
	/// Crop bounds (top-down coordinates)
	var/crop_ox = 0
	var/crop_oy = 0
	var/crop_w = 32
	var/crop_h = 32

/// Build the carved icon from selected pixel coordinates
/obj/item/carved_piece/proc/setup_from_pixels(icon/source_icon, list/pixels, mob_name)
	source_mob_name = mob_name
	source_width = source_icon.Width()
	source_height = source_icon.Height()
	name = "carved [mob_name] piece"

	// Copy source icon and blank it, preserving icon metadata
	carved_icon = icon(source_icon)
	carved_icon.DrawBox(null, 1, 1, source_width, source_height)

	// Build a set of selected pixel keys for fast lookup
	var/list/selected_set = list()
	var/min_x = source_width
	var/min_y = source_height
	var/max_x = -1
	var/max_y = -1

	for(var/list/px in pixels)
		var/tx = px["x"]
		var/ty = px["y"]
		var/bx = tx + 1
		var/by = source_height - ty
		selected_set["[bx],[by]"] = TRUE
		if(tx < min_x)
			min_x = tx
		if(tx > max_x)
			max_x = tx
		if(ty < min_y)
			min_y = ty
		if(ty > max_y)
			max_y = ty

	// Draw only selected pixels from the source
	for(var/key in selected_set)
		var/list/coords = splittext(key, ",")
		var/bx = text2num(coords[1])
		var/by = text2num(coords[2])
		var/color = source_icon.GetPixel(bx, by)
		if(color)
			carved_icon.DrawBox(color, bx, by)

	if(max_x >= 0)
		crop_ox = min_x
		crop_oy = min_y
		crop_w = max_x - min_x + 1
		crop_h = max_y - min_y + 1

	carved_base64 = icon2base64(carved_icon)
	src.icon = carved_icon

// ================== CARVE BODY EDITOR ==================

/datum/carve_body_editor
	/// The target dead mob
	var/mob/living/simple_animal/target_mob
	/// The artist using the editor
	var/mob/living/carbon/human/artist
	/// South-facing source icon (current selection)
	var/icon/source_icon
	/// Icon dimensions
	var/source_width = 32
	var/source_height = 32
	/// Base64 of the source icon for TGUI
	var/source_base64
	/// List of opaque pixel coords (top-down, 0-indexed)
	var/list/opaque_pixels
	/// Set of opaque pixel keys for fast lookup
	var/list/opaque_set
	/// Selected pixels: "x,y" -> TRUE
	var/list/selected_pixels
	/// Whether using the living sprite (TRUE) or dead (FALSE)
	var/using_living = FALSE
	/// Living sprite icon
	var/icon/living_icon
	/// Dead sprite icon
	var/icon/dead_icon
	/// Living sprite base64
	var/living_base64
	/// Dead sprite base64
	var/dead_base64
	/// Whether the mob has distinct living/dead sprites
	var/has_both_sprites = FALSE

/datum/carve_body_editor/New(mob/living/simple_animal/target, mob/living/carbon/human/user)
	target_mob = target
	artist = user
	selected_pixels = list()

	// Build both living and dead icons
	var/dead_state = target.icon_dead || target.icon_state
	var/living_state = target.icon_living || target.icon_state
	dead_icon = icon(target.icon, dead_state, SOUTH)
	living_icon = icon(target.icon, living_state, SOUTH)
	dead_base64 = icon2base64(dead_icon)
	living_base64 = icon2base64(living_icon)
	has_both_sprites = (dead_state != living_state)

	// Default to dead sprite
	set_source_icon(dead_icon, dead_base64)

/// Rebuild opaque pixel data from the given icon
/datum/carve_body_editor/proc/set_source_icon(icon/I, base64)
	source_icon = I
	source_width = I.Width()
	source_height = I.Height()
	source_base64 = base64

	opaque_pixels = list()
	opaque_set = list()
	for(var/by in 1 to source_height)
		for(var/bx in 1 to source_width)
			if(I.GetPixel(bx, by))
				var/tx = bx - 1
				var/ty = source_height - by
				opaque_pixels += list(list("x" = tx, "y" = ty))
				opaque_set["[tx],[ty]"] = TRUE

/datum/carve_body_editor/Destroy()
	target_mob = null
	artist = null
	source_icon = null
	living_icon = null
	dead_icon = null
	return ..()

/datum/carve_body_editor/ui_state(mob/user)
	return GLOB.conscious_state

/datum/carve_body_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CarveBodyEditor")
		ui.open()

/datum/carve_body_editor/ui_static_data(mob/user)
	var/list/data = list()
	data["mobName"] = target_mob.name
	data["hasBothSprites"] = has_both_sprites
	return data

/datum/carve_body_editor/ui_data(mob/user)
	var/list/data = list()
	data["sourceBase64"] = source_base64
	data["sourceWidth"] = source_width
	data["sourceHeight"] = source_height
	data["opaquePixels"] = opaque_pixels
	data["usingLiving"] = using_living

	var/list/sel_list = list()
	for(var/key in selected_pixels)
		var/list/coords = splittext(key, ",")
		sel_list += list(list(
			"x" = text2num(coords[1]),
			"y" = text2num(coords[2])
		))
	data["selectedPixels"] = sel_list
	data["sections"] = get_sections()
	return data

/datum/carve_body_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle_pixels")
			var/list/pixels = params["pixels"]
			var/mode = params["mode"]
			if(!islist(pixels))
				return
			for(var/list/px in pixels)
				var/x = text2num(px["x"])
				var/y = text2num(px["y"])
				if(!isnum(x) || !isnum(y))
					continue
				var/key = "[x],[y]"
				if(!opaque_set[key])
					continue
				if(mode == "select")
					selected_pixels[key] = TRUE
				else
					selected_pixels -= key
			. = TRUE

		if("clear_selection")
			selected_pixels = list()
			. = TRUE

		if("switch_sprite")
			using_living = !using_living
			selected_pixels = list()
			if(using_living)
				set_source_icon(living_icon, living_base64)
			else
				set_source_icon(dead_icon, dead_base64)
			. = TRUE

		if("carve_out")
			do_carve()
			. = TRUE

/// BFS flood fill to find contiguous groups of selected pixels
/datum/carve_body_editor/proc/get_sections()
	var/list/sections = list()
	var/list/visited = list()
	var/list/dirs = list(list(1, 0), list(-1, 0), list(0, 1), list(0, -1))

	for(var/key in selected_pixels)
		if(visited[key])
			continue

		var/list/section_pixels = list()
		var/list/queue = list(key)
		visited[key] = TRUE

		while(length(queue))
			var/current = queue[1]
			queue.Cut(1, 2)
			var/list/coords = splittext(current, ",")
			var/cx = text2num(coords[1])
			var/cy = text2num(coords[2])
			section_pixels += list(list("x" = cx, "y" = cy))

			for(var/list/d in dirs)
				var/nkey = "[cx + d[1]],[cy + d[2]]"
				if(selected_pixels[nkey] && !visited[nkey])
					visited[nkey] = TRUE
					queue += nkey

		sections += list(list(
			"pixels" = section_pixels,
			"size" = length(section_pixels),
			"valid" = length(section_pixels) >= 8
		))

	return sections

/// Create carved pieces from valid sections and gib the mob
/datum/carve_body_editor/proc/do_carve()
	var/list/sections = get_sections()
	var/has_valid = FALSE
	for(var/list/section in sections)
		if(section["valid"])
			has_valid = TRUE
			break

	if(!has_valid)
		to_chat(artist, span_warning("You need at least one group of 8 or more connected pixels to carve."))
		return

	if(!target_mob || target_mob.stat != DEAD)
		to_chat(artist, span_warning("The creature is no longer available."))
		return

	if(!do_after(artist, 3 SECONDS, target_mob))
		to_chat(artist, span_warning("You were interrupted!"))
		return

	var/target_turf = get_turf(target_mob)
	var/carved_count = 0

	for(var/list/section in sections)
		if(!section["valid"])
			continue
		var/obj/item/carved_piece/piece = new(target_turf)
		piece.setup_from_pixels(source_icon, section["pixels"], target_mob.name)
		carved_count++

	to_chat(artist, span_nicegreen("You carefully carve [carved_count] piece\s from [target_mob]."))
	playsound(target_mob, 'sound/effects/splat.ogg', 50, TRUE)

	var/datum/component/artistic_exp/exp_comp = artist.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		exp_comp.add_activity_exp("create_artwork")

	target_mob.gib()
	SStgui.close_uis(src)
	qdel(src)

