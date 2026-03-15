// ============================================================
// Path Items — Path Selection Crystal & EXP Crystal
// ============================================================

// ---- Path Selection Crystal ----

/// An item that allows the user to choose and receive a Path.
/// Use in hand to select from available paths.
/obj/item/path_crystal
	name = "Stellaron Fragment"
	desc = "A fragment of crystallized imaginary energy. Use in hand to awaken your Path."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"
	w_class = WEIGHT_CLASS_SMALL

	/// Assoc list of path names to path types
	var/list/available_paths = list(
		"Destruction" = /datum/path/destruction,
	)

/obj/item/path_crystal/attack_self(mob/living/carbon/human/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can awaken a Path."))
		return

	if(user.HasPath())
		to_chat(user, span_warning("You already walk a Path. You cannot choose another."))
		return

	// Build choice list with descriptions
	var/list/choices = list()
	for(var/path_name in available_paths)
		choices += path_name

	if(!length(choices))
		to_chat(user, span_warning("No paths are available."))
		return

	var/choice = tgui_input_list(user, "Choose your Path. This decision shapes your combat abilities.", "Awaken Your Path", choices)
	if(!choice)
		return
	if(QDELETED(src) || QDELETED(user))
		return
	if(!user.is_holding(src))
		return
	if(user.HasPath())
		return

	var/path_type = available_paths[choice]
	if(!path_type)
		return

	// Grant the path
	if(user.GrantPath(path_type))
		to_chat(user, span_nicegreen("You have awakened the Path of [choice]. The imaginary energy flows through you."))
		playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
		qdel(src)
	else
		to_chat(user, span_warning("Failed to awaken your Path."))

/obj/item/path_crystal/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to choose a Path.")
	. += span_notice("Available paths:")
	for(var/path_name in available_paths)
		. += span_notice("  - [path_name]")

// ---- Path EXP Crystal ----

/// An item that grants path EXP (levels up the active path).
/// Cost scales by current ascension phase.
/obj/item/path_exp_crystal
	name = "Path EXP Crystal"
	desc = "A crystal of concentrated imaginary energy. Use in hand to grant a level to your active path."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/path_exp_crystal/attack_self(mob/living/carbon/human/user)
	if(!ishuman(user))
		return

	var/datum/path/P = user.GetPath()
	if(!P)
		to_chat(user, span_warning("You don't have an active Path!"))
		return

	// Check level cap for current ascension
	if(P.ascension_phase < length(P.level_caps))
		var/cap = P.level_caps[P.ascension_phase + 1]
		if(P.path_level >= cap)
			to_chat(user, span_warning("You have reached the level cap ([cap]) for your current ascension phase. Ascend first!"))
			return

	if(P.path_level >= 80)
		to_chat(user, span_warning("Your path is already at maximum level!"))
		return

	// Level up
	P.SetLevel(P.path_level + 1)
	to_chat(user, span_nicegreen("Your [P.name] path is now level [P.path_level]!"))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	qdel(src)

/obj/item/path_exp_crystal/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to level up your active path by 1.")

// ---- Path Ascension Crystal ----

/// An item that ascends the active path to the next phase.
/obj/item/path_ascension_crystal
	name = "Path Ascension Crystal"
	desc = "A crystal of pure imaginary energy. Use in hand to ascend your path to the next phase."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/path_ascension_crystal/attack_self(mob/living/carbon/human/user)
	if(!ishuman(user))
		return

	var/datum/path/P = user.GetPath()
	if(!P)
		to_chat(user, span_warning("You don't have an active Path!"))
		return

	if(P.ascension_phase >= 6)
		to_chat(user, span_warning("Your path is already at maximum ascension!"))
		return

	// Check if at level cap for current phase
	var/cap = P.level_caps[P.ascension_phase + 1]
	if(P.path_level < cap)
		to_chat(user, span_warning("You must reach level [cap] before ascending!"))
		return

	if(P.Ascend())
		to_chat(user, span_nicegreen("Your [P.name] path has ascended to phase [P.ascension_phase]! Level cap raised."))
		playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
		qdel(src)
	else
		to_chat(user, span_warning("Failed to ascend!"))

/obj/item/path_ascension_crystal/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to ascend your path to the next phase.")
