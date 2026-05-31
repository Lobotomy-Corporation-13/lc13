/*
 * Placeholder Starlight Quirks — testing the picker + shop UI loop.
 * No add() / on_spawn() hooks; they attach but do nothing in-game.
 * Replace these with real mechanics once the system is locked in.
 */

// ---- Afterimage Entanglement ----
// Curtain Call reward: two translucent silhouettes that trail one tile
// behind the holder, mirroring the holder's appearance (clothing + held
// items) and copying the holder's last facing each step. Modeled after
// the Mirror Shattered Reaper afterimage with full appearance mirroring
// instead of a fixed icon_state.

/obj/effect/starlight_afterimage
	name = "afterimage"
	desc = "A translucent echo, mimicking someone at half a step behind."
	icon = 'icons/effects/effects.dmi'
	icon_state = ""
	alpha = 90
	color = "#c1a0ff"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE
	var/mob/living/parent_mob
	var/update_timer
	/// Dir the holder was facing when they left this AF's current tile.
	/// Re-applied after every appearance refresh so the gear-update timer
	/// doesn't snap us back to the holder's current facing.
	var/cached_dir = SOUTH

/obj/effect/starlight_afterimage/Initialize(mapload, mob/living/owner)
	. = ..()
	if(!owner)
		return INITIALIZE_HINT_QDEL
	parent_mob = owner
	cached_dir = owner.dir
	forceMove(get_turf(owner))
	UpdateMirror()
	RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(SelfDestruct))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(SelfDestruct))
	// 1s refresh covers gear changes while standing still — the owning quirk
	// repositions us on every step.
	update_timer = addtimer(CALLBACK(src, PROC_REF(UpdateMirror)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/obj/effect/starlight_afterimage/Destroy()
	if(update_timer)
		deltimer(update_timer)
		update_timer = null
	if(parent_mob)
		UnregisterSignal(parent_mob, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
		parent_mob = null
	return ..()

/// Snapshots the holder's full appearance (icon, overlays = clothing/held items,
/// transform, etc.) then re-applies the afterimage-specific visual overrides.
/// `appearance = parent.appearance` also copies dir; we override that with
/// `cached_dir` so the AF keeps the facing it had on its current tile.
/obj/effect/starlight_afterimage/proc/UpdateMirror()
	if(QDELETED(parent_mob))
		return
	appearance = parent_mob.appearance
	name = "afterimage"
	alpha = 90
	color = "#c1a0ff"
	layer = BELOW_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = rand(-8, 8)
	pixel_y = rand(-4, 4)
	setDir(cached_dir)

/obj/effect/starlight_afterimage/proc/SelfDestruct()
	SIGNAL_HANDLER
	qdel(src)

/datum/quirk/starlight_afterimage_entanglement
	name = "Afterimage Entanglement"
	desc = "Two translucent silhouettes trail one step behind you, copying your appearance and last facing each tile they move. Stand still and they catch up onto your tile. Toggleable via an action button."
	value = 8
	starlight_locked = TRUE
	starlight_cost = 500
	required_line_completed = "curtain_call"
	medical_record_text = "Subject's silhouette displays unstable replication artifacts."
	gain_text = "<span class='notice'>Two ghostly echoes settle behind you, mimicking your every step.</span>"
	lose_text = "<span class='notice'>Your trailing silhouettes dissolve.</span>"
	var/list/active_afterimages = list()
	/// Recently-vacated tiles, most recent first. Capped at the AF count (2).
	var/list/tile_history = list()
	/// Holder's dir on each tile in tile_history (parallel list).
	var/list/dir_history = list()
	/// world.time of the last movement signal; the idle re-center is gated
	/// behind a fresh re-check of this so a late-firing timer doesn't
	/// teleport the AFs while the holder is still walking.
	var/last_move_time = 0
	/// 3-second idle timer; firing recenters both afterimages on the holder.
	var/idle_timer
	/// Player-facing on/off; the action button flips this.
	var/enabled = TRUE
	/// HUD toggle that calls ToggleAfterimages().
	var/datum/action/cooldown/starlight_afterimage_toggle/toggle_action

/datum/quirk/starlight_afterimage_entanglement/add()
	if(!toggle_action)
		toggle_action = new(quirk_holder)
		toggle_action.quirk = src
	toggle_action.Grant(quirk_holder)
	if(enabled)
		SpawnAfterimages()

/datum/quirk/starlight_afterimage_entanglement/proc/SpawnAfterimages()
	if(QDELETED(quirk_holder))
		return
	ClearAfterimages()
	for(var/i in 1 to 2)
		var/obj/effect/starlight_afterimage/A = new(get_turf(quirk_holder), quirk_holder)
		active_afterimages += A
	RegisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED, PROC_REF(OnOwnerMoved))

/datum/quirk/starlight_afterimage_entanglement/on_transfer()
	if(toggle_action && quirk_holder)
		toggle_action.Grant(quirk_holder)
	if(enabled)
		SpawnAfterimages()

/datum/quirk/starlight_afterimage_entanglement/remove()
	ClearAfterimages()
	if(toggle_action)
		QDEL_NULL(toggle_action)

/// Flips the on/off state. Off despawns the afterimages and stops listening
/// for movement; on respawns them centered on the holder.
/datum/quirk/starlight_afterimage_entanglement/proc/ToggleAfterimages(mob/user)
	enabled = !enabled
	if(enabled)
		SpawnAfterimages()
		if(user)
			to_chat(user, span_notice("Your trailing silhouettes flicker back into being."))
	else
		ClearAfterimages()
		if(user)
			to_chat(user, span_notice("Your trailing silhouettes melt into nothing."))

/datum/action/cooldown/starlight_afterimage_toggle
	name = "Toggle Afterimages"
	desc = "Dismiss or recall your two trailing afterimages."
	icon_icon = 'icons/hud/guardian.dmi'
	button_icon_state = "manifest"
	cooldown_time = 0
	transparent_when_unavailable = TRUE
	var/datum/quirk/starlight_afterimage_entanglement/quirk

/datum/action/cooldown/starlight_afterimage_toggle/Trigger()
	. = ..()
	if(!. || !quirk)
		return
	quirk.ToggleAfterimages(owner)

/datum/action/cooldown/starlight_afterimage_toggle/Destroy()
	quirk = null
	return ..()

/datum/quirk/starlight_afterimage_entanglement/proc/ClearAfterimages()
	if(quirk_holder)
		UnregisterSignal(quirk_holder, COMSIG_MOVABLE_MOVED)
	if(idle_timer)
		deltimer(idle_timer)
		idle_timer = null
	for(var/obj/effect/starlight_afterimage/A as anything in active_afterimages)
		if(!QDELETED(A))
			qdel(A)
	active_afterimages.Cut()
	tile_history.Cut()
	dir_history.Cut()

/datum/quirk/starlight_afterimage_entanglement/proc/OnOwnerMoved(atom/movable/source, atom/old_loc)
	SIGNAL_HANDLER
	if(!isturf(old_loc))
		return
	tile_history.Insert(1, old_loc)
	// source.dir on a normal step is the dir they turned to before leaving,
	// which is exactly the facing they had on old_loc — what we want.
	dir_history.Insert(1, source.dir)
	if(length(tile_history) > length(active_afterimages))
		tile_history.Cut(length(active_afterimages) + 1)
		dir_history.Cut(length(active_afterimages) + 1)
	last_move_time = world.time
	RepositionAfterimages()
	if(idle_timer)
		deltimer(idle_timer)
	idle_timer = addtimer(CALLBACK(src, PROC_REF(OnIdle)), 3 SECONDS, TIMER_STOPPABLE)

/datum/quirk/starlight_afterimage_entanglement/proc/OnIdle()
	idle_timer = null
	// Defensive: if the holder moved during the 3s window but the timer
	// somehow wasn't cancelled, re-queue for the remaining time instead
	// of teleporting mid-stride.
	var/elapsed = world.time - last_move_time
	if(elapsed < 3 SECONDS)
		var/remaining = (3 SECONDS) - elapsed
		idle_timer = addtimer(CALLBACK(src, PROC_REF(OnIdle)), remaining, TIMER_STOPPABLE)
		return
	CenterOnPlayer()

/// Drops both afterimages onto the holder's current tile — used when they've
/// been stationary long enough that the trail catches up.
/datum/quirk/starlight_afterimage_entanglement/proc/CenterOnPlayer()
	if(QDELETED(quirk_holder))
		return
	var/turf/T = get_turf(quirk_holder)
	if(!T)
		return
	tile_history.Cut()
	dir_history.Cut()
	for(var/obj/effect/starlight_afterimage/A as anything in active_afterimages)
		if(QDELETED(A))
			continue
		A.cached_dir = quirk_holder.dir
		A.forceMove(T)
		A.UpdateMirror()

/// Spreads the afterimages across the most-recent tile history so they never
/// share a square once enough movement has happened to fill the history.
/datum/quirk/starlight_afterimage_entanglement/proc/RepositionAfterimages()
	if(QDELETED(quirk_holder) || !length(tile_history))
		return
	for(var/i in 1 to length(active_afterimages))
		var/obj/effect/starlight_afterimage/A = active_afterimages[i]
		if(QDELETED(A))
			continue
		var/turf/dest = (i <= length(tile_history)) ? tile_history[i] : tile_history[length(tile_history)]
		var/historical_dir = (i <= length(dir_history)) ? dir_history[i] : dir_history[length(dir_history)]
		if(!isturf(dest))
			continue
		A.cached_dir = historical_dir
		A.forceMove(dest)
		A.UpdateMirror()

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
	value = 8
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
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	)
	if(!H.equip_in_one_of_slots(holder, slots, qdel_on_fail = FALSE))
		holder.forceMove(get_turf(H))

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
	value = 2
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
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	)
	if(!H.equip_in_one_of_slots(bouquet, slots, qdel_on_fail = FALSE))
		bouquet.forceMove(get_turf(H))

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
	value = 4
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
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	)
	if(!H.equip_in_one_of_slots(launcher, slots, qdel_on_fail = FALSE))
		launcher.forceMove(get_turf(H))
