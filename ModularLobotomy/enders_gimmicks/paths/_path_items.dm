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
	custom_price = 500

	/// Assoc list of path names to path types
	var/list/available_paths = list(
		"Destruction" = /datum/path/destruction,
		"The Hunt" = /datum/path/hunt,
		"Erudition" = /datum/path/erudition,
		"Nihility" = /datum/path/nihility,
		"Harmony" = /datum/path/harmony,
		"Preservation" = /datum/path/preservation,
		"Abundance" = /datum/path/abundance,
	)

/obj/item/path_crystal/attack_self(mob/living/carbon/human/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can awaken a Path."))
		return

	if(user.HasPath())
		to_chat(user, span_warning("You already walk a Path. You cannot choose another."))
		return

	if(GLOB.path_realm_active)
		to_chat(user, span_warning("The Path Realm is already open. Please wait."))
		return

	// Start the Path Realm experience
	var/datum/path_realm/realm = new(user)
	realm.Start()
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	qdel(src)

/obj/item/path_crystal/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to choose a Path.")

// ---- Direct Path Selection (Debug/Admin) ----

/// Simplified path selection item that skips the realm experience
/obj/item/path_crystal/direct
	name = "Stellaron Fragment (Direct)"
	desc = "A fragment of crystallized imaginary energy. Use in hand to directly choose your Path."

/obj/item/path_crystal/direct/attack_self(mob/living/carbon/human/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can awaken a Path."))
		return
	if(user.HasPath())
		to_chat(user, span_warning("You already walk a Path. You cannot choose another."))
		return
	var/list/choices = list()
	for(var/path_name in available_paths)
		choices += path_name
	if(!length(choices))
		to_chat(user, span_warning("No paths are available."))
		return
	var/choice = tgui_input_list(user, "Choose your Path.", "Awaken Your Path", choices)
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
	if(user.GrantPath(path_type))
		to_chat(user, span_nicegreen("You have awakened the Path of [choice]."))
		playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
		qdel(src)
	else
		to_chat(user, span_warning("Failed to awaken your Path."))
	. += span_notice("Available paths:")
	for(var/path_name in available_paths)
		. += span_notice("  - [path_name]")

// ---- Path EXP Crystals (3 tiers, stackable) ----

/// Base path EXP crystal stack. Use in hand to select how many to consume.
/obj/item/stack/path_exp_crystal
	name = "Path EXP Crystal (Small)"
	singular_name = "Path EXP Crystal (Small)"
	desc = "A fragment of imaginary energy. Grants 1,000 Character EXP per crystal to your active path."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"
	w_class = WEIGHT_CLASS_SMALL
	max_amount = 50
	novariants = TRUE
	custom_price = 2
	merge_type = /obj/item/stack/path_exp_crystal
	/// EXP granted per crystal
	var/exp_per = 1000

/obj/item/stack/path_exp_crystal/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/datum/path/P = H.GetPath()
	if(!P)
		to_chat(user, span_warning("You don't have an active Path!"))
		return
	if(P.path_level >= 80)
		to_chat(user, span_warning("Your path is already at maximum level!"))
		return
	var/use_count = 1
	if(amount > 1)
		use_count = input(user, "How many crystals to use? ([exp_per] EXP each, have [amount])", "Use Path EXP Crystals", 1) as null|num
		if(!use_count || use_count <= 0)
			return
		if(QDELETED(src) || QDELETED(user))
			return
		if(!user.is_holding(src))
			return
		use_count = min(use_count, amount)
	var/total_exp = exp_per * use_count
	use(use_count)
	P.GainExp(total_exp)
	to_chat(user, span_nicegreen("Used [use_count] crystal\s for [total_exp] Path EXP!"))
	playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)

/obj/item/stack/path_exp_crystal/examine(mob/user)
	. = ..()
	. += span_notice("Grants [exp_per] Character EXP per crystal. Use in hand to consume.")
	var/datum/path/P
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		P = H.GetPath()
	if(P)
		var/to_next = P.GetExpToNext()
		. += span_notice("Current: [P.path_exp] / [P.GetExpAtLevel() + to_next] EXP (Lv.[P.path_level])")

/// Tier 2: 5,000 EXP per crystal
/obj/item/stack/path_exp_crystal/medium
	name = "Path EXP Crystal (Medium)"
	singular_name = "Path EXP Crystal (Medium)"
	desc = "A crystal of imaginary energy. Grants 5,000 Character EXP per crystal to your active path."
	custom_price = 10
	merge_type = /obj/item/stack/path_exp_crystal/medium
	exp_per = 5000

/// Tier 3: 20,000 EXP per crystal
/obj/item/stack/path_exp_crystal/large
	name = "Path EXP Crystal (Large)"
	singular_name = "Path EXP Crystal (Large)"
	desc = "A dense crystal of imaginary energy. Grants 20,000 Character EXP per crystal to your active path."
	custom_price = 42
	merge_type = /obj/item/stack/path_exp_crystal/large
	exp_per = 20000

// ---- Path Ascension Crystal ----

/// An item that ascends the active path to the next phase.
/// Required when reaching a level cap to continue leveling.
/obj/item/path_ascension_crystal
	name = "Path Ascension Crystal"
	desc = "A crystal of pure imaginary energy. Use when at a level cap to ascend your path and raise the cap."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"
	w_class = WEIGHT_CLASS_SMALL
	custom_price = 100

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
	// Must be at level cap for current phase
	var/cap = P.level_caps[P.ascension_phase + 1]
	if(P.path_level < cap)
		to_chat(user, span_warning("You must reach level [cap] before ascending! (Currently level [P.path_level])"))
		return
	if(P.Ascend())
		to_chat(user, span_nicegreen("Your [P.name] path has ascended to phase [P.ascension_phase]! Level cap raised to [P.level_caps[P.ascension_phase + 1]]."))
		playsound(get_turf(user), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
		qdel(src)
	else
		to_chat(user, span_warning("Failed to ascend!"))

/obj/item/path_ascension_crystal/examine(mob/user)
	. = ..()
	. += span_notice("Use at a level cap to ascend your path.")
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/datum/path/P = H.GetPath()
		if(P)
			. += span_notice("Current: A[P.ascension_phase], Lv.[P.path_level]")
			if(P.ascension_phase < 6)
				. += span_notice("Next cap: Lv.[P.level_caps[P.ascension_phase + 1]]")

// ============================================================
// Path Vending Machine
// ============================================================

/obj/machinery/vending/pathstrider
	name = "\improper Pathstrider Supplies"
	desc = "A machine selling Path awakening and leveling materials."
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	product_slogans = "Walk your Path.;The imaginary energy calls."
	product_ads = "Awaken your potential!"
	icon_state = "generic"
	icon_deny = null
	products = list(
		/obj/item/path_crystal = 5,
		/obj/item/stack/path_exp_crystal = 1500,
		/obj/item/stack/path_exp_crystal/medium = 1500,
		/obj/item/stack/path_exp_crystal/large = 1500,
		/obj/item/path_ascension_crystal = 50,
	)

	default_price = 0
	input_display_header = "Pathstrider Supplies"
