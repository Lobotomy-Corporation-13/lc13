// Asat Pramad.
//
// Handles items like a person rather than a beast: dextrous, so he can pick
// things up, read, and use what he holds, and he renders the inhand sprite of
// whatever is in his hands the way a human does.
//
// Abilities:
//   Veil    drops out of sight at once and walks through solid matter, and
//           returns whenever he chooses with a short fade in. Coming back is
//           never gated; only going under is.
//   Shift   cycles between his three looks: bare hand, crowned with the die,
//           and wearing the hat.
//   Coat    opens the space beneath his coat, an ordinary storage window he
//           drags things in and out of, with no practical limit.
//   Call    one button per void ranger. Each asks how many to raise and
//           whether they come up hostile or peaceable.
//   Command one order to every ranger answering to him.
//   Face    wears a copy of a nearby person, or a stranger who never existed.
//           See asat_disguise.dm.

/// Layer the held-item overlay sits on. Above the body, below the HUD.
#define ASAT_HANDS_LAYER 20
/// Tint on his phase, shift and summoning effects, matched to his hand.
#define ASAT_VEIL_COLOR "#4E3CD4"

/mob/living/simple_animal/hostile/asat_pramad
	name = "Asat Pramad"
	desc = "A white greatcoat over a gilded waistcoat, and where a head should be, a curled violet hand. It regards you without eyes."
	icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	icon_state = "base_hat"
	icon_living = "base_hat"
	icon_dead = "base"
	health_doll_icon = "base_hat"
	mob_biotypes = MOB_HUMANOID
	maxHealth = 2000
	health = 2000
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2)

	melee_damage_type = PALE_DAMAGE
	melee_damage_lower = 24
	melee_damage_upper = 30
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/slash.ogg'
	move_to_delay = 3
	speed = 1
	stat_attack = HARD_CRIT
	// FACTION_ASAT is what his rangers recognise him by. It is never stripped,
	// so ordering them hostile does not turn them on him.
	faction = list("neutral", FACTION_ASAT)
	del_on_death = FALSE

	response_help_continuous = "reaches out to"
	response_help_simple = "reach out to"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	response_harm_continuous = "strikes"
	response_harm_simple = "strike"

	// Handles objects the way a person does: carry, read, use.
	dextrous = TRUE
	held_items = list(null, null)
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)

	footstep_type = FOOTSTEP_MOB_SHOE

	/// TRUE while he is out of sight and walking through matter.
	var/veiled = FALSE
	/// Icon states he shifts between, in cycle order.
	var/list/forms = list("base", "base_dice", "base_hat")
	/// How each form reads in the shift message, indexed alongside `forms`.
	var/list/form_names = list("bare", "crowned with the die", "hatted")
	/// Index into `forms` of the look he is currently wearing.
	var/form_index = 3

	/// The space beneath his coat. Held inside him, never in a hand.
	var/obj/item/storage/asat_coat/coat_storage
	/// Ranger types he can call up, and how many of each his leadership
	/// component will hold at once.
	var/list/ranger_roster = list(
		/mob/living/simple_animal/hostile/void_ranger/baryon = 4,
		/mob/living/simple_animal/hostile/void_ranger/antibaryon = 4,
		/mob/living/simple_animal/hostile/void_ranger/reaver = 3,
		/mob/living/simple_animal/hostile/void_ranger/distorter = 2,
		/mob/living/simple_animal/hostile/void_ranger/eliminator = 2,
	)
	/// Most rangers he may have standing at once.
	var/max_rangers = 8

	var/datum/action/cooldown/asat_veil/veil_action
	var/datum/action/cooldown/asat_shift/shift_action
	var/datum/action/innate/asat_coat/coat_action
	var/datum/action/innate/asat_command/command_action
	/// Repeating timer that keeps the rangers walking after him.
	var/formation_timer
	/// One summon button per ranger type, built from the action subtypes.
	var/list/summon_actions = list()

/mob/living/simple_animal/hostile/asat_pramad/Initialize(mapload)
	. = ..()
	coat_storage = new(src)
	veil_action = new()
	veil_action.Grant(src)
	shift_action = new()
	shift_action.Grant(src)
	coat_action = new()
	coat_action.Grant(src)
	command_action = new()
	command_action.Grant(src)
	mimic_action = new()
	mimic_action.Grant(src)
	stranger_action = new()
	stranger_action.Grant(src)
	for(var/summon_type in subtypesof(/datum/action/cooldown/asat_summon))
		var/datum/action/cooldown/asat_summon/summon = new summon_type()
		summon.Grant(src)
		summon_actions += summon
	// Rangers he raises fall in behind him on their own.
	AddComponent(/datum/component/ai_leadership, ranger_roster, max_rangers, TRUE)
	// A hostile's own AI cancels its walk the moment it finds no target, which
	// wipes out the follow order the leadership component issues on recruit.
	// Re-issuing it on a slow tick is what actually keeps them in tow.
	formation_timer = addtimer(CALLBACK(src, PROC_REF(KeepFormation)), 2 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/mob/living/simple_animal/hostile/asat_pramad/Destroy()
	if(veil_action)
		veil_action.Remove(src)
		QDEL_NULL(veil_action)
	if(shift_action)
		shift_action.Remove(src)
		QDEL_NULL(shift_action)
	if(coat_action)
		coat_action.Remove(src)
		QDEL_NULL(coat_action)
	if(command_action)
		command_action.Remove(src)
		QDEL_NULL(command_action)
	if(mimic_action)
		mimic_action.Remove(src)
		QDEL_NULL(mimic_action)
	if(stranger_action)
		stranger_action.Remove(src)
		QDEL_NULL(stranger_action)
	for(var/datum/action/summon as anything in summon_actions)
		summon.Remove(src)
		qdel(summon)
	summon_actions = null
	if(formation_timer)
		deltimer(formation_timer)
		formation_timer = null
	QDEL_NULL(coat_storage)
	return ..()

// ---- Held items ----

/// Rebuilds the body overlays so a held item is drawn in hand. The parent keeps
/// the HUD slots in sync; it does not draw anything on the mob itself.
/mob/living/simple_animal/hostile/asat_pramad/update_inv_hands()
	. = ..()
	update_icon()

/mob/living/simple_animal/hostile/asat_pramad/update_overlays()
	. = ..()
	for(var/obj/item/held in held_items)
		// Left hand is index 1, right is 2, matching how carbons pick the file.
		var/index = get_held_index_of_item(held)
		var/icon_file = (index % 2 == 0) ? held.righthand_file : held.lefthand_file
		if(!icon_file)
			continue
		var/mutable_appearance/inhand = held.build_worn_icon(
			default_layer = ASAT_HANDS_LAYER,
			default_icon_file = icon_file,
			isinhands = TRUE,
		)
		if(inhand)
			. += inhand

// ---- Shifting form ----

/// Cycles to his next look. Purely cosmetic, so it stays available even while
/// veiled; the new form is simply what he returns as.
/mob/living/simple_animal/hostile/asat_pramad/proc/ShiftForm()
	form_index = (form_index % length(forms)) + 1
	var/new_state = forms[form_index]
	icon_state = new_state
	icon_living = new_state
	health_doll_icon = new_state
	update_icon()
	var/obj/effect/temp_visual/turn_book/T = new(get_turf(src))
	T.color = ASAT_VEIL_COLOR
	playsound(get_turf(src), 'sound/effects/magic.ogg', 35, TRUE)
	to_chat(src, span_notice("You take your [form_names[form_index]] shape."))
	return TRUE

// ---- The Veil ----

/// Drops out of sight at once and lets him move through solid matter.
/mob/living/simple_animal/hostile/asat_pramad/proc/Veil()
	if(veiled)
		return FALSE
	veiled = TRUE
	// No fade on the way out: he is simply gone the moment it is pressed.
	alpha = 0
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	incorporeal_move = INCORPOREAL_MOVE_JAUNT
	var/obj/effect/temp_visual/turn_book/T = new(get_turf(src))
	T.color = ASAT_VEIL_COLOR
	playsound(get_turf(src), 'sound/effects/ghost2.ogg', 40, TRUE)
	to_chat(src, span_notice("You slip out of sight. Nothing solid holds you now."))
	return TRUE

/// Returns to the world with a short fade in. Refuses to solidify inside
/// anything, since that would leave him stuck in a wall.
/mob/living/simple_animal/hostile/asat_pramad/proc/Unveil()
	if(!veiled)
		return FALSE
	var/turf/here = get_turf(src)
	if(!here || here.is_blocked_turf(TRUE, src))
		to_chat(src, span_warning("There is no room here to return. Move somewhere clear."))
		return FALSE
	veiled = FALSE
	density = initial(density)
	mouse_opacity = initial(mouse_opacity)
	incorporeal_move = FALSE
	var/obj/effect/temp_visual/turn_book/T = new(here)
	T.color = ASAT_VEIL_COLOR
	playsound(here, 'sound/effects/ghost.ogg', 40, TRUE)
	// Fade back in rather than snapping into place.
	alpha = 0
	animate(src, alpha = initial(alpha), time = 0.6 SECONDS)
	to_chat(src, span_notice("You draw yourself back into the world."))
	return TRUE

/// Never leave a corpse invisible or phased through a wall, and let whatever he
/// was carrying fall out rather than vanishing with him.
/mob/living/simple_animal/hostile/asat_pramad/death(gibbed)
	if(veiled)
		veiled = FALSE
		density = initial(density)
		mouse_opacity = initial(mouse_opacity)
		incorporeal_move = FALSE
		alpha = initial(alpha)
	SpillCoat()
	return ..()

// ---- Rangers ----

/// The rangers currently answering to him, straight from the leadership
/// component so there is only ever one list to keep true.
/// Re-issues the walk order to any ranger that is idle. Skips ones that are
/// fighting, so an order to follow never drags them off a target, and skips
/// ones told to Hold, whose AI is switched off entirely.
/mob/living/simple_animal/hostile/asat_pramad/proc/KeepFormation()
	if(QDELETED(src) || stat == DEAD)
		return
	for(var/mob/living/simple_animal/hostile/ranger in GetRangers())
		if(ranger.AIStatus == AI_OFF)
			continue
		if(ranger.target)
			continue
		if(get_dist(src, ranger) <= 2)
			continue
		walk_to(ranger, src, 2, ranger.move_to_delay)

/// Every outward tell an order gives off goes through these two, so that
/// commanding from behind the veil stays as quiet as standing there does. The
/// player still gets their own to_chat either way; it is only the room that
/// hears nothing.
/mob/living/simple_animal/hostile/asat_pramad/proc/OrderHeard(message, sound_file, volume = 40)
	if(veiled)
		return
	if(message)
		visible_message(message)
	if(sound_file)
		playsound(get_turf(src), sound_file, volume, TRUE)

/// The shimmer left where a ranger arrives or leaves.
/mob/living/simple_animal/hostile/asat_pramad/proc/OrderMark(turf/spot)
	if(veiled || !spot)
		return
	var/obj/effect/temp_visual/turn_book/T = new(spot)
	T.color = ASAT_VEIL_COLOR

/// TRUE if any ranger is listening, with a word to the player if none are.
/mob/living/simple_animal/hostile/asat_pramad/proc/RangersAnswer()
	if(length(GetRangers()))
		return TRUE
	to_chat(src, span_warning("No rangers are answering to you."))
	return FALSE

/mob/living/simple_animal/hostile/asat_pramad/proc/GetRangers()
	var/datum/component/ai_leadership/lead = GetComponent(/datum/component/ai_leadership)
	if(!lead)
		return list()
	var/list/live = list()
	for(var/mob/living/ranger in lead.followers)
		if(!QDELETED(ranger) && ranger.stat != DEAD)
			live += ranger
	return live

/// Raises `count` rangers of a type on free tiles beside him. `hostile` decides
/// which faction they come up wearing.
/mob/living/simple_animal/hostile/asat_pramad/proc/SummonRanger(ranger_type, count = 1, hostile = TRUE)
	if(!ranger_type)
		return FALSE
	var/standing = length(GetRangers())
	if(standing >= max_rangers)
		to_chat(src, span_warning("You already hold as many as you can command."))
		return FALSE
	var/raising = min(count, max_rangers - standing)
	if(raising < count)
		to_chat(src, span_warning("You have room for only [raising] more."))
	var/turf/here = get_turf(src)
	var/raised = 0
	for(var/i in 1 to raising)
		var/list/spots = list()
		for(var/turf/open/candidate in orange(2, here))
			if(!candidate.is_blocked_turf(TRUE))
				spots += candidate
		var/turf/spot = length(spots) ? pick(spots) : here
		var/mob/living/simple_animal/hostile/void_ranger/ranger = new ranger_type(spot)
		ranger.faction = hostile ? list(FACTION_ASAT) : list("neutral", FACTION_ASAT)
		// Enlist it here rather than waiting for the leadership component's
		// periodic scan. That scan refuses to recruit while the leader has a
		// target, so a ranger raised mid-fight would never join and would then
		// ignore every order.
		var/datum/component/ai_leadership/lead = GetComponent(/datum/component/ai_leadership)
		if(lead && !(ranger in lead.followers))
			lead.Recruit(ranger)
		OrderMark(spot)
		raised++
	if(!raised)
		return FALSE
	OrderHeard(span_warning("[src] draws [raised] ranger\s out of the empty air!"), 'sound/effects/ghost.ogg')
	if(veiled)
		to_chat(src, span_notice("[raised] step out of nothing beside you, unremarked."))
	// Put them in step at once rather than on the next upkeep tick.
	KeepFormation()
	if(hostile)
		to_chat(src, span_warning("They come up looking for someone to hurt."))
	return TRUE

/// Places every ranger in a column directly behind him, nearest first.
/mob/living/simple_animal/hostile/asat_pramad/proc/FormUp()
	if(!RangersAnswer())
		return FALSE
	var/list/rangers = GetRangers()
	var/back = turn(dir, 180)
	var/turf/step_turf = get_turf(src)
	var/placed = 0
	for(var/mob/living/ranger in rangers)
		var/turf/next = get_step(step_turf, back)
		// Step past anything solid so the line does not pile up on a wall.
		var/tries = 0
		while(next && next.is_blocked_turf(TRUE) && tries < 4)
			next = get_step(next, back)
			tries++
		if(!next || next.is_blocked_turf(TRUE))
			break
		OrderMark(get_turf(ranger))
		ranger.forceMove(next)
		ranger.setDir(dir)
		step_turf = next
		placed++
	OrderHeard(null, 'sound/effects/ghost2.ogg')
	to_chat(src, span_notice("[placed] fall into line behind you."))
	return TRUE

/// Brings every ranger to the tiles around him.
/mob/living/simple_animal/hostile/asat_pramad/proc/RecallRangers()
	if(!RangersAnswer())
		return FALSE
	var/list/rangers = GetRangers()
	var/turf/here = get_turf(src)
	for(var/mob/living/ranger in rangers)
		var/list/spots = list()
		for(var/turf/open/candidate in orange(2, here))
			if(!candidate.is_blocked_turf(TRUE))
				spots += candidate
		var/turf/spot = length(spots) ? pick(spots) : here
		OrderMark(get_turf(ranger))
		ranger.forceMove(spot)
	OrderHeard(null, 'sound/effects/ghost2.ogg')
	to_chat(src, span_notice("They step out of nothing at your side."))
	return TRUE

/// Sets whether the rangers treat the living as prey. Dropping "neutral" is
/// what makes them hostile; FACTION_ASAT is kept either way so they never turn
/// on him.
/mob/living/simple_animal/hostile/asat_pramad/proc/SetRangersHostile(hostile)
	if(!RangersAnswer())
		return FALSE
	var/list/rangers = GetRangers()
	for(var/mob/living/simple_animal/hostile/ranger in rangers)
		ranger.faction = hostile ? list(FACTION_ASAT) : list("neutral", FACTION_ASAT)
		ranger.LoseTarget()
	if(hostile)
		OrderHeard(span_userdanger("[src] gestures, and the rangers turn outward."))
		if(veiled)
			to_chat(src, span_warning("They turn outward, and nothing shows who told them to."))
	else
		to_chat(src, span_notice("They settle, and stop looking at anyone."))
	return TRUE

/// Freezes or releases the rangers where they stand.
/mob/living/simple_animal/hostile/asat_pramad/proc/SetRangersHolding(holding)
	if(!RangersAnswer())
		return FALSE
	var/list/rangers = GetRangers()
	for(var/mob/living/simple_animal/hostile/ranger in rangers)
		ranger.toggle_ai(holding ? AI_OFF : AI_ON)
		if(holding)
			walk(ranger, 0)
	if(holding)
		to_chat(src, span_notice("They stop where they are."))
	else
		KeepFormation()
		to_chat(src, span_notice("They take up behind you again."))
	return TRUE

/// Sends them back where they came from.
/mob/living/simple_animal/hostile/asat_pramad/proc/DismissRangers()
	if(!RangersAnswer())
		return FALSE
	var/list/rangers = GetRangers()
	for(var/mob/living/ranger in rangers)
		OrderMark(get_turf(ranger))
		qdel(ranger)
	OrderHeard(null, 'sound/effects/ghost.ogg')
	to_chat(src, span_notice("You let them go."))
	return TRUE

// ---- The space beneath the coat ----

/// A normal storage object that lives inside him, so opening it gives the same
/// window a backpack does: drag items in, take single items back out, see
/// everything at once. The limits are set high enough to never be met rather
/// than special-cased away, which keeps every stock storage interaction working.
/obj/item/storage/asat_coat
	name = "the space beneath the coat"
	desc = "There is more room in here than there is out there."
	icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	icon_state = "action_void"
	w_class = WEIGHT_CLASS_GIGANTIC
	resistance_flags = INDESTRUCTIBLE
	item_flags = ABSTRACT | DROPDEL

/obj/item/storage/asat_coat/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 1000
	STR.max_combined_w_class = 10000
	STR.max_w_class = WEIGHT_CLASS_GIGANTIC
	STR.allow_quick_empty = TRUE
	STR.allow_quick_gather = TRUE
	STR.screen_max_columns = 10
	STR.screen_max_rows = 10

/// Tips everything out of the coat onto the floor.
/mob/living/simple_animal/hostile/asat_pramad/proc/SpillCoat()
	if(!coat_storage)
		return
	var/datum/component/storage/STR = coat_storage.GetComponent(/datum/component/storage)
	if(STR)
		STR.do_quick_empty(get_turf(src))

// ---- Actions ----

/datum/action/cooldown/asat_veil
	name = "Veil"
	desc = "Slip out of sight and walk through solid matter. Use again to return; returning is never on cooldown."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_veil"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/asat_veil/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/asat_pramad/asat = owner
	if(!istype(asat))
		return FALSE
	if(asat.veiled)
		// Coming back is always available; the cooldown starts here so he
		// cannot flicker in and out on the spot.
		if(asat.Unveil())
			StartCooldown()
		return TRUE
	return asat.Veil()

/datum/action/cooldown/asat_shift
	name = "Shift Form"
	desc = "Change between your bare hand, the die that crowns it, and the hat."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_form"
	cooldown_time = 1 SECONDS

/datum/action/cooldown/asat_shift/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/asat_pramad/asat = owner
	if(!istype(asat))
		return FALSE
	asat.ShiftForm()
	StartCooldown()
	return TRUE

/datum/action/innate/asat_coat
	name = "Open the Coat"
	desc = "Open the space beneath your coat. Put things in and take them out as you would any bag; it does not fill."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_void"

/datum/action/innate/asat_coat/Activate()
	var/mob/living/simple_animal/hostile/asat_pramad/asat = owner
	if(!istype(asat) || !asat.coat_storage)
		return
	var/datum/component/storage/STR = asat.coat_storage.GetComponent(/datum/component/storage)
	if(!STR)
		return
	STR.show_to(asat)

/// One button per ranger. The base is abstract; each subtype names its own
/// ranger and wears that ranger's sprite, so they read apart on the HUD. Every
/// one asks how many to raise and whether they come up hostile.
/datum/action/cooldown/asat_summon
	name = "Call a Ranger"
	desc = "Draw void rangers out of the empty air. They fall in behind you on their own."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_summon"
	cooldown_time = 4 SECONDS
	/// Which ranger this button calls.
	var/ranger_type

/datum/action/cooldown/asat_summon/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/asat_pramad/asat = owner
	if(!istype(asat) || !ranger_type)
		return FALSE
	var/room = asat.max_rangers - length(asat.GetRangers())
	if(room <= 0)
		to_chat(asat, span_warning("You already hold as many as you can command."))
		return FALSE
	var/list/counts = list()
	for(var/i in 1 to room)
		counts += "[i]"
	var/picked = tgui_input_list(asat, "How many?", "Call Rangers", counts)
	if(!picked)
		return FALSE
	// Hostile leads, so it is what the list opens on.
	var/list/stances = list("Hostile (attack the living)", "Peaceable (harm no one)")
	var/stance = tgui_input_list(asat, "How do they come up?", "Call Rangers", stances)
	if(!stance)
		return FALSE
	if(asat.SummonRanger(ranger_type, text2num(picked), stance == "Hostile (attack the living)"))
		StartCooldown()
	return TRUE

/datum/action/cooldown/asat_summon/baryon
	name = "Call Baryon Ranger"
	desc = "A ranger of settled matter. Steady, and hard to talk out of a position."
	button_icon_state = "action_r_baryon"
	ranger_type = /mob/living/simple_animal/hostile/void_ranger/baryon

/datum/action/cooldown/asat_summon/antibaryon
	name = "Call Antibaryon Ranger"
	desc = "A ranger wearing its own absence. Quicker to wound than to endure."
	button_icon_state = "action_r_antibaryon"
	ranger_type = /mob/living/simple_animal/hostile/void_ranger/antibaryon

/datum/action/cooldown/asat_summon/reaver
	name = "Call Ranger Reaver"
	desc = "Built to close distance and nothing else."
	button_icon_state = "action_r_reaver"
	ranger_type = /mob/living/simple_animal/hostile/void_ranger/reaver

/datum/action/cooldown/asat_summon/distorter
	name = "Call Ranger Distorter"
	desc = "The air bends around it in ways that suggest effort."
	button_icon_state = "action_r_distorter"
	ranger_type = /mob/living/simple_animal/hostile/void_ranger/distorter

/datum/action/cooldown/asat_summon/eliminator
	name = "Call Ranger Eliminator"
	desc = "Sent when the matter is already decided."
	button_icon_state = "action_r_eliminator"
	ranger_type = /mob/living/simple_animal/hostile/void_ranger/eliminator

/datum/action/innate/asat_command
	name = "Command the Rangers"
	desc = "Give an order to every ranger answering to you."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/asat_pramad.dmi'
	button_icon_state = "action_command"

/datum/action/innate/asat_command/Activate()
	var/mob/living/simple_animal/hostile/asat_pramad/asat = owner
	if(!istype(asat))
		return
	var/list/orders = list(
		"Form Up (line up behind me)",
		"To Me (bring them to my side)",
		"Stand To (attack the living)",
		"Stand Down (harm no one)",
		"Hold (stop where they are)",
		"Follow (take up behind me)",
		"Dismiss (send them away)",
	)
	var/order = tgui_input_list(asat, "Order the rangers.", "Command", orders)
	if(!order)
		return
	switch(order)
		if("Form Up (line up behind me)")
			asat.FormUp()
		if("To Me (bring them to my side)")
			asat.RecallRangers()
		if("Stand To (attack the living)")
			asat.SetRangersHostile(TRUE)
		if("Stand Down (harm no one)")
			asat.SetRangersHostile(FALSE)
		if("Hold (stop where they are)")
			asat.SetRangersHolding(TRUE)
		if("Follow (take up behind me)")
			asat.SetRangersHolding(FALSE)
		if("Dismiss (send them away)")
			asat.DismissRangers()

#undef ASAT_HANDS_LAYER
#undef ASAT_VEIL_COLOR
