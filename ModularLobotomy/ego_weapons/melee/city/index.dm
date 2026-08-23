//Base index is Grade 5,
//Proxy is Grade 3,
//Messenger is Grade 2.
/obj/item/ego_weapon/city/index
	name = "index recruit sword"
	desc = "A sheathed sword used by index recruits."
	icon_state = "index"
	inhand_icon_state = "index"
	force = 37
	damtype = PALE_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("smacks", "hammers", "beats")
	attack_verb_simple = list("smack", "hammer", "beat")
	var/prescript_target
	var/weapon_owner
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/item/ego_weapon/city/index/attack_self(mob/user)
	..()
	if(force != initial(force))
		to_chat(user, span_notice("The prescript buff is still active."))
		return

	//Okay, check if you have a prescript
	if(prescript_target && user == weapon_owner)
		var/mob/living/simple_animal/hostile/abnormality/Y = prescript_target
		if(Y.stat == DEAD)
			prescript_target = null
			to_chat(user, span_notice("Your prescript has died. Use it in hand to recieve a prescript."))
		else
			to_chat(user, span_notice("Your prescript target is [prescript_target]."))

	//If you don't have one, pick a breached mob if available.
	else if(!prescript_target && user == weapon_owner)
		var/list/breached = list()
		for(var/mob/living/simple_animal/hostile/abnormality/B in GLOB.abnormality_mob_list)
			if(!(B.status_flags & GODMODE) && (B.stat != DEAD))
				breached+=B
		if(LAZYLEN(breached))
			prescript_target = pick(breached)
			to_chat(user, span_userdanger("Your prescript target is [prescript_target]. Slay them, and deal the killing blow with this weapon."))
		else
			to_chat(user, span_notice("There are no prescripts available."))

	//If this weapon has no owner, than make you it.
	else if(!weapon_owner)
		to_chat(user, span_notice("This weapon is now yours. Use it in hand to recieve a prescript."))
		weapon_owner = user

	else
		to_chat(user, span_warning("This is not your weapon!"))


/obj/item/ego_weapon/city/index/attack(mob/living/target, mob/living/user)
	var/living = FALSE
	if(target.stat != DEAD)
		living = TRUE
	if(!..())
		return

	if(target.stat == DEAD && target == prescript_target && living)
		prescript_complete(user)

//Make this do something
/obj/item/ego_weapon/city/index/proc/prescript_complete(mob/living/user)
	prescript_target = null
	to_chat(user, span_userdanger("You have completed your prescript, and you have been graced."))
	force *= 1.45	//BEEG BONUS
	addtimer(CALLBACK(src, PROC_REF(Return), user), 5 MINUTES)

/obj/item/ego_weapon/city/index/proc/Return(mob/living/carbon/human/user)
	force /= 1.45	//BEEG BONUS
	to_chat(user, span_notice("The power from your prescript is now gone."))


//Just gonna set this to the big proxy weapon for requirement reasons
/obj/item/ego_weapon/city/index/proxy
	name = "index longsword"
	desc = "A long sword used by index proxies."
	icon_state = "indexlongsword"
	inhand_icon_state = "indexlongsword"
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 56
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

//Just gonna set this to the big proxy weapon for requirement reasons
/obj/item/ego_weapon/city/index/proxy/spear
	name = "index spear"
	desc = "A spear used by index proxies."
	icon_state = "indexspear"
	inhand_icon_state = "indexspear"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/fixer/generic/nail1.ogg'
	reach = 2
	force = 64
	stuntime = 5
	swingstyle = WEAPONSWING_THRUST

//Fockin massive sword
/obj/item/ego_weapon/city/index/yan
	name = "index greatsword"
	desc = "A greatsword sword used by a specific index messenger."
	icon_state = "indexgreatsword"
	inhand_icon_state = "indexgreatsword"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	attack_verb_continuous = list("cleaves", "cuts")
	attack_verb_simple = list("cleaves", "cuts")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'
	force = 130
	attack_speed = 2
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 120
							)

/obj/item/clothing/accessory/index_pager
	name = "index pager"
	desc = "A small pager which the index use to get their prescripts remotely."
	icon = 'icons/obj/spider_house/index/index_pager.dmi'
	icon_state = "index_beeper"
	worn_icon_state = "index_beeper"
	lefthand_file = 'icons/obj/spider_house/index/index_pager_worn_left.dmi'
	righthand_file = 'icons/obj/spider_house/index/index_pager_worn_right.dmi'
	above_suit = FALSE
	minimize_when_attached = TRUE
	attachment_slot = CHEST

	/// The current prescript text
	var/prescript_text
	/// The name of the recipient for this prescript
	var/prescript_recipient
	/// Whether the prescript has been loaded (typewriter finished)
	var/prescript_loaded = FALSE
	/// Whether the prescript is currently being displayed (typewriter in progress)
	var/prescript_displaying = FALSE
	/// Whether the 5-minute pool timer is running
	var/pool_timer_active = FALSE
	/// List of submitted prescripts in pool (ckey -> text)
	var/list/submitted_prescripts = list()
	/// List of ckeys that have prescripts in pool
	var/list/submitted_ckeys = list()
	/// List of submission timestamps (ckey -> world.time when submitted)
	var/list/submission_times = list()
	/// Draft text for each ghost's UI (ckey -> text)
	var/list/ghost_drafts = list()
	/// The looping sound datum for prescript loading
	var/datum/looping_sound/index_pager_prescript/soundloop
	/// Timer ID for the pool timer (so it can be cancelled)
	var/pool_timer_id
	/// Whether automatic prescript selection is paused (admin control)
	var/auto_select_paused = FALSE
	/// List of past prescripts (list of lists with "id", "text", "completed", "creator_ckey", "judged", "time_received")
	var/list/prescript_history = list()
	/// Counter for prescript IDs
	var/next_prescript_id = 1
	/// Timer IDs for auto turn-in (prescript_id -> timer_id)
	var/list/auto_turnin_timers = list()
	/// Timer IDs for judgment window expiry (prescript_id -> timer_id)
	var/list/judgment_timers = list()
	/// The ckey of the ghost who created the current prescript
	var/current_prescript_creator

/obj/item/clothing/accessory/index_pager/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/point_of_interest)
	soundloop = new(list(src), FALSE)

/obj/item/clothing/accessory/index_pager/Topic(href, href_list)
	. = ..()
	if(href_list["interact"])
		if(isobserver(usr))
			ui_interact(usr)

/obj/item/clothing/accessory/index_pager/Destroy()
	if(soundloop)
		QDEL_NULL(soundloop)
	return ..()

/obj/item/clothing/accessory/index_pager/attack_ghost(mob/user)
	if(!isobserver(user))
		return
	ui_interact(user)
	return ..()

/obj/item/clothing/accessory/index_pager/equipped(mob/user, slot)
	. = ..()
	// Runtime fix: equipped() and on_uniform_equip() both register this signal, causing "atom_examine overridden" when re-equipping
	RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_carrier_examined), override = TRUE)

/obj/item/clothing/accessory/index_pager/dropped(mob/user)
	UnregisterSignal(user, COMSIG_PARENT_EXAMINE)
	return ..()

/obj/item/clothing/accessory/index_pager/on_uniform_equip(obj/item/clothing/under/U, mob/living/user)
	. = ..()
	// Runtime fix: equipped() and on_uniform_equip() both register this signal, causing "atom_examine overridden" when re-equipping
	RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_carrier_examined), override = TRUE)
	playsound(src, 'sound/items/index_beeper_closing.ogg', 50, FALSE)

/obj/item/clothing/accessory/index_pager/on_uniform_dropped(obj/item/clothing/under/U, mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_PARENT_EXAMINE)
	playsound(src, 'sound/items/index_beeper_opening.ogg', 50, FALSE)

/// Called when the person carrying the pager is examined
/obj/item/clothing/accessory/index_pager/proc/on_carrier_examined(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER
	if(isobserver(examiner))
		INVOKE_ASYNC(src, TYPE_PROC_REF(/datum, ui_interact), examiner)

/obj/item/clothing/accessory/index_pager/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return

	// If there's a pending prescript that hasn't been displayed yet
	if(prescript_text && !prescript_loaded && !prescript_displaying)
		StartPrescriptDisplay()
	ui_interact(user)

/obj/item/clothing/accessory/index_pager/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/index_pager),
	)

/obj/item/clothing/accessory/index_pager/ui_state(mob/user)
	// Use always_state since we need both ghosts and living users to interact
	// Permission checks are handled in ui_act
	return GLOB.always_state

/obj/item/clothing/accessory/index_pager/ui_status(mob/user)
	// Ghosts can always interact regardless of range
	if(isobserver(user))
		return UI_INTERACTIVE
	return ..()

/obj/item/clothing/accessory/index_pager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IndexPager", name)
		ui.open()

/obj/item/clothing/accessory/index_pager/ui_close(mob/user)
	. = ..()
	// Stop the sound if the user closes the UI while typewriter is running
	if(prescript_displaying && !isobserver(user))
		FinishPrescriptDisplay()

/obj/item/clothing/accessory/index_pager/ui_data(mob/user)
	var/list/data = list()

	data["is_ghost"] = isobserver(user)
	data["on_cooldown"] = pool_timer_active
	data["submission_window_open"] = TRUE  // Always open for submissions
	data["has_submitted"] = (user.ckey in submitted_ckeys)
	data["current_submission"] = submitted_prescripts[user.ckey]  // For editing
	data["prescript_text"] = prescript_text
	data["prescript_recipient"] = prescript_recipient
	data["prescript_loaded"] = prescript_loaded
	data["prescript_displaying"] = prescript_displaying
	data["draft_text"] = ghost_drafts[user.ckey]
	data["is_admin"] = (user.client && check_rights_for(user.client, R_ADMIN))
	data["auto_select_paused"] = auto_select_paused
	data["pool_count"] = length(submitted_prescripts)

	// For living users: split into active (incomplete) and completed prescripts
	if(!isobserver(user))
		var/list/active_list = list()
		var/list/completed_list = list()
		for(var/list/entry in prescript_history)
			if(entry["completed"])
				completed_list += list(entry)
			else
				// Calculate time remaining for auto turn-in
				var/time_received = entry["time_received"]
				var/time_remaining_text = null
				if(time_received)
					var/elapsed = world.time - time_received
					var/remaining = (10 MINUTES) - elapsed
					if(remaining > 0)
						var/mins = round(remaining / (1 MINUTES))
						var/secs = round((remaining % (1 MINUTES)) / 10)
						time_remaining_text = "[mins]m [secs]s"
				var/list/entry_copy = entry.Copy()
				entry_copy["time_remaining"] = time_remaining_text
				active_list += list(entry_copy)
		data["active_prescripts"] = active_list
		data["completed_prescripts"] = completed_list
	else
		data["prescript_history"] = prescript_history

	// For ghosts: show pending judgments (prescripts they created that were completed but not judged)
	if(isobserver(user))
		var/list/pending_judgments = list()
		for(var/list/entry in prescript_history)
			if(entry["creator_ckey"] == user.ckey && entry["completed"] && !entry["judged"])
				var/list/entry_copy = entry.Copy()
				// Calculate judgment time remaining
				var/timer_key = "[entry["id"]]"
				if(judgment_timers[timer_key])
					var/remaining = timeleft(judgment_timers[timer_key])
					if(remaining > 0)
						var/mins = round(remaining / (1 MINUTES))
						var/secs = round((remaining % (1 MINUTES)) / 10)
						entry_copy["judgment_time_remaining"] = "[mins]m [secs]s"
				pending_judgments += list(entry_copy)
		data["pending_judgments"] = pending_judgments

	return data

/obj/item/clothing/accessory/index_pager/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	switch(action)
		if("submit_prescript")
			if(!isobserver(user))
				return

			var/text = params["text"]
			if(!text || length(text) < 5 || length(text) > 300)
				to_chat(user, span_warning("Prescript must be between 5 and 300 characters."))
				return

			// Sanitize the text
			text = strip_html(text)

			// Check if updating existing or adding new
			var/is_update = (user.ckey in submitted_ckeys)

			submitted_prescripts[user.ckey] = text
			if(!is_update)
				submitted_ckeys += user.ckey
				submission_times[user.ckey] = world.time  // Track when first submitted
			ghost_drafts[user.ckey] = null

			// Start the 5-minute pool timer on first submission
			if(!pool_timer_active)
				StartPoolTimer()

			if(is_update)
				to_chat(user, span_notice("Your prescript has been updated."))
			else
				to_chat(user, span_notice("Your prescript has been submitted to the pool."))
			return TRUE

		if("update_draft")
			if(!isobserver(user))
				return
			ghost_drafts[user.ckey] = params["text"]
			return TRUE

		if("typing_complete")
			if(!isobserver(user))
				FinishPrescriptDisplay()
			return TRUE

		if("priority_submit")
			// Only admins who are ghosts can use this
			if(!isobserver(user))
				return
			if(!user.client || !check_rights_for(user.client, R_ADMIN))
				to_chat(user, span_warning("You do not have permission to use priority submit."))
				return

			var/text = params["text"]
			if(!text || length(text) < 5 || length(text) > 300)
				to_chat(user, span_warning("Prescript must be between 5 and 300 characters."))
				return

			// Sanitize the text
			text = strip_html(text)

			// Cancel existing timer if running
			if(pool_timer_id)
				deltimer(pool_timer_id)
				pool_timer_id = null

			// Archive current prescript to history before replacing
			if(prescript_text)
				var/new_id = next_prescript_id
				prescript_history += list(list("id" = new_id, "text" = prescript_text, "recipient" = prescript_recipient, "creator_ckey" = user.ckey, "completed" = FALSE, "judged" = FALSE, "time_received" = world.time))
				// Start 10-minute auto turn-in timer
				auto_turnin_timers["[new_id]"] = addtimer(CALLBACK(src, PROC_REF(auto_turn_in), new_id), 10 MINUTES, TIMER_STOPPABLE)
				next_prescript_id++

			// Set the new prescript immediately
			prescript_text = text
			current_prescript_creator = user.ckey
			prescript_loaded = FALSE
			prescript_displaying = FALSE

			// Determine recipient name
			var/mob/living/holder = get_wearer()
			if(holder)
				prescript_recipient = holder.real_name
			else
				prescript_recipient = "Unknown"

			// Log to admins
			message_admins("[user.ckey] (ADMIN) sent a PRIORITY prescript to [prescript_recipient]: \"[prescript_text]\"")
			log_game("INDEX PAGER: [user.ckey] (ADMIN) sent PRIORITY prescript to [prescript_recipient]: \"[prescript_text]\"")

			// Deliver the prescript
			DeliverPrescript()

			// Restart the 5-minute timer
			pool_timer_active = TRUE
			pool_timer_id = addtimer(CALLBACK(src, PROC_REF(PickFromPool)), 5 MINUTES, TIMER_STOPPABLE)

			to_chat(user, span_notice("Priority prescript sent successfully."))
			return TRUE

		if("toggle_auto_select")
			if(!isobserver(user))
				return
			if(!user.client || !check_rights_for(user.client, R_ADMIN))
				to_chat(user, span_warning("You do not have permission to do this."))
				return

			auto_select_paused = !auto_select_paused
			if(auto_select_paused)
				message_admins("[user.ckey] (ADMIN) PAUSED automatic prescript selection on index pager.")
				to_chat(user, span_notice("Automatic prescript selection has been paused."))
			else
				message_admins("[user.ckey] (ADMIN) RESUMED automatic prescript selection on index pager.")
				to_chat(user, span_notice("Automatic prescript selection has been resumed."))
			return TRUE

		if("skip_timer")
			if(!isobserver(user))
				return
			if(!user.client || !check_rights_for(user.client, R_ADMIN))
				to_chat(user, span_warning("You do not have permission to do this."))
				return

			if(!length(submitted_prescripts))
				to_chat(user, span_warning("There are no prescripts in the pool to pick from."))
				return

			// Cancel existing timer
			if(pool_timer_id)
				deltimer(pool_timer_id)
				pool_timer_id = null

			message_admins("[user.ckey] (ADMIN) skipped the timer and forced a prescript pick on index pager.")
			to_chat(user, span_notice("Timer skipped. Picking a random prescript now."))

			// Force pick from pool (bypasses pause)
			PickFromPool(TRUE)
			return TRUE

		if("submit_current")
			// Living users can submit their current prescript to complete it and get a new one
			if(isobserver(user))
				return
			if(!prescript_text || !prescript_loaded)
				to_chat(user, span_warning("There is no loaded prescript to submit."))
				return

			// Archive current prescript as completed
			var/new_id = next_prescript_id
			prescript_history += list(list("id" = new_id, "text" = prescript_text, "recipient" = prescript_recipient, "creator_ckey" = current_prescript_creator, "completed" = TRUE, "judged" = FALSE, "time_received" = world.time))
			next_prescript_id++
			// Start 2.5-minute judgment window
			judgment_timers["[new_id]"] = addtimer(CALLBACK(src, PROC_REF(expire_judgment), new_id), 2.5 MINUTES, TIMER_STOPPABLE)

			// Broadcast completion to deadchat
			deadchat_broadcast("[span_name("[user.real_name]")] has completed a prescript: \"[prescript_text]\"", message_type = DEADCHAT_ANNOUNCEMENT)
			to_chat(user, span_notice("Prescript submitted successfully."))
			playsound(src, 'sound/items/index_beeper_prescript.ogg', 50, FALSE)

			// Clear current prescript
			prescript_text = null
			prescript_recipient = null
			prescript_loaded = FALSE
			prescript_displaying = FALSE
			current_prescript_creator = null
			icon_state = "index_beeper"

			// Try to pick a new prescript from the pool immediately
			if(length(submitted_prescripts))
				if(pool_timer_id)
					deltimer(pool_timer_id)
					pool_timer_id = null
				PickFromPool()

			return TRUE

		if("turn_in")
			// Only living users can turn in prescripts
			if(isobserver(user))
				return

			var/prescript_id = text2num(params["id"])
			if(!prescript_id)
				return

			// Find the prescript in history
			for(var/list/entry in prescript_history)
				if(entry["id"] == prescript_id && !entry["completed"])
					entry["completed"] = TRUE
					// Cancel the auto turn-in timer
					var/timer_key = "[prescript_id]"
					if(auto_turnin_timers[timer_key])
						deltimer(auto_turnin_timers[timer_key])
						auto_turnin_timers -= timer_key
					// Start 2.5-minute judgment window
					judgment_timers[timer_key] = addtimer(CALLBACK(src, PROC_REF(expire_judgment), prescript_id), 2.5 MINUTES, TIMER_STOPPABLE)
					// Broadcast to ghosts
					deadchat_broadcast("[span_name("[user.real_name]")] has completed a prescript: \"[entry["text"]]\"", message_type = DEADCHAT_ANNOUNCEMENT)
					to_chat(user, span_notice("Prescript turned in successfully."))
					playsound(src, 'sound/items/index_beeper_prescript.ogg', 50, FALSE)
					return TRUE

			to_chat(user, span_warning("Could not find that prescript or it was already completed."))
			return

		if("reward_prescript")
			// Only ghosts can reward
			if(!isobserver(user))
				return

			var/prescript_id = text2num(params["id"])
			var/reward_type = params["type"]
			if(!prescript_id || !reward_type)
				return

			// Find the prescript and verify ownership
			for(var/list/entry in prescript_history)
				if(entry["id"] == prescript_id && entry["creator_ckey"] == user.ckey && entry["completed"] && !entry["judged"])
					if(apply_reward(reward_type))
						entry["judged"] = TRUE
						// Cancel judgment expiry timer
						var/timer_key = "[prescript_id]"
						if(judgment_timers[timer_key])
							deltimer(judgment_timers[timer_key])
							judgment_timers -= timer_key
						to_chat(user, span_notice("You have rewarded the proxy for completing your prescript."))
						deadchat_broadcast("[user.ckey] has rewarded [entry["recipient"]] for completing their prescript.", message_type = DEADCHAT_ANNOUNCEMENT)
					return TRUE

			to_chat(user, span_warning("Could not find that prescript or you cannot judge it."))
			return

		if("punish_prescript")
			// Only ghosts can punish
			if(!isobserver(user))
				return

			var/prescript_id = text2num(params["id"])
			var/punish_type = params["type"]
			if(!prescript_id || !punish_type)
				return

			// Find the prescript and verify ownership
			for(var/list/entry in prescript_history)
				if(entry["id"] == prescript_id && entry["creator_ckey"] == user.ckey && entry["completed"] && !entry["judged"])
					if(apply_punishment(punish_type))
						entry["judged"] = TRUE
						// Cancel judgment expiry timer
						var/timer_key = "[prescript_id]"
						if(judgment_timers[timer_key])
							deltimer(judgment_timers[timer_key])
							judgment_timers -= timer_key
						to_chat(user, span_notice("You have punished the proxy for their execution of your prescript."))
						deadchat_broadcast("[user.ckey] has punished [entry["recipient"]] for their execution of their prescript.", message_type = DEADCHAT_ANNOUNCEMENT)
					return TRUE

			to_chat(user, span_warning("Could not find that prescript or you cannot judge it."))
			return

/// Starts the pool timer - first prescript is sent immediately, then checks every 5 minutes
/obj/item/clothing/accessory/index_pager/proc/StartPoolTimer()
	pool_timer_active = TRUE
	PickFromPool()

/// Picks a random prescript from the pool and delivers it
/obj/item/clothing/accessory/index_pager/proc/PickFromPool(force_pick = FALSE)
	if(!length(submitted_prescripts))
		// Pool is empty - keep current prescript, stop timer
		pool_timer_active = FALSE
		return

	// If paused and not forced, just reschedule without picking
	if(auto_select_paused && !force_pick)
		pool_timer_id = addtimer(CALLBACK(src, PROC_REF(PickFromPool)), 5 MINUTES, TIMER_STOPPABLE)
		return

	// Archive current prescript to history before replacing
	if(prescript_text)
		var/new_id = next_prescript_id
		prescript_history += list(list("id" = new_id, "text" = prescript_text, "recipient" = prescript_recipient, "creator_ckey" = current_prescript_creator, "completed" = FALSE, "judged" = FALSE, "time_received" = world.time))
		// Start 10-minute auto turn-in timer
		auto_turnin_timers["[new_id]"] = addtimer(CALLBACK(src, PROC_REF(auto_turn_in), new_id), 10 MINUTES, TIMER_STOPPABLE)
		next_prescript_id++

	// Pick a submission weighted by time in pool (longer = more likely)
	var/list/weighted_ckeys = list()
	for(var/ckey in submitted_ckeys)
		var/time_in_pool = world.time - submission_times[ckey]
		// Weight is based on minutes in pool, minimum weight of 1
		var/weight = max(1, round(time_in_pool / (1 MINUTES)) + 1)
		weighted_ckeys[ckey] = weight

	var/selected_ckey = pickweight(weighted_ckeys)
	prescript_text = submitted_prescripts[selected_ckey]
	current_prescript_creator = selected_ckey
	submitted_prescripts -= selected_ckey
	submitted_ckeys -= selected_ckey
	submission_times -= selected_ckey

	// Reset display state for new prescript
	prescript_loaded = FALSE
	prescript_displaying = FALSE

	// Determine recipient name
	var/mob/living/holder = loc
	if(istype(holder))
		prescript_recipient = holder.real_name
	else
		prescript_recipient = "Unknown"

	// Log to admins
	message_admins("[selected_ckey] submitted a prescript to [prescript_recipient]: \"[prescript_text]\"")
	log_game("INDEX PAGER: [selected_ckey] submitted prescript to [prescript_recipient]: \"[prescript_text]\"")

	// Deliver the prescript
	DeliverPrescript()

	// Schedule next pick in 5 minutes
	pool_timer_id = addtimer(CALLBACK(src, PROC_REF(PickFromPool)), 5 MINUTES, TIMER_STOPPABLE)

/// Returns the mob wearing this pager, checking both direct hold and uniform attachment
/obj/item/clothing/accessory/index_pager/proc/get_wearer()
	// Check if directly held by a mob
	if(isliving(loc))
		return loc
	// Check if attached to a uniform that's being worn
	if(istype(loc, /obj/item/clothing/under))
		var/obj/item/clothing/under/U = loc
		if(isliving(U.loc))
			return U.loc
	return null

/// Called when a prescript is ready to be delivered to the holder
/obj/item/clothing/accessory/index_pager/proc/DeliverPrescript()
	playsound(src, 'sound/items/index_beeper_alert.ogg', 50, FALSE)
	icon_state = "index_beeper_alert"

	// Broadcast to deadchat/observers
	deadchat_broadcast("Prescript sent to [span_name("[prescript_recipient]")]: \"[prescript_text]\"", message_type = DEADCHAT_ANNOUNCEMENT)

	var/mob/living/holder = get_wearer()
	if(holder)
		to_chat(holder, span_userdanger("Your index pager beeps! A new prescript has arrived. Use it in hand to view."))

/// Begins the typewriter animation display
/obj/item/clothing/accessory/index_pager/proc/StartPrescriptDisplay()
	prescript_displaying = TRUE
	icon_state = "index_beeper_prescript_loading"
	soundloop.start()

/// Called when typewriter animation completes
/obj/item/clothing/accessory/index_pager/proc/FinishPrescriptDisplay()
	prescript_displaying = FALSE
	prescript_loaded = TRUE
	icon_state = "index_beeper_prescript"
	soundloop.stop()

/// Called after 10 minutes to auto turn-in a prescript
/obj/item/clothing/accessory/index_pager/proc/auto_turn_in(prescript_id)
	// Remove from timer tracking
	auto_turnin_timers -= "[prescript_id]"

	// Find the prescript in history
	for(var/list/entry in prescript_history)
		if(entry["id"] == prescript_id && !entry["completed"])
			entry["completed"] = TRUE
			// Start 2.5-minute judgment window
			judgment_timers["[prescript_id]"] = addtimer(CALLBACK(src, PROC_REF(expire_judgment), prescript_id), 2.5 MINUTES, TIMER_STOPPABLE)
			// Broadcast to ghosts
			var/recipient_name = entry["recipient"] || "Unknown"
			deadchat_broadcast("[span_name("[recipient_name]")]'s prescript was auto-completed: \"[entry["text"]]\"", message_type = DEADCHAT_ANNOUNCEMENT)
			// Notify the holder
			var/mob/living/holder = get_wearer()
			if(holder)
				to_chat(holder, span_notice("A prescript has been automatically turned in after 10 minutes."))
				playsound(src, 'sound/items/index_beeper_prescript.ogg', 50, FALSE)
			return

/// Called after 2.5 minutes to expire the judgment window on a completed prescript
/obj/item/clothing/accessory/index_pager/proc/expire_judgment(prescript_id)
	judgment_timers -= "[prescript_id]"
	for(var/list/entry in prescript_history)
		if(entry["id"] == prescript_id && entry["completed"] && !entry["judged"])
			entry["judged"] = TRUE
			return

/// Applies a reward to the pager holder
/obj/item/clothing/accessory/index_pager/proc/apply_reward(reward_type)
	var/mob/living/carbon/human/holder = get_wearer()
	if(!istype(holder))
		return FALSE

	switch(reward_type)
		if("heal")
			var/heal_amount = holder.maxHealth * 0.1
			holder.adjustBruteLoss(-heal_amount)
			holder.adjustFireLoss(-heal_amount)
			var/sp_heal = holder.maxSanity * 0.05
			holder.adjustSanityLoss(-sp_heal)
			to_chat(holder, span_notice("The Oracle has blessed you with healing for completing your prescript."))
			playsound(src, 'sound/abnormalities/onesin/bless.ogg', 50, FALSE)
			new /obj/effect/temp_visual/onesin_blessing(get_turf(holder))
		if("buff")
			holder.apply_status_effect(/datum/status_effect/index_judgment/blessing)
			to_chat(holder, span_userdanger("The Oracle has blessed you with power for completing your prescript!"))
			playsound(src, 'sound/items/index_beeper_prescript.ogg', 50, FALSE)

	return TRUE

/// Applies a punishment to the pager holder
/obj/item/clothing/accessory/index_pager/proc/apply_punishment(punish_type)
	var/mob/living/carbon/human/holder = get_wearer()
	if(!istype(holder))
		return FALSE

	switch(punish_type)
		if("damage")
			var/sp_damage = holder.maxSanity * 0.05
			holder.adjustSanityLoss(sp_damage)
			to_chat(holder, span_userdanger("The Oracle is displeased with your execution of the prescript!"))
			playsound(src, 'sound/effects/sanity_damage.ogg', 50, FALSE)
		if("debuff")
			holder.apply_status_effect(/datum/status_effect/index_judgment/curse)
			to_chat(holder, span_userdanger("The Oracle has weakened you for your poor execution of the prescript!"))
			playsound(src, 'sound/effects/sanity_damage.ogg', 50, FALSE)

	return TRUE

/// Oracle judgment: a timed Justice shift handed out by a prescript's outcome.
/datum/status_effect/index_judgment
	id = "index_judgment"
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null
	tick_interval = -1
	/// How much the owner's Justice is shifted while this is active
	var/justice_mod = 0
	/// Shown to the owner when an identical judgment resets the duration
	var/refresh_message = ""
	/// Shown to the owner when the judgment runs out
	var/end_message = ""

/datum/status_effect/index_judgment/on_apply()
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, justice_mod)
	return ..()

/datum/status_effect/index_judgment/on_remove()
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -justice_mod)
	to_chat(owner, span_notice(end_message))
	return ..()

/datum/status_effect/index_judgment/refresh()
	. = ..()
	to_chat(owner, span_notice(refresh_message))

/datum/status_effect/index_judgment/blessing
	id = "index_blessing"
	duration = 5 MINUTES
	justice_mod = 50
	refresh_message = "The Oracle's blessing duration has been refreshed."
	end_message = "The Oracle's blessing of power has faded."

/datum/status_effect/index_judgment/curse
	id = "index_curse"
	duration = 2 MINUTES
	justice_mod = -50
	refresh_message = "The Oracle's curse duration has been refreshed."
	end_message = "The Oracle's curse has lifted."
