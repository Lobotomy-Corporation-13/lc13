// Status effects and visual distortion for the Arayashiki \u963F\u983C\u8036\u8B58.
// Sever the Thread \u5207\u7D72 is the victim-side stacking debuff that arms the dismember at 10 stacks
// and continues climbing to 100 to fuel chat / HUD distortion on client-bearing victims.
// Muga \u7121\u6211 is the wielder-side accumulator with the same distortion mechanics.

//////////////////////////////////
// Shared block-censor visuals  //
//////////////////////////////////

// IMPORTANT: We use /image objects added to client.images, NOT screen objects.
// /atom/movable/screen has APPEARANCE_UI baked in and is rendered through the HUD
// pipeline, which sits above world atoms regardless of plane/layer. Images placed
// at world turfs (via loc) are real world atoms for rendering purposes and respect
// plane/layer z-ordering against mobs.
//
// Each image is anchored to a turf at random offsets from the wielder. plane=GAME_PLANE
// and layer=MOB_LAYER-0.01 places the image above turfs/items but below mobs and
// runechat. Adding to client.images shows it only to the wielder.

/// Rebuilds the random-scatter white-block overlay images for this status effect.
/// Severity 0 clears, severity N places (N*N*4) blocks at random world tiles in view.
/datum/status_effect/proc/UpdateBlockOverlays()
	if(!owner || !owner.client)
		return
	var/sev = SeverityForGarble()
	var/desired_count = sev * sev * 4
	var/view_radius = isnum(owner.client.view) ? owner.client.view : 7
	var/axis = view_radius * 2 + 1
	var/cap = axis * axis
	desired_count = min(desired_count, cap)

	ClearBlockOverlays()
	if(desired_count <= 0)
		return

	var/turf/center = get_turf(owner)
	if(!center)
		return

	if(!active_blocks)
		active_blocks = list()
	var/list/used_keys = list()
	var/safety = 0
	while(length(active_blocks) < desired_count && safety < desired_count * 4)
		safety++
		var/dx = rand(-view_radius, view_radius)
		var/dy = rand(-view_radius, view_radius)
		var/key = "[dx],[dy]"
		if(used_keys[key])
			continue
		used_keys[key] = TRUE
		var/turf/T = locate(center.x + dx, center.y + dy, center.z)
		if(!T)
			continue
		var/image/I = image('icons/hud/screen_gen.dmi', T, "flash")
		I.color = "#ffffff"
		I.alpha = 255
		I.plane = GAME_PLANE
		I.layer = MOB_LAYER - 0.01
		I.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		I.appearance_flags = RESET_TRANSFORM | RESET_COLOR | KEEP_APART
		owner.client.images += I
		active_blocks += I

/datum/status_effect/proc/ClearBlockOverlays()
	if(!active_blocks)
		return
	if(owner && owner.client)
		for(var/image/I in active_blocks)
			owner.client.images -= I
	active_blocks = null

/// Returns 0..10. Default = 0 (no distortion). Subtypes override.
/datum/status_effect/proc/SeverityForGarble()
	return 0

/// Storage for the block screens; declared on the base so the shared procs can find it.
/datum/status_effect
	var/list/active_blocks

/////////////////////////////////
// Shared chat-garble hearing  //
/////////////////////////////////

/// Best-effort dark/light glyph picker. Defaults to \u25A0.
/proc/get_garble_glyph(mob/M)
	return "\u25A0"

/// Mutates an incoming raw chat message, replacing characters with \u25A0 at a frequency scaled by severity.
/// Hooked to COMSIG_MOVABLE_HEAR; mutates HEARING_RAW_MESSAGE so embedded span tags are preserved.
/datum/status_effect/proc/GarbleHearing(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	var/sev = SeverityForGarble()
	if(sev <= 0)
		return
	var/raw = hearing_args[HEARING_RAW_MESSAGE]
	if(!raw)
		return
	var/glyph = get_garble_glyph(owner)
	var/replace_chance = min(75, sev * 12)
	var/list/chars = splittext(raw, "")
	for(var/i in 1 to length(chars))
		if(chars[i] == " ")
			continue
		if(prob(replace_chance))
			chars[i] = glyph
	hearing_args[HEARING_RAW_MESSAGE] = chars.Join("")

//////////////////////////////////////////////////
// to_chat distortion (Muga + Sever the Thread) //
//////////////////////////////////////////////////

/// Walks an HTML string and replaces non-tag, non-whitespace chars with the garble glyph.
/// Tag content (anything inside <...>) is copied verbatim so spans/links survive.
/proc/arayashiki_mangle_chat_html(html, sev)
	if(!html || sev <= 0)
		return html
	var/glyph = "\u25A0"
	var/replace_chance = min(75, sev * 12)
	var/list/chars = splittext(html, "")
	var/in_tag = FALSE
	for(var/i in 1 to length(chars))
		var/c = chars[i]
		if(c == "<")
			in_tag = TRUE
			continue
		if(c == ">")
			in_tag = FALSE
			continue
		if(in_tag)
			continue
		if(c == " " || c == "\t" || c == "\n")
			continue
		if(prob(replace_chance))
			chars[i] = glyph
	return chars.Join("")

/// Plain-text mangler - same algorithm without the tag-state machine.
/proc/arayashiki_mangle_chat_text(text, sev)
	if(!text || sev <= 0)
		return text
	var/glyph = "\u25A0"
	var/replace_chance = min(75, sev * 12)
	var/list/chars = splittext(text, "")
	for(var/i in 1 to length(chars))
		if(chars[i] == " " || chars[i] == "\t" || chars[i] == "\n")
			continue
		if(prob(replace_chance))
			chars[i] = glyph
	return chars.Join("")

/// Returns a NEW message list with mangled html/text fields if the recipient has Muga or Sever the Thread,
/// or null if no distortion is needed (caller uses the original message unchanged).
/proc/arayashiki_distort_message(client/C, list/message)
	if(!C || !isliving(C.mob))
		return null
	var/mob/living/L = C.mob
	var/datum/status_effect/muga/Mu = L.has_status_effect(/datum/status_effect/muga)
	var/datum/status_effect/stacking/sever_the_thread/St = L.has_status_effect(/datum/status_effect/stacking/sever_the_thread)
	var/sev = 0
	if(Mu)
		sev = max(sev, Mu.SeverityForGarble())
	if(St)
		sev = max(sev, St.SeverityForGarble())
	if(sev <= 0)
		return null
	var/list/out = message.Copy()
	if(out["html"])
		out["html"] = arayashiki_mangle_chat_html(out["html"], sev)
	if(out["text"])
		out["text"] = arayashiki_mangle_chat_text(out["text"], sev)
	return out

/////////////////////////////////////
// Sever the Thread \u5207\u7D72 (victim) //
/////////////////////////////////////

/atom/movable/screen/alert/status_effect/sever_the_thread
	name = "Sever the Thread \u5207\u7D72"
	desc = "The thread of your form is fraying. At 10 stacks the next stroke severs a limb. At 100, you are erased."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "sever_the_thread"

/atom/movable/screen/alert/status_effect/muga
	name = "Muga \u7121\u6211"
	desc = "Selflessness erodes your perception. Arayashiki feeds on your form."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "muga"

/datum/status_effect/stacking/sever_the_thread
	id = "sever_the_thread"
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/sever_the_thread
	stack_threshold = 10
	max_stacks = 100
	consumed_on_threshold = FALSE
	stack_decay = 0
	delay_before_decay = 0
	tick_interval = 1 SECONDS
	stacking_display_name = "sewwound"
	overlay_file = 'ModularLobotomy/_Lobotomyicons/tegu_effects10x10.dmi'
	overlay_state = "sewwound"
	/// Set TRUE when the threshold is crossed; consumed by the next Arayashiki strike to dismember.
	var/armed = FALSE
	/// Latches once armed for the first time; informational.
	var/has_been_armed = FALSE
	/// Tracks whether we've already registered the chat hook for a client owner.
	var/chat_hook_registered = FALSE
	/// Set TRUE when the Erasing Me, Erasing You cutscene is in progress on this owner.
	/// Prevents repeat triggers from subsequent hits during the ~12s cutscene window.
	var/cutscene_active = FALSE

/datum/status_effect/stacking/sever_the_thread/threshold_cross_effect()
	armed = TRUE
	has_been_armed = TRUE
	to_chat(owner, span_userdanger("The thread is taut. The next stroke will sever you. \u5207\u7D72"))

/datum/status_effect/stacking/sever_the_thread/on_apply()
	. = ..()
	if(. && owner && owner.client)
		RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(GarbleHearing))
		chat_hook_registered = TRUE

/datum/status_effect/stacking/sever_the_thread/on_remove()
	if(chat_hook_registered && owner)
		UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
		chat_hook_registered = FALSE
	ClearBlockOverlays()
	return ..()

/datum/status_effect/stacking/sever_the_thread/tick()
	..()
	UpdateBlockOverlays()

/datum/status_effect/stacking/sever_the_thread/SeverityForGarble()
	return clamp(round(stacks / 10), 0, 10)

/////////////////////////////
// Muga \u7121\u6211 (wielder)    //
/////////////////////////////

/datum/status_effect/muga
	id = "muga"
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/muga
	tick_interval = 1 SECONDS
	/// Stacks of Muga; uncapped, but visual severity buckets at 5/15/30/50/80.
	var/muga = 0
	/// world.time of the last attack that bumped stacks; out-of-combat decay starts after 30s.
	var/last_attack_world_time = 0
	/// Cached HUD originals so we can restore screen_loc / alpha on remove.
	var/list/saved_screen_loc = list()
	var/list/saved_alpha = list()
	/// Whether the chat hook is currently registered.
	var/chat_hook_registered = FALSE

/datum/status_effect/muga/on_apply()
	if(!ishuman(owner))
		return FALSE
	last_attack_world_time = world.time
	return ..()

/datum/status_effect/muga/on_remove()
	RestoreHud()
	ClearBlockOverlays()
	if(chat_hook_registered && owner)
		UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
		chat_hook_registered = FALSE
	return ..()

/datum/status_effect/muga/proc/AddMuga(amount)
	muga += amount
	last_attack_world_time = world.time
	UpdateVisuals()

/datum/status_effect/muga/proc/Severity()
	switch(muga)
		if(0 to 4)
			return 0
		if(5 to 14)
			return 1
		if(15 to 29)
			return 2
		if(30 to 49)
			return 3
		if(50 to 79)
			return 4
		else
			return 5

/datum/status_effect/muga/SeverityForGarble()
	return Severity()

/datum/status_effect/muga/proc/UpdateVisuals()
	if(!owner || !owner.client)
		return
	var/sev = Severity()
	UpdateBlockOverlays()
	ApplyHudGlitchPass(sev)
	if(sev >= 1 && !chat_hook_registered)
		RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(GarbleHearing))
		chat_hook_registered = TRUE
	else if(sev <= 0 && chat_hook_registered)
		UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
		chat_hook_registered = FALSE

/// Walks client.screen and randomly perturbs a subset of HUD elements based on severity.
/// Caches each touched element's original screen_loc / alpha on first contact.
/datum/status_effect/muga/proc/ApplyHudGlitchPass(sev)
	if(!owner || !owner.client)
		return
	if(sev <= 0)
		RestoreHud()
		return
	var/list/screen = owner.client.screen
	if(!length(screen))
		return
	var/touch_count = sev * 3
	var/max_offset = sev * 8
	for(var/i in 1 to touch_count)
		var/atom/movable/screen/elem = pick(screen)
		if(!elem)
			continue
		// Fullscreen elements use stretched screen_loc; offsetting them breaks the display
		if(istype(elem, /atom/movable/screen/fullscreen))
			continue
		var/key = "\ref[elem]"
		if(!saved_screen_loc[key] && elem.screen_loc)
			saved_screen_loc[key] = elem.screen_loc
		if(!saved_alpha[key])
			saved_alpha[key] = elem.alpha
		if(elem.screen_loc)
			elem.screen_loc = "[saved_screen_loc[key]]:[rand(-max_offset, max_offset)],:[rand(-max_offset, max_offset)]"
		elem.alpha = max(40, saved_alpha[key] - sev * 30)

/datum/status_effect/muga/proc/RestoreHud()
	if(!owner || !owner.client)
		saved_screen_loc.Cut()
		saved_alpha.Cut()
		return
	for(var/atom/movable/screen/elem in owner.client.screen)
		var/key = "\ref[elem]"
		if(saved_screen_loc[key])
			elem.screen_loc = saved_screen_loc[key]
		if(saved_alpha[key])
			elem.alpha = saved_alpha[key]
	saved_screen_loc.Cut()
	saved_alpha.Cut()

/datum/status_effect/muga/tick()
	if(world.time - last_attack_world_time >= 30 SECONDS && muga > 0)
		muga = max(0, muga - 1)
		UpdateVisuals()
		if(muga == 0)
			qdel(src)
			return
	UpdateVisuals()
	// Erases a severity-scaled share of the wielder's chat, so a long history erodes faster
	var/sev = Severity()
	if(sev > 0 && owner && owner.client)
		arayashiki_prune_chat(owner.client, sev * 10)

/// Sends a "drop the oldest N% of chat messages" command to a specific client's TGUI panel.
/// Backed by the chat/pruneOldestPercent action in tgui-panel/chat/middleware.js.
/// Also decrements the server-side chat_message_count to keep the approximation in sync
/// (mirrors the client's own Math.max(1, floor(total * pct / 100)) drop count).
/proc/arayashiki_prune_chat(client/C, percent)
	if(!C || percent <= 0)
		return
	var/datum/tgui_panel/panel = C.tgui_panel
	if(!panel)
		return
	panel.window?.send_message("chat/pruneOldestPercent", percent)
	if(C.chat_message_count > 0)
		var/dropped = max(1, round(C.chat_message_count * min(100, percent) / 100))
		C.chat_message_count = max(0, C.chat_message_count - dropped)
