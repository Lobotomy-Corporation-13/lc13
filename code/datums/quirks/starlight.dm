/*
 * Placeholder Starlight Quirks — testing the picker + shop UI loop.
 * No add() / on_spawn() hooks; they attach but do nothing in-game.
 * Replace these with real mechanics once the system is locked in.
 */

// Robust slot-cascade for item-granting starlight quirks.
//
// `equip_in_one_of_slots` (carbon/inventory.dm) calls
// `equip_to_slot_if_possible` with `bypass_equip_delay_self = FALSE`
// AND `redraw_mob = TRUE`. At roundstart / latejoin, quirk on_spawn()
// fires before `transfer_character()` hands the client over to the
// body — `mob_can_equip`'s implicit do_after path bails immediately
// without a client, and the redraw can also fail on a transient mob,
// silently dropping the item at the player's feet. We bypass both by
// using the same `initial = TRUE` path the job outfit equipper takes.
/proc/starlight_quirk_grant(mob/living/carbon/human/H, obj/item/I, list/slots)
	if(!ishuman(H) || !I)
		return FALSE
	for(var/slot_name in slots)
		if(H.equip_to_slot_if_possible(I, slots[slot_name], FALSE, TRUE, FALSE, TRUE, TRUE))
			return TRUE
	I.forceMove(get_turf(H))
	return FALSE

// // ---- Afterimage Entanglement ----
// // Curtain Call reward: two translucent silhouettes that trail one tile
// // behind the holder, mirroring the holder's appearance (clothing + held
// // items) and copying the holder's last facing each step. Modeled after
// // the Mirror Shattered Reaper afterimage with full appearance mirroring
// // instead of a fixed icon_state.

// /obj/effect/starlight_afterimage
// 	name = "afterimage"
// 	desc = "A translucent echo, mimicking someone at half a step behind."
// 	icon = 'icons/effects/effects.dmi'
// 	icon_state = ""
// 	alpha = 90
// 	color = "#c1a0ff"
// 	layer = BELOW_MOB_LAYER
// 	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
// 	anchored = TRUE
// 	var/mob/living/parent_mob
// 	var/update_timer
// 	/// Dir the holder was facing when they left this AF's current tile.
// 	/// Re-applied after every appearance refresh so the gear-update timer
// 	/// doesn't snap us back to the holder's current facing.
// 	var/cached_dir = SOUTH

// /obj/effect/starlight_afterimage/Initialize(mapload, mob/living/owner)
// 	. = ..()
// 	if(!owner)
// 		return INITIALIZE_HINT_QDEL
// 	parent_mob = owner
// 	cached_dir = owner.dir
// 	forceMove(get_turf(owner))
// 	UpdateMirror()
// 	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(SelfDestruct))
// 	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(SelfDestruct))
// 	// 1s refresh covers gear changes while standing still — the owning quirk
// 	// repositions us on every step.
// 	update_timer = addtimer(CALLBACK(src, PROC_REF(UpdateMirror)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

// /obj/effect/starlight_afterimage/Destroy()
// 	if(update_timer)
// 		deltimer(update_timer)
// 		update_timer = null
// 	if(parent_mob)
// 		UnregisterSignal(parent_mob, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
// 		parent_mob = null
// 	return ..()

// /// Snapshots the holder's full appearance (icon, overlays = clothing/held items,
// /// transform, etc.) then re-applies the afterimage-specific visual overrides.
// /// `appearance = parent.appearance` also copies dir; we override that with
// /// `cached_dir` so the AF keeps the facing it had on its current tile.
// /obj/effect/starlight_afterimage/proc/UpdateMirror()
// 	if(QDELETED(parent_mob))
// 		return
// 	appearance = parent_mob.appearance
// 	name = "afterimage"
// 	alpha = 90
// 	color = "#c1a0ff"
// 	layer = BELOW_MOB_LAYER
// 	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
// 	pixel_x = rand(-8, 8)
// 	pixel_y = rand(-4, 4)
// 	setDir(cached_dir)

// /obj/effect/starlight_afterimage/proc/SelfDestruct()
// 	SIGNAL_HANDLER
// 	qdel(src)

// /datum/quirk/starlight_afterimage_entanglement
// 	name = "Afterimage Entanglement"
// 	desc = "Two translucent silhouettes trail one step behind you, copying your appearance and last facing each tile they move. Stand still and they catch up onto your tile. Toggleable via an action button."
// 	value = 8
// 	starlight_locked = TRUE
// 	starlight_cost = 500
// 	required_line_completed = "curtain_call"
// 	medical_record_text = "Subject's silhouette displays unstable replication artifacts."
// 	gain_text = "<span class='notice'>Two ghostly echoes settle behind you, mimicking your every step.</span>"
// 	lose_text = "<span class='notice'>Your trailing silhouettes dissolve.</span>"
// 	var/list/active_afterimages = list()
// 	/// Recently-vacated tiles, most recent first. Capped at the AF count (2).
// 	var/list/tile_history = list()
// 	/// Holder's dir on each tile in tile_history (parallel list).
// 	var/list/dir_history = list()
// 	/// world.time of the last movement signal; the idle re-center is gated
// 	/// behind a fresh re-check of this so a late-firing timer doesn't
// 	/// teleport the AFs while the holder is still walking.
// 	var/last_move_time = 0
// 	/// 3-second idle timer; firing recenters both afterimages on the holder.
// 	var/idle_timer
// 	/// Player-facing on/off; the action button flips this.
// 	var/enabled = TRUE
// 	/// HUD toggle that calls ToggleAfterimages().
// 	var/datum/action/cooldown/starlight_afterimage_toggle/toggle_action

// /datum/quirk/starlight_afterimage_entanglement/add()
// 	if(!toggle_action)
// 		toggle_action = new(quirk_holder)
// 		toggle_action.quirk = src
// 	toggle_action.Grant(quirk_holder)
// 	if(enabled)
// 		SpawnAfterimages()

// /datum/quirk/starlight_afterimage_entanglement/proc/SpawnAfterimages()
// 	if(QDELETED(quirk_holder))
// 		return
// 	ClearAfterimages()
// 	for(var/i in 1 to 2)
// 		var/obj/effect/starlight_afterimage/A = new(get_turf(quirk_holder), quirk_holder)
// 		active_afterimages += A
// 	RegisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED, PROC_REF(OnOwnerMoved))

// /datum/quirk/starlight_afterimage_entanglement/on_transfer()
// 	if(toggle_action && quirk_holder)
// 		toggle_action.Grant(quirk_holder)
// 	if(enabled)
// 		SpawnAfterimages()

// /datum/quirk/starlight_afterimage_entanglement/remove()
// 	ClearAfterimages()
// 	if(toggle_action)
// 		QDEL_NULL(toggle_action)

// /// Flips the on/off state. Off despawns the afterimages and stops listening
// /// for movement; on respawns them centered on the holder.
// /datum/quirk/starlight_afterimage_entanglement/proc/ToggleAfterimages(mob/user)
// 	enabled = !enabled
// 	if(enabled)
// 		SpawnAfterimages()
// 		if(user)
// 			to_chat(user, span_notice("Your trailing silhouettes flicker back into being."))
// 	else
// 		ClearAfterimages()
// 		if(user)
// 			to_chat(user, span_notice("Your trailing silhouettes melt into nothing."))

// /datum/action/cooldown/starlight_afterimage_toggle
// 	name = "Toggle Afterimages"
// 	desc = "Dismiss or recall your two trailing afterimages."
// 	icon_icon = 'icons/hud/guardian.dmi'
// 	button_icon_state = "manifest"
// 	cooldown_time = 0
// 	transparent_when_unavailable = TRUE
// 	var/datum/quirk/starlight_afterimage_entanglement/quirk

// /datum/action/cooldown/starlight_afterimage_toggle/Trigger()
// 	. = ..()
// 	if(!. || !quirk)
// 		return
// 	quirk.ToggleAfterimages(owner)

// /datum/action/cooldown/starlight_afterimage_toggle/Destroy()
// 	quirk = null
// 	return ..()

// /datum/quirk/starlight_afterimage_entanglement/proc/ClearAfterimages()
// 	if(quirk_holder)
// 		UnregisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED)
// 	if(idle_timer)
// 		deltimer(idle_timer)
// 		idle_timer = null
// 	for(var/obj/effect/starlight_afterimage/A as anything in active_afterimages)
// 		if(!QDELETED(A))
// 			qdel(A)
// 	active_afterimages.Cut()
// 	tile_history.Cut()
// 	dir_history.Cut()

// /datum/quirk/starlight_afterimage_entanglement/proc/OnOwnerMoved(atom/movable/source, atom/old_loc)
// 	SIGNAL_HANDLER
// 	if(!isturf(old_loc))
// 		return
// 	tile_history.Insert(1, old_loc)
// 	// source.dir on a normal step is the dir they turned to before leaving,
// 	// which is exactly the facing they had on old_loc — what we want.
// 	dir_history.Insert(1, source.dir)
// 	if(length(tile_history) > length(active_afterimages))
// 		tile_history.Cut(length(active_afterimages) + 1)
// 		dir_history.Cut(length(active_afterimages) + 1)
// 	last_move_time = world.time
// 	RepositionAfterimages()
// 	if(idle_timer)
// 		deltimer(idle_timer)
// 	idle_timer = addtimer(CALLBACK(src, PROC_REF(OnIdle)), 3 SECONDS, TIMER_STOPPABLE)

// /datum/quirk/starlight_afterimage_entanglement/proc/OnIdle()
// 	idle_timer = null
// 	// Defensive: if the holder moved during the 3s window but the timer
// 	// somehow wasn't cancelled, re-queue for the remaining time instead
// 	// of teleporting mid-stride.
// 	var/elapsed = world.time - last_move_time
// 	if(elapsed < 3 SECONDS)
// 		var/remaining = (3 SECONDS) - elapsed
// 		idle_timer = addtimer(CALLBACK(src, PROC_REF(OnIdle)), remaining, TIMER_STOPPABLE)
// 		return
// 	CenterOnPlayer()

// /// Drops both afterimages onto the holder's current tile — used when they've
// /// been stationary long enough that the trail catches up.
// /datum/quirk/starlight_afterimage_entanglement/proc/CenterOnPlayer()
// 	if(QDELETED(quirk_holder))
// 		return
// 	var/turf/T = get_turf(quirk_holder)
// 	if(!T)
// 		return
// 	tile_history.Cut()
// 	dir_history.Cut()
// 	for(var/obj/effect/starlight_afterimage/A as anything in active_afterimages)
// 		if(QDELETED(A))
// 			continue
// 		A.cached_dir = quirk_holder.dir
// 		A.forceMove(T)
// 		A.UpdateMirror()

// /// Spreads the afterimages across the most-recent tile history so they never
// /// share a square once enough movement has happened to fill the history.
// /datum/quirk/starlight_afterimage_entanglement/proc/RepositionAfterimages()
// 	if(QDELETED(quirk_holder) || !length(tile_history))
// 		return
// 	for(var/i in 1 to length(active_afterimages))
// 		var/obj/effect/starlight_afterimage/A = active_afterimages[i]
// 		if(QDELETED(A))
// 			continue
// 		var/turf/dest = (i <= length(tile_history)) ? tile_history[i] : tile_history[length(tile_history)]
// 		var/historical_dir = (i <= length(dir_history)) ? dir_history[i] : dir_history[length(dir_history)]
// 		if(!isturf(dest))
// 			continue
// 		A.cached_dir = historical_dir
// 		A.forceMove(dest)
// 		A.UpdateMirror()

// ---- Tagalong Rat ----
// Curtain Call reward: pet rat that starts in the holder's backpack (folded
// into a mob_holder, like a scooped mouse). Drop the holder on the ground
// to release the rat, then click it with an empty hand to order it around
// (Follow / Stay / Haul / Pick up). Behavior modeled on
// /mob/living/simple_animal/hostile/price (ModularLobotomy/extra_mobs/lc13_outskirtdwellers.dm).
// Tinted via the Pet Rat Color preference, same UI pattern as Phobia.

/mob/living/simple_animal/hostile/pet_rat
	name = "pet rat"
	desc = "A devoted little rat trotting at your heels."
	icon = 'icons/mob/animal.dmi'
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	faction = list("neutral")
	wander = 0
	obj_damage = 0
	environment_smash = FALSE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_chance = 1
	a_intent = INTENT_HELP
	maxHealth = 30
	health = 30
	melee_damage_lower = 0
	melee_damage_upper = 0
	speak = list("Squeak!", "Squeak?", "Skrr.")
	emote_hear = list("squeaks.", "sniffs.")
	emote_see = list("scratches an ear.", "stands on its hind legs.")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "steps on"
	response_harm_simple = "step on"
	density = FALSE
	mob_size = MOB_SIZE_TINY
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	can_be_held = TRUE
	held_state = "mouse_gray"
	gold_core_spawnable = NO_SPAWN
	loot = list()

/mob/living/simple_animal/hostile/pet_rat/AttackingTarget()
	return

/mob/living/simple_animal/hostile/pet_rat/CanAttack(atom/the_target)
	return

/mob/living/simple_animal/hostile/pet_rat/attack_hand(mob/living/carbon/M)
	if(stat || client || !istype(M) || M.a_intent != INTENT_HELP)
		return ..()
	var/cmd = alert(M, "Order [name]:", "Pet Rat", "Follow", "Stay", "Haul")
	if(QDELETED(src) || QDELETED(M))
		return
	switch(cmd)
		if("Follow")
			walk_to(src, M, 1, move_to_delay)
			visible_message(span_notice("[src] perks up and starts following [M]."))
		if("Stay")
			walk(src, 0)
			visible_message(span_notice("[src] settles in place."))
		if("Haul")
			HaulNearestObject(M)

/// Picks the nearest non-anchored structure in a 1-tile radius and starts pulling it.
/// Mirrors /mob/living/simple_animal/hostile/price/haul.
/mob/living/simple_animal/hostile/pet_rat/proc/HaulNearestObject(mob/living/carbon/M)
	stop_pulling()
	for(var/obj/structure/A in oview(1, get_turf(src)))
		if(A == M || A.anchored)
			continue
		start_pulling(A)
		visible_message(span_notice("[src] grabs onto [A] and starts hauling."))
		return
	to_chat(M, span_warning("There's nothing nearby [src] can haul."))

/datum/quirk/starlight_tagalong_rat
	name = "Tagalong Rat"
	desc = "A pet rat curled up in your backpack. Drop them out to follow you around and haul light objects on command. You picked their color."
	value = 4
	starlight_locked = TRUE
	starlight_cost = 400
	required_line_completed = "curtain_call"
	medical_record_text = "Subject has registered emotional support rodent."
	gain_text = "<span class='notice'>You feel a familiar weight curl up inside your backpack.</span>"
	lose_text = "<span class='notice'>Your pet rat is nowhere to be found.</span>"

/datum/quirk/starlight_tagalong_rat/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return
	var/mob/living/simple_animal/hostile/pet_rat/rat = new(null)
	var/color_pref = H.client?.prefs?.pet_rat_color
	if(color_pref)
		rat.color = color_pref
	rat.name = "[H.real_name]'s pet rat"
	rat.real_name = rat.name
	var/obj/item/clothing/head/mob_holder/holder = new(get_turf(H), rat, rat.held_state, null, null, null, NONE)
	holder.name = rat.name
	holder.desc = "Your pet rat, curled up small. Drop them on the ground to set them down."
	starlight_quirk_grant(H, holder, list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	))

// ---- Scarlet Bouquet ----
// Subtype of /obj/item/bouquet that hosts a bloodfeast pool with a hard
// 5000-blood cap and a 10000 warning threshold (effectively unreachable —
// no floor-splatter spam fires). Use-in-hand toggles passive_siphon.
// A "graybouquet_overlay" tints brighter red as the pool fills. The pool
// decays 5000 over 15 minutes so an idle bouquet returns to gray.

#define SCARLET_BOUQUET_MAX_BLOOD 5000
#define SCARLET_BOUQUET_DECAY_INTERVAL (1 SECONDS)
/// Per-tick decay = max / (15 minutes in seconds) — drains the full pool in 15 min.
#define SCARLET_BOUQUET_DECAY_PER_TICK (SCARLET_BOUQUET_MAX_BLOOD / 900)

/obj/item/bouquet/scarlet
	name = "scarlet bouquet"
	desc = "A bouquet of pale gray blossoms that drink in stray blood, their petals warming red as they grow heavy."
	icon_state = "graybouquet"
	var/decay_timer
	var/mutable_appearance/bloom_overlay

/obj/item/bouquet/scarlet/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/bloodfeast, FALSE, 1, 0, 10000, SCARLET_BOUQUET_MAX_BLOOD)
	UpdateRedness()
	decay_timer = addtimer(CALLBACK(src, PROC_REF(DecayBlood)), SCARLET_BOUQUET_DECAY_INTERVAL, TIMER_LOOP | TIMER_STOPPABLE)

/obj/item/bouquet/scarlet/Destroy()
	if(decay_timer)
		deltimer(decay_timer)
		decay_timer = null
	return ..()

/obj/item/bouquet/scarlet/attack_self(mob/user)
	var/datum/component/bloodfeast/B = GetComponent(/datum/component/bloodfeast)
	if(!B)
		return
	B.passive_siphon = !B.passive_siphon
	to_chat(user, span_notice("You [B.passive_siphon ? "open" : "close"] the [name]'s petals."))

/obj/item/bouquet/scarlet/proc/DecayBlood()
	var/datum/component/bloodfeast/B = GetComponent(/datum/component/bloodfeast)
	if(!B)
		return
	if(B.blood_amount > 0)
		B.AdjustBlood(-SCARLET_BOUQUET_DECAY_PER_TICK)
	UpdateRedness()

/// Tints the "graybouquet_overlay" red, intensity scaling with the pool fill.
/obj/item/bouquet/scarlet/proc/UpdateRedness()
	if(bloom_overlay)
		cut_overlay(bloom_overlay)
		bloom_overlay = null
	var/datum/component/bloodfeast/B = GetComponent(/datum/component/bloodfeast)
	if(!B || B.blood_amount <= 0)
		return
	var/ratio = clamp(B.blood_amount / SCARLET_BOUQUET_MAX_BLOOD, 0, 1)
	var/intensity = round(80 + ratio * 175)
	bloom_overlay = mutable_appearance(icon, "graybouquet_overlay")
	bloom_overlay.color = "#[num2hex(intensity, 2)]0000"
	add_overlay(bloom_overlay)

/datum/quirk/starlight_scarlet_bouquet
	name = "Scarlet Bouquet"
	desc = "You carry a bouquet of gray blossoms that drink in stray blood. Use-in-hand toggles whether the petals open and siphon; the more they hold, the brighter their red glow."
	value = 1
	starlight_locked = TRUE
	starlight_cost = 200
	required_line_completed = "nova_flare"
	medical_record_text = "Subject carries an unusual horticultural curiosity."
	gain_text = "<span class='notice'>The scarlet bouquet rests heavy in your pack, petals still gray.</span>"
	lose_text = "<span class='notice'>Your scarlet bouquet is no longer with you.</span>"

/datum/quirk/starlight_scarlet_bouquet/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return
	var/obj/item/bouquet/scarlet/bouquet = new(get_turf(H))
	starlight_quirk_grant(H, bouquet, list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	))

// ---- Sparkle Mine Launcher ----
// A harmless party launcher: planting a sparkle mine on a target tile drops
// a /obj/effect/sparkle_mine that goes through the same fall/launch cycle as
// the Nova Flare keeper_mine but explodes into pipebombs + a party horn
// instead of damage. Three charges, 10-second per-charge reload that
// auto-chains while there's room.

#define SPARKLE_MINE_LAUNCHER_MAX_CHARGES 3
#define SPARKLE_MINE_LAUNCHER_RELOAD_TIME (10 SECONDS)

/obj/item/sparkle_mine_launcher
	name = "sparkle mine launcher"
	desc = "A heavy gauntlet rigged to deploy festive mines. Use in hand to begin reloading; click a target tile to deploy."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "powerfist"
	inhand_icon_state = "powerfist"
	w_class = WEIGHT_CLASS_NORMAL
	force = 0
	throwforce = 0
	var/charges = SPARKLE_MINE_LAUNCHER_MAX_CHARGES
	var/max_charges = SPARKLE_MINE_LAUNCHER_MAX_CHARGES
	var/reload_time = SPARKLE_MINE_LAUNCHER_RELOAD_TIME
	var/reloading = FALSE

/obj/item/sparkle_mine_launcher/examine(mob/user)
	. = ..()
	. += span_notice("It has [charges]/[max_charges] sparkle mines loaded.")
	if(reloading)
		. += span_notice("It is currently reloading.")

/obj/item/sparkle_mine_launcher/attack_self(mob/user)
	if(reloading)
		to_chat(user, span_warning("[src] is already reloading!"))
		return
	if(charges >= max_charges)
		to_chat(user, span_warning("[src] is already fully loaded!"))
		return
	StartReloadCycle(user)

/obj/item/sparkle_mine_launcher/proc/StartReloadCycle(mob/user)
	if(reloading || QDELETED(src) || QDELETED(user))
		return
	if(charges >= max_charges)
		return
	reloading = TRUE
	to_chat(user, span_notice("You begin loading a sparkle mine into [src]..."))
	if(!do_after(user, reload_time, target = user))
		reloading = FALSE
		to_chat(user, span_warning("Your reload of [src] is interrupted."))
		return
	reloading = FALSE
	if(QDELETED(src))
		return
	charges = min(charges + 1, max_charges)
	playsound(get_turf(user), 'sound/weapons/gun/general/bolt_rack.ogg', 30, TRUE)
	to_chat(user, span_notice("You slot a sparkle mine into [src]. ([charges]/[max_charges])"))
	if(charges < max_charges)
		StartReloadCycle(user)

/obj/item/sparkle_mine_launcher/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!target || !user)
		return
	var/turf/T = get_turf(target)
	if(!T || isclosedturf(T) || isclosedturf(target))
		to_chat(user, span_warning("You can't deploy a mine there."))
		return
	if(charges <= 0)
		to_chat(user, span_warning("[src] has no sparkle mines loaded!"))
		return
	charges--
	to_chat(user, span_notice("You launch a sparkle mine onto [T]. ([charges]/[max_charges])"))
	playsound(get_turf(user), 'sound/weapons/gun/general/dry_fire.ogg', 30, TRUE)
	new /obj/effect/sparkle_mine(T)

// Festive cousin of /obj/effect/keeper_mine — same fall/launch animation,
// zero damage, scatters pipebombs and toots a party horn on detonation.
/obj/effect/sparkle_mine
	name = "sparkle mine"
	desc = "A jubilant pink mine. Stand near it at your own discretion."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "uglymine"
	color = "#ff66cc"
	density = FALSE
	anchored = TRUE
	layer = OBJ_LAYER
	var/detect_range = 1
	var/explode_radius = 1
	var/lifetime = 30 SECONDS
	var/falling = TRUE
	var/fall_time = 0.5 SECONDS
	var/fall_height = 128
	var/launching = FALSE
	var/launch_height = 15
	var/launch_up_time = 0.5 SECONDS
	var/airborne_beep_time = 1 SECONDS
	var/launch_down_time = 0.4 SECONDS
	var/pixel_y_rest = 0

/obj/effect/sparkle_mine/Initialize()
	. = ..()
	for(var/obj/effect/sparkle_mine/other in loc)
		if(other == src)
			continue
		pixel_x = pick(-10, -5, 5, 10)
		pixel_y_rest = pick(-10, -5, 5, 10)
		break
	START_PROCESSING(SSfastprocess, src)
	QDEL_IN(src, lifetime)
	pixel_y = pixel_y_rest + fall_height
	animate(src, pixel_y = pixel_y_rest, time = fall_time)
	addtimer(CALLBACK(src, PROC_REF(Land)), fall_time)

/obj/effect/sparkle_mine/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/effect/sparkle_mine/proc/Land()
	if(QDELETED(src))
		return
	falling = FALSE
	playsound(get_turf(src), 'sound/effects/clang.ogg', 30, FALSE, 1)

/obj/effect/sparkle_mine/process()
	if(launching || falling || QDELETED(src))
		return
	for(var/mob/living/carbon/human/H in range(detect_range, src))
		if(H.stat == DEAD)
			continue
		INVOKE_ASYNC(src, PROC_REF(TriggerCycle))
		return

/obj/effect/sparkle_mine/proc/TriggerCycle()
	if(launching || QDELETED(src))
		return
	launching = TRUE
	animate(src, pixel_y = pixel_y_rest + launch_height, time = launch_up_time)
	sleep(launch_up_time)
	var/end_t = world.time + airborne_beep_time
	while(world.time < end_t)
		if(QDELETED(src))
			return
		playsound(get_turf(src), 'sound/items/timer.ogg', 30, FALSE, 1)
		sleep(2)
	if(QDELETED(src))
		return
	animate(src, pixel_y = pixel_y_rest, time = launch_down_time)
	Explode()
	sleep(launch_down_time)
	if(QDELETED(src))
		return
	qdel(src)

/obj/effect/sparkle_mine/proc/Explode()
	var/turf/T = get_turf(src)
	new /obj/effect/temp_visual/explosion(T)
	playsound(T, 'sound/items/party_horn.ogg', 60, FALSE, 4)
	for(var/turf/scatter in range(explode_radius, src))
		if(isclosedturf(scatter))
			continue
		new /obj/effect/decal/cleanable/glitter(scatter)

/datum/quirk/starlight_sparkle_mine_launcher
	name = "Sparkle Mine Launcher"
	desc = "You start with a Sparkle Mine Launcher in your pack. Three festive mines that detonate into a shower of suspicious letters and a party horn. Use-in-hand reloads (10 seconds per charge, auto-chains)."
	value = 2
	starlight_locked = TRUE
	starlight_cost = 400
	required_line_completed = "nova_flare"
	medical_record_text = "Subject carries an apparently-non-lethal mine deployment device."
	gain_text = "<span class='notice'>You feel the weight of a heavy gauntlet settle into your pack.</span>"
	lose_text = "<span class='notice'>Your sparkle mine launcher is no longer with you.</span>"

/datum/quirk/starlight_sparkle_mine_launcher/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return
	var/obj/item/sparkle_mine_launcher/launcher = new(get_turf(H))
	starlight_quirk_grant(H, launcher, list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	))

// ---- Mutated Form ----
// Negative-cost Starlight quirk: paints a red "mutant_face" overlay on
// the holder. Any other carbon examining them takes 5 SP; the holder
// takes 20 SP. Wearing a HIDEFACE mask suppresses the trigger — the
// quirk hands out a clown wig + mask as the on-spawn suppressant.

/datum/quirk/starlight_mutated_form
	name = "Mutated Form"
	desc = "Something has rewritten your face. Anyone looking at it takes a sliver of sanity off the top, and you take a heavier hit. Wearing a face-hiding mask suppresses the effect — a clown wig and mask come with the package."
	value = -2
	starlight_locked = TRUE
	starlight_cost = 400
	required_line_completed = "nova_flare"
	medical_record_text = "Subject's face presents an acute psychogenic hazard to direct observers."
	gain_text = "<span class='warning'>Something stretches across your face and settles into place.</span>"
	lose_text = "<span class='notice'>The mutation peels away. Your face is yours again.</span>"
	/// SP applied to a carbon examiner that gets a clear look.
	var/examiner_damage = 5
	/// SP applied to the holder per such examine.
	var/holder_damage = 20
	var/mutable_appearance/face_overlay

/datum/quirk/starlight_mutated_form/add()
	if(QDELETED(quirk_holder))
		return
	// BODY_ADJ_LAYER is the "body markings / snout" tier — sits above the
	// body sprite but under underwear (BODY_LAYER) and every worn slot,
	// so the mask + uniform cover the mutation when worn.
	face_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi', "mutant_face", -BODY_ADJ_LAYER)
	face_overlay.color = "#ff0000"
	quirk_holder.add_overlay(face_overlay)
	RegisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE, PROC_REF(OnExamined))

/datum/quirk/starlight_mutated_form/on_transfer()
	add()

/datum/quirk/starlight_mutated_form/remove()
	if(quirk_holder)
		UnregisterSignal(quirk_holder, COMSIG_PARENT_EXAMINE)
		if(face_overlay)
			quirk_holder.cut_overlay(face_overlay)
	face_overlay = null

/datum/quirk/starlight_mutated_form/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return
	var/obj/item/clothing/mask/gas/clown_hat/M = new(get_turf(H))
	starlight_quirk_grant(H, M, list(
		"mask" = ITEM_SLOT_MASK,
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	))

/datum/quirk/starlight_mutated_form/proc/OnExamined(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!iscarbon(user) || user == quirk_holder)
		return
	if(!ishuman(quirk_holder))
		return
	var/mob/living/carbon/human/H = quirk_holder
	if(H.wear_mask && (H.wear_mask.flags_inv & HIDEFACE))
		to_chat(user, span_notice("[H]'s mask hides whatever crawls under it. You look away easily."))
		to_chat(H, span_notice("[user]'s eyes touch your mask and slide off. Whatever's under it stays under."))
		return
	to_chat(user, span_warning("You catch a glimpse of [H]'s face — something inside you reels back."))
	to_chat(H, span_warning("[user]'s eyes land on your face. The mutation answers — something in you twists."))
	H.adjustSanityLoss(holder_damage)
	if(ishuman(user))
		var/mob/living/carbon/human/U = user
		U.adjustSanityLoss(examiner_damage)

// ---- Chemical Expertise ----
// Permanent SCAN_REAGENTS via TRAIT_SEE_REAGENTS — the human helper proc
// can_see_reagents() picks the trait up alongside the worn-goggles check.
// The /datum/quirk base class auto-applies and auto-removes mob_trait, so
// nothing else needs to be wired up here.

/datum/quirk/starlight_chemical_expertise
	name = "Chemical Expertise"
	desc = "You can read the contents of any reagent container at a glance — same effect as a pair of science goggles, no goggles required."
	value = 2
	starlight_locked = TRUE
	starlight_cost = 200
	required_line_completed = "nova_flare"
	mob_trait = TRAIT_SEE_REAGENTS
	medical_record_text = "Subject reads reagent containers without instruments."
	gain_text = "<span class='notice'>You realise you can read what's in every beaker around you without looking at the label.</span>"
	lose_text = "<span class='notice'>Beakers fade back into opaque shapes — whatever sense you had for their contents is gone.</span>"

// ---- Mirror Shattered ----
// Curtain Call reward: a custom exit path out of the Door to Nowhere's
// repentance dimension. While inside `/area/fishboat/repentance`,
// interacting with any regret_door pops a menu of every regret_door
// AND every door_to_nowhere abnormality that is NOT in repentance —
// pick one, channel for 5 seconds, and emerge from there. Frees you
// from the trapped list without re-teleporting (we run the exit
// ourselves, so we must NOT call RescueFromRepentanceDimension —
// that proc would forceMove the player to the saved return location
// instead of the chosen exit). Hook lives in
// /obj/structure/regret_door/attack_hand inside door_to_nowhere.dm.

/datum/quirk/starlight_mirror_shattered
	name = "Mirror Shattered"
	desc = "You have grown connected to the realm of nowhere between the Mirror Worlds, you are able to have more control over how to leave it."
	value = 2
	starlight_locked = TRUE
	starlight_cost = 300
	required_line_completed = "curtain_call"
	medical_record_text = "Subject reports an unusual familiarity with the space behind mirrors."
	gain_text = "<span class='notice'>You feel the realm between mirrors notice you back.</span>"
	lose_text = "<span class='notice'>The realm between mirrors goes quiet again.</span>"

/// Called from regret_door.attack_hand when the holder is inside
/// /area/fishboat/repentance. Enumerates every regret_door and
/// door_to_nowhere abnormality outside repentance, presents a
/// labelled picker, and on selection drives the 5-second channel.
/datum/quirk/starlight_mirror_shattered/proc/OpenExitMenu(mob/living/carbon/human/H)
	if(!H || QDELETED(H))
		return
	var/list/choices = list()
	var/list/key_to_target = list()
	for(var/obj/structure/regret_door/D in world)
		if(istype(get_area(D), /area/fishboat/repentance))
			continue
		var/area/A = get_area(D)
		var/key = "[D.name] — [A?.name || "unknown area"]"
		choices += key
		key_to_target[key] = D
	for(var/mob/living/simple_animal/hostile/abnormality/door_to_nowhere/Abno in GLOB.mob_list)
		if(istype(get_area(Abno), /area/fishboat/repentance))
			continue
		var/area/A = get_area(Abno)
		var/key = "[Abno.name] — [A?.name || "unknown area"]"
		choices += key
		key_to_target[key] = Abno
	if(!length(choices))
		to_chat(H, span_warning("Nothing on the other side calls to you yet."))
		return
	var/picked = tgui_input_list(H, "Where do you emerge?", "Mirror Shattered", choices)
	if(!picked)
		return
	var/atom/target = key_to_target[picked]
	if(!target || QDELETED(target))
		to_chat(H, span_warning("The reflection slipped away before you could step through."))
		return
	ResolveExit(H, target)

/// 5-second channel, then forceMove the holder to the picked exit's
/// turf. If trapped, clears the GLOB tracking lists manually — never
/// call RescueFromRepentanceDimension here, because that proc does
/// its own forceMove which would override the chosen destination.
/datum/quirk/starlight_mirror_shattered/proc/ResolveExit(mob/living/carbon/human/H, atom/target)
	if(!H || QDELETED(H))
		return
	to_chat(H, span_notice("You press your palm to the door. Something on the other side presses back."))
	if(!do_after(H, 5 SECONDS, target = H))
		to_chat(H, span_notice("Your concentration breaks. The mirror dims."))
		return
	if(QDELETED(target))
		to_chat(H, span_warning("Your destination shattered before you could reach it."))
		return
	var/turf/dest = get_turf(target)
	if(!dest)
		to_chat(H, span_warning("The path collapses into nothing."))
		return
	// Manual trap-cleanup: clear without teleporting (we forceMove
	// the holder ourselves below). RescueFromRepentanceDimension would
	// stomp the chosen destination with the saved return location.
	if(IsTrappedInRepentance(H))
		GLOB.repentance_trapped_players -= H
		GLOB.repentance_return_locations -= H
		if(GLOB.repentance_status_effects[H])
			H.remove_status_effect(/datum/status_effect/repentance_ambience)
			GLOB.repentance_status_effects -= H
	H.forceMove(dest)
	playsound(dest, 'sound/magic/teleport_app.ogg', 50, TRUE)
	to_chat(H, span_nicegreen("You step out of [target]."))

// ---- Tagalong Crow ----
// Curtain Call reward: same drop-from-pack pattern as Tagalong Rat,
// but a peaceful crow that answers to Fly / Walk / Sit. No colour
// customisation — owners rename via Alt-click instead. The flying
// mode toggles `is_flying_animal` AND `TRAIT_MOVE_FLYING` in lockstep
// (mirrors the runtime VV pattern at simple_animal.dm:348-353). The
// Sit mode is the only state that exposes `can_be_held`, so the
// drag-pickup gesture only succeeds while the crow is calm — and the
// holder always renders the "crow_sit" pose since that's what
// `held_state` points at.

/mob/living/simple_animal/hostile/pet_crow
	name = "pet crow"
	desc = "A devoted little crow, head tilted at you in quiet expectation."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "crow"
	icon_living = "crow"
	icon_dead = "crow"
	faction = list("neutral")
	wander = 0
	obj_damage = 0
	environment_smash = FALSE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak_chance = 1
	a_intent = INTENT_HELP
	maxHealth = 30
	health = 30
	melee_damage_lower = 0
	melee_damage_upper = 0
	speak = list("Caw!", "Caw?", "...kra.")
	emote_hear = list("caws.", "ruffles its feathers.")
	emote_see = list("preens.", "cocks its head.")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoos"
	response_disarm_simple = "shoo"
	response_harm_continuous = "kicks at"
	response_harm_simple = "kick at"
	density = FALSE
	mob_size = MOB_SIZE_TINY
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	// Pickup is gated to the Sit order — Fly + Walk turn this off.
	can_be_held = FALSE
	held_state = "crow_sit"
	gold_core_spawnable = NO_SPAWN
	loot = list()

/mob/living/simple_animal/hostile/pet_crow/AttackingTarget()
	return

/mob/living/simple_animal/hostile/pet_crow/CanAttack(atom/the_target)
	return

/mob/living/simple_animal/hostile/pet_crow/attack_hand(mob/living/carbon/M)
	if(stat || client || !istype(M) || M.a_intent != INTENT_HELP)
		return ..()
	var/cmd = alert(M, "Order [name]:", "Pet Crow", "Fly", "Walk", "Sit")
	if(QDELETED(src) || QDELETED(M))
		return
	switch(cmd)
		if("Fly")
			OrderFly(M)
		if("Walk")
			OrderWalk(M)
		if("Sit")
			OrderSit()

/mob/living/simple_animal/hostile/pet_crow/AltClick(mob/user)
	if(!istype(user) || user.stat || stat == DEAD)
		return ..()
	var/new_name = stripped_input(user, "Rename your crow:", "Pet Crow", name, MAX_NAME_LEN)
	if(QDELETED(src) || !new_name)
		return
	new_name = trim(new_name)
	if(!length(new_name) || new_name == name)
		return
	name = new_name
	real_name = new_name
	visible_message(span_notice("[src] answers to its new name."))

/mob/living/simple_animal/hostile/pet_crow/proc/OrderFly(mob/orderer)
	if(stat == DEAD || QDELETED(src))
		return
	is_flying_animal = TRUE
	ADD_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
	icon_state = "crow_flying"
	icon_living = "crow_flying"
	can_be_held = FALSE
	walk_to(src, orderer, 1, move_to_delay)
	visible_message(span_notice("[src] takes wing and glides alongside [orderer]."))

/mob/living/simple_animal/hostile/pet_crow/proc/OrderWalk(mob/orderer)
	if(stat == DEAD || QDELETED(src))
		return
	is_flying_animal = FALSE
	REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
	icon_state = "crow"
	icon_living = "crow"
	can_be_held = FALSE
	walk_to(src, orderer, 1, move_to_delay)
	visible_message(span_notice("[src] hops to the ground and pads after [orderer]."))

/mob/living/simple_animal/hostile/pet_crow/proc/OrderSit()
	if(stat == DEAD || QDELETED(src))
		return
	is_flying_animal = FALSE
	REMOVE_TRAIT(src, TRAIT_MOVE_FLYING, ROUNDSTART_TRAIT)
	icon_state = "crow_sit"
	icon_living = "crow_sit"
	can_be_held = TRUE
	walk(src, 0)
	visible_message(span_notice("[src] settles down and folds its wings."))

/datum/quirk/starlight_tagalong_crow
	name = "Tagalong Crow"
	desc = "A pet crow folded into your pack. Drop them out to perch on your shoulder or flit alongside you — they answer to Fly, Walk, or Sit. Alt-click to rename them."
	value = 3
	starlight_locked = TRUE
	starlight_cost = 400
	required_line_completed = "curtain_call"
	medical_record_text = "Subject has registered emotional support corvid."
	gain_text = "<span class='notice'>You feel a familiar weight rustle inside your backpack.</span>"
	lose_text = "<span class='notice'>Your pet crow is nowhere to be found.</span>"

/datum/quirk/starlight_tagalong_crow/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return
	var/mob/living/simple_animal/hostile/pet_crow/crow = new(null)
	crow.name = "[H.real_name]'s pet crow"
	crow.real_name = crow.name
	var/obj/item/clothing/head/mob_holder/holder = new(get_turf(H), crow, crow.held_state, null, null, null, NONE)
	holder.name = crow.name
	holder.desc = "Your pet crow, folded small and quiet. Drop them on the ground to set them down."
	starlight_quirk_grant(H, holder, list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	))

// ---- Azarus Gambit ----
// Curtain Call reward: a heavy d20 modelled on the dealer's own dice.
// Five-bucket roll table:
//   1     — fires the berforate-A-lot smite on the roller.
//   2-7   — staggered "unseen forces" throws, repetition count
//           scales inversely with the roll (8 - result).
//   8-14  — flavour chat line only.
//   15-19 — random pastries from pastries.dm rain around the
//           roller, count scales with the roll (result - 14).
//   20    — gold coin shower around the roller, each coin
//           playing the flip animation.
// One-minute cooldown between rolls; the die carries a soft red
// outline filter while ready and loses it while cooling. All
// effects target the roller only.

/obj/item/dice/d20/azarus_gambit
	name = "Azarus's gambit"
	desc = "A heavy ebony d20 with the dealer's grin etched into the 20-face. It feels expectant. The faint red glow fades when it has just been thrown."
	icon_state = "de20"
	COOLDOWN_DECLARE(roll_cd)
	var/cooldown_time = 60 SECONDS
	var/ready_outline_colour = "#ff8080"
	var/static/list/pastry_pool

/obj/item/dice/d20/azarus_gambit/Initialize(mapload)
	. = ..()
	ApplyReadyOutline()

/obj/item/dice/d20/azarus_gambit/proc/ApplyReadyOutline()
	add_filter("azarus_gambit_ready", 1, list(
		"type" = "outline",
		"size" = 1,
		"color" = ready_outline_colour,
	))

/obj/item/dice/d20/azarus_gambit/proc/ClearReadyOutline()
	remove_filter("azarus_gambit_ready")

/obj/item/dice/d20/azarus_gambit/proc/GetPastryPool()
	if(!pastry_pool)
		// Drawn from code/game/objects/items/food/pastries.dm — every
		// pastry-ish base + their subtypes. Skips the soylent bricks
		// and the hotdog (sandwich-shaped, not the vibe). Cached once.
		pastry_pool = list()
		pastry_pool += typesof(/obj/item/food/donut)
		pastry_pool += typesof(/obj/item/food/muffin)
		pastry_pool += typesof(/obj/item/food/chawanmushi)
		pastry_pool += typesof(/obj/item/food/waffles)
		pastry_pool += typesof(/obj/item/food/rofflewaffles)
		pastry_pool += typesof(/obj/item/food/donkpocket)
		pastry_pool += typesof(/obj/item/food/dankpocket)
		pastry_pool += typesof(/obj/item/food/cookie)
		pastry_pool += typesof(/obj/item/food/fortunecookie)
		pastry_pool += typesof(/obj/item/food/poppypretzel)
		pastry_pool += typesof(/obj/item/food/plumphelmetbiscuit)
		pastry_pool += typesof(/obj/item/food/cracker)
		pastry_pool += typesof(/obj/item/food/meatbun)
		pastry_pool += typesof(/obj/item/food/khachapuri)
		pastry_pool += typesof(/obj/item/food/chococornet)
		pastry_pool += typesof(/obj/item/food/cherrycupcake)
		pastry_pool += typesof(/obj/item/food/honeybun)
		pastry_pool += typesof(/obj/item/food/pancakes)
		pastry_pool += typesof(/obj/item/food/cannoli)
		pastry_pool += typesof(/obj/item/food/croissant)
		pastry_pool += typesof(/obj/item/food/pain_au_chocolat)
	return pastry_pool

/obj/item/dice/d20/azarus_gambit/diceroll(mob/user)
	if(!COOLDOWN_FINISHED(src, roll_cd))
		if(user)
			var/seconds_left = CEILING(COOLDOWN_TIMELEFT(src, roll_cd) / 10, 1)
			to_chat(user, span_warning("[src] still hums between throws. [seconds_left] second\s left to settle."))
		return
	. = ..()
	var/roll = result
	if(!isliving(user) || !isnum(roll) || roll <= 0)
		return
	COOLDOWN_START(src, roll_cd, cooldown_time)
	ClearReadyOutline()
	addtimer(CALLBACK(src, PROC_REF(ApplyReadyOutline)), cooldown_time, TIMER_STOPPABLE)
	ApplyRollEffect(user, roll)

/obj/item/dice/d20/azarus_gambit/proc/ApplyRollEffect(mob/living/user, roll)
	if(QDELETED(user) || user.stat == DEAD)
		return
	switch(roll)
		if(1)
			FireBerforate(user)
		if(2 to 7)
			QueueUnseenThrows(user, 8 - roll)
		if(8 to 14)
			to_chat(user, span_notice("The die rolls to a clean stop. The table is silent."))
		if(15 to 19)
			RainPastries(user, roll - 14)
		if(20)
			RainGoldCoins(user)

/obj/item/dice/d20/azarus_gambit/proc/FireBerforate(mob/living/user)
	var/datum/smite/berforate/B = new()
	B.hatred = "A lot"
	B.effect(null, user)

/obj/item/dice/d20/azarus_gambit/proc/QueueUnseenThrows(mob/living/user, count)
	if(count <= 0)
		return
	for(var/i in 1 to count)
		addtimer(CALLBACK(src, PROC_REF(UnseenThrow), user), i * 15)

/obj/item/dice/d20/azarus_gambit/proc/UnseenThrow(mob/living/user)
	if(QDELETED(user) || user.stat == DEAD)
		return
	var/turf/T = get_turf(user)
	if(!T)
		return
	T.visible_message(span_userdanger("Unseen forces throw [user]!"))
	user.Stun(25)
	user.adjustBruteLoss(15)
	var/throw_dir = pick(GLOB.cardinals)
	var/atom/throw_target = get_edge_target_turf(user, throw_dir)
	user.throw_at(throw_target, 200, 4)

/obj/item/dice/d20/azarus_gambit/proc/RainPastries(mob/living/user, count)
	if(count <= 0)
		return
	var/list/pool = GetPastryPool()
	if(!length(pool))
		return
	var/list/spots = list()
	for(var/turf/T in range(2, user))
		if(T.density)
			continue
		spots += T
	if(!length(spots))
		return
	for(var/i in 1 to count)
		var/turf/T = pick(spots)
		var/pastry_type = pick(pool)
		new pastry_type(T)

/obj/item/dice/d20/azarus_gambit/proc/RainGoldCoins(mob/living/user)
	var/list/spots = list()
	for(var/turf/T in range(2, user))
		if(T.density)
			continue
		spots += T
	if(!length(spots))
		return
	spots = shuffle(spots)
	var/coin_count = min(12, length(spots))
	for(var/i in 1 to coin_count)
		addtimer(CALLBACK(src, PROC_REF(DropOneGoldCoin), spots[i]), i * 2)

/obj/item/dice/d20/azarus_gambit/proc/DropOneGoldCoin(turf/T)
	if(!T || QDELETED(T))
		return
	var/obj/item/coin/gold/G = new(T)
	flick("coin_[G.coinflip]_flip", G)
	playsound(T, 'sound/items/coinflip.ogg', 50, TRUE)

/datum/quirk/starlight_azarus_gambit
	name = "Azarus Gambit"
	desc = "You carry one of the dealer's own dice. Use in hand to roll; most outcomes nudge fortune your way, but the floor of the table is unforgiving. The die needs a minute to settle between throws."
	value = 2
	starlight_locked = TRUE
	starlight_cost = 400
	required_line_completed = "curtain_call"
	medical_record_text = "Subject carries a heavy custom die. They will not explain its provenance."
	gain_text = "<span class='notice'>A heavy d20 settles in your pocket. The 20-face winks at you.</span>"
	lose_text = "<span class='notice'>Your gambit die is no longer with you.</span>"

/datum/quirk/starlight_azarus_gambit/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return
	var/obj/item/dice/d20/azarus_gambit/D = new(get_turf(H))
	starlight_quirk_grant(H, D, list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	))

// ---- Stagestricken ----
// Negative Curtain Call quirk themed on the Envy of Humanity.
// The longing under the holder's face only speaks when there are
// other humans around to envy. More nearby humans = heavier stutter
// + slur + tier-3 ALL CAPS scream-pitch. Implementation uses the
// built-in stuttering/slurring vars (decremented in carbon/life.dm)
// topped up each `on_process` tick — the say-signal layer can't
// mutate the outgoing message itself (treat_message runs before the
// signal fires), so per-word custom mutation isn't viable. The
// tier-3 UPPERCASE return bit (COMPONENT_UPPERCASE_SPEECH) and the
// per-say SP drain both live in the COMSIG_MOB_SAY signal handler.
// HIDEFACE mask gates both polling and the say handler off.

/datum/quirk/starlight_stagestricken
	name = "Stagestricken"
	desc = "The thing under your face only speaks when there are faces to envy. \
		The more people around you, the more your words come apart. \
		A face-hiding mask holds it shut."
	value = -2
	starlight_locked = TRUE
	starlight_cost = 450
	required_line_completed = "curtain_call"
	medical_record_text = "Subject exhibits progressive verbal disintegration in crowded settings."
	gain_text = "<span class='warning'>Something behind your teeth notices the cast. It is hungrier than you.</span>"
	lose_text = "<span class='notice'>The borrowed voice quiets. Your tongue is yours again.</span>"

/datum/quirk/starlight_stagestricken/add()
	if(!ishuman(quirk_holder))
		return
	RegisterSignal(quirk_holder, COMSIG_MOB_SAY, PROC_REF(OnSay))

/datum/quirk/starlight_stagestricken/on_transfer()
	if(ishuman(quirk_holder))
		RegisterSignal(quirk_holder, COMSIG_MOB_SAY, PROC_REF(OnSay))

/datum/quirk/starlight_stagestricken/remove()
	if(quirk_holder)
		UnregisterSignal(quirk_holder, COMSIG_MOB_SAY)

/// Envy tier from the number of OTHER humans in view of the holder.
/// 0 → silent, 1 → mild, 2 → moderate, 3 → panic.
/datum/quirk/starlight_stagestricken/proc/GetEnvyTier()
	var/mob/living/carbon/human/H = quirk_holder
	if(!ishuman(H))
		return 0
	var/count = 0
	for(var/mob/living/carbon/human/N in view(7, H))
		if(N == H)
			continue
		count++
	if(count == 0)
		return 0
	if(count <= 2)
		return 1
	if(count <= 4)
		return 2
	return 3

/// Topped-up speech effect: keeps stuttering (+ slurring at higher
/// tiers) at a target value while there's a crowd to envy. Carbon
/// Life() decrements both by 1 per tick, so once the crowd disperses
/// the effect fades naturally without us having to clear it.
/datum/quirk/starlight_stagestricken/on_process(delta_time)
	if(!ishuman(quirk_holder))
		return
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD)
		return
	if(H.wear_mask?.flags_inv & HIDEFACE)
		return
	var/tier = GetEnvyTier()
	if(tier == 0)
		return
	var/target_stutter = 0
	var/target_slur = 0
	switch(tier)
		if(1)
			target_stutter = 5
		if(2)
			target_stutter = 15
			target_slur = 5
		if(3)
			target_stutter = 30
			target_slur = 15
	if(target_stutter > 0)
		H.stuttering = max(H.stuttering, target_stutter)
	if(target_slur > 0)
		H.slurring = max(H.slurring, target_slur)

/// COMSIG_MOB_SAY fires after treat_message has run, so we can't
/// rewrite the message body here. We use this hook for two things:
/// (1) per-say SP drain scaled by tier, and (2) tier-3 returns
/// COMPONENT_UPPERCASE_SPEECH so the message is screamed out in
/// ALL CAPS by the parent say chain (see living_say.dm:196).
/datum/quirk/starlight_stagestricken/proc/OnSay(datum/source, list/say_args)
	SIGNAL_HANDLER
	if(!ishuman(quirk_holder))
		return
	var/mob/living/carbon/human/H = quirk_holder
	if(H.wear_mask?.flags_inv & HIDEFACE)
		return
	var/tier = GetEnvyTier()
	if(tier == 0)
		return
	H.adjustSanityLoss(SanityCostForTier(tier))
	if(tier == 3)
		return COMPONENT_UPPERCASE_SPEECH

/datum/quirk/starlight_stagestricken/proc/SanityCostForTier(tier)
	switch(tier)
		if(1)
			return 1
		if(2)
			return 3
		if(3)
			return 5
	return 0

// ---- Bloodfiend Origins ----
// Curtain Call negative quirk themed on Eric.T's bloodfiend lore.
// Two halves: hydrophobia (water in any form costs SP, severity
// scaling with intimacy of contact) and bloodfiend physiology
// (passive blood drain, vampire-style bite tuned weaker and
// breakable, forced red eyes). Hooks live at five sites, each
// gated by HAS_TRAIT(M, TRAIT_BLOODFIEND):
//   - water reagent expose_mob (TOUCH branch — coverage scaled)
//   - edible component TakeBite (refuse self-eat, jitter force-feed)
//   - drinks attack proc (refuse self-drink, jitter force-feed)
//   - /turf/open/water/Entered (massive panic, 5s cooldown)
//   - bite action grant from add() / removal in remove()

/datum/quirk/starlight_bloodfiend_origins
	name = "Bloodfiend Origins"
	desc = "As a new form bloodfiend, your hunger for blood just awakend. Your blood passively drains faster, \
		your eyes burn red, and water in any form makes your throat \
		seize. A bite of your own can top you back up — quickly, \
		but never deeply."
	value = 3
	starlight_locked = TRUE
	starlight_cost = 500
	required_line_completed = "curtain_call"
	medical_record_text = "Subject exhibits bloodfiend traits: hydrophobia, accelerated blood loss, ocular discolouration."
	gain_text = "<span class='warning'>Something thirsty pulls itself awake in your chest. The water in the air looks colder than it should.</span>"
	lose_text = "<span class='notice'>The thirst quiets. Water is just water again.</span>"
	mob_trait = TRAIT_BLOODFIEND
	COOLDOWN_DECLARE(water_panic_cd)
	var/water_panic_cooldown = 5 SECONDS
	var/cached_eye_color
	var/datum/action/cooldown/bloodfiend_bite/bite_action

/datum/quirk/starlight_bloodfiend_origins/add()
	if(!ishuman(quirk_holder))
		return
	var/mob/living/carbon/human/H = quirk_holder
	cached_eye_color = H.eye_color
	H.eye_color = "8B0000"
	H.regenerate_icons()
	if(!bite_action)
		bite_action = new(quirk_holder)
		bite_action.parent_quirk = src
	bite_action.Grant(quirk_holder)

/datum/quirk/starlight_bloodfiend_origins/on_transfer()
	if(!ishuman(quirk_holder))
		return
	var/mob/living/carbon/human/H = quirk_holder
	ADD_TRAIT(H, TRAIT_BLOODFIEND, "quirk_bloodfiend")
	cached_eye_color = cached_eye_color || H.eye_color
	H.eye_color = "8B0000"
	H.regenerate_icons()
	if(bite_action)
		bite_action.Grant(quirk_holder)

/// post_add fires after the holder is fully spawned with a client
/// attached, so the disclaimer to_chat actually reaches the player.
/// (`add()` runs too early on roundstart — the body doesn't have a
/// client yet, so to_chat there is silently dropped.)
/datum/quirk/starlight_bloodfiend_origins/post_add()
	if(!quirk_holder)
		return
	to_chat(quirk_holder, span_userdanger("Please note that your bloodfiend quirk does NOT give you the right to attack people or otherwise cause any interference to the round. You are not an antagonist, and the rules will treat you the same as other crewmembers."))

/datum/quirk/starlight_bloodfiend_origins/remove()
	if(ishuman(quirk_holder))
		var/mob/living/carbon/human/H = quirk_holder
		REMOVE_TRAIT(H, TRAIT_BLOODFIEND, "quirk_bloodfiend")
		if(cached_eye_color)
			H.eye_color = cached_eye_color
			H.regenerate_icons()
	if(bite_action)
		QDEL_NULL(bite_action)

/// Passive blood drain. Matches the vampire species exactly:
/// `/datum/species/vampire/spec_life` drains 0.25 per Life tick
/// (Life runs at SSmobs's ~2-second cadence) → 0.125 per second.
/// SSquirks ticks at 1-second cadence so a `delta_time = 1` call
/// drains 0.125 — same per-second bleed rate as a vampire.
/datum/quirk/starlight_bloodfiend_origins/on_process(delta_time)
	if(!ishuman(quirk_holder))
		return
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD)
		return
	H.blood_volume = max(0, H.blood_volume - (0.125 * delta_time))

/// Shared panic helper. /turf/open/water/Entered and
/// /datum/reagent/water/expose_mob both route here. The cooldown
/// is on the quirk datum so two hits in the same 5s window don't
/// stack.
/datum/quirk/starlight_bloodfiend_origins/proc/ApplyWaterPanic(sp_hit, jitter_strength, source_label)
	if(!ishuman(quirk_holder))
		return
	if(!COOLDOWN_FINISHED(src, water_panic_cd))
		return
	COOLDOWN_START(src, water_panic_cd, water_panic_cooldown)
	var/mob/living/carbon/human/H = quirk_holder
	if(H.stat == DEAD)
		return
	H.adjustSanityLoss(sp_hit)
	if(jitter_strength > 0)
		H.do_jitter_animation(jitter_strength)
	switch(source_label)
		if("step")
			to_chat(H, span_userdanger("Cold water pulls at your boots. Every nerve in you screams to be anywhere else."))
			H.visible_message(span_warning("[H] convulses, eyes wide, as the water laps around them."))
		if("splash")
			to_chat(H, span_warning("Water on your skin — the bloodfiend in you recoils."))

// ---- Bloodfiend bite action ----
// Modelled on /datum/action/item_action/organ_action/vampire but
// looser: no grab requirement, no garlic/antimagic gates, works on
// corpses, shorter channel + smaller drain.

/datum/action/cooldown/bloodfiend_bite
	name = "Bloodfiend's Bite"
	desc = "Sink your teeth into anyone adjacent and pull a mouthful of their blood. Smaller than the real thing — they can shake you off easily."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/teguicons.dmi'
	button_icon_state = "power_feed"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 20 SECONDS
	/// Back-ref so the action can refuse / restore on quirk removal.
	var/datum/quirk/starlight_bloodfiend_origins/parent_quirk

/datum/action/cooldown/bloodfiend_bite/Trigger()
	if(!IsAvailable())
		return
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	// Must be passively grabbing a carbon victim — same gate the
	// vanilla vampire bite uses. If the pull breaks mid-chain the
	// chain's do_after will fail naturally and the loop will end.
	if(!H.pulling || !iscarbon(H.pulling))
		to_chat(H, span_warning("You need to be pulling someone to bite them."))
		return
	var/mob/living/carbon/victim = H.pulling
	if(H.blood_volume >= BLOOD_VOLUME_MAXIMUM)
		to_chat(H, span_warning("You're already full."))
		return
	if(!victim.blood_volume)
		to_chat(H, span_warning("[victim] has nothing left to give."))
		return
	to_chat(H, span_notice("You sink your teeth into [victim]..."))
	if(victim.stat != DEAD)
		to_chat(victim, span_userdanger("[H] is biting you! Move away to shake them off!"))
	// Chain bite: each successful 1.5-second channel drains another
	// 25 blood and loops back into another channel. Stops on the
	// first do_after that fails (victim moves out of range, dies in
	// a way that interrupts, holder is interrupted) OR when the
	// drink runs dry / the holder caps out.
	var/bites_landed = 0
	while(do_after(H, 15, target = victim))
		if(QDELETED(victim) || QDELETED(H))
			break
		if(H.blood_volume >= BLOOD_VOLUME_MAXIMUM)
			to_chat(H, span_notice("You're full — you pull away."))
			break
		if(!victim.blood_volume)
			to_chat(H, span_notice("[victim] has nothing left to give."))
			break
		var/blood_room = BLOOD_VOLUME_MAXIMUM - H.blood_volume
		var/drained = min(victim.blood_volume, 25, blood_room)
		victim.blood_volume = max(0, victim.blood_volume - drained)
		H.blood_volume = min(BLOOD_VOLUME_MAXIMUM, H.blood_volume + drained)
		playsound(H, 'sound/items/drink.ogg', 30, TRUE, -2)
		if(victim.stat != DEAD)
			to_chat(victim, span_danger("[H] tears [drained] units of blood from you!"))
		to_chat(H, span_notice("You take [drained] units of blood from [victim]."))
		bites_landed++
	if(!bites_landed)
		to_chat(H, span_warning("[victim] shifts free of your bite."))
	StartCooldown()

/datum/action/cooldown/bloodfiend_bite/Destroy()
	parent_quirk = null
	return ..()

// ---- Quiet Insight ----
// Small Curtain Call positive quirk inspired by the Blade Priest's
// "reads what's under your face" gimmick, flavoured generically so
// the priest / Heart / carving motifs aren't named directly. Hook
// is COMSIG_MOB_EXAMINATE on the holder — every time they examine
// another human, they get a private to_chat readout coloured along
// a green→red gradient by the target's sanityhealth/maxSanity
// fraction. The line never enters examine_list, so OOC examiners
// and other observers don't see it.

/datum/quirk/starlight_quiet_insight
	name = "Quiet Insight"
	desc = "You can read what people are carrying without them needing to tell you. When you look at someone, the strain under their skin shows itself to you."
	value = 1
	starlight_locked = TRUE
	starlight_cost = 250
	required_line_completed = "curtain_call"
	medical_record_text = "Subject demonstrates unusual perceptive insight into others' psychological state."
	gain_text = "<span class='notice'>Something behind your attention sharpens. Faces are louder than they used to be.</span>"
	lose_text = "<span class='notice'>The quiet attention recedes. Faces are only faces again.</span>"

/datum/quirk/starlight_quiet_insight/add()
	if(!ishuman(quirk_holder))
		return
	RegisterSignal(quirk_holder, COMSIG_MOB_EXAMINATE, PROC_REF(OnExaminate))

/datum/quirk/starlight_quiet_insight/on_transfer()
	if(ishuman(quirk_holder))
		RegisterSignal(quirk_holder, COMSIG_MOB_EXAMINATE, PROC_REF(OnExaminate))

/datum/quirk/starlight_quiet_insight/remove()
	if(quirk_holder)
		UnregisterSignal(quirk_holder, COMSIG_MOB_EXAMINATE)

/datum/quirk/starlight_quiet_insight/proc/OnExaminate(datum/source, atom/target)
	SIGNAL_HANDLER
	if(!ishuman(target) || target == quirk_holder)
		return
	var/mob/living/carbon/human/H = target
	if(!H.maxSanity)
		return
	var/fraction = H.sanityhealth / H.maxSanity
	var/message
	var/colour
	if(fraction >= 0.95)
		message = "They are quiet inside. Nothing is asking to come out."
		colour = "#4ade80"
	else if(fraction >= 0.75)
		message = "A small unease sits behind their eyes — small enough they may not feel it yet."
		colour = "#a3e635"
	else if(fraction >= 0.5)
		message = "Something in them is straining. The seams are showing through."
		colour = "#facc15"
	else if(fraction >= 0.25)
		message = "They are close to coming apart. You can read what they're trying to keep down."
		colour = "#fb923c"
	else if(fraction > 0)
		message = "Whatever they are holding back is winning. They will not stay this side of it for long."
		colour = "#f87171"
	else
		message = "There is no composure left to read. What was holding them together is already gone."
		colour = "#dc2626"
	to_chat(quirk_holder, "<span style='color:[colour]'>[message]</span>")
