// Travel Event System
// Handles random encounters during expedition travel

// Most event defines are in _resurgence_defines.dm
// Additional defines used only by travel events:
#define EVENT_CATEGORY_COMBAT "combat"
#define EVENT_CATEGORY_SOCIAL "social"
#define EVENT_SKILL_NONE "none"

// ============================================
// EVENT CHOICE DATUM
// ============================================

/**
 * Event Choice
 *
 * Represents a single choice option for a travel event.
 * Each choice can have different skill requirements and outcomes.
 */
/datum/event_choice
	/// Display name of the choice
	var/name = "Do Something"
	/// Description of what this choice entails
	var/desc = "Attempt to do something."
	/// Skill type required (or EVENT_SKILL_NONE for no check)
	var/skill_type = EVENT_SKILL_NONE
	/// Difficulty of the skill check (1-20)
	var/difficulty = 5
	/// Credits rewarded on success
	var/pass_credits = 0
	/// Items rewarded on success (list of types)
	var/list/pass_items = list()
	/// Message shown on success
	var/pass_message = "Success!"
	/// Damage dealt on failure
	var/fail_damage = 0
	/// Damage type on failure
	var/fail_damage_type = BRUTE
	/// Faith lost on failure (alternative to damage for spiritual/mental effects)
	var/fail_faith_loss = 0
	/// Message shown on failure
	var/fail_message = "You failed."
	/// Whether this choice auto-succeeds (no skill check)
	var/auto_success = FALSE
	/// Whether this choice can only be attempted once per player
	var/one_attempt = TRUE
	/// Button color class
	var/button_class = "choice-button"

/datum/event_choice/New(choice_name, choice_desc, choice_skill, choice_diff)
	. = ..()
	if(choice_name)
		name = choice_name
	if(choice_desc)
		desc = choice_desc
	if(choice_skill)
		skill_type = choice_skill
	if(choice_diff)
		difficulty = choice_diff

// ============================================
// BASE TRAVEL EVENT
// ============================================

/**
 * Travel Event Base
 *
 * Base datum for all travel events encountered during expeditions.
 * Supports multiple choices with different skill checks and outcomes.
 */
/datum/travel_event
	/// Display name of the event
	var/name = "Unknown Event"
	/// Description shown to players
	var/desc = "Something blocks your path."
	/// Event category (scavenge, hazard, combat, social)
	var/category = EVENT_CATEGORY_SCAVENGE
	/// Spawn weight for random selection (higher = more common)
	var/weight = 50
	/// List of valid terrain types for this event
	var/list/valid_terrains = list(TERRAIN_PLAINS, TERRAIN_FOREST, TERRAIN_MOUNTAIN, TERRAIN_DESERT, TERRAIN_RUINS)
	/// List of available choices for this event
	var/list/datum/event_choice/choices = list()
	/// Reference to the barrier that spawned this event
	var/obj/structure/expedition_barrier/parent_barrier
	/// Reference to the expedition party
	var/datum/expedition_party/expedition
	/// Whether the event has been resolved
	var/resolved = FALSE
	/// List of players who have attempted each choice (choice_index -> list of mobs)
	var/list/attempted_choices = list()
	/// Global fail damage (applied if all players fail all choices)
	var/global_fail_damage = 0
	/// Global fail message
	var/global_fail_message = "Everyone failed to overcome the obstacle."

/datum/travel_event/New(obj/structure/expedition_barrier/barrier)
	. = ..()
	parent_barrier = barrier
	if(barrier?.parent_landmark?.manager?.expedition)
		expedition = barrier.parent_landmark.manager.expedition
	// Initialize choices - override in subtypes
	setup_choices()

/datum/travel_event/Destroy()
	parent_barrier = null
	expedition = null
	for(var/datum/event_choice/C in choices)
		qdel(C)
	choices = null
	attempted_choices = null
	return ..()

/**
 * Setup the available choices for this event
 * Override in subtypes to define specific choices
 */
/datum/travel_event/proc/setup_choices()
	// Default: single "Proceed" choice with no check
	var/datum/event_choice/proceed = new()
	proceed.name = "Proceed"
	proceed.desc = "Continue forward carefully."
	proceed.auto_success = TRUE
	proceed.pass_message = "You proceed safely."
	choices += proceed

/**
 * Check if this event is valid for the given terrain
 */
/datum/travel_event/proc/is_valid_for_terrain(terrain_type)
	return terrain_type in valid_terrains

/**
 * Generate HTML content for the event popup
 */
/datum/travel_event/proc/get_html_content(mob/living/user)
	var/html = {"
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>[name]</title>
	<style>
		body {
			font-family: Verdana, sans-serif;
			background-color: #1a1a2e;
			color: #eee;
			padding: 15px;
			margin: 0;
		}
		.event-title {
			font-size: 18px;
			font-weight: bold;
			color: #ffd700;
			margin-bottom: 10px;
			text-align: center;
			border-bottom: 2px solid #ffd700;
			padding-bottom: 5px;
		}
		.event-category {
			font-size: 12px;
			color: #888;
			text-align: center;
			margin-bottom: 15px;
		}
		.event-desc {
			font-size: 14px;
			line-height: 1.5;
			margin-bottom: 20px;
			padding: 10px;
			background-color: #252540;
			border-radius: 5px;
		}
		.choices-header {
			font-size: 14px;
			font-weight: bold;
			color: #4da6ff;
			margin-bottom: 10px;
			text-align: center;
		}
		.choice-container {
			background-color: #252540;
			border-radius: 8px;
			padding: 12px;
			margin-bottom: 10px;
			border-left: 4px solid #4da6ff;
		}
		.choice-container:hover {
			background-color: #303050;
		}
		.choice-container.disabled {
			opacity: 0.5;
			border-left-color: #555;
		}
		.choice-name {
			font-size: 14px;
			font-weight: bold;
			color: #fff;
			margin-bottom: 5px;
		}
		.choice-desc {
			font-size: 12px;
			color: #aaa;
			margin-bottom: 8px;
		}
		.choice-skill {
			font-size: 11px;
			padding: 3px 8px;
			border-radius: 3px;
			display: inline-block;
			margin-right: 5px;
		}
		.skill-mining {
			background-color: #8B4513;
			color: #fff;
		}
		.skill-cooking {
			background-color: #228B22;
			color: #fff;
		}
		.skill-crafting {
			background-color: #4169E1;
			color: #fff;
		}
		.skill-harvesting {
			background-color: #6B8E23;
			color: #fff;
		}
		.skill-analysis {
			background-color: #9932CC;
			color: #fff;
		}
		.skill-social {
			background-color: #DAA520;
			color: #fff;
		}
		.skill-none {
			background-color: #555;
			color: #fff;
		}
		.difficulty {
			font-size: 11px;
			color: #ff6b6b;
		}
		.choice-button {
			display: inline-block;
			padding: 8px 16px;
			font-size: 12px;
			font-weight: bold;
			text-decoration: none;
			border-radius: 4px;
			cursor: pointer;
			float: right;
			margin-top: -25px;
		}
		.btn-attempt {
			background-color: #4CAF50;
			color: white;
		}
		.btn-attempt:hover {
			background-color: #45a049;
		}
		.btn-disabled {
			background-color: #555;
			color: #999;
			cursor: not-allowed;
		}
		.btn-flee {
			background-color: #f44336;
			color: white;
		}
		.btn-flee:hover {
			background-color: #da190b;
		}
		.flee-section {
			margin-top: 20px;
			padding-top: 15px;
			border-top: 1px solid #444;
			text-align: center;
		}
		.flee-warning {
			font-size: 11px;
			color: #ff6b6b;
			margin-bottom: 10px;
		}
		.clearfix::after {
			content: "";
			clear: both;
			display: table;
		}
	</style>
</head>
<body>
	<div class="event-title">[name]</div>
	<div class="event-category">[uppertext(category)] EVENT</div>
	<div class="event-desc">[desc]</div>
	<div class="choices-header">Available Actions</div>
"}

	// Render each choice
	for(var/i in 1 to length(choices))
		var/datum/event_choice/choice = choices[i]
		var/has_attempted = has_player_attempted(user, i)
		var/disabled_class = has_attempted ? " disabled" : ""

		html += {"<div class="choice-container[disabled_class] clearfix">"}
		html += {"<div class="choice-name">[choice.name]</div>"}
		html += {"<div class="choice-desc">[choice.desc]</div>"}

		// Skill requirement display
		if(choice.skill_type != EVENT_SKILL_NONE && !choice.auto_success)
			var/skill_class = "skill-[choice.skill_type]"
			html += {"<span class="choice-skill [skill_class]">[capitalize(choice.skill_type)]</span>"}
			html += {"<span class="difficulty">Difficulty: [choice.difficulty]</span>"}
		else if(choice.auto_success)
			html += {"<span class="choice-skill skill-none">No Check Required</span>"}

		// Action button
		if(has_attempted && choice.one_attempt)
			html += {"<span class="choice-button btn-disabled">Already Tried</span>"}
		else
			html += {"<a class="choice-button btn-attempt" href="?src=[REF(src)];action=choose;choice=[i]">Choose</a>"}

		html += {"</div>"}

	// Flee option
	html += {"
	<div class="flee-section">
		<div class="flee-warning">Fleeing will cause you to take damage!</div>
		<a class="choice-button btn-flee" href="?src=[REF(src)];action=flee">Flee (Take Damage)</a>
	</div>
</body>
</html>
"}

	return html

/**
 * Check if a player has attempted a specific choice
 */
/datum/travel_event/proc/has_player_attempted(mob/living/user, choice_index)
	var/key = "[choice_index]"
	if(!(key in attempted_choices))
		return FALSE
	return user in attempted_choices[key]

/**
 * Mark a player as having attempted a choice
 */
/datum/travel_event/proc/mark_attempted(mob/living/user, choice_index)
	var/key = "[choice_index]"
	if(!(key in attempted_choices))
		attempted_choices[key] = list()
	attempted_choices[key] |= user

/**
 * Show the event popup to a player
 */
/datum/travel_event/proc/show_popup(mob/living/user)
	if(!user?.client)
		return

	var/html = get_html_content(user)
	user << browse(html, "window=travel_event;size=450x550;can_close=1;can_minimize=0;can_maximize=0;can_resize=0;titlebar=1")

/**
 * Close the event popup for a player
 */
/datum/travel_event/proc/close_popup(mob/living/user)
	if(!user?.client)
		return
	user << browse(null, "window=travel_event")

/**
 * Handle Topic calls from the HTML popup
 */
/datum/travel_event/Topic(href, href_list)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr
	if(!isliving(user))
		return

	if(resolved)
		close_popup(user)
		return

	switch(href_list["action"])
		if("choose")
			var/choice_index = text2num(href_list["choice"])
			if(choice_index && choice_index >= 1 && choice_index <= length(choices))
				attempt_choice(user, choice_index)
		if("flee")
			flee_event(user)

/**
 * Player attempts a specific choice
 */
/datum/travel_event/proc/attempt_choice(mob/living/user, choice_index)
	var/datum/event_choice/choice = choices[choice_index]
	if(!choice)
		return

	// Check if already attempted (for one-attempt choices)
	if(choice.one_attempt && has_player_attempted(user, choice_index))
		to_chat(user, span_warning("You have already attempted this option!"))
		return

	mark_attempted(user, choice_index)

	// Auto-success choices
	if(choice.auto_success)
		on_choice_pass(user, choice)
		return

	// Perform skill check
	if(choice.skill_type != EVENT_SKILL_NONE)
		var/success = perform_skill_check(user, choice)
		if(success)
			on_choice_pass(user, choice)
		else
			on_choice_fail(user, choice)
			check_all_failed()
	else
		// No skill type and not auto-success, treat as auto-success
		on_choice_pass(user, choice)

	// Update popup for this user
	show_popup(user)

/**
 * Perform a skill check for a choice
 * Returns TRUE on success, FALSE on failure
 */
/datum/travel_event/proc/perform_skill_check(mob/living/user, datum/event_choice/choice)
	// Base success chance: 50% + (skill - difficulty) * 5%
	// Clamped to 5-95%
	var/skill_level = get_player_skill(user, choice.skill_type)
	var/success_chance = 50 + (skill_level - choice.difficulty) * 5
	success_chance = clamp(success_chance, 5, 95)

	var/roll = rand(1, 100)
	var/success = roll <= success_chance

	// Notify the player
	to_chat(user, span_notice("Skill check: [capitalize(choice.skill_type)] (Level [skill_level]) vs Difficulty [choice.difficulty]"))
	to_chat(user, span_notice("Success chance: [success_chance]% - Rolled: [roll] - [success ? "SUCCESS!" : "FAILED"]"))

	return success

/**
 * Get a player's skill level for a given skill type
 * Retrieves stats from the resurgence_core organ
 */
/datum/travel_event/proc/get_player_skill(mob/living/user, skill_type)
	if(!ishuman(user))
		return 5  // Default for non-humans

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)

	if(!core || !istype(core))
		return 5  // Default if no core

	switch(skill_type)
		if(EVENT_SKILL_MINING)
			return core.stat_mining
		if(EVENT_SKILL_COOKING)
			return core.stat_cooking
		if(EVENT_SKILL_CRAFTING)
			return core.stat_crafting
		if(EVENT_SKILL_HARVESTING)
			return core.stat_harvesting
		if(EVENT_SKILL_ANALYSIS)
			return core.stat_analysis
		if(EVENT_SKILL_SOCIAL)
			return core.stat_social
		else
			return 5  // Default for unknown skill types

/**
 * Called when a player succeeds at a choice
 */
/datum/travel_event/proc/on_choice_pass(mob/living/user, datum/event_choice/choice)
	to_chat(user, span_boldnotice("[choice.pass_message]"))

	// Give credits reward
	if(choice.pass_credits > 0)
		if(GLOB.resurgence_trading)
			GLOB.resurgence_trading.add_credits(choice.pass_credits)
		to_chat(user, span_notice("You gained [choice.pass_credits] credits for the outpost!"))
		// Notify other party members
		for(var/mob/living/M in expedition?.members)
			if(M != user)
				to_chat(M, span_notice("[user.name] earned [choice.pass_credits] credits for the outpost!"))

	// Give item rewards
	// pass_items can be:
	// - Simple list of types: list(/obj/item/foo, /obj/item/bar)
	// - Associative list with amounts for stacks: list(/obj/item/stack/sheet/metal = 5)
	for(var/item_type in choice.pass_items)
		var/amount = choice.pass_items[item_type]
		if(ispath(item_type, /obj/item/stack) && isnum(amount) && amount > 1)
			// Create stack with specific amount
			var/obj/item/stack/S = new item_type(get_turf(user), amount)
			to_chat(user, span_notice("You obtained: [amount]x [S.name]"))
		else
			// Create single item (or stack with default amount)
			var/obj/item/I = new item_type(get_turf(user))
			to_chat(user, span_notice("You obtained: [I.name]"))

	// Resolve the event for everyone
	resolve_event()

/**
 * Called when a player fails at a choice
 */
/datum/travel_event/proc/on_choice_fail(mob/living/user, datum/event_choice/choice)
	to_chat(user, span_warning("[choice.fail_message]"))

	// Apply damage
	if(choice.fail_damage > 0)
		user.apply_damage_type(choice.fail_damage, choice.fail_damage_type)
		to_chat(user, span_danger("You take [choice.fail_damage] damage!"))

	// Apply faith loss (for spiritual/mental effects)
	if(choice.fail_faith_loss > 0 && ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			core.adjust_faith(-choice.fail_faith_loss)
			to_chat(user, span_warning("You lose [choice.fail_faith_loss] faith!"))

/**
 * Player chooses to flee
 */
/datum/travel_event/proc/flee_event(mob/living/user)
	to_chat(user, span_warning("You flee in panic!"))

	// Take flee damage (average of all choice fail damages, minimum 10)
	var/flee_damage = 10
	var/total_damage = 0
	var/damage_count = 0
	for(var/datum/event_choice/C in choices)
		if(C.fail_damage > 0)
			total_damage += C.fail_damage
			damage_count++
	if(damage_count > 0)
		flee_damage = max(10, round(total_damage / damage_count / 2))

	user.apply_damage_type(flee_damage, BRUTE)
	to_chat(user, span_danger("You take [flee_damage] damage while fleeing!"))

	// Mark all choices as attempted for this user
	for(var/i in 1 to length(choices))
		mark_attempted(user, i)

	// Check if everyone has fled/failed
	check_all_failed()

	// Update popup
	show_popup(user)

/**
 * Check if all party members have failed/fled all options
 */
/datum/travel_event/proc/check_all_failed()
	if(!expedition)
		return

	// Check if any living member hasn't attempted all choices
	for(var/mob/living/M in expedition.members)
		if(M.stat == DEAD)
			continue

		// Check if this player has any unattempted choices
		for(var/i in 1 to length(choices))
			var/datum/event_choice/choice = choices[i]
			if(choice.one_attempt && !has_player_attempted(M, i))
				return  // Still has options

	// Everyone has tried everything - apply global fail and resolve
	on_all_failed()

/**
 * Called when all players have failed all choices
 */
/datum/travel_event/proc/on_all_failed()
	// Notify all party members
	for(var/mob/living/M in expedition?.members)
		to_chat(M, span_boldwarning("[global_fail_message]"))

		// Apply global fail damage if any
		if(global_fail_damage > 0)
			M.apply_damage_type(global_fail_damage, BRUTE)
			to_chat(M, span_danger("You take [global_fail_damage] damage!"))

	// Still resolve the event (let them pass)
	resolve_event()

/**
 * Resolve the event and allow passage
 */
/datum/travel_event/proc/resolve_event()
	if(resolved)
		return
	resolved = TRUE

	// Close popups for all players
	for(var/mob/living/M in expedition?.members)
		close_popup(M)

	// Tell the barrier to resolve
	if(parent_barrier)
		parent_barrier.resolve()

	// Notify players
	for(var/mob/living/M in expedition?.members)
		to_chat(M, span_notice("The path ahead is now clear. Continue onward."))

// ============================================
// GLOBAL EVENT REGISTRY
// ============================================

GLOBAL_LIST_EMPTY(travel_events)

/**
 * Initialize the travel event registry
 */
/proc/init_travel_events()
	if(length(GLOB.travel_events))
		return

	// Register all event subtypes
	for(var/event_type in subtypesof(/datum/travel_event))
		var/datum/travel_event/E = new event_type()
		if(E.name != "Unknown Event")  // Skip base type
			GLOB.travel_events += E
		else
			qdel(E)

/**
 * Pick a random event valid for the given terrain
 */
/proc/pick_travel_event(terrain_type)
	init_travel_events()

	var/list/valid_events = list()
	for(var/datum/travel_event/E in GLOB.travel_events)
		if(E.is_valid_for_terrain(terrain_type))
			valid_events[E.type] = E.weight

	if(!length(valid_events))
		return null

	var/chosen_type = pickweight(valid_events)
	return chosen_type
