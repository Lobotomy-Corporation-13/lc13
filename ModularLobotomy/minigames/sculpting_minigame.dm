// Sculpting Minigame
// A timing-based minigame for refining corporist artworks

/datum/sculpting_minigame
	/// The player doing the sculpting
	var/mob/living/carbon/human/sculptor
	/// The artwork being refined
	var/obj/structure/corporist_artwork/artwork
	/// Current round (1-6)
	var/current_round = 1
	/// Total rounds
	var/total_rounds = 6
	/// Current score
	var/score = 0
	/// Current combo
	var/combo = 0
	/// Best combo achieved
	var/best_combo = 0
	/// Needle position (0-100)
	var/needle_position = 0
	/// Needle direction (1 = right, -1 = left)
	var/needle_direction = 1
	/// Needle speed (positions per tick)
	var/needle_speed = 2
	/// List of sweet spot positions (each is list("start", "end", "perfect_start", "perfect_end"))
	var/list/sweet_spots = list()
	/// Whether the minigame is active
	var/active = FALSE
	/// Whether waiting for input this round
	var/awaiting_input = TRUE
	/// Last hit result for display
	var/last_hit_result = ""
	/// Timer ID for needle movement
	var/movement_timer
	/// Difficulty modifier based on artist type
	var/difficulty = "medium"
	/// Starting score bonus based on artist type
	var/starting_bonus = 0

/datum/sculpting_minigame/New(mob/living/carbon/human/user, obj/structure/corporist_artwork/target)
	sculptor = user
	artwork = target
	determine_difficulty()
	generate_sweet_spots()
	score = starting_bonus

/datum/sculpting_minigame/Destroy()
	if(movement_timer)
		deltimer(movement_timer)
	sculptor = null
	artwork = null
	return ..()

/// Determine difficulty based on artist type
/datum/sculpting_minigame/proc/determine_difficulty()
	if(!sculptor)
		return

	// Check artist type
	if(istype(sculptor.dna?.species, /datum/species/corporist_maestro))
		difficulty = "easy"
		needle_speed = 1.5
		starting_bonus = 2
	else if(istype(sculptor.dna?.species, /datum/species/corporist_apprentice))
		difficulty = "medium"
		needle_speed = 2
		starting_bonus = 1
	else if(sculptor.GetComponent(/datum/component/corporist_student))
		difficulty = "medium"
		needle_speed = 2
		starting_bonus = 0
	else if(sculptor.GetComponent(/datum/component/inspired_artist))
		difficulty = "hard"
		needle_speed = 2.5
		starting_bonus = -1

/// Generate sweet spots for the current round
/datum/sculpting_minigame/proc/generate_sweet_spots()
	sweet_spots = list()

	// Number of sweet spots decreases in later rounds
	var/num_spots = 3
	if(current_round >= 5)
		num_spots = 2
	else if(current_round >= 3)
		num_spots = 3

	// Sweet spot size based on difficulty
	var/spot_size
	var/perfect_size
	switch(difficulty)
		if("easy")
			spot_size = 15
			perfect_size = 5
		if("medium")
			spot_size = 12
			perfect_size = 4
		if("hard")
			spot_size = 8
			perfect_size = 2

	// Generate non-overlapping sweet spots
	var/list/used_ranges = list()
	for(var/i in 1 to num_spots)
		var/attempts = 0
		var/valid = FALSE
		var/start_pos

		while(!valid && attempts < 50)
			attempts++
			start_pos = rand(5, 95 - spot_size)
			valid = TRUE

			// Check for overlap with existing spots
			for(var/list/range in used_ranges)
				if(start_pos < range["end"] + 5 && start_pos + spot_size > range["start"] - 5)
					valid = FALSE
					break

		if(valid)
			var/end_pos = start_pos + spot_size
			var/perfect_start = start_pos + round((spot_size - perfect_size) / 2)
			var/perfect_end = perfect_start + perfect_size

			sweet_spots += list(list(
				"start" = start_pos,
				"end" = end_pos,
				"perfect_start" = perfect_start,
				"perfect_end" = perfect_end
			))
			used_ranges += list(list("start" = start_pos, "end" = end_pos))

/datum/sculpting_minigame/proc/start_game()
	active = TRUE
	awaiting_input = TRUE
	current_round = 1
	score = starting_bonus
	combo = 0
	best_combo = 0
	needle_position = 0
	needle_direction = 1
	last_hit_result = ""
	generate_sweet_spots()
	start_needle_movement()

/datum/sculpting_minigame/proc/start_needle_movement()
	if(movement_timer)
		deltimer(movement_timer)
	movement_timer = addtimer(CALLBACK(src, PROC_REF(move_needle)), 0.5, TIMER_LOOP | TIMER_STOPPABLE)

/datum/sculpting_minigame/proc/stop_needle_movement()
	if(movement_timer)
		deltimer(movement_timer)
		movement_timer = null

/datum/sculpting_minigame/proc/move_needle()
	if(!active || !awaiting_input)
		return

	// Move needle
	needle_position += needle_speed * needle_direction

	// Bounce at edges
	if(needle_position >= 100)
		needle_position = 100
		needle_direction = -1
	else if(needle_position <= 0)
		needle_position = 0
		needle_direction = 1

	// Update UI
	SStgui.update_uis(src)

/// Called when player attempts to sculpt
/datum/sculpting_minigame/proc/attempt_sculpt()
	if(!active || !awaiting_input)
		return

	awaiting_input = FALSE
	var/hit_type = check_hit()

	// Apply score
	var/points = 0
	switch(hit_type)
		if("perfect")
			points = 3
			combo++
			last_hit_result = "PERFECT!"
			playsound(sculptor, 'sound/machines/chime.ogg', 50, TRUE)
		if("good")
			points = 2
			combo++
			last_hit_result = "Good"
			playsound(sculptor, 'sound/machines/click.ogg', 40, TRUE)
		if("okay")
			points = 1
			combo++
			last_hit_result = "Okay"
			playsound(sculptor, 'sound/machines/click.ogg', 30, TRUE)
		if("miss")
			points = -1
			combo = 0
			last_hit_result = "Miss"
			playsound(sculptor, 'sound/effects/splat.ogg', 40, TRUE)

	// Apply combo multiplier
	var/multiplier = 1
	if(combo >= 5)
		multiplier = 2
	else if(combo >= 3)
		multiplier = 1.5

	if(points > 0)
		points = round(points * multiplier)

	score += points

	// Track best combo
	if(combo > best_combo)
		best_combo = combo

	// Update UI to show result
	SStgui.update_uis(src)

	// Short delay then advance round
	addtimer(CALLBACK(src, PROC_REF(advance_round)), 1 SECONDS)

/// Check what type of hit the player got
/datum/sculpting_minigame/proc/check_hit()
	for(var/list/spot in sweet_spots)
		if(needle_position >= spot["perfect_start"] && needle_position <= spot["perfect_end"])
			return "perfect"
		if(needle_position >= spot["start"] && needle_position <= spot["end"])
			// Check if close to perfect zone
			var/perfect_center = (spot["perfect_start"] + spot["perfect_end"]) / 2
			var/distance = abs(needle_position - perfect_center)
			if(distance <= 3)
				return "good"
			return "okay"
	return "miss"

/datum/sculpting_minigame/proc/advance_round()
	current_round++

	if(current_round > total_rounds)
		end_game()
		return

	// Increase speed slightly each round
	needle_speed += 0.15

	// Generate new sweet spots
	generate_sweet_spots()

	// Reset for next round
	awaiting_input = TRUE
	last_hit_result = ""

	SStgui.update_uis(src)

/datum/sculpting_minigame/proc/end_game()
	active = FALSE
	stop_needle_movement()

	// Calculate grade
	var/grade = calculate_grade()

	// Apply grade to artwork
	if(artwork)
		artwork.complete_refinement(grade)

		// Add flat EXP based on grade
		var/datum/component/artistic_exp/exp_comp = sculptor.GetComponent(/datum/component/artistic_exp)
		if(exp_comp)
			exp_comp.add_refine_exp(grade)

	to_chat(sculptor, span_notice("Refinement complete! Grade: [grade]"))

	// Update UI one final time
	SStgui.update_uis(src)

/datum/sculpting_minigame/proc/calculate_grade()
	if(score <= 5)
		return "F"
	if(score <= 10)
		return "C"
	if(score <= 15)
		return "B"
	if(score <= 20)
		return "A"
	return "S"

/datum/sculpting_minigame/proc/get_grade_color(grade)
	switch(grade)
		if("F")
			return "red"
		if("C")
			return "orange"
		if("B")
			return "yellow"
		if("A")
			return "green"
		if("S")
			return "gold"
	return "white"

// TGUI Interface
/datum/sculpting_minigame/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SculptingMinigame")
		ui.open()

/datum/sculpting_minigame/ui_state(mob/user)
	return GLOB.conscious_state

/datum/sculpting_minigame/ui_data(mob/user)
	var/list/data = list()

	data["active"] = active
	data["currentRound"] = current_round
	data["totalRounds"] = total_rounds
	data["score"] = score
	data["combo"] = combo
	data["bestCombo"] = best_combo
	data["needlePosition"] = needle_position
	data["awaitingInput"] = awaiting_input
	data["lastHitResult"] = last_hit_result
	data["difficulty"] = difficulty

	// Sweet spots data
	data["sweetSpots"] = list()
	for(var/list/spot in sweet_spots)
		data["sweetSpots"] += list(list(
			"start" = spot["start"],
			"end" = spot["end"],
			"perfectStart" = spot["perfect_start"],
			"perfectEnd" = spot["perfect_end"]
		))

	// Game over data
	if(!active && current_round > total_rounds)
		data["gameOver"] = TRUE
		data["finalGrade"] = calculate_grade()
		data["gradeColor"] = get_grade_color(calculate_grade())
	else
		data["gameOver"] = FALSE

	return data

/datum/sculpting_minigame/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("sculpt")
			attempt_sculpt()
			return TRUE
		if("start")
			start_game()
			return TRUE
		if("close")
			qdel(src)
			return TRUE

	return FALSE

/datum/sculpting_minigame/ui_close(mob/user)
	. = ..()
	qdel(src)
