// Tinkerer's Corrosions - Antagonist datum for corroded beings

/datum/antagonist/tinkerer_corrosion
	name = "Tinkerer's Corrosion"
	roundend_category = "Tinkerer's corrosions"
	show_in_roundend = TRUE
	prevent_roundtype_conversion = FALSE
	can_coexist_with_others = FALSE
	antagpanel_category = "Other"
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	antag_hud_type = ANTAG_HUD_HERETIC
	antag_hud_name = "tinkerer"

/datum/antagonist/tinkerer_corrosion/on_gain()
	. = ..()
	create_objectives()
	owner.special_role = "Tinkerer's Corrosion"

	// Add to team if it exists, create if not
	var/datum/team/tinkerer_corrosions/T = locate(/datum/team/tinkerer_corrosions) in GLOB.antagonist_teams
	if(!T)
		T = new /datum/team/tinkerer_corrosions()
		T.add_member(owner)
	else
		T.add_member(owner)

/datum/antagonist/tinkerer_corrosion/proc/create_objectives()
	var/datum/objective/tinkerer_corrosion/main_objective = new()
	main_objective.owner = owner
	objectives += main_objective

/datum/antagonist/tinkerer_corrosion/greet()
	to_chat(owner.current, span_userdanger("You have been corroded by the Tinkerer!"))
	to_chat(owner.current, span_danger("Your body has been transformed into a more machine-like form."))
	to_chat(owner.current, span_warning("Your emotions have been heavily suppressed, leaving only cold logic and purpose."))
	to_chat(owner.current, span_notice("You seek to follow objectives, but you need to find someone else to follow orders from."))
	to_chat(owner.current, span_notice("Perhaps another corrupted being, or someone with authority..."))

	owner.announce_objectives()

/datum/antagonist/tinkerer_corrosion/farewell()
	to_chat(owner.current, span_notice("The mechanical corruption fades from your mind..."))
	owner.special_role = null

/datum/antagonist/tinkerer_corrosion/apply_innate_effects(mob/living/mob_override)
	var/mob/living/current = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, current)

/datum/antagonist/tinkerer_corrosion/remove_innate_effects(mob/living/mob_override)
	var/mob/living/current = mob_override || owner.current
	remove_antag_hud(antag_hud_type, current)

/datum/antagonist/tinkerer_corrosion/get_team()
	return locate(/datum/team/tinkerer_corrosions) in GLOB.antagonist_teams

// Team datum for Tinkerer's Corrosions
/datum/team/tinkerer_corrosions
	name = "Tinkerer's Corrosions"
	member_name = "corrosion"

/datum/team/tinkerer_corrosions/proc/forge_objectives()
	// Team objectives could be added here if needed
	return

/datum/team/tinkerer_corrosions/roundend_report()
	var/list/report = list()
	report += "<span class='header'>The Tinkerer's Corrosions were:</span>"

	for(var/datum/mind/M in members)
		report += printplayer(M)

	if(length(report) <= 1)
		report += "<span class='warning'>There were no Tinkerer's Corrosions!</span>"

	return "<div class='panel redborder'>[report.Join("<br>")]</div>"

// Custom objective for Tinkerer's Corrosions
/datum/objective/tinkerer_corrosion
	name = "Behave, Machine"
	explanation_text = "You have been corroded into a more machine-like form. Your emotions are suppressed. Seek someone to follow - another corrupted being, a figure of authority, or forge your own path. The choice is yours, but you must have purpose."
	martyr_compatible = TRUE

/datum/objective/tinkerer_corrosion/check_completion()
	// This is a roleplay objective, always considered complete if the player survived
	if(owner && owner.current)
		if(owner.current.stat != DEAD)
			return TRUE
		// Check if they died but completed some meaningful action
		// This could be expanded based on specific criteria
		return TRUE
	return FALSE
