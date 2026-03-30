// ============================================================
// Seven Association — Investigation Items
// ============================================================
// Camera, Scanner, Recorder, Receiver, and Spyglass Kit.

/// Global list tracking active recorders per owner: key = ref(owner), value = list(recorders)
GLOBAL_LIST_EMPTY(seven_active_recorders)
/// Global list of active Seven PDA interceptors
GLOBAL_LIST_EMPTY(seven_pda_interceptors)

// ============================================================
// Seven Intel Camera
// ============================================================
/// A modified camera used by Seven Association investigators.
/// Silently photographs targets and creates intel snapshots.
/// The snapshot records ground truth data but is hidden from the fixer.
/obj/item/camera/seven_intel
	name = "Seven intel camera"
	desc = "A modified camera used by Seven Association investigators. Silently photographs targets for intelligence reports."
	flash_enabled = FALSE
	silent = TRUE
	pictures_max = 15
	pictures_left = 15
	can_customise = FALSE
	default_picture_name = "Intel Photo"

/// Override to create intel snapshots and attach them to the photo.
/// Only tells the fixer the target's name — all other data is hidden.
/obj/item/camera/seven_intel/after_picture(mob/user, datum/picture/picture, proximity_flag)
	// Print photo silently (no broadcast message)
	var/obj/item/photo/p = new(get_turf(src), picture)
	if(!in_range(src, user))
		return
	user.put_in_hands(p)
	pictures_left--
	p.set_picture(picture, TRUE, TRUE)

	// Create intel snapshot for the main target (first human in frame)
	if(picture && length(picture.mobs_seen))
		var/mob/living/carbon/human/main_target
		for(var/mob/living/carbon/human/M in picture.mobs_seen)
			main_target = M
			break
		var/timestamp = gameTimestamp()
		if(main_target)
			var/datum/seven_intel_snapshot/snap = new(main_target)
			LAZYADD(p.seven_snapshots, snap)
			picture.picture_desc += " Subject: [main_target.name]."
			picture.picture_desc += " Taken at [timestamp]."
			p.desc = picture.picture_desc
			to_chat(user, span_notice("Subject captured: [main_target.name]. [pictures_left] photos remaining."))
		else
			picture.picture_desc += " Taken at [timestamp]."
			p.desc = picture.picture_desc
			to_chat(user, span_notice("No valid subjects in frame. [pictures_left] photos remaining."))
	else
		to_chat(user, span_notice("Photo captured. [pictures_left] remaining."))

	// Grant 20 EXP for taking intel photos
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(exp && exp.association_type == ASSOCIATION_SEVEN)
		exp.modify_exp(20)

/// Var added to /obj/item/photo for storing intel snapshots
/obj/item/photo
	/// Intel snapshots attached by the Seven camera
	var/list/datum/seven_intel_snapshot/seven_snapshots

// ============================================================
// Backpack Scanner
// ============================================================
/// A handheld scanner that silently reveals a target's backpack contents.
/obj/item/seven_scanner
	name = "Seven backpack scanner"
	desc = "A handheld scanner that silently reveals a target's backpack contents after a short delay. Use on an intel report to attach scan data."
	icon = 'icons/obj/device.dmi'
	icon_state = "forensicnew"
	w_class = WEIGHT_CLASS_SMALL
	/// Cooldown tracking
	var/next_scan_time = 0
	/// Whether a scan is currently in progress
	var/scanning = FALSE
	/// Last scan result text (for attaching to intel reports)
	var/last_scan_result = ""

/obj/item/seven_scanner/afterattack(atom/target, mob/user, proximity, click_params)
	. = ..()
	if(!iscarbon(target))
		to_chat(user, span_warning("[src] can only scan living targets."))
		return
	if(!(target in view(5, user)))
		to_chat(user, span_warning("Target is too far away."))
		return
	if(world.time < next_scan_time)
		to_chat(user, span_warning("[src] is still recalibrating."))
		return
	if(scanning)
		return
	scanning = TRUE
	next_scan_time = world.time + 10 SECONDS
	to_chat(user, span_notice("Scanning [target.name]..."))
	addtimer(CALLBACK(src, PROC_REF(finish_scan), target, user), 3 SECONDS)

/// Complete the scan and display results.
/obj/item/seven_scanner/proc/finish_scan(mob/living/carbon/target, mob/user)
	scanning = FALSE
	if(QDELETED(user) || QDELETED(target))
		return
	if(!(target in view(5, user)))
		to_chat(user, span_warning("Lost line of sight to target."))
		return
	// Build contents list
	var/list/contents_list = list()
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(H.back)
			for(var/obj/item/I in H.back.contents)
				contents_list += I.name
	if(!length(contents_list))
		to_chat(user, span_notice("Scan complete: Target's backpack is empty or not present."))
		last_scan_result = "Scan: [target.name] - backpack empty or not present."
		return
	to_chat(user, span_notice("Scan complete - [target.name]'s backpack contents:"))
	var/list/result_parts = list("Scan: [target.name] - [length(contents_list)] items:")
	for(var/item_name in contents_list)
		to_chat(user, span_notice("  - [item_name]"))
		result_parts += item_name
	last_scan_result = result_parts.Join("\n")
	// Grant 20 EXP
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(exp && exp.association_type == ASSOCIATION_SEVEN)
		exp.modify_exp(20)

// ============================================================
// Seven Surveillance Recorder
// ============================================================
/// A miniature recording device that captures nearby speech.
/// Can be used in hand, dropped on the ground, or hidden inside items. Supports disguise.
/obj/item/seven_recorder
	name = "Seven surveillance recorder"
	desc = "A miniature recording device that captures nearby speech. Use in hand to toggle recording. Hit the recorder with an item to disguise it as that item. Click the recorder on an item to hide it inside."
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "voice"
	w_class = WEIGHT_CLASS_TINY
	/// Whether currently recording
	var/recording = FALSE
	/// Stored messages: list(list("time" = X, "speaker" = Y, "message" = Z))
	var/list/stored_messages = list()
	/// Owner mob weakref (for EXP tracking and removal permissions)
	var/datum/weakref/owner_weakref
	/// EXP tracking: messages recorded since last EXP tick
	var/messages_since_exp = 0
	/// EXP cooldown
	var/next_exp_time = 0
	// Active recorders tracked via GLOB.seven_active_recorders
	/// Stealth timer — hard to find for a period after deployment
	var/stealth_until = 0
	/// The item this recorder is attached to (if item-attached)
	var/obj/item/attached_to
	/// Disguised appearance
	var/disguised = FALSE
	var/disguise_name
	var/disguise_desc
	var/disguise_icon
	var/disguise_icon_state
	/// Deployment delay in deciseconds
	var/deploy_time = 3 SECONDS

/obj/item/seven_recorder/examine(mob/user)
	// Owner always sees full info
	var/mob/living/owner_mob = owner_weakref?.resolve()
	if(user == owner_mob)
		. = ..()
		if(recording)
			. += span_notice("It is actively recording.")
		else
			. += span_notice("Use in hand to start recording.")
			if(!disguised)
				. += span_notice("Hit it with an item to copy that item's appearance as a disguise.")
			. += span_notice("Click it on an item to hide it inside and begin recording.")
		if(disguised)
			. += span_notice("It has been disguised as [disguise_name].")
		. += span_notice("[length(stored_messages)] messages recorded.")
		return
	// If stealthed and examiner is not the owner, show nothing special
	if(stealth_until > world.time && !isobserver(user))
		return list()
	. = ..()
	if(recording)
		. += span_notice("It appears to be a small recording device.")

/// Toggle recording on/off when used in hand
/obj/item/seven_recorder/attack_self(mob/user)
	if(recording)
		stop_recording()
		to_chat(user, span_notice("You stop recording."))
	else
		if(!try_deploy(user))
			return
		start_recording(user)
		to_chat(user, span_notice("You start recording."))

/obj/item/seven_recorder/attackby(obj/item/I, mob/user, params)
	if(!recording && !disguised && !istype(I, /obj/item/seven_recorder))
		// Copy appearance from item for disguise
		disguise_name = I.name
		disguise_desc = I.desc
		disguise_icon = I.icon
		disguise_icon_state = I.icon_state
		disguised = TRUE
		name = disguise_name
		desc = disguise_desc
		icon = disguise_icon
		icon_state = disguise_icon_state
		to_chat(user, span_notice("You disguise [src] as [disguise_name]."))
		return
	return ..()

/// Attach recorder to an item (with delay)
/obj/item/seven_recorder/afterattack(atom/target, mob/user, proximity, click_params)
	. = ..()
	if(!proximity)
		return
	if(recording)
		to_chat(user, span_warning("[src] is already recording."))
		return
	if(istype(target, /obj/item) && !istype(target, /obj/item/seven_recorder))
		if(!try_deploy(user))
			return
		to_chat(user, span_notice("Attaching recorder to [target]..."))
		if(!do_after(user, deploy_time, target))
			return
		if(recording)
			return
		user.transferItemToLoc(src, target)
		attached_to = target
		RegisterSignal(attached_to, COMSIG_PARENT_EXAMINE, PROC_REF(on_host_examined))
		start_recording(user)
		stealth_until = world.time + 10 MINUTES
		to_chat(user, span_notice("You hide [src] inside [target]. It begins recording."))
		return

/// Check if the user can deploy another recorder (max 5)
/obj/item/seven_recorder/proc/try_deploy(mob/user)
	var/owner_key = ref(user)
	if(!GLOB.seven_active_recorders[owner_key])
		GLOB.seven_active_recorders[owner_key] = list()
	var/list/my_recorders = GLOB.seven_active_recorders[owner_key]
	// Clean up deleted recorders
	for(var/obj/item/seven_recorder/R in my_recorders)
		if(QDELETED(R) || !R.recording)
			my_recorders -= R
	if(length(my_recorders) >= 5)
		to_chat(user, span_warning("You already have 5 active recorders deployed."))
		return FALSE
	return TRUE

/// Begin recording
/obj/item/seven_recorder/proc/start_recording(mob/user)
	recording = TRUE
	owner_weakref = WEAKREF(user)
	flags_1 |= HEAR_1
	var/owner_key = ref(user)
	if(!GLOB.seven_active_recorders[owner_key])
		GLOB.seven_active_recorders[owner_key] = list()
	GLOB.seven_active_recorders[owner_key] += src

/// Stop recording and clean up
/obj/item/seven_recorder/proc/stop_recording()
	recording = FALSE
	flags_1 &= ~HEAR_1
	if(attached_to)
		UnregisterSignal(attached_to, COMSIG_PARENT_EXAMINE)
		attached_to = null
	var/mob/living/owner_mob = owner_weakref?.resolve()
	if(owner_mob)
		var/owner_key = ref(owner_mob)
		if(GLOB.seven_active_recorders[owner_key])
			GLOB.seven_active_recorders[owner_key] -= src

/// Signal handler: when someone examines the host item this recorder is hidden inside
/obj/item/seven_recorder/proc/on_host_examined(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/owner_mob = owner_weakref?.resolve()
	if(user == owner_mob)
		examine_list += span_notice("A Seven recorder is attached. <a href='?src=[REF(src)];action=remove_recorder'>\[Remove\]</a>")
	else if(stealth_until <= world.time || isobserver(user))
		examine_list += span_warning("There is a small recording device attached. <a href='?src=[REF(src)];action=remove_recorder'>\[Remove\]</a>")

/// Handle clickable examine links for recorder removal
/obj/item/seven_recorder/Topic(href, list/href_list)
	. = ..()
	if(.)
		return
	if(href_list["action"] != "remove_recorder")
		return
	var/mob/user = usr
	if(!user || !attached_to || QDELETED(user))
		return
	if(!user.can_interact_with(attached_to))
		return
	var/mob/living/owner_mob = owner_weakref?.resolve()
	if(user == owner_mob)
		remove_from_host(user)
	else if(stealth_until <= world.time)
		remove_from_host(user)
	else
		to_chat(user, span_warning("You can't find anything unusual."))

/// Remove the recorder from its host item and put it in the user's hands
/obj/item/seven_recorder/proc/remove_from_host(mob/user)
	if(!attached_to)
		return
	var/obj/item/host = attached_to
	stop_recording()
	forceMove(get_turf(host))
	if(user)
		user.put_in_hands(src)
		to_chat(user, span_notice("You remove the recorder from [host]."))

/// Maximum number of stored messages per recorder
#define SEVEN_RECORDER_MAX_MESSAGES 300

/// Capture nearby emotes (*me messages)
/obj/item/seven_recorder/proc/record_emote(mob/user, emote_message)
	if(!recording)
		return
	if(length(stored_messages) >= SEVEN_RECORDER_MAX_MESSAGES)
		return
	var/timestamp = gameTimestamp()
	stored_messages += list(list(
		"time" = timestamp,
		"speaker" = user?.name || "Unknown",
		"message" = emote_message
	))
	messages_since_exp++
	if(messages_since_exp >= 5 && world.time >= next_exp_time)
		messages_since_exp = 0
		next_exp_time = world.time + 1 MINUTES
		var/mob/living/owner_mob = owner_weakref?.resolve()
		if(owner_mob)
			var/datum/component/association_exp/exp = owner_mob.GetComponent(/datum/component/association_exp)
			if(exp && exp.association_type == ASSOCIATION_SEVEN)
				exp.modify_exp(10)

/// Capture nearby speech
/obj/item/seven_recorder/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, spans, list/message_mods = list())
	. = ..()
	if(!recording)
		return
	if(length(stored_messages) >= SEVEN_RECORDER_MAX_MESSAGES)
		return
	var/timestamp = gameTimestamp()
	stored_messages += list(list(
		"time" = timestamp,
		"speaker" = speaker?.name || "Unknown",
		"message" = raw_message || message
	))
	// EXP tracking: grant 10 EXP per 5 messages, max once per minute
	messages_since_exp++
	if(messages_since_exp >= 5 && world.time >= next_exp_time)
		messages_since_exp = 0
		next_exp_time = world.time + 1 MINUTES
		var/mob/living/owner_mob = owner_weakref?.resolve()
		if(owner_mob)
			var/datum/component/association_exp/exp = owner_mob.GetComponent(/datum/component/association_exp)
			if(exp && exp.association_type == ASSOCIATION_SEVEN)
				exp.modify_exp(10)

/// Pick up — stop recording
/obj/item/seven_recorder/pickup(mob/user)
	. = ..()
	if(recording)
		stop_recording()
		to_chat(user, span_notice("You retrieve [src]. Recording stopped."))

/obj/item/seven_recorder/Destroy()
	if(recording)
		stop_recording()
	owner_weakref = null
	attached_to = null
	return ..()

// ============================================================
// Seven Surveillance Receiver
// ============================================================
/// Tunes into deployed Seven recorders to read captured messages.
/// Shows detailed info: area, disguise, attached item, direction, distance.
/obj/item/seven_receiver
	name = "Seven surveillance receiver"
	desc = "Tunes into deployed Seven recorders to read captured messages and track their positions."
	icon = 'icons/obj/device.dmi'
	icon_state = "spectrometer"
	w_class = WEIGHT_CLASS_SMALL
	/// Owner mob weakref
	var/datum/weakref/owner_weakref
	/// Currently tuned recorder
	var/obj/item/seven_recorder/tuned_recorder
	/// Last message index we've displayed (for live feed)
	var/last_message_index = 0
	/// Print cooldown
	var/canprint = TRUE

/obj/item/seven_receiver/attack_self(mob/user)
	owner_weakref = WEAKREF(user)
	ui_interact(user)

/obj/item/seven_receiver/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SevenReceiver", name)
		ui.open()

/obj/item/seven_receiver/ui_state(mob/user)
	return GLOB.physical_state

/obj/item/seven_receiver/ui_data(mob/user)
	var/list/data = list()
	// List all active recorders owned by this user
	var/owner_key = ref(user)
	var/list/recorder_list = list()
	if(!GLOB.seven_active_recorders[owner_key])
		data["recorders"] = recorder_list
		data["feed"] = list()
		data["has_tuned"] = !!tuned_recorder
		return data
	var/list/my_recorders = GLOB.seven_active_recorders[owner_key]
	if(islist(my_recorders))
		var/turf/user_turf = get_turf(user)
		for(var/obj/item/seven_recorder/R in my_recorders)
			if(QDELETED(R) || !R.recording)
				continue
			var/area/A = get_area(R)
			// Direction and distance like a pinpointer
			var/turf/rec_turf = get_turf(R)
			var/direction = "unknown"
			var/distance = "unknown"
			var/dist_category = "unknown"
			if(user_turf && rec_turf && user_turf.z == rec_turf.z)
				var/d = get_dist(user_turf, rec_turf)
				distance = "[d] tiles"
				direction = dir2text(get_dir(user_turf, rec_turf))
				if(!direction)
					direction = "here"
				if(d == 0)
					dist_category = "here"
				else if(d <= 8)
					dist_category = "close"
				else if(d <= 16)
					dist_category = "medium"
				else
					dist_category = "far"
			else
				distance = "different level"
				direction = "N/A"
				dist_category = "far"
			// Disguise and attachment info
			var/display_name = R.disguised ? R.disguise_name : "Recorder"
			var/attached_info = ""
			if(R.attached_to && !QDELETED(R.attached_to))
				attached_info = R.attached_to.name
			recorder_list += list(list(
				"ref" = ref(R),
				"name" = display_name,
				"disguised" = R.disguised,
				"real_name" = "Seven surveillance recorder",
				"area" = A ? A.name : "Unknown",
				"attached_to" = attached_info,
				"messages" = R.stored_messages.len,
				"direction" = direction,
				"distance" = distance,
				"dist_category" = dist_category,
				"tuned" = (R == tuned_recorder)
			))
	data["recorders"] = recorder_list
	// Feed from tuned recorder
	var/list/feed = list()
	if(tuned_recorder && !QDELETED(tuned_recorder))
		// Show last 20 messages
		var/start = max(1, tuned_recorder.stored_messages.len - 19)
		for(var/i in start to tuned_recorder.stored_messages.len)
			feed += list(tuned_recorder.stored_messages[i])
	data["feed"] = feed
	data["has_tuned"] = !!tuned_recorder
	data["canprint"] = canprint
	return data

/obj/item/seven_receiver/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("tune")
			var/target_ref = params["ref"]
			if(!target_ref)
				return
			var/obj/item/seven_recorder/R = locate(target_ref)
			if(!istype(R) || QDELETED(R) || !R.recording)
				to_chat(usr, span_warning("That recorder is no longer active."))
				tuned_recorder = null
				return
			tuned_recorder = R
			last_message_index = R.stored_messages.len
			to_chat(usr, span_notice("Tuned into [R.name]."))
			. = TRUE
		if("untune")
			tuned_recorder = null
			last_message_index = 0
			. = TRUE
		if("retrieve")
			var/target_ref = params["ref"]
			if(!target_ref || !ishuman(usr))
				return
			var/obj/item/seven_recorder/R = locate(target_ref)
			if(!istype(R) || QDELETED(R))
				to_chat(usr, span_warning("That recorder no longer exists."))
				return
			if(R.owner_weakref?.resolve() != usr)
				to_chat(usr, span_warning("That is not your recorder."))
				return
			// Charge 2000 ahn for remote retrieval
			var/mob/living/carbon/human/H = usr
			var/obj/item/card/id/ID = H.get_idcard(TRUE)
			if(!ID?.registered_account)
				to_chat(usr, span_warning("You need an ID card with a bank account."))
				return
			if(!ID.registered_account.has_money(2000))
				to_chat(usr, span_warning("Remote retrieval costs 2000 ahn. Insufficient funds."))
				return
			ID.registered_account.adjust_money(-2000)
			// Stop recording and move to user's hands
			R.stop_recording()
			if(tuned_recorder == R)
				tuned_recorder = null
			R.forceMove(get_turf(usr))
			usr.put_in_hands(R)
			to_chat(usr, span_notice("Recorder retrieved remotely. 2000 ahn charged."))
			. = TRUE
		if("clear_messages")
			var/target_ref = params["ref"]
			if(!target_ref)
				return
			var/obj/item/seven_recorder/R = locate(target_ref)
			if(!istype(R) || QDELETED(R))
				return
			if(R.owner_weakref?.resolve() != usr)
				return
			R.stored_messages = list()
			R.messages_since_exp = 0
			to_chat(usr, span_notice("Messages cleared from [R.name]."))
			. = TRUE
		if("print_transcript")
			var/target_ref = params["ref"]
			if(!target_ref || !ishuman(usr))
				return
			if(!canprint)
				to_chat(usr, span_warning("The receiver can't print that fast!"))
				return
			var/obj/item/seven_recorder/R = locate(target_ref)
			if(!istype(R) || QDELETED(R))
				to_chat(usr, span_warning("That recorder no longer exists."))
				return
			if(R.owner_weakref?.resolve() != usr)
				return
			if(!length(R.stored_messages))
				to_chat(usr, span_warning("No messages to print."))
				return
			var/obj/item/paper/P = new(get_turf(usr))
			var/t1 = "<B>Surveillance Transcript:</B><BR>"
			t1 += "<B>Recorder: [R.name]</B><BR><BR>"
			for(var/list/msg in R.stored_messages)
				t1 += "\[[msg["time"]]\] "
				t1 += "<B>[msg["speaker"]]</B>: "
				t1 += "[msg["message"]]<BR>"
			P.info = t1
			P.name = "paper - 'Surveillance Transcript'"
			P.update_icon_state()
			usr.put_in_hands(P)
			canprint = FALSE
			addtimer(VARSET_CALLBACK(src, canprint, TRUE), 30 SECONDS)
			to_chat(usr, span_notice("Transcript printed."))
			. = TRUE

// ============================================================
// Seven PDA Signal Interceptor
// ============================================================
/// Intercepts PDA messages on the network. Anonymizes sender and recipient
/// identities with persistent random IDs.
/obj/item/seven_pda_interceptor
	name = "Seven signal interceptor"
	desc = "A device that taps into the PDA messaging network. Intercepted identities are anonymized."
	icon = 'icons/obj/device.dmi'
	icon_state = "nanite_scanner"
	w_class = WEIGHT_CLASS_SMALL
	/// Whether the interceptor is actively listening
	var/active = FALSE
	/// Intercepted messages: list(list("time", "sender_id", "recipient_id", "message"))
	var/list/intercepted_messages = list()
	/// Persistent identity map: real name -> anonymous ID
	var/list/identity_map = list()
	/// Max stored messages
	var/max_messages = 300
	/// Owner mob weakref
	var/datum/weakref/owner_weakref

/obj/item/seven_pda_interceptor/attack_self(mob/user)
	owner_weakref = WEAKREF(user)
	ui_interact(user)

/obj/item/seven_pda_interceptor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SevenInterceptor", name)
		ui.open()

/obj/item/seven_pda_interceptor/ui_state(mob/user)
	return GLOB.physical_state

/obj/item/seven_pda_interceptor/ui_data(mob/user)
	var/list/data = list()
	data["active"] = active
	data["message_count"] = length(intercepted_messages)
	data["max_messages"] = max_messages
	data["id_count"] = length(identity_map)
	// Send last 50 messages for display
	var/list/display = list()
	var/start = max(1, length(intercepted_messages) - 49)
	for(var/i in start to length(intercepted_messages))
		display += list(intercepted_messages[i])
	data["messages"] = display
	return data

/obj/item/seven_pda_interceptor/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle")
			active = !active
			if(active)
				GLOB.seven_pda_interceptors += src
				to_chat(usr, span_notice("Signal interceptor activated. Monitoring PDA network."))
			else
				GLOB.seven_pda_interceptors -= src
				to_chat(usr, span_notice("Signal interceptor deactivated."))
			. = TRUE
		if("clear")
			intercepted_messages = list()
			to_chat(usr, span_notice("Intercepted messages cleared."))
			. = TRUE
		if("clear_ids")
			identity_map = list()
			to_chat(usr, span_notice("Identity map reset. New IDs will be assigned."))
			. = TRUE

/// Generate or retrieve an anonymous ID for a real name
/obj/item/seven_pda_interceptor/proc/get_anon_id(real_name)
	if(!real_name)
		return "??????"
	if(identity_map[real_name])
		return identity_map[real_name]
	// Generate random 6-character hex ID
	var/id = ""
	var/static/list/hex_chars = list("0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F")
	for(var/i in 1 to 6)
		id += pick(hex_chars)
	identity_map[real_name] = id
	return id

/// Called by the broadcast() hook when a PDA message is sent
/obj/item/seven_pda_interceptor/proc/intercept_message(datum/signal/subspace/messaging/pda/signal)
	if(!active)
		return
	if(length(intercepted_messages) >= max_messages)
		return
	var/sender_name = signal.data["name"]
	var/sender_id = get_anon_id(sender_name)
	// Process each target
	var/list/target_ids = list()
	for(var/target_string in signal.data["targets"])
		// target_string is "Name (Job)" - extract just the name
		var/paren_pos = findtext(target_string, " (")
		var/target_name = target_string
		if(paren_pos)
			target_name = copytext(target_string, 1, paren_pos)
		target_ids += get_anon_id(target_name)
	var/recipient_text = target_ids.Join(", ")
	if(length(signal.data["targets"]) > 3)
		recipient_text = "Broadcast"
	intercepted_messages += list(list(
		"time" = gameTimestamp(),
		"sender" = sender_id,
		"recipient" = recipient_text,
		"message" = signal.data["message"]
	))
	// Grant 10 EXP per 10 intercepted messages
	var/mob/living/owner_mob = owner_weakref?.resolve()
	if(owner_mob && length(intercepted_messages) % 10 == 0)
		var/datum/component/association_exp/exp = owner_mob.GetComponent(/datum/component/association_exp)
		if(exp && exp.association_type == ASSOCIATION_SEVEN)
			exp.modify_exp(10)

/obj/item/seven_pda_interceptor/Destroy()
	GLOB.seven_pda_interceptors -= src
	owner_weakref = null
	return ..()

// ============================================================
// Spyglass Kit
// ============================================================
/// A box containing Seven Association surveillance glasses and a spy bug.
/obj/item/storage/box/seven_spyglass
	name = "Seven surveillance kit"
	desc = "Contains Seven Association surveillance glasses and a spy bug."

/obj/item/storage/box/seven_spyglass/PopulateContents()
	var/obj/item/spy_bug/seven/newbug = new(src)
	var/obj/item/clothing/glasses/sunglasses/spy/seven/newglasses = new(src)
	newbug.linked_glasses = newglasses
	newglasses.linked_bug = newbug

/// Seven-branded spy bug with 5x5 view and speech relay
/obj/item/spy_bug/seven
	name = "Seven surveillance bug"
	desc = "A miniature camera bug used by Seven Association investigators. Enhanced with a wider camera and built-in microphone."

/obj/item/spy_bug/seven/Initialize()
	. = ..()
	flags_1 |= HEAR_1

/// Override to use 5x5 view (range 2) instead of the default 3x3
/obj/item/spy_bug/seven/update_view()
	cam_screen.vis_contents.Cut()
	for(var/turf/visible_turf in view(2, get_turf(src)))
		cam_screen.vis_contents += visible_turf

/// Relay overheard speech to whoever is wearing the linked glasses
/obj/item/spy_bug/seven/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, spans, list/message_mods = list())
	. = ..()
	if(!linked_glasses)
		return
	if(!ishuman(linked_glasses.loc))
		return
	var/mob/living/carbon/human/wearer = linked_glasses.loc
	if(wearer.get_item_by_slot(ITEM_SLOT_EYES) != linked_glasses)
		return
	var/display_message = raw_message || message
	to_chat(wearer, span_notice("\[Bug\] [speaker?.name || "Unknown"]: [display_message]"))

/// Seven-branded spy glasses with 5x5 view and EXP generation
/obj/item/clothing/glasses/sunglasses/spy/seven
	name = "Seven surveillance glasses"
	desc = "Modified glasses that display a live feed from a paired Seven surveillance bug. Generates investigation EXP while the bug is deployed."
	/// Timer for EXP ticks
	var/datum/timerid

/// Override to use 5x5 popup (matching the bug's 5x5 view range)
/obj/item/clothing/glasses/sunglasses/spy/seven/show_to_user(mob/user)
	if(!user)
		return
	if(!user.client)
		return
	if(!linked_bug)
		user.audible_message(span_warning("[src] lets off a shrill beep!"))
	if("spypopup_map" in user.client.screen_maps)
		return
	user.client.setup_popup("spypopup", 5, 5, 2)
	user.client.register_map_obj(linked_bug.cam_screen)
	for(var/plane in linked_bug.cam_plane_masters)
		user.client.register_map_obj(plane)
	linked_bug.update_view()

/obj/item/clothing/glasses/sunglasses/spy/seven/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_EYES)
		timerid = addtimer(CALLBACK(src, PROC_REF(exp_tick), user), 30 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/obj/item/clothing/glasses/sunglasses/spy/seven/dropped(mob/user)
	. = ..()
	if(timerid)
		deltimer(timerid)
		timerid = null

/// Grant 1 EXP every 30s while glasses worn and bug is deployed
/obj/item/clothing/glasses/sunglasses/spy/seven/proc/exp_tick(mob/user)
	if(QDELETED(user) || QDELETED(src))
		if(timerid)
			deltimer(timerid)
			timerid = null
		return
	// Check bug is linked and deployed (not in a hand or container held by someone)
	if(!linked_bug || istype(linked_bug.loc, /mob))
		return
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(exp && exp.association_type == ASSOCIATION_SEVEN)
		exp.modify_exp(10)

/obj/item/clothing/glasses/sunglasses/spy/seven/Destroy()
	if(timerid)
		deltimer(timerid)
		timerid = null
	return ..()
