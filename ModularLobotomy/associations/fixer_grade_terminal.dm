// Fixer Grade Identification Terminal
/obj/structure/fixer_grade_terminal
	name = "Fixer Grade Identification Terminal"
	desc = "Insert your ID card to receive official fixer designation and grade classification."
	icon = 'icons/obj/terminals.dmi'
	icon_state = "req_comp0"
	density = TRUE
	anchored = TRUE
	var/obj/item/card/id/inserted_id
	var/processing = FALSE
	var/process_time = 5 SECONDS
	var/list/previous_grades = list() // Assoc list of ckey = grade

/obj/structure/fixer_grade_terminal/Initialize()
	. = ..()
	update_icon()

/obj/structure/fixer_grade_terminal/Destroy()
	if(inserted_id)
		inserted_id.forceMove(drop_location())
		inserted_id = null
	return ..()

/obj/structure/fixer_grade_terminal/proc/calculate_fixer_grade(mob/living/carbon/human/H)
	// Grade calculation based only on stats, similar to potential machine
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE,
	)
	
	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	
	// Average of all stats
	stattotal /= 4
	
	// Calculate grade based on average stat level
	// Every 20 levels = 1 grade improvement
	var/grade_offset = round(stattotal / 20)
	var/grade = 10 - grade_offset
	
	// Clamp between 1 and 9
	return clamp(grade, 1, 9)

/obj/structure/fixer_grade_terminal/proc/update_id_assignment(obj/item/card/id/I, datum/fixer_office/office, grade, mob/living/carbon/human/H)
	if(office)
		if(office.is_director(H))
			I.assignment = "Grade [grade] [office.name] Representative"
		else
			I.assignment = "Grade [grade] [office.name] Fixer"
	else
		I.assignment = "Grade [grade] Solo Fixer"
	I.update_label()

/obj/structure/fixer_grade_terminal/proc/calculate_grade_reward(old_grade, new_grade)
	// Lower grade number = higher rank (Grade 1 is best, Grade 9 is worst)
	// So improvement means new_grade < old_grade
	if(new_grade >= old_grade)
		return 0
	var/grades_improved = old_grade - new_grade
	return grades_improved * 300

/obj/structure/fixer_grade_terminal/proc/process_id(mob/living/carbon/human/H)
	if(!inserted_id || !H || !H.mind || QDELETED(H))
		processing = FALSE
		update_icon()
		return

	// Mark as registered fixer if not already
	if(!H.mind.registered_fixer)
		H.mind.registered_fixer = TRUE
		to_chat(H, span_nicegreen("You are now registered as an official fixer!"))

	var/grade = calculate_fixer_grade(H)
	var/datum/fixer_office/office = null

	// Check if user is part of an office
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		if(H in F.members)
			office = F
			break

	// Check for grade improvement and give reward
	var/old_grade = previous_grades[H.ckey] || 9 // Default to lowest grade if first time
	var/reward = calculate_grade_reward(old_grade, grade)

	if(reward > 0)
		// Give Ahn reward
		var/obj/item/holochip/C = new /obj/item/holochip(get_turf(src), reward)
		H.put_in_hands(C)
		to_chat(H, span_nicegreen("Grade improvement bonus: [reward] Ahn! (Grade [old_grade] → Grade [grade])"))
		playsound(src, 'sound/machines/chime.ogg', 50, FALSE)
	else if(old_grade > grade)
		to_chat(H, span_warning("Your grade has decreased from [old_grade] to [grade]."))

	// Update stored grade
	previous_grades[H.ckey] = grade

	update_id_assignment(inserted_id, office, grade, H)

	to_chat(H, span_nicegreen("ID updated: [inserted_id.assignment]"))
	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)

	processing = FALSE
	update_icon()

/obj/structure/fixer_grade_terminal/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/card/id))
		if(inserted_id)
			to_chat(user, span_warning("There's already an ID inserted!"))
			return
		if(!ishuman(user))
			to_chat(user, span_warning("Only humans can use this terminal!"))
			return
		var/mob/living/carbon/human/H = user
		if(!H.mind)
			to_chat(user, span_warning("You need a functioning mind to register!"))
			return

		if(!user.transferItemToLoc(I, src))
			return
		inserted_id = I
		to_chat(user, span_notice("You insert [I] into the terminal."))
		processing = TRUE
		update_icon()
		addtimer(CALLBACK(src, PROC_REF(process_id), H), process_time)
		return
	return ..()

/obj/structure/fixer_grade_terminal/attack_hand(mob/user)
	if(!inserted_id)
		to_chat(user, span_notice("No ID card inserted."))
		return
	if(processing)
		to_chat(user, span_warning("Please wait for processing to complete..."))
		return

	user.put_in_hands(inserted_id)
	to_chat(user, span_notice("You remove [inserted_id] from the terminal."))
	inserted_id = null
	update_icon()

/obj/structure/fixer_grade_terminal/update_icon()
	. = ..()
	update_icon_state()

/obj/structure/fixer_grade_terminal/update_icon_state()
	if(processing)
		icon_state = "req_comp3" // Animated/active state
	else if(inserted_id)
		icon_state = "req_comp1" // Loaded state
	else
		icon_state = "req_comp0" // Default state

// Add registered_fixer variable to mind datum
/datum/mind
	var/registered_fixer = FALSE
