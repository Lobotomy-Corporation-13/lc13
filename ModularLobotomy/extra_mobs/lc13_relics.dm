// ==========================================================
// Ruin Relics - Strange artifacts from the city ruins
// ==========================================================

// ==================== BASE RELIC ====================

/// Strange tools and objects from ruins that hold almost magical effects.
/obj/item/ruin_relic
	name = "???"
	desc = "A curious object recovered from the city's ruins. It hums with a faint, unknowable energy."
	icon = 'ModularLobotomy/_Lobotomyicons/ruin_relics.dmi'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_POCKETS
	/// Rarity tier from 1 (common) to 5 (legendary)
	var/rarity = 1
	/// Whether the holder is currently in combat (set TRUE on attack, expires after 30s)
	var/in_combat = FALSE
	/// Timer ID for combat expiry
	var/combat_timer
	/// Paper note attached to this relic
	var/obj/item/paper/attached_note
	/// Cached note overlay for removal
	var/mutable_appearance/note_overlay
	/// The mob attuned to this relic, identified by tag (only they can use its powers)
	var/attuned_mob_tag
	/// Quick check flag for attunement
	var/attuned = FALSE
	/// Generic tracked mob tag — subtypes can use this for their primary tracked human
	var/tracked_mob_tag
	/// WHITE damage dealt on failed attunement attempt (overridden per relic)
	var/attunement_fail_damage = 5
	/// Global tracker: how many relics each mob is attuned to (mob tag -> count)
	var/static/list/attunement_counts = list()
	/// Maximum number of relics a single person can be attuned to
	var/static/max_attunements = 2
	/// world.time when the attunement cooldown expires (set on fail)
	var/attunement_cooldown_end = 0
	/// Debug mode — skips attunement conditions, allowing anyone to attune
	var/debug_attune = FALSE

/obj/item/ruin_relic/Destroy()
	Unattune()
	if(attached_note)
		QDEL_NULL(attached_note)
	return ..()

/obj/item/ruin_relic/Initialize()
	. = ..()
	// Pulsing outline glow colored by the relic's average icon color
	var/glow_color = GetAverageColor(src)
	if(glow_color)
		glow_color += "30" // Append low alpha
		add_filter("relic_glow", 2, list("type" = "outline", "color" = glow_color, "size" = 2))
		addtimer(CALLBACK(src, PROC_REF(GlowLoop)), rand(1, 19))

/// Animate the relic's outline glow pulsing in and out.
/obj/item/ruin_relic/proc/GlowLoop()
	var/filter = get_filter("relic_glow")
	if(filter)
		animate(filter, alpha = 110, time = 15, loop = -1)
		animate(alpha = 40, time = 25)

/obj/item/ruin_relic/examine(mob/user)
	. = ..()
	. += span_notice("You could label this with a pen.")
	if(attached_note)
		. += span_notice("There is a note attached. Use wirecutters to remove it.")
		if(in_range(user, src) && user.can_read(attached_note))
			attached_note.ui_interact(user)
	// Attunement status
	if(!attuned)
		. += span_notice("It hums with dormant energy. Use it in your hand to attempt attunement.")
	else if(attuned_mob_tag == user.tag)
		. += span_notice("It resonates with your essence. <a href='?src=[REF(src)];break_attune=1'>Break Attunement</a>")
	else
		. += span_warning("It is bound to another. It will not respond to you.")

/obj/item/ruin_relic/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/pen))
		var/new_name = stripped_input(user, "What do you want to label this relic?", name)
		if(!new_name)
			return
		if(!Adjacent(user))
			return
		name = new_name
		to_chat(user, span_notice("You label the relic: [new_name]."))
		return
	if(istype(I, /obj/item/paper))
		if(attached_note)
			to_chat(user, span_warning("There's already a note attached to [src]."))
			return
		if(!user.transferItemToLoc(I, src))
			to_chat(user, span_warning("You can't attach [I] to [src]."))
			return
		attached_note = I
		user.visible_message(span_notice("[user] attaches [I] to [src]."), span_notice("You attach [I] to [src]."))
		UpdateNoteOverlay()
		return
	if(I.tool_behaviour == TOOL_WIRECUTTER && attached_note)
		user.visible_message(span_notice("[user] removes the note from [src]."), span_notice("You remove the note from [src]."))
		attached_note.forceMove(user.drop_location())
		if(user.can_hold_items())
			user.put_in_hands(attached_note)
		attached_note = null
		UpdateNoteOverlay()
		return
	return ..()

/obj/item/ruin_relic/Topic(href, href_list)
	. = ..()
	if(.)
		return
	if(href_list["break_attune"])
		if(!attuned || attuned_mob_tag != usr.tag)
			return
		if(!ishuman(usr) || !Adjacent(usr))
			return
		playsound(get_turf(src), 'sound/machines/click.ogg', 25, TRUE)
		to_chat(usr, span_notice("You sever your connection to [src]. It grows cold in your hands."))
		Unattune()

/// Updates the paper note overlay on the relic.
/obj/item/ruin_relic/proc/UpdateNoteOverlay()
	if(note_overlay)
		cut_overlay(note_overlay)
		note_overlay = null
	if(attached_note)
		note_overlay = mutable_appearance('icons/obj/bureaucracy.dmi', "paper")
		note_overlay.pixel_x = 5
		note_overlay.pixel_y = 5
		note_overlay.transform = note_overlay.transform.Scale(0.5, 0.5)
		add_overlay(note_overlay)

/obj/item/ruin_relic/equipped(mob/user, slot, initial)
	. = ..()
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnHolderAttack))

/obj/item/ruin_relic/dropped(mob/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_ITEM_ATTACK)
	in_combat = FALSE
	if(combat_timer)
		deltimer(combat_timer)
		combat_timer = null

// ==================== ATTUNEMENT SYSTEM ====================

/// Attempt to attune a user to this relic. Returns TRUE only if already attuned to this user (proceed with power).
/obj/item/ruin_relic/proc/TryAttune(mob/living/carbon/human/user)
	if(attuned)
		if(attuned_mob_tag == user.tag)
			return TRUE
		to_chat(user, span_warning("[src] is bound to another. It will not respond to you."))
		return FALSE
	// Check cooldown from previous failure
	if(world.time < attunement_cooldown_end)
		var/remaining = round((attunement_cooldown_end - world.time) / 10)
		to_chat(user, span_warning("[src] is still rejecting you. Wait [remaining] seconds."))
		return FALSE
	// Check attunement cap
	var/key = user.tag
	if(attunement_counts[key] >= max_attunements)
		to_chat(user, span_warning("You are already attuned to too many relics. Break an existing attunement first."))
		return FALSE
	if(debug_attune || CheckAttunement(user))
		OnAttuneSuccess(user)
	else
		OnAttuneFail(user)
	return FALSE

/// Override per relic. Returns TRUE if the user meets the attunement condition.
/obj/item/ruin_relic/proc/CheckAttunement(mob/living/carbon/human/user)
	return TRUE

/// Called when attunement succeeds. Sets vars, plays sound, registers death signal.
/obj/item/ruin_relic/proc/OnAttuneSuccess(mob/living/carbon/human/user)
	attuned = TRUE
	attuned_mob_tag = user.tag
	// Track attunement count
	var/key = user.tag
	attunement_counts[key] = (attunement_counts[key] || 0) + 1
	playsound(get_turf(src), 'sound/magic/staff_healing.ogg', 30, TRUE)
	to_chat(user, span_notice("[src] resonates with your essence. You are now attuned."))

/// Override per relic. Called when attunement fails. Deals damage, gives a hint, and starts cooldown.
/obj/item/ruin_relic/proc/OnAttuneFail(mob/living/carbon/human/user)
	playsound(get_turf(src), 'sound/machines/buzz-sigh.ogg', 30, TRUE)
	user.deal_damage(attunement_fail_damage, WHITE_DAMAGE)
	attunement_cooldown_end = world.time + 2 MINUTES

/// Returns TRUE if the given mob is attuned to this relic.
/obj/item/ruin_relic/proc/IsAttuned(mob/living/user)
	return attuned && attuned_mob_tag == user.tag

/// Clears attunement state.
/obj/item/ruin_relic/proc/Unattune()
	if(attuned_mob_tag)
		// Decrement attunement count
		if(attunement_counts[attuned_mob_tag])
			attunement_counts[attuned_mob_tag]--
			if(attunement_counts[attuned_mob_tag] <= 0)
				attunement_counts -= attuned_mob_tag
	attuned = FALSE
	attuned_mob_tag = null

// ==================== RAVENOUS VESSEL ====================

/// Ravenous Vessel - A sentient cauldron fed with organic matter to charge blood stacks.
/// Use in hand with different intents to trigger effects scaled by blood.
/// GRAB = Bubble (Offense Level Up), DISARM = Puff (BLACK damage AoE + smoke), HARM = Shock (electrocution over 3s).
/// Backfire chance scales with blood level (+25% if visibly bloody). Backfire includes the user in the effect.
/// All blood is consumed on use.
/obj/item/ruin_relic/ravenous_vessel
	name = "???"
	desc = "A small cauldron-like vessel with a stern face etched into its surface. Its eyes seem to follow you, and you swear the mouth twitches when you look away."
	icon_state = "oddity3"
	rarity = 2
	attunement_fail_damage = 10
	/// Current blood stacks. Gained by feeding, consumed on use.
	var/blood = 0
	/// Whether the vessel is visibly bloody (removed by washing)
	var/bloody = FALSE
	/// Bloody overlay appearance
	var/mutable_appearance/bloody_overlay
	/// Whether the vessel is currently consuming something
	var/consuming = FALSE
	/// Whether the vessel is currently performing an effect
	var/performing = FALSE
	/// Maximum blood stacks
	var/max_blood = 20
	/// Blood gained from feeding meat/food
	var/feed_meat = 1
	/// Blood gained from feeding organs
	var/feed_organ = 3

/obj/item/ruin_relic/ravenous_vessel/Initialize()
	. = ..()
	bloody_overlay = mutable_appearance(icon, "oddity3_bloody")

/obj/item/ruin_relic/ravenous_vessel/Destroy()
	bloody_overlay = null
	return ..()

/obj/item/ruin_relic/ravenous_vessel/CheckAttunement(mob/living/carbon/human/user)
	var/obj/item/other = user.get_inactive_held_item()
	return istype(other, /obj/item/food) || istype(other, /obj/item/organ)

/obj/item/ruin_relic/ravenous_vessel/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The vessel's face sneers. It hungers — show it something to eat."))
	user.apply_lc_bleed(3)
	to_chat(user, span_userdanger("The vessel bites down on your hand, drawing blood!"))

/obj/item/ruin_relic/ravenous_vessel/examine(mob/user)
	. = ..()
	if(blood > 0)
		. += span_notice("Its face is beaming with delight. It has [blood] blood stored.")
	else
		. += span_warning("Its stern face stares at you expectantly. You sense it wants something.")
	if(blood >= max_blood)
		. += span_boldwarning("It looks dangerously overfull. Crimson light pulses from within.")

// ==================== ICON MANAGEMENT ====================

/// Updates the resting icon_state based on blood and bloody status
/obj/item/ruin_relic/ravenous_vessel/proc/UpdateIcon()
	// Resting state: gleeful if has blood, default otherwise
	icon_state = blood > 0 ? "oddity3_glee" : "oddity3"
	// Bloody overlay
	if(bloody)
		if(!(bloody_overlay in overlays))
			add_overlay(bloody_overlay)
	else
		cut_overlay(bloody_overlay)

/obj/item/ruin_relic/ravenous_vessel/wash(clean_types)
	. = ..()
	if(bloody)
		bloody = FALSE
		cut_overlay(bloody_overlay)
		return TRUE

// ==================== FEEDING ====================

/obj/item/ruin_relic/ravenous_vessel/attackby(obj/item/I, mob/user, params)
	if(consuming || performing)
		to_chat(user, span_warning("[src] is busy!"))
		return
	if(blood >= max_blood)
		to_chat(user, span_warning("[src] is already full!"))
		return
	var/feed_amount = 0
	if(istype(I, /obj/item/organ))
		feed_amount = feed_organ
	else if(istype(I, /obj/item/bodypart))
		feed_amount = feed_organ
	else if(istype(I, /obj/item/food))
		feed_amount = feed_meat
	if(feed_amount)
		Feed(I, user, feed_amount)
		return
	return ..()

/obj/item/ruin_relic/ravenous_vessel/attack(mob/living/M, mob/living/user)
	if(!IsAttuned(user))
		return ..()
	if(consuming || performing)
		to_chat(user, span_warning("[src] is busy!"))
		return
	if(blood >= max_blood)
		to_chat(user, span_warning("[src] is already full!"))
		return
	if(iscarbon(M))
		to_chat(user, span_warning("[src] has no interest in that."))
		return
	if(M.stat == DEAD)
		FeedCorpse(M, user)
		return
	return ..()

/// Feeds an item to the vessel, gaining blood stacks
/obj/item/ruin_relic/ravenous_vessel/proc/Feed(obj/item/meal, mob/user, feed_amount)
	consuming = TRUE
	user.visible_message(
		span_warning("[user] shoves [meal] into [src]!"),
		span_notice("You feed [meal] to [src].")
	)
	playsound(src, 'sound/items/eatfood.ogg', 50, TRUE)
	flick("oddity3_consume", src)
	qdel(meal)
	addtimer(CALLBACK(src, PROC_REF(FinishFeeding), feed_amount), 2.5 SECONDS)

/// Feeds a corpse to the vessel for more blood stacks
/obj/item/ruin_relic/ravenous_vessel/proc/FeedCorpse(mob/living/corpse, mob/user)
	consuming = TRUE
	user.visible_message(
		span_boldwarning("[src] opens wide and devours [corpse]!"),
		span_notice("You offer [corpse] to [src]. It eagerly consumes the remains.")
	)
	playsound(src, 'sound/items/eatfood.ogg', 100, TRUE)
	flick("oddity3_consume", src)
	corpse.gib()
	addtimer(CALLBACK(src, PROC_REF(FinishFeeding), feed_organ), 2.5 SECONDS)

/// Called after the consume animation finishes
/obj/item/ruin_relic/ravenous_vessel/proc/FinishFeeding(feed_amount)
	blood = min(blood + feed_amount, max_blood)
	bloody = TRUE
	consuming = FALSE
	// Red sparkles on the relic
	var/obj/effect/temp_visual/sparkles/S = new /obj/effect/temp_visual/sparkles(get_turf(src))
	S.color = "#960000"
	UpdateIcon()

// ==================== ACTIVATION ====================

/obj/item/ruin_relic/ravenous_vessel/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	if(consuming || performing)
		to_chat(user, span_warning("[src] is busy!"))
		return
	if(blood <= 0)
		to_chat(user, span_warning("[src] stares at you blankly. It has nothing to give."))
		return
	switch(user.a_intent)
		if(INTENT_HELP)
			return
		if(INTENT_GRAB)
			ActivateBubble(user)
		if(INTENT_DISARM)
			ActivatePuff(user)
		if(INTENT_HARM)
			ActivateShock(user)

/// Returns TRUE if the effect backfires. Chance scales with blood, +25% if bloody.
/obj/item/ruin_relic/ravenous_vessel/proc/CheckBackfire(stored_blood)
	var/chance = (stored_blood / max_blood) * 100
	if(bloody)
		chance += 25
	return prob(chance)

/// Consumes all blood and returns to default state after an effect
/obj/item/ruin_relic/ravenous_vessel/proc/FinishEffect()
	blood = 0
	performing = FALSE
	UpdateIcon()

// ==================== BUBBLE - BUFF ====================

/// Bubble effect (GRAB intent): Grants Offense Level Up scaled by blood.
/// Higher blood increases chance of backfire that also damages the user.
/obj/item/ruin_relic/ravenous_vessel/proc/ActivateBubble(mob/living/user)
	performing = TRUE
	var/stored_blood = blood
	var/backfire = CheckBackfire(stored_blood)
	flick("oddity3_bubble", src)
	user.visible_message(
		span_notice("[src] bubbles with crimson energy around [user]!"),
		span_notice("[src] releases a surge of empowering energy!")
	)
	addtimer(CALLBACK(src, PROC_REF(ApplyBubbleEffect), user, stored_blood, backfire), 1.6 SECONDS)

/// Applied after the bubble animation finishes
/obj/item/ruin_relic/ravenous_vessel/proc/ApplyBubbleEffect(mob/living/user, stored_blood, backfire)
	if(!QDELETED(user))
		user.apply_lc_offense_level_up(round(max(1, stored_blood * 1.5)))
		to_chat(user, span_notice("Power surges through you from [src]!"))
		// Crimson sparkles on the buffed user
		var/obj/effect/temp_visual/sparkles/S = new /obj/effect/temp_visual/sparkles(get_turf(user))
		S.color = "#960000"
		if(backfire)
			user.deal_damage(round(stored_blood * 1.5), RED_DAMAGE, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_STATUS)
			to_chat(user, span_userdanger("[src]'s excess energy tears into your flesh!"))
			flash_color(user, flash_color = "#960000", flash_time = 15)
			do_sparks(3, FALSE, user)
	FinishEffect()

// ==================== PUFF - AREA DEBUFF ====================

/// Puff effect (DISARM intent): Deals BLACK damage to nearby enemies scaled by blood.
/// Higher blood increases chance of backfire that also damages the user.
/obj/item/ruin_relic/ravenous_vessel/proc/ActivatePuff(mob/living/user)
	performing = TRUE
	var/stored_blood = blood
	var/backfire = CheckBackfire(stored_blood)
	flick("oddity3_puff", src)
	user.visible_message(
		span_boldwarning("[src] spews a cloud of thick black smoke!"),
		span_warning("You unleash [src]'s black smoke!")
	)
	addtimer(CALLBACK(src, PROC_REF(ApplyPuffEffect), user, stored_blood, backfire), 1.5 SECONDS)

/// Applied after the puff animation finishes
/obj/item/ruin_relic/ravenous_vessel/proc/ApplyPuffEffect(mob/living/user, stored_blood, backfire)
	var/turf/center = get_turf(src)
	if(!center)
		FinishEffect()
		return
	// Spread actual smoke — radius scales with blood
	var/smoke_radius = max(2, round(stored_blood * 0.4))
	var/datum/effect_system/smoke_spread/bad/smoke = new
	smoke.set_up(smoke_radius, center)
	smoke.start()
	qdel(smoke)
	var/puff_damage = round(stored_blood * 2.5)
	for(var/mob/living/L in range(3, center))
		if(L == user && !backfire)
			continue
		L.deal_damage(puff_damage, BLACK_DAMAGE, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_STATUS)
		to_chat(L, span_warning("Black smoke from [src] burns into you!"))
	if(backfire && !QDELETED(user))
		to_chat(user, span_userdanger("The smoke is too thick — it chokes you too!"))
		flash_color(user, flash_color = "#1a1a2e", flash_time = 20)
	FinishEffect()

// ==================== SHOCK - BURST DAMAGE ====================

/// Shock effect (HARM intent): Deals periodic RED damage over 3 seconds scaled by blood.
/// Higher blood increases chance of backfire that also damages the user.
/obj/item/ruin_relic/ravenous_vessel/proc/ActivateShock(mob/living/user)
	performing = TRUE
	var/stored_blood = blood
	var/backfire = CheckBackfire(stored_blood)
	icon_state = "oddity3_shock"
	playsound(get_turf(src), 'sound/magic/lightningshock.ogg', 75, TRUE)
	user.visible_message(
		span_userdanger("[src] erupts with arcs of electricity!"),
		span_danger("You channel [src]'s stored energy into a violent discharge!")
	)
	// 3 shock ticks over 3 seconds (at 0s, 1s, 2s), effect ends at 3s
	var/shock_damage = round(stored_blood * 1.5)
	ApplyShockTick(user, shock_damage, backfire, stored_blood)
	addtimer(CALLBACK(src, PROC_REF(ApplyShockTick), user, shock_damage, backfire, stored_blood), 1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(ApplyShockTick), user, shock_damage, backfire, stored_blood), 2 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(FinishShock)), 3 SECONDS)

/// Single tick of shock damage to nearby enemies
/obj/item/ruin_relic/ravenous_vessel/proc/ApplyShockTick(mob/living/user, shock_damage, backfire, stored_blood)
	var/turf/center = get_turf(src)
	if(!center)
		return
	do_sparks(3, FALSE, src)
	for(var/mob/living/L in range(3, center))
		if(L == user && !backfire)
			continue
		var/distance = get_dist(center, L)
		var/final_damage = max(1, shock_damage - (distance * 2))
		if(iscarbon(L))
			var/mob/living/carbon/C = L
			if(C.electrocute_act(final_damage, src, 1, SHOCK_NOGLOVES | SHOCK_NOSTUN))
				if(stored_blood >= 10)
					C.dropItemToGround(C.get_active_held_item())
					C.dropItemToGround(C.get_inactive_held_item())
				C.add_confusion(15)
		else
			L.electrocute_act(final_damage, src, 1, SHOCK_NOSTUN)
		do_sparks(2, FALSE, L)
	if(backfire && !QDELETED(user))
		shake_camera(user, 3, 2)

/// Called after the 3 second shock duration ends
/obj/item/ruin_relic/ravenous_vessel/proc/FinishShock()
	icon_state = "oddity3"
	FinishEffect()

// ==========================================================
// Golden Locket - Empathic tracking relic
// ==========================================================

/// Golden Locket - Links to a carbon human and tracks their health, sanity, location, and direction.
/// While open, creates an empathic bond that shares a % of the target's damage as WHITE damage to the holder.
/// Bond strength ramps +5% every 60s (cap 50%). After 5 minutes, becomes NODROP and drains sanity.
/// If the linked target dies while open, kills the holder, fully revives the target, and shatters the locket.
/obj/item/ruin_relic/golden_locket
	name = "???"
	desc = "An ornate golden locket with fine engravings worn smooth by age. It feels warm to the touch, as though something inside is still breathing."
	icon_state = "locket"
	w_class = WEIGHT_CLASS_SMALL
	rarity = 3
	attunement_fail_damage = 15
	/// The carbon human we're tracking
	var/mob/living/carbon/human/linked_target
	/// Whether the locket is currently open
	var/is_open = FALSE
	/// How long the locket has been open (deciseconds)
	var/open_duration = 0
	/// Maximum safe open duration before NODROP + sanity drain (5 minutes)
	var/max_safe_duration = 3000
	/// Current damage share percentage (starts at 5, ramps +5 every 60s, caps at 50)
	var/damage_share_percent = 5
	/// Deciseconds between damage share ramp-ups
	var/damage_ramp_interval = 600
	/// open_duration when we last ramped damage share
	var/last_damage_ramp = 0
	/// open_duration when we last sent a whisper
	var/last_whisper = 0
	/// Whether NODROP has been applied
	var/bond_locked = FALSE
	/// Whether the locket has shattered (unuseable)
	var/shattered = FALSE

/obj/item/ruin_relic/golden_locket/Destroy()
	if(linked_target)
		UnregisterSignal(linked_target, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_LIVING_DEATH))
		linked_target = null
	STOP_PROCESSING(SSobj, src)
	return ..()

// ==================== EXAMINE ====================

/obj/item/ruin_relic/golden_locket/examine(mob/user)
	. = ..()
	if(shattered)
		. += span_warning("It is cracked beyond repair. Whatever power it held is gone.")
		return
	if(!linked_target)
		. += span_notice("The locket is empty. Touch it to someone to create a link.")
		return
	. += span_notice("The locket is linked to [linked_target].")
	if(!is_open)
		. += span_notice("Open it to track them.")
		return
	// --- Tracking display while open ---
	// Health
	var/health_percent = round((linked_target.health / linked_target.maxHealth) * 100)
	var/health_color = "#00cc00"
	if(health_percent < 30)
		health_color = "#cc0000"
	else if(health_percent < 60)
		health_color = "#cc8800"
	. += span_notice("Health: <font color='[health_color]'>[health_percent]%</font>")
	// Sanity
	var/sanity_percent = round((linked_target.sanityhealth / linked_target.maxSanity) * 100)
	var/sanity_color = "#00cc00"
	if(sanity_percent < 30)
		sanity_color = "#cc0000"
	else if(sanity_percent < 60)
		sanity_color = "#cc8800"
	. += span_notice("Sanity: <font color='[sanity_color]'>[sanity_percent]%</font>")
	// Status
	switch(linked_target.stat)
		if(CONSCIOUS)
			. += span_notice("Status: Conscious")
		if(UNCONSCIOUS)
			. += span_boldwarning("Status: Unconscious")
		if(DEAD)
			. += span_userdanger("Status: DEAD")
	// Location and direction
	var/turf/user_turf = get_turf(user)
	var/turf/target_turf = get_turf(linked_target)
	if(!user_turf || !target_turf)
		. += span_warning("Location: Unknown")
	else if(user_turf.z != target_turf.z)
		. += span_warning("Location: Different level")
	else
		var/distance = get_dist(user_turf, target_turf)
		if(distance == 0)
			. += span_notice("Distance: Right here")
		else
			var/dist_text = "Far"
			if(distance <= 8)
				dist_text = "Close"
			else if(distance <= 16)
				dist_text = "Medium"
			. += span_notice("Distance: [dist_text] ([distance] tiles)")
			. += span_notice("Direction: [dir2text(get_dir(user_turf, target_turf))]")
		var/area/target_area = get_area(linked_target)
		if(target_area)
			. += span_notice("Area: [target_area.name]")
	// Bond warning
	if(damage_share_percent > 5)
		. += span_warning("Empathic bond: sharing [damage_share_percent]% of their pain.")
	if(bond_locked)
		. += span_boldwarning("The locket has fused to your hand. Close it to break free.")

/obj/item/ruin_relic/golden_locket/CheckAttunement(mob/living/carbon/human/user)
	// Must have another living human adjacent
	for(var/mob/living/carbon/human/H in range(1, user))
		if(H != user && H.stat != DEAD)
			return TRUE
	return FALSE

/obj/item/ruin_relic/golden_locket/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The locket remains cold. It yearns for a bond — bring someone close."))
	// Lash out at the nearest adjacent human — punishing the failed bond
	for(var/mob/living/carbon/human/H in range(1, user))
		if(H == user || H.stat == DEAD)
			continue
		H.deal_damage(10, WHITE_DAMAGE)
		to_chat(H, span_userdanger("A wave of cold loneliness washes over you from [src]."))
		break

// ==================== LINKING ====================

/obj/item/ruin_relic/golden_locket/attack(mob/living/M, mob/living/user)
	if(!IsAttuned(user))
		return ..()
	if(shattered)
		to_chat(user, span_warning("[src] is shattered. It no longer responds."))
		return
	if(!ishuman(M))
		to_chat(user, span_warning("[src] doesn't react to [M]."))
		return
	if(linked_target == M)
		to_chat(user, span_notice("[src] is already linked to [M]."))
		return
	// Unlink previous target
	if(linked_target)
		UnregisterSignal(linked_target, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_LIVING_DEATH))
	// Link new target
	linked_target = M
	RegisterSignal(linked_target, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnTargetDamaged))
	RegisterSignal(linked_target, COMSIG_LIVING_DEATH, PROC_REF(OnTargetDeath))
	user.visible_message(
		span_notice("[user] touches [M] with [src]. It glows briefly."),
		span_notice("You link [src] to [M]. A faint image appears inside the locket.")
	)
	var/obj/effect/temp_visual/sparkles/S = new /obj/effect/temp_visual/sparkles(get_turf(M))
	S.color = "#FFD700"
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)

// ==================== OPEN / CLOSE ====================

/obj/item/ruin_relic/golden_locket/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	if(shattered)
		to_chat(user, span_warning("[src] is shattered. It no longer responds."))
		return
	if(!linked_target)
		to_chat(user, span_notice("[src] is empty. You need to link it to someone first."))
		return
	if(is_open)
		CloseLocket(user)
	else
		OpenLocket(user)

/// Opens the locket and begins tracking + empathic bond processing
/obj/item/ruin_relic/golden_locket/proc/OpenLocket(mob/living/user)
	is_open = TRUE
	icon_state = "locket_open"
	w_class = WEIGHT_CLASS_BULKY
	user.visible_message(
		span_notice("[user] opens [src], revealing a small portrait inside."),
		span_notice("You open [src]. A faint warmth spreads through your fingers.")
	)
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	START_PROCESSING(SSobj, src)

/// Closes the locket, resets bond strength, and stops processing
/obj/item/ruin_relic/golden_locket/proc/CloseLocket(mob/living/user)
	is_open = FALSE
	icon_state = "locket"
	w_class = WEIGHT_CLASS_SMALL
	open_duration = 0
	damage_share_percent = 5
	last_damage_ramp = 0
	last_whisper = 0
	if(bond_locked)
		bond_locked = FALSE
		REMOVE_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	user.visible_message(
		span_notice("[user] closes [src] with a soft click."),
		span_notice("You close [src]. The warmth fades.")
	)
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	STOP_PROCESSING(SSobj, src)

/obj/item/ruin_relic/golden_locket/dropped(mob/user)
	. = ..()
	if(is_open && !bond_locked)
		is_open = FALSE
		icon_state = "locket"
		w_class = WEIGHT_CLASS_SMALL
		open_duration = 0
		damage_share_percent = 5
		last_damage_ramp = 0
		last_whisper = 0
		STOP_PROCESSING(SSobj, src)

// ==================== PROCESSING ====================

/obj/item/ruin_relic/golden_locket/process(delta_time)
	// Target gone — clean up
	if(!linked_target || QDELETED(linked_target))
		if(linked_target)
			UnregisterSignal(linked_target, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_LIVING_DEATH))
			linked_target = null
		var/mob/living/holder = GetHandHolder()
		if(holder)
			CloseLocket(holder)
		else
			// No holder — force close state
			is_open = FALSE
			icon_state = "locket"
			w_class = WEIGHT_CLASS_SMALL
			open_duration = 0
			damage_share_percent = 5
			last_damage_ramp = 0
			last_whisper = 0
			bond_locked = FALSE
			REMOVE_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
			STOP_PROCESSING(SSobj, src)
		return
	if(!is_open)
		STOP_PROCESSING(SSobj, src)
		return
	// Track open time (delta_time in seconds, open_duration in deciseconds)
	open_duration += delta_time * 10
	var/mob/living/carbon/human/holder = GetHandHolder()
	// Ramp damage share every interval
	if(open_duration - last_damage_ramp >= damage_ramp_interval)
		last_damage_ramp = open_duration
		damage_share_percent = min(damage_share_percent + 5, 50)
		if(holder)
			to_chat(holder, span_warning("[src] grows warmer in your hands. The connection deepens."))
			flash_color(holder, flash_color = "#FFD700", flash_time = 10)
	// NODROP + sanity drain at max duration
	if(open_duration >= max_safe_duration)
		if(!bond_locked)
			bond_locked = TRUE
			ADD_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
			if(holder)
				to_chat(holder, span_userdanger("[src] fuses to your hand! The bond is overwhelming!"))
				flash_color(holder, flash_color = "#960000", flash_time = 20)
		if(holder)
			holder.adjustSanityLoss(2 * delta_time)
	// Periodic whisper every ~10 seconds
	if(holder && open_duration - last_whisper >= 100)
		last_whisper = open_duration
		SendWhisper(holder)

/// Returns the mob currently holding the locket in hand, or null
/obj/item/ruin_relic/golden_locket/proc/GetHandHolder()
	var/mob/living/carbon/human/holder = get_atom_on_turf(src, /mob/living/carbon/human)
	if(istype(holder) && (src in holder.held_items))
		return holder
	return null

/// Sends a short directional whisper to the holder
/obj/item/ruin_relic/golden_locket/proc/SendWhisper(mob/living/holder)
	if(!linked_target)
		return
	if(linked_target.stat == DEAD)
		to_chat(holder, span_warning("[src] whispers: [linked_target] — gone..."))
		return
	var/turf/holder_turf = get_turf(holder)
	var/turf/target_turf = get_turf(linked_target)
	if(!holder_turf || !target_turf)
		to_chat(holder, span_warning("[src] whispers: [linked_target] — unknown."))
		return
	if(holder_turf.z != target_turf.z)
		to_chat(holder, span_warning("[src] whispers: [linked_target] — beyond your reach."))
		return
	var/distance = get_dist(holder_turf, target_turf)
	if(distance == 0)
		to_chat(holder, span_warning("[src] whispers: [linked_target] — right here."))
		return
	var/direction = dir2text(get_dir(holder_turf, target_turf))
	to_chat(holder, span_warning("[src] whispers: [linked_target] — [direction], [distance] tiles away."))

// ==================== EMPATHIC BOND ====================

/// Signal handler: when the linked target takes damage, share a portion as WHITE damage to the holder
/obj/item/ruin_relic/golden_locket/proc/OnTargetDamaged(mob/living/target, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!is_open)
		return
	var/mob/living/holder = GetHandHolder()
	if(!holder || holder == target)
		return
	var/shared_damage = damage * (damage_share_percent / 100)
	if(shared_damage <= 0)
		return
	holder.deal_damage(shared_damage, WHITE_DAMAGE, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_STATUS)
	to_chat(holder, span_warning("You feel [linked_target]'s pain through [src]!"))
	if(damage_share_percent >= 25)
		flash_color(holder, flash_color = "#FFD700", flash_time = 5)
	if(damage_share_percent >= 40)
		do_sparks(2, FALSE, holder)

// ==================== DEATH SWAP ====================

/// Signal handler: when the linked target dies while the locket is open, kill the holder and revive the target
/obj/item/ruin_relic/golden_locket/proc/OnTargetDeath(mob/living/target, gibbed)
	SIGNAL_HANDLER
	if(!is_open || shattered)
		return
	var/mob/living/carbon/human/holder = GetHandHolder()
	if(!holder || holder == target)
		return
	// Schedule the swap — signal handlers can't sleep
	INVOKE_ASYNC(src, PROC_REF(PerformDeathSwap), holder, target)

/// Performs the death swap: kills the holder, revives the target, shatters the locket
/obj/item/ruin_relic/golden_locket/proc/PerformDeathSwap(mob/living/carbon/human/holder, mob/living/carbon/human/target)
	// Dramatic message
	holder.visible_message(
		span_userdanger("[src] erupts with blinding golden light! [holder]'s life drains away!"),
		span_userdanger("[src] tears your life from your body to save [target]!")
	)
	flash_color(holder, flash_color = "#FFD700", flash_time = 30)
	playsound(src, 'sound/magic/lightningshock.ogg', 100, TRUE)
	do_sparks(5, FALSE, holder)
	// Gold sparkles on both
	var/obj/effect/temp_visual/sparkles/S1 = new /obj/effect/temp_visual/sparkles(get_turf(holder))
	S1.color = "#FFD700"
	var/obj/effect/temp_visual/sparkles/S2 = new /obj/effect/temp_visual/sparkles(get_turf(target))
	S2.color = "#FFD700"
	// Kill the holder
	holder.death()
	// Revive the target
	target.revive(full_heal = TRUE)
	target.visible_message(
		span_notice("[target] gasps back to life, pulled from the brink by [src]!"),
		span_notice("Warmth floods back into you. Someone gave their life for yours.")
	)
	// Shatter the locket
	Shatter()

/// Shatters the locket, making it permanently unuseable
/obj/item/ruin_relic/golden_locket/proc/Shatter()
	// Unlink target
	if(linked_target)
		UnregisterSignal(linked_target, list(COMSIG_MOB_APPLY_DAMGE, COMSIG_LIVING_DEATH))
		linked_target = null
	// Reset all state
	shattered = TRUE
	is_open = FALSE
	icon_state = "locket_shatter"
	w_class = WEIGHT_CLASS_SMALL
	name = "shattered [name]"
	desc = "A cracked and dull golden locket. Whatever warmth it once held has gone cold."
	open_duration = 0
	damage_share_percent = 5
	last_damage_ramp = 0
	last_whisper = 0
	if(bond_locked)
		bond_locked = FALSE
		REMOVE_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	STOP_PROCESSING(SSobj, src)
	playsound(src, 'sound/effects/glassbr3.ogg', 75, TRUE)

// ==========================================================
// Void Reliquary - Damage-absorbing area denial relic
// ==========================================================

/// Void Reliquary - A golden geometric box that absorbs damage taken by the holder as charge.
/// When activated, spawns an anchored structure that grants Defense Level Up, heals 5% max HP
/// (brute, fire, sanity), and increases hallucination for nearby carbons. Duration scales with stored charge.
/obj/item/ruin_relic/void_reliquary
	name = "???"
	desc = "A golden geometric box with intricate facets. It feels heavier than it should, and staring into its surface makes your thoughts feel distant."
	icon_state = "oddity6"
	rarity = 3
	attunement_fail_damage = 15
	/// Current charge stacks, gained by absorbing holder's damage
	var/charge = 0
	/// Maximum charge
	var/max_charge = 20
	/// Charge gained per point of damage taken (1 charge per 5 damage)
	var/charge_per_damage = 0.2
	/// The mob we're currently registered to for damage signals
	var/mob/living/holder_ref

/obj/item/ruin_relic/void_reliquary/Destroy()
	if(holder_ref)
		UnregisterSignal(holder_ref, list(COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_PARENT_QDELETING))
		holder_ref = null
	return ..()

/obj/item/ruin_relic/void_reliquary/examine(mob/user)
	. = ..()
	if(charge <= 0)
		. += span_notice("It feels hollow and cold. It has no charge.")
	else if(charge >= max_charge)
		. += span_boldwarning("It pulses with dark energy, ready to be unleashed. ([charge]/[max_charge])")
	else
		. += span_notice("It holds [charge]/[max_charge] absorbed suffering.")

// ==================== CHARGING ====================

/obj/item/ruin_relic/void_reliquary/CheckAttunement(mob/living/carbon/human/user)
	var/list/missing = user.get_missing_limbs()
	for(var/zone in missing)
		if(zone == BODY_ZONE_L_ARM || zone == BODY_ZONE_R_ARM || zone == BODY_ZONE_L_LEG || zone == BODY_ZONE_R_LEG)
			return TRUE
	return FALSE

/obj/item/ruin_relic/void_reliquary/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The reliquary rejects you. It feeds on suffering — show it what you've lost."))
	// The void reaches out and damages a random limb
	var/list/zones = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_CHEST)
	var/zone = pick(zones)
	user.deal_damage(15, RED_DAMAGE, def_zone = zone)
	to_chat(user, span_userdanger("The void inside lashes out, tearing at your [zone]!"))

/obj/item/ruin_relic/void_reliquary/equipped(mob/user, slot, initial)
	. = ..()
	if(holder_ref == user)
		return
	// Unregister from previous holder if any
	if(holder_ref)
		UnregisterSignal(holder_ref, list(COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_PARENT_QDELETING))
	holder_ref = user
	RegisterSignal(holder_ref, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(OnHolderDamaged))
	RegisterSignal(holder_ref, COMSIG_PARENT_QDELETING, PROC_REF(OnHolderDeleted))

/obj/item/ruin_relic/void_reliquary/dropped(mob/user)
	. = ..()
	if(holder_ref)
		UnregisterSignal(holder_ref, list(COMSIG_MOB_AFTER_APPLY_DAMGE, COMSIG_PARENT_QDELETING))
		holder_ref = null

/// Signal handler: absorb a portion of the holder's damage as charge
/obj/item/ruin_relic/void_reliquary/proc/OnHolderDamaged(mob/living/target, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(charge >= max_charge)
		return
	var/gained = round(damage * charge_per_damage)
	if(gained <= 0)
		return
	charge = min(charge + gained, max_charge)
	// Dark sparkles on the relic
	var/obj/effect/temp_visual/sparkles/S = new /obj/effect/temp_visual/sparkles(get_turf(src))
	S.color = "#1a1a2e"

/// Signal handler: cleans up when the holder mob is deleted
/obj/item/ruin_relic/void_reliquary/proc/OnHolderDeleted(datum/source)
	SIGNAL_HANDLER
	holder_ref = null

// ==================== ACTIVATION ====================

/obj/item/ruin_relic/void_reliquary/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	if(charge <= 0)
		to_chat(user, span_warning("[src] is empty. It has nothing to give."))
		return
	user.visible_message(
		span_boldwarning("[user] places [src] on the ground. It begins to fill with void!"),
		span_warning("You set [src] down. Darkness floods into it!")
	)
	var/turf/T = get_turf(user)
	var/obj/structure/void_reliquary/structure = new(T, charge, src)
	if(!structure)
		return
	// Hide item inside the structure
	forceMove(structure)
	charge = 0

// ==========================================================
// Void Reliquary Structure - Hovering area effect
// ==========================================================

/// The deployed void reliquary structure. Grants Defense Level Up, heals 5% max HP, and adds hallucination to nearby carbons.
/obj/structure/void_reliquary
	name = "void reliquary"
	desc = "A golden box hovering in place, filled with an abyssal void. The air around it shimmers."
	icon = 'ModularLobotomy/_Lobotomyicons/ruin_relics.dmi'
	icon_state = "oddity6"
	anchored = TRUE
	density = FALSE
	/// Total hover duration in deciseconds
	var/duration = 0
	/// Seconds of hover time per charge point
	var/seconds_per_charge = 3
	/// Whether the structure is actively hovering and processing effects
	var/active = FALSE
	/// The item stored inside, returned when structure expires
	var/obj/item/ruin_relic/void_reliquary/stored_item
	/// Range of the area effect
	var/effect_range = 4
	/// Hallucination added to nearby carbons per tick
	var/hallucination_per_tick = 5
	/// How often to apply effects (deciseconds) — every 5 seconds
	var/tick_interval = 50
	/// Tracks active time for effect ticks and expiry
	var/time_active = 0

/obj/structure/void_reliquary/Initialize(mapload, charge_amount, obj/item/ruin_relic/void_reliquary/item_ref)
	. = ..()
	if(!charge_amount)
		return INITIALIZE_HINT_QDEL
	duration = charge_amount * seconds_per_charge * 10
	stored_item = item_ref
	// Play the void-filling animation, then activate after it finishes
	flick("oddity6_void", src)
	addtimer(CALLBACK(src, PROC_REF(Activate)), 3.4 SECONDS)

/obj/structure/void_reliquary/Destroy()
	if(stored_item)
		stored_item.forceMove(get_turf(src))
		stored_item = null
	STOP_PROCESSING(SSobj, src)
	return ..()

/// Called after the void-filling animation finishes. Begins the hovering phase.
/obj/structure/void_reliquary/proc/Activate()
	icon_state = "oddity6_voidfilled"
	active = TRUE
	START_PROCESSING(SSobj, src)

/obj/structure/void_reliquary/process(delta_time)
	if(!active)
		return
	var/prev_time = time_active
	time_active += delta_time * 10
	// Check expiry
	if(time_active >= duration)
		Expire()
		return
	// Apply effects every tick_interval (5 seconds)
	if(round(time_active / tick_interval) <= round(prev_time / tick_interval))
		return
	for(var/mob/living/carbon/human/C in range(effect_range, src))
		C.hallucination += hallucination_per_tick
		C.apply_lc_defense_level_up(5)
		var/heal_amount = C.maxHealth * 0.05
		C.adjustBruteLoss(-heal_amount)
		C.adjustFireLoss(-heal_amount)
		C.adjustSanityLoss(-heal_amount)

/// Called when the hover duration expires. Drops the item and deletes the structure.
/obj/structure/void_reliquary/proc/Expire()
	visible_message(span_notice("[src] flickers and falls silent. The void recedes."))
	STOP_PROCESSING(SSobj, src)
	if(stored_item)
		stored_item.forceMove(get_turf(src))
		stored_item = null
	qdel(src)

// ==========================================================
// Effigy Tablet - Voodoo-like engraving + golden figure
// ==========================================================

/// Effigy Tablet - A stone tablet that can be engraved with a person's likeness using a sharp weapon.
/// The engraved person can perform a blood sacrifice (below 50% HP, costs 25% maxHP) to fill it with gold.
/// The golden figure can then be extracted and used by another person to heal their brute, burn, and toxin damage,
/// at the cost of the engraved person taking equivalent BRUTE damage.
/obj/item/ruin_relic/effigy_tablet
	name = "???"
	desc = "A smooth stone tablet covered in faint, worn carvings. Running your fingers across it fills you with an inexplicable sense of obligation."
	icon_state = "oddity4"
	rarity = 4
	attunement_fail_damage = 20
	/// Tag of the person whose likeness is engraved
	var/engraved_human_tag
	/// Display name of the engraved person
	var/engraved_human_name
	/// Current state: "blank", "engraved", "filling", "gold_filled"
	var/state = "blank"

/obj/item/ruin_relic/effigy_tablet/Destroy()
	engraved_human_tag = null
	return ..()

/obj/item/ruin_relic/effigy_tablet/CheckAttunement(mob/living/carbon/human/user)
	// Must be holding a knife and have 5+ bleed stacks
	var/obj/item/held = user.get_inactive_held_item()
	if(!held || !(held.sharpness & SHARP_EDGED))
		return FALSE
	var/datum/status_effect/stacking/lc_bleed/B = user.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!B || B.stacks < 5)
		return FALSE
	return TRUE

/obj/item/ruin_relic/effigy_tablet/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The tablet resists your touch. It demands a blade in hand and blood freely given."))
	user.apply_lc_bleed(5)
	to_chat(user, span_userdanger("The tablet's carvings slice into your fingers as it rejects you."))

// ==================== EXAMINE ====================

/obj/item/ruin_relic/effigy_tablet/examine(mob/user)
	. = ..()
	switch(state)
		if("blank")
			. += span_notice("The tablet is blank and unmarked. Perhaps a sharp edge could carve something into it.")
		if("engraved")
			. += span_notice("A humanoid figure is carved into its surface. It resembles [engraved_human_name].")
			. += span_warning("The engraved person must sacrifice their blood to fill it with gold.")
		if("filling")
			. += span_warning("Gold flows into the carved channels...")
		if("gold_filled")
			. += span_notice("A golden humanoid figure gleams within the tablet, ready to be removed.")

// ==================== ENGRAVING ====================

/obj/item/ruin_relic/effigy_tablet/attackby(obj/item/I, mob/user, params)
	if(!IsAttuned(user))
		return ..()
	if(state != "blank")
		return ..()
	if(I.get_sharpness() != SHARP_EDGED)
		return ..()
	if(!ishuman(user))
		to_chat(user, span_warning("[src] doesn't respond to you."))
		return
	// Engrave the user's likeness
	engraved_human_tag = user.tag
	engraved_human_name = user.real_name
	state = "engraved"
	icon_state = "oddity4_humanoid"
	user.visible_message(
		span_notice("[user] carefully carves into [src] with [I]."),
		span_notice("You carve your likeness into the tablet. It feels strangely intimate.")
	)
	playsound(src, 'sound/items/screwdriver2.ogg', 50, TRUE)

// ==================== BLOOD SACRIFICE + EXTRACTION ====================

/obj/item/ruin_relic/effigy_tablet/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	switch(state)
		if("blank")
			to_chat(user, span_notice("[src] is blank. You need to engrave it first."))
		if("engraved")
			BloodSacrifice(user)
		if("filling")
			to_chat(user, span_warning("The gold is still flowing. Be patient."))
		if("gold_filled")
			ExtractFigure(user)

/// The engraved person sacrifices blood to fill the engraving with gold
/obj/item/ruin_relic/effigy_tablet/proc/BloodSacrifice(mob/living/user)
	// Check engraved person still exists
	if(!engraved_human_tag)
		to_chat(user, span_warning("The engraving has faded. The tablet is blank once more."))
		state = "blank"
		icon_state = "oddity4"
		return
	// Must be the engraved person
	if(user.tag != engraved_human_tag)
		to_chat(user, span_warning("[src] doesn't respond to you. Only the engraved can offer blood."))
		return
	// Must be below 50% HP
	if(user.health >= user.maxHealth * 0.5)
		to_chat(user, span_warning("You aren't suffering enough. The tablet demands more."))
		return
	// Blood sacrifice — costs 25% maxHP
	state = "filling"
	user.deal_damage(user.maxHealth * 0.25, BRUTE, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_STATUS)
	user.visible_message(
		span_boldwarning("[user]'s blood flows into [src], turning to gold as it fills the channels!"),
		span_userdanger("Your blood pours into [src]. Agony gives way to a golden glow.")
	)
	flash_color(user, flash_color = "#960000", flash_time = 20)
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)
	flick("oddity4_pour_gold", src)
	addtimer(CALLBACK(src, PROC_REF(FinishFilling)), 4 SECONDS)

/// Called after the gold pouring animation finishes
/obj/item/ruin_relic/effigy_tablet/proc/FinishFilling()
	state = "gold_filled"
	icon_state = "oddity4_goldhumanoid"
	var/obj/effect/temp_visual/sparkles/S = new /obj/effect/temp_visual/sparkles(get_turf(src))
	S.color = "#FFD700"

/// Extract the golden figure from the tablet
/obj/item/ruin_relic/effigy_tablet/proc/ExtractFigure(mob/living/user)
	var/obj/item/ruin_relic/golden_figure/figure = new(get_turf(user), engraved_human_tag, engraved_human_name)
	user.put_in_hands(figure)
	state = "engraved"
	icon_state = "oddity4_humanoid"
	user.visible_message(
		span_notice("[user] pries the golden figure free from [src]."),
		span_notice("You pry the golden figure free. The empty engraving stares back at you.")
	)
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)

// ==========================================================
// Golden Figure - Consumable heal at the engraved person's expense
// ==========================================================

/// A golden humanoid figure extracted from the effigy tablet.
/// Using it heals the user's brute, burn, and toxin damage. The engraved person takes equivalent BRUTE damage.
/obj/item/ruin_relic/golden_figure
	name = "???"
	desc = "A small golden humanoid figure, still warm to the touch. It pulses faintly, as though a heartbeat is trapped inside the metal."
	icon_state = "oddity4_raw_goldhumanoid"
	w_class = WEIGHT_CLASS_SMALL
	rarity = 4
	/// Weakref to the person whose likeness this figure represents
	var/datum/weakref/engraved_human_ref
	/// Display name of the engraved person
	var/engraved_human_name

/obj/item/ruin_relic/golden_figure/Initialize(mapload, engraved_tag, engraved_name)
	. = ..()
	if(engraved_tag)
		var/mob/living/carbon/human/engraved = locate(engraved_tag)
		if(engraved)
			engraved_human_ref = WEAKREF(engraved)
	engraved_human_name = engraved_name

/obj/item/ruin_relic/golden_figure/Destroy()
	engraved_human_ref = null
	return ..()

/obj/item/ruin_relic/golden_figure/examine(mob/user)
	. = ..()
	var/mob/living/carbon/human/engraved_human = engraved_human_ref?.resolve()
	if(!engraved_human)
		. += span_warning("The figure has lost its connection. It's just gold now.")
	else
		. += span_notice("A golden figure in the shape of [engraved_human_name].")
		. += span_warning("Using it will fully heal you at their expense.")

/obj/item/ruin_relic/golden_figure/attack_self(mob/living/user)
	if(!iscarbon(user))
		return
	// Require a valid, living engraved person
	var/mob/living/carbon/human/engraved_human = engraved_human_ref?.resolve()
	if(!engraved_human)
		to_chat(user, span_warning("The figure has lost its connection. It's just gold now."))
		return
	if(engraved_human.stat == DEAD)
		to_chat(user, span_warning("The figure's warmth has faded. Its source is dead."))
		return
	// Prevent self-use
	if(user == engraved_human)
		to_chat(user, span_warning("You can't use your own effigy."))
		return
	// Check if user actually needs healing (brute, burn, toxin only)
	var/brute = user.getBruteLoss()
	var/burn = user.getFireLoss()
	var/toxin = user.getToxLoss()
	var/heal_amount = brute + burn + toxin
	if(heal_amount <= 0)
		to_chat(user, span_notice("You have no wounds the figure can mend."))
		return
	// Heal brute, burn, and toxin damage
	user.adjustBruteLoss(-brute)
	user.adjustFireLoss(-burn)
	user.adjustToxLoss(-toxin)
	user.visible_message(
		span_notice("Golden light envelops [user] as [src] crumbles to dust!"),
		span_notice("Golden light washes over you. Your wounds mend completely.")
	)
	var/obj/effect/temp_visual/sparkles/S = new /obj/effect/temp_visual/sparkles(get_turf(user))
	S.color = "#FFD700"
	// Punish the engraved person
	engraved_human.deal_damage(heal_amount, BRUTE, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_STATUS)
	to_chat(engraved_human, span_userdanger("You feel your flesh tear open as something pulls at your life force!"))
	flash_color(engraved_human, flash_color = "#FFD700", flash_time = 20)
	do_sparks(3, FALSE, engraved_human)
	// Consume the figure
	qdel(src)

// ==================== VIOLET MASS ====================

/// Violet Mass - A pulsating purple orb that lets the holder scry on living players.
/// While scrying, the user's screen turns dark purple and their SP drains rapidly.
/// If SP drops below 10%, the user is forcibly ejected and takes 500 SP damage after 5 seconds.
/// There is a 5 second minimum watch time before the user can voluntarily stop.
/obj/item/ruin_relic/violet_mass
	name = "???"
	desc = "A dark purple orb covered in faint luminous text. A layer of pliant, skin-like membrane pulses rhythmically across its surface. Looking into it makes you feel watched."
	icon_state = "violetmass"
	rarity = 2
	attunement_fail_damage = 10
	w_class = WEIGHT_CLASS_SMALL
	/// The person currently being watched
	var/mob/living/carbon/human/watched_target
	/// Whether we are actively scrying
	var/is_scrying = FALSE
	/// world.time when scrying began
	var/scry_start_time = 0
	/// Minimum time (deciseconds) before user can voluntarily stop scrying
	var/min_watch_time = 50
	/// SP drained each process tick
	var/sp_drain_per_tick = 4
	/// Stored client.color before scrying started
	var/initial_color

/obj/item/ruin_relic/violet_mass/CheckAttunement(mob/living/carbon/human/user)
	return !user.getorgan(/obj/item/organ/eyes)

/obj/item/ruin_relic/violet_mass/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The mass peers at your eyes with contempt. Remove them, and see truly."))
	user.hallucination += 20
	// Temporary blindness — the mass overwhelms your sight
	user.blind_eyes(5)
	to_chat(user, span_userdanger("Your vision goes dark as the mass floods your senses!"))

/obj/item/ruin_relic/violet_mass/examine(mob/user)
	. = ..()
	if(is_scrying)
		. += span_warning("The orb's surface swirls with frantic energy. It is locked onto someone.")
	else
		. += span_notice("The orb pulses gently, waiting.")

/obj/item/ruin_relic/violet_mass/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	var/mob/living/carbon/human/H = user
	if(is_scrying)
		// Attempt to stop scrying
		if(world.time < scry_start_time + min_watch_time)
			to_chat(H, span_warning("The orb's grip hasn't loosened yet..."))
			return
		StopScrying(H)
		return
	// Build list of valid targets on same Z-level
	var/list/valid_targets = list()
	for(var/mob/living/carbon/human/target in GLOB.player_list)
		if(target == H)
			continue
		if(target.stat == DEAD)
			continue
		if(target.z != H.z)
			continue
		valid_targets += target
	if(!length(valid_targets))
		to_chat(H, span_warning("There is nobody to watch."))
		return
	var/mob/living/carbon/human/chosen = tgui_input_list(H, "Choose a target to observe.", "Violet Mass", valid_targets)
	if(!chosen || QDELETED(chosen) || QDELETED(src))
		return
	if(!H.is_holding(src))
		return
	StartScrying(H, chosen)

/// Begin scrying on the target. Switches perspective, applies purple screen, starts SP drain.
/obj/item/ruin_relic/violet_mass/proc/StartScrying(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!target || QDELETED(target) || target.stat == DEAD)
		to_chat(user, span_warning("The target is no longer valid."))
		return
	if(!user.client)
		return
	watched_target = target
	is_scrying = TRUE
	scry_start_time = world.time
	// Store and apply purple screen color
	initial_color = user.client.color
	user.client.color = "#e5b5ff"
	// Switch perspective to target
	user.reset_perspective(target)
	START_PROCESSING(SSobj, src)
	to_chat(user, span_warning("The orb hums and your vision floods with violet. You see through [target]'s eyes."))

/obj/item/ruin_relic/violet_mass/process(delta_time)
	// Find holder
	var/mob/living/carbon/human/holder
	var/atom/AT = get_atom_on_turf(src, /mob/living)
	if(ishuman(AT))
		var/mob/living/carbon/human/H = AT
		if(src in H.held_items)
			holder = H
	if(!holder || !holder.client || holder.stat == DEAD)
		if(holder)
			StopScrying(holder)
		else
			// No valid holder — force reset
			is_scrying = FALSE
			watched_target = null
			STOP_PROCESSING(SSobj, src)
		return
	// Check if target is still valid
	if(!watched_target || QDELETED(watched_target) || watched_target.stat == DEAD)
		to_chat(holder, span_warning("Your target has slipped away. The vision fades."))
		StopScrying(holder)
		return
	// Drain SP
	holder.adjustSanityLoss(sp_drain_per_tick)
	// Check if SP dropped below 10%
	if(holder.sanityhealth < holder.maxSanity * 0.1)
		to_chat(holder, span_userdanger("The orb tears itself from your mind! Your sanity is shattered!"))
		StopScrying(holder)
		addtimer(CALLBACK(src, PROC_REF(ScryBacklash), holder), 50)

/// Stop scrying. Resets perspective, restores screen color, clears state.
/obj/item/ruin_relic/violet_mass/proc/StopScrying(mob/living/carbon/human/user)
	if(!is_scrying)
		return
	is_scrying = FALSE
	watched_target = null
	STOP_PROCESSING(SSobj, src)
	if(!user || QDELETED(user))
		return
	// Reset perspective back to self
	user.reset_perspective()
	// Restore screen color
	if(user.client)
		user.client.color = initial_color
	initial_color = null
	to_chat(user, span_notice("The violet haze recedes from your vision."))

/// Delayed SP punishment after being forcibly ejected from scrying.
/obj/item/ruin_relic/violet_mass/proc/ScryBacklash(mob/living/carbon/human/user)
	if(QDELETED(user) || user.stat == DEAD)
		return
	user.adjustSanityLoss(500, forced = TRUE)
	flash_color(user, flash_color = "#6a0dad", flash_time = 30)
	shake_camera(user, 5, 3)
	to_chat(user, span_userdanger("Agony floods your mind as the orb's visions burn into your psyche!"))

/obj/item/ruin_relic/violet_mass/dropped(mob/user)
	. = ..()
	if(is_scrying && ishuman(user))
		StopScrying(user)

/obj/item/ruin_relic/violet_mass/Destroy()
	if(is_scrying)
		var/atom/AT = get_atom_on_turf(src, /mob/living)
		if(ishuman(AT))
			StopScrying(AT)
	watched_target = null
	return ..()

// ==================== CORRUPTED SKULL ====================

/// Corrupted Skull - Drains BLACK damage from nearby mobs via beams, building corruption. Heals the holder per target.
/// Deals 5x damage to non-human mobs. At 75+ corruption, tethers drained targets to the holder.
/// Ages the user over time (gray hair, nearsightedness, dust at age 969). Older users drain harder.
/// After 200 drain ticks, permanently applies rotten skin. At max corruption (150), transforms into a hostile mob.
/// When killed, reverts to an item with corruption reset.
/obj/item/ruin_relic/corrupted_skull
	name = "???"
	desc = "A weathered skull covered in faint purple runes. The bone feels unnaturally warm, and holding it too long makes your hands ache."
	icon_state = "skull"
	rarity = 5
	attunement_fail_damage = 25
	/// Whether actively draining nearby mobs
	var/is_draining = FALSE
	/// Corruption level, 0-150. Transforms to mob at 150.
	var/corruption = 0
	/// Maximum corruption before transformation
	var/max_corruption = 150
	/// Range in tiles to drain targets
	var/drain_range = 4
	/// Current BLACK damage per process tick, increases with corruption
	var/drain_damage = 3
	/// Movement restriction range for high-corruption tethering
	var/tether_range = 5
	/// Assoc list of mob ref -> /datum/beam for active drain beams
	var/list/drain_beams = list()
	/// List of mobs currently tethered by the skull
	var/list/tethered_mobs = list()
	/// Corruption decay per process tick while not draining
	var/corruption_decay = 0.3
	/// Whether to drain all mobs (TRUE) or only simple mobs (FALSE)
	var/drain_all = TRUE
	/// The action button for toggling drain on/off
	var/datum/action/innate/skull_drain/drain_action
	/// The mob currently affected by the purple skin tint
	var/mob/living/carbon/human/tinted_mob
	/// The current tint color applied (for targeted removal)
	var/current_tint
	/// Cumulative process ticks spent actively draining
	var/drain_ticks = 0
	/// Number of drain ticks before rotten skin is permanently applied to the holder
	var/rotten_skin_threshold = 200

/// Cleans up beam and tether for a single target.
/obj/item/ruin_relic/corrupted_skull/proc/CleanupTarget(mob/living/target)
	if(target in drain_beams)
		qdel(drain_beams[target])
		drain_beams -= target
	if(target in tethered_mobs)
		var/datum/component/tether/T = target.GetComponent(/datum/component/tether)
		if(T)
			qdel(T)
		tethered_mobs -= target
	UnregisterSignal(target, COMSIG_PARENT_QDELETING)

/// Cleans up all tracked targets' beams and tethers.
/obj/item/ruin_relic/corrupted_skull/proc/CleanupAllTargets()
	var/list/all_targets = drain_beams.Copy()
	for(var/mob/living/L in tethered_mobs)
		all_targets[L] = TRUE
	for(var/mob/living/L in all_targets)
		CleanupTarget(L)

/// Signal handler: called when a tethered/beamed mob is deleted.
/obj/item/ruin_relic/corrupted_skull/proc/OnTargetDeleted(datum/source)
	SIGNAL_HANDLER
	var/mob/living/L = source
	drain_beams -= L
	tethered_mobs -= L

/obj/item/ruin_relic/corrupted_skull/Initialize()
	. = ..()
	drain_action = new(src)

/obj/item/ruin_relic/corrupted_skull/CheckAttunement(mob/living/carbon/human/user)
	// Average of all 4 stats must be >= 80 and user must be age 50+
	var/avg = (get_attribute_level(user, FORTITUDE_ATTRIBUTE) + get_attribute_level(user, PRUDENCE_ATTRIBUTE) + get_attribute_level(user, TEMPERANCE_ATTRIBUTE) + get_attribute_level(user, JUSTICE_ATTRIBUTE)) / 4
	return avg >= 80 && user.age >= 50

/obj/item/ruin_relic/corrupted_skull/OnAttuneFail(mob/living/carbon/human/user)
	..()
	user.apply_lc_mental_decay(5)
	user.age += 5
	var/avg = (get_attribute_level(user, FORTITUDE_ATTRIBUTE) + get_attribute_level(user, PRUDENCE_ATTRIBUTE) + get_attribute_level(user, TEMPERANCE_ATTRIBUTE) + get_attribute_level(user, JUSTICE_ATTRIBUTE)) / 4
	if(avg < 80)
		to_chat(user, span_userdanger("The skull laughs. 'Pathetic. You lack the strength to wield me.'"))
	else
		to_chat(user, span_userdanger("The skull sneers. 'Strong, but too young. Come back when you've lived long enough.'"))

/obj/item/ruin_relic/corrupted_skull/examine(mob/user)
	. = ..()
	if(corruption <= 0)
		. += span_notice("The runes are dormant. It looks inert.")
	else if(corruption < 50)
		. += span_warning("Faint purple light seeps from the carvings.")
	else if(corruption < 100)
		. += span_warning("The skull throbs with dark energy. The runes glow brightly.")
	else
		. += span_userdanger("The skull is almost alive. Violet fire dances in its eye sockets.")
	if(is_draining)
		. += span_warning("It is actively draining nearby life.")
	. += span_notice("Currently targeting: [drain_all ? "all living creatures" : "simple creatures only"].")

/obj/item/ruin_relic/corrupted_skull/equipped(mob/user, slot, initial)
	. = ..()
	if(drain_action)
		drain_action.Grant(user)

/obj/item/ruin_relic/corrupted_skull/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	// Toggle targeting mode
	drain_all = !drain_all
	if(drain_all)
		to_chat(user, span_warning("The skull's hunger broadens. It will drain all living creatures."))
	else
		to_chat(user, span_notice("The skull's focus narrows. It will only drain simple creatures."))

/// Toggles draining on or off. Called by the action button.
/obj/item/ruin_relic/corrupted_skull/proc/ToggleDrain(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		to_chat(user, span_warning("[src] does not respond. You must attune to it first."))
		return
	if(is_draining)
		StopDraining()
		to_chat(user, span_notice("The skull's eyes dim. The draining stops."))
		return
	is_draining = TRUE
	START_PROCESSING(SSobj, src)
	to_chat(user, span_warning("The skull's eyes ignite with violet light. You feel it reaching out..."))

/obj/item/ruin_relic/corrupted_skull/process(delta_time)
	// Passive corruption decay while not draining
	if(!is_draining)
		corruption = max(0, corruption - corruption_decay * delta_time)
		UpdateCorruptionPassive()
		if(corruption <= 0)
			STOP_PROCESSING(SSobj, src)
		return
	// Find holder — works from hands, belt, or pockets
	var/mob/living/carbon/human/holder
	if(ishuman(loc))
		holder = loc
	else if(istype(loc, /obj/item))
		// Inside a belt or pocket container
		if(ishuman(loc.loc))
			holder = loc.loc
	if(!holder || holder.stat == DEAD)
		StopDraining()
		return
	// Calculate drain with age bonus
	var/age_bonus = max(0, round((holder.age - 30) / 20))
	var/total_drain = drain_damage + age_bonus
	// Find and drain targets (view checks line of sight)
	var/list/current_targets = list()
	var/hit_any = FALSE
	for(var/mob/living/L in view(drain_range, holder))
		if(L == holder || L.stat == DEAD)
			continue
		// Filter by targeting mode
		if(!drain_all && !isanimal(L))
			continue
		current_targets += L
		hit_any = TRUE
		// Deal BLACK damage — 5x to non-human mobs
		var/mob_damage = total_drain
		if(!ishuman(L))
			mob_damage *= 5
		L.deal_damage(mob_damage, BLACK_DAMAGE)
		// Manage beam
		if(!(L in drain_beams))
			drain_beams[L] = holder.Beam(L, icon_state = "drain_life")
			RegisterSignal(L, COMSIG_PARENT_QDELETING, PROC_REF(OnTargetDeleted))
		// Heal user per target
		holder.adjustBruteLoss(-1)
		holder.adjustSanityLoss(-1)
		// Build corruption
		corruption += 0.5 * delta_time
		// Tether at high corruption
		if(corruption >= 75 && !(L in tethered_mobs))
			L.AddComponent(/datum/component/tether, holder, tether_range, src)
			tethered_mobs += L
	// Age drain every tick that damage is dealt
	if(hit_any)
		drain_ticks++
		ApplyAgeDrain(holder)
		if(QDELETED(holder) || holder.stat == DEAD)
			StopDraining()
			return
		// Apply permanent rotten skin after enough use
		if(drain_ticks >= rotten_skin_threshold && !holder.GetComponent(/datum/component/rotten_skin))
			holder.AddComponent(/datum/component/rotten_skin)
			to_chat(holder, span_userdanger("Your skin crawls and darkens. The skull's corruption has seeped into your flesh."))
	// Clean up beams for targets no longer in range
	for(var/mob/living/L in drain_beams)
		if(!(L in current_targets) || QDELETED(L) || L.stat == DEAD)
			CleanupTarget(L)
	// Update corruption stage
	UpdateCorruption(holder)
	// Check max corruption
	if(corruption >= max_corruption)
		TransformToMob(holder)

/// Updates icon_state, drain_damage, and drain_range based on corruption thresholds.
/obj/item/ruin_relic/corrupted_skull/proc/UpdateCorruption(mob/living/carbon/human/holder)
	var/new_icon
	var/new_drain
	var/new_range
	if(corruption >= 100)
		new_icon = "skull_corruption_v4"
		new_drain = 13
		new_range = 8
	else if(corruption >= 75)
		new_icon = "skull_corruption_v3"
		new_drain = 10
		new_range = 7
	else if(corruption >= 50)
		new_icon = "skull_corruption_v2"
		new_drain = 7
		new_range = 6
	else if(corruption >= 25)
		new_icon = "skull_corruption_v1"
		new_drain = 5
		new_range = 5
	else
		new_icon = "skull"
		new_drain = 3
		new_range = 4
	if(new_icon != icon_state)
		icon_state = new_icon
		drain_damage = new_drain
		drain_range = new_range
		to_chat(holder, span_warning("The skull pulses with growing darkness..."))
	UpdateSkinTint(holder)

/// Updates icon_state, drain_damage, and drain_range during passive decay (no holder needed).
/obj/item/ruin_relic/corrupted_skull/proc/UpdateCorruptionPassive()
	var/new_icon
	var/new_drain
	var/new_range
	if(corruption >= 100)
		new_icon = "skull_corruption_v4"
		new_drain = 13
		new_range = 8
	else if(corruption >= 75)
		new_icon = "skull_corruption_v3"
		new_drain = 10
		new_range = 7
	else if(corruption >= 50)
		new_icon = "skull_corruption_v2"
		new_drain = 7
		new_range = 6
	else if(corruption >= 25)
		new_icon = "skull_corruption_v1"
		new_drain = 5
		new_range = 5
	else
		new_icon = "skull"
		new_drain = 3
		new_range = 4
	if(new_icon != icon_state)
		icon_state = new_icon
		drain_damage = new_drain
		drain_range = new_range
	UpdateSkinTint(tinted_mob)

/// Updates the purple skin tint on the holder based on corruption level.
/obj/item/ruin_relic/corrupted_skull/proc/UpdateSkinTint(mob/living/carbon/human/target)
	var/new_tint
	if(corruption >= 100)
		new_tint = "#DD80DD"
	else if(corruption >= 75)
		new_tint = "#E8A0E8"
	else if(corruption >= 50)
		new_tint = "#F0C0F0"
	else if(corruption >= 25)
		new_tint = "#F8E0F8"
	// Skip if nothing changed
	if(new_tint == current_tint && target == tinted_mob)
		return
	// Remove old tint
	RemoveSkinTint()
	// Apply new tint if needed
	if(new_tint && target)
		target.add_atom_colour(new_tint, TEMPORARY_COLOUR_PRIORITY)
		current_tint = new_tint
		tinted_mob = target

/// Removes the purple skin tint from whoever currently has it.
/obj/item/ruin_relic/corrupted_skull/proc/RemoveSkinTint()
	if(tinted_mob && current_tint)
		tinted_mob.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, current_tint)
	current_tint = null
	tinted_mob = null

/// Stops all draining, cleans up beams and tethers. Keeps processing for corruption decay.
/obj/item/ruin_relic/corrupted_skull/proc/StopDraining()
	if(!is_draining)
		return
	is_draining = FALSE
	CleanupAllTargets()
	// Keep processing for passive corruption decay, or stop if already at 0
	if(corruption <= 0)
		STOP_PROCESSING(SSobj, src)

/// Ages the user, applying cosmetic and mechanical penalties. Faster when younger, slower after 200.
/obj/item/ruin_relic/corrupted_skull/proc/ApplyAgeDrain(mob/living/carbon/human/user)
	if(!user || QDELETED(user))
		return
	// Age faster when younger, slower after 200
	var/age_gain = 1
	if(user.age < 50)
		age_gain = 5
	else if(user.age < 100)
		age_gain = 3
	else if(user.age < 200)
		age_gain = 2
	else
		// After 200: slows to 0.5 per tick (rounds to 1 every other tick)
		age_gain = prob(50) ? 1 : 0
	user.age += age_gain
	if(user.age > 70)
		user.facial_hair_color = "ccc"
		user.hair_color = "ccc"
		// Gray the gradient too, but darker
		if(user.gradient_style)
			user.gradient_color = "999"
		user.update_hair()
		if(user.age > 100)
			user.become_nearsighted(type)
			if(user.gender == MALE)
				user.facial_hairstyle = "Beard (Very Long)"
				user.update_hair()
		if(user.age > 969)
			// Drop the skull before dusting
			var/turf/T = get_turf(user)
			StopDraining()
			forceMove(T)
			user.visible_message(span_notice("[user] becomes older than any man should be.. and crumbles into dust!"))
			user.dust(just_ash = FALSE, drop_items = TRUE, force = FALSE)

/// Transforms the skull item into a hostile mob.
/obj/item/ruin_relic/corrupted_skull/proc/TransformToMob(mob/living/carbon/human/holder)
	StopDraining()
	var/turf/T = get_turf(holder)
	// Force drop the skull from the holder
	holder.dropItemToGround(src, TRUE)
	var/mob/living/simple_animal/hostile/corrupted_skull_mob/M = new(T, src)
	forceMove(M)
	M.GiveTarget(holder)
	visible_message(span_userdanger("The skull screams! Dark energy erupts as it tears itself from [holder]'s grasp and takes form!"))

/obj/item/ruin_relic/corrupted_skull/dropped(mob/user)
	. = ..()
	// Only stop draining if truly dropped to the ground, not moved to belt/pocket
	if(isturf(loc))
		if(is_draining)
			StopDraining()
		if(drain_action)
			drain_action.Remove(user)
		RemoveSkinTint()

/obj/item/ruin_relic/corrupted_skull/Unattune()
	drain_ticks = 0
	return ..()

/obj/item/ruin_relic/corrupted_skull/Destroy()
	StopDraining()
	RemoveSkinTint()
	QDEL_NULL(drain_action)
	return ..()

/// Action button to toggle the corrupted skull's drain on/off.
/datum/action/innate/skull_drain
	name = "Toggle Drain"
	desc = "Activate or deactivate the skull's life drain."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/ruin_relics.dmi'
	button_icon_state = "skull"
	check_flags = AB_CHECK_CONSCIOUS
	/// The skull item this action is linked to
	var/obj/item/ruin_relic/corrupted_skull/skull

/datum/action/innate/skull_drain/New(Target)
	..()
	if(istype(Target, /obj/item/ruin_relic/corrupted_skull))
		skull = Target

/datum/action/innate/skull_drain/Destroy()
	skull = null
	return ..()

/datum/action/innate/skull_drain/Activate()
	if(!skull || QDELETED(skull))
		return
	skull.ToggleDrain(owner)

// ==================== ROTTEN SKIN COMPONENT ====================

/// Permanent body overlay applied after prolonged use of the corrupted skull.
/// Renders under clothing at the body adjustment layer.
/datum/component/rotten_skin
	/// The overlay appearance applied to the mob
	var/mutable_appearance/skin_overlay

/datum/component/rotten_skin/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	skin_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/ruin_relics.dmi', "rotten_skin", -BODY_ADJ_LAYER)
	var/mob/living/carbon/human/H = parent
	H.add_overlay(skin_overlay)

/datum/component/rotten_skin/Destroy()
	var/mob/living/carbon/human/H = parent
	if(H && !QDELETED(H))
		H.cut_overlay(skin_overlay)
	skin_overlay = null
	return ..()

// ==================== CORRUPTED SKULL MOB ====================

/// Living Skull - The corrupted skull at max corruption, hostile mob form.
/// Pulses every 10 seconds to drain nearby humans via beams.
/// On death, drops the skull item with corruption reset.
/mob/living/simple_animal/hostile/corrupted_skull_mob
	name = "living skull"
	desc = "The skull has taken on a life of its own. Violet energy crackles from its hollow eyes as dark tendrils reach outward."
	icon = 'ModularLobotomy/_Lobotomyicons/ruin_relics.dmi'
	icon_state = "skull_living"
	icon_living = "skull_living"
	faction = list("corrupted_skull")
	gender = NEUTER
	maxHealth = 2000
	health = 2000
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 20
	melee_damage_upper = 30
	is_flying_animal = TRUE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 2)
	move_to_delay = 4
	del_on_death = TRUE
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_verb_continuous = "gnashes"
	attack_verb_simple = "gnash"
	/// The skull item stored inside this mob
	var/obj/item/ruin_relic/corrupted_skull/stored_item
	/// Range for pulse drain (max tier)
	var/drain_range = 8
	/// Tether range for drained targets
	var/tether_range = 8
	/// BLACK damage per pulse
	var/drain_damage = 8
	/// Deciseconds between drain pulses
	var/pulse_interval = 100
	/// world.time of last pulse
	var/last_pulse = 0
	/// Active drain beams from current pulse
	var/list/drain_beams = list()
	/// List of mobs currently tethered
	var/list/tethered_mobs = list()

/// Cleans up beam and tether for a single target.
/mob/living/simple_animal/hostile/corrupted_skull_mob/proc/CleanupTarget(mob/living/target)
	if(target in drain_beams)
		qdel(drain_beams[target])
		drain_beams -= target
	if(target in tethered_mobs)
		var/datum/component/tether/T = target.GetComponent(/datum/component/tether)
		if(T)
			qdel(T)
		tethered_mobs -= target
	UnregisterSignal(target, COMSIG_PARENT_QDELETING)

/// Cleans up all tracked targets' beams and tethers.
/mob/living/simple_animal/hostile/corrupted_skull_mob/proc/CleanupAllTargets()
	var/list/all_targets = drain_beams.Copy()
	for(var/mob/living/L in tethered_mobs)
		all_targets[L] = TRUE
	for(var/mob/living/L in all_targets)
		CleanupTarget(L)

/// Signal handler: called when a tethered/beamed mob is deleted.
/mob/living/simple_animal/hostile/corrupted_skull_mob/proc/OnTargetDeleted(datum/source)
	SIGNAL_HANDLER
	var/mob/living/L = source
	drain_beams -= L
	tethered_mobs -= L

/mob/living/simple_animal/hostile/corrupted_skull_mob/Initialize(mapload, obj/item/ruin_relic/corrupted_skull/skull_item)
	. = ..()
	stored_item = skull_item
	last_pulse = world.time

/mob/living/simple_animal/hostile/corrupted_skull_mob/Life()
	. = ..()
	if(stat == DEAD)
		return
	// Pulse drain every pulse_interval
	if(world.time < last_pulse + pulse_interval)
		return
	last_pulse = world.time
	PulseDrain()

/// Pulse AoE drain on all nearby humans and tether them.
/mob/living/simple_animal/hostile/corrupted_skull_mob/proc/PulseDrain()
	// Clean up old beams first
	for(var/key in drain_beams)
		qdel(drain_beams[key])
	drain_beams.Cut()
	// Drain all nearby living mobs
	var/list/current_targets = list()
	for(var/mob/living/L in range(drain_range, src))
		if(L == src || L.stat == DEAD)
			continue
		current_targets += L
		L.deal_damage(drain_damage, BLACK_DAMAGE)
		// Create short-lived beam
		drain_beams[L] = Beam(L, icon_state = "drain_life", time = 20)
		// Heal self
		adjustBruteLoss(-2)
		// Tether drained targets
		if(!(L in tethered_mobs))
			L.AddComponent(/datum/component/tether, src, tether_range, src)
			tethered_mobs += L
			RegisterSignal(L, COMSIG_PARENT_QDELETING, PROC_REF(OnTargetDeleted))
	// Clean up tethers for targets no longer in range
	for(var/mob/living/L in tethered_mobs)
		if(!(L in current_targets) || QDELETED(L) || L.stat == DEAD)
			CleanupTarget(L)
	visible_message(span_warning("Dark tendrils lash out from [src], draining the life of those nearby!"))

/mob/living/simple_animal/hostile/corrupted_skull_mob/death(gibbed)
	// Clean up beams and tethers
	CleanupAllTargets()
	// Reset the skull item's corruption state
	if(stored_item && !QDELETED(stored_item))
		stored_item.corruption = 0
		stored_item.icon_state = "skull"
		stored_item.drain_damage = 3
		stored_item.is_draining = FALSE
		stored_item = null
	// Dump all contents to the ground (like mimic)
	for(var/atom/movable/M in src)
		M.forceMove(get_turf(src))
	visible_message(span_notice("The living skull crumbles, leaving behind the ancient relic..."))
	return ..()

/mob/living/simple_animal/hostile/corrupted_skull_mob/Destroy()
	if(stored_item && !QDELETED(stored_item))
		stored_item.forceMove(get_turf(src))
		stored_item = null
	CleanupAllTargets()
	return ..()

// ==========================================================
// Rarity 1 Relics - Simple Curiosities
// ==========================================================

// ==================== TESU DOLL ====================

/// Tesu Doll - Use in hand to apply a 100 HP mental shield (absorbs WHITE damage). 60-second cooldown. Whispers eerie phrases.
/obj/item/ruin_relic/tesu_doll
	name = "???"
	desc = "A small white figure dangling from a frayed string. Its hollow eyes stare ahead with unsettling calm."
	icon_state = "tesu"
	w_class = WEIGHT_CLASS_SMALL
	verb_say = "whispers"
	/// Whether the doll is on cooldown
	var/on_cooldown = FALSE
	/// Shield HP granted per use
	var/shield_amount = 100

/obj/item/ruin_relic/tesu_doll/CheckAttunement(mob/living/carbon/human/user)
	// Must be low SP and in danger (hostile mob nearby)
	if(user.sanityhealth >= (user.maxSanity * 0.3))
		return FALSE
	for(var/mob/living/simple_animal/hostile/H in view(7, user))
		if(H.stat != DEAD)
			return TRUE
	return FALSE

/obj/item/ruin_relic/tesu_doll/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The doll stares blankly. 'Only the desperate in their darkest hour deserve my protection...'"))
	// The doll siphons your mind instead of shielding it
	var/sp_drain = user.maxSanity * 0.15
	user.adjustSanityLoss(sp_drain)
	to_chat(user, span_userdanger("The doll's hollow eyes flash and you feel your thoughts drain away."))

/obj/item/ruin_relic/tesu_doll/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	if(on_cooldown)
		to_chat(user, span_warning("The doll is cold and unresponsive."))
		return
	var/mob/living/carbon/human/H = user
	// Check if already shielded
	if(H.GetComponent(/datum/component/mental_shield))
		to_chat(H, span_warning("A mental shield is already active."))
		return
	// Apply the shield
	H.AddComponent(/datum/component/mental_shield, shield_amount, src)
	// Mysterious dialogue
	var/list/phrases = list(
		"...I'll hold them back...",
		"...your mind is mine to guard...",
		"...don't let go...",
		"...the voices can't reach you now...",
		"...stay still... stay quiet...",
		"...I promised...",
	)
	say(pick(phrases))
	to_chat(H, span_notice("A cold stillness wraps around your thoughts. You feel shielded."))
	playsound(src, 'sound/machines/click.ogg', 25, TRUE)
	on_cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(ResetCooldown)), 600)

/// Resets the use cooldown.
/obj/item/ruin_relic/tesu_doll/proc/ResetCooldown()
	on_cooldown = FALSE

// ==================== MENTAL SHIELD COMPONENT ====================

/// A flat HP shield that absorbs WHITE (SP) damage before the mob's sanity.
/// When depleted, shatters and applies White Fragile to the owner.
/datum/component/mental_shield
	/// Current shield HP
	var/shield_hp = 0
	/// Maximum shield HP
	var/max_shield_hp = 100
	/// The relic that granted this shield (for reference)
	var/obj/item/ruin_relic/source_relic
	/// Shield visual overlay
	var/shield_overlay

/datum/component/mental_shield/Initialize(amount, obj/item/ruin_relic/source)
	. = ..()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	shield_hp = amount
	max_shield_hp = amount
	source_relic = source
	shield_overlay = icon('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "white_shield")
	var/mob/living/owner = parent
	owner.add_overlay(shield_overlay)
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnDamage))

/datum/component/mental_shield/Destroy()
	var/mob/living/owner = parent
	if(owner && !QDELETED(owner))
		owner.cut_overlay(shield_overlay)
	shield_overlay = null
	source_relic = null
	return ..()

/// Intercept WHITE damage and absorb it into the shield HP.
/datum/component/mental_shield/proc/OnDamage(datum/source, damage, damage_type, def_zone, attacker, flags, attack_type)
	SIGNAL_HANDLER
	if(damage_type != WHITE_DAMAGE || damage <= 0 || shield_hp <= 0)
		return
	if(damage >= shield_hp)
		// Shield breaks — overflow passes through normally
		var/overflow = damage - shield_hp
		shield_hp = 0
		ShieldBreak()
		if(overflow > 0)
			// Let the overflow damage through by not returning DENY
			// We need to re-apply just the overflow amount
			INVOKE_ASYNC(src, PROC_REF(DealOverflow), parent, overflow)
		return COMPONENT_MOB_DENY_DAMAGE
	else
		// Shield absorbs all damage
		shield_hp -= damage
		playsound(get_turf(parent), 'sound/mecha/mech_shield_deflect.ogg', 40)
		return COMPONENT_MOB_DENY_DAMAGE

/// Deal overflow WHITE damage when shield breaks.
/datum/component/mental_shield/proc/DealOverflow(mob/living/target, damage)
	if(!target || QDELETED(target))
		return
	target.deal_damage(damage, WHITE_DAMAGE)

/// Called when the shield breaks — shatter sound, apply White Fragile, remove component.
/datum/component/mental_shield/proc/ShieldBreak()
	var/mob/living/owner = parent
	if(!owner || QDELETED(owner))
		qdel(src)
		return
	playsound(get_turf(owner), 'sound/effects/glassbr3.ogg', 50, TRUE)
	to_chat(owner, span_userdanger("The mental shield shatters! Your mind feels exposed."))
	owner.apply_lc_white_fragile(2)
	qdel(src)

/// Returns the living mob carrying this item (hands, pockets, belt), or null.
/obj/item/ruin_relic/proc/GetHolder()
	if(isliving(loc))
		return loc
	return null

/// Called when a mob carrying this relic attacks something. Activates combat mode for 30 seconds.
/obj/item/ruin_relic/proc/OnHolderAttack(mob/living/source, mob/living/target)
	SIGNAL_HANDLER
	ActivateCombat()

/// Activates or refreshes the 30-second combat window.
/obj/item/ruin_relic/proc/ActivateCombat()
	in_combat = TRUE
	if(combat_timer)
		deltimer(combat_timer)
	combat_timer = addtimer(CALLBACK(src, PROC_REF(DeactivateCombat)), 300, TIMER_STOPPABLE)

/// Deactivates combat mode when the 30-second window expires.
/obj/item/ruin_relic/proc/DeactivateCombat()
	in_combat = FALSE
	combat_timer = null

// ==================== PULSING SPHERE ====================

/// Pulsing Sphere - Throw to launch a bouncing projectile that ricochets up to 50 times.
/// Passes through mobs dealing RED damage + Overheat. Bounces off walls and structures.
/// Gains speed and damage every 5 bounces. Explodes for 100 RED damage + Overheat in a 5x5 area,
/// leaves flame tiles, and drops the relic at the explosion site.
/obj/item/ruin_relic/pulsing_sphere
	name = "???"
	desc = "A smooth sphere that shifts between dull pink and angry red. It radiates faint warmth that prickles your skin."
	icon_state = "ball"
	w_class = WEIGHT_CLASS_SMALL
	throw_range = 7
	throw_speed = 2

/obj/item/ruin_relic/pulsing_sphere/CheckAttunement(mob/living/carbon/human/user)
	return user.on_fire || user.fire_stacks > 0

/obj/item/ruin_relic/pulsing_sphere/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The sphere flickers coldly. It yearns for someone who knows the warmth of flame."))
	user.apply_lc_overheat(5)
	to_chat(user, span_userdanger("The sphere scorches your hands with a burst of searing heat!"))

/obj/item/ruin_relic/pulsing_sphere/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	to_chat(user, span_notice("The sphere pulses warmly in your hand. Throw it to unleash its power."))

/obj/item/ruin_relic/pulsing_sphere/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	// Gate projectile behind attunement — unattuned throws act as normal items
	if(!IsAttuned(thrownby))
		return ..()
	// Spawn projectile at our location
	var/turf/T = get_turf(src)
	var/obj/projectile/pulsing_sphere/P = new(T)
	P.parent_relic = src
	P.firer = thrownby
	// Calculate firing angle toward whatever we hit
	if(hit_atom)
		P.preparePixelProjectile(hit_atom, T)
	P.fire()
	// Hide the sphere item while the projectile is active
	moveToNullspace()

// ==================== PULSING SPHERE PROJECTILE ====================

/// Bouncing projectile spawned when the Pulsing Sphere relic is thrown.
/obj/projectile/pulsing_sphere
	name = "pulsing sphere"
	icon = 'ModularLobotomy/_Lobotomyicons/ruin_relics.dmi'
	icon_state = "fire_ball"
	damage = 15
	damage_type = RED_DAMAGE
	speed = 0.8
	range = 500
	nondirectional_sprite = TRUE
	// Ricochet config — always bounce, ignore flag checks, no decay
	ricochets_max = 50
	ricochet_chance = 500
	ricochet_ignore_flag = TRUE
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1
	ricochet_incidence_leeway = 80
	reflect_range_decrease = 0
	// Can hit the thrower, phase through mobs (we handle mob damage in Moved)
	projectile_phasing = PASSMOB
	ignore_source_check = TRUE
	/// The relic item that spawned this projectile
	var/obj/item/ruin_relic/pulsing_sphere/parent_relic
	/// Base damage for scaling calculations
	var/base_damage = 15
	/// Whether we're currently exploding (prevents recursive Explode from Destroy)
	var/exploding = FALSE

/// Use directional sprites instead of transform rotation — set dir from angle.
/obj/projectile/pulsing_sphere/set_angle(new_angle)
	. = ..()
	setDir(angle2dir_cardinal(new_angle))

/// Override Impact to force bounce-back when handle_ricochet fails at steep angles.
/obj/projectile/pulsing_sphere/Impact(atom/A)
	if(!trajectory)
		qdel(src)
		return FALSE
	if(impacted[A])
		return FALSE
	if(ricochets < ricochets_max && check_ricochet_flag(A) && check_ricochet(A))
		ricochets++
		if(A.handle_ricochet(src))
			on_ricochet(A)
			impacted = list()
			ignore_source_check = TRUE
			decayedRange = max(0, decayedRange - reflect_range_decrease)
			ricochet_chance *= ricochet_decay_chance
			damage *= ricochet_decay_damage
			range = decayedRange
			return TRUE
		else
			// handle_ricochet failed (bad angle) — force a 180 bounce-back
			set_angle(SIMPLIFY_DEGREES(Angle + 180))
			on_ricochet(A)
			impacted = list()
			ignore_source_check = TRUE
			return TRUE
	// Max ricochets reached — explode on next hit
	return process_hit(get_turf(A), select_target(get_turf(A), A, A), A)

/// Range expiry triggers explosion instead of silent deletion.
/obj/projectile/pulsing_sphere/on_range()
	Explode()

/// Damage all living mobs on every turf the sphere passes through.
/obj/projectile/pulsing_sphere/Moved(atom/OldLoc, Dir)
	. = ..()
	if(!fired)
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/mob/living/L in T)
		L.deal_damage(damage, damage_type)
		L.apply_lc_overheat(3)

/// After each ricochet, scale speed and damage every 5 bounces.
/obj/projectile/pulsing_sphere/on_ricochet(atom/A)
	..()
	if(ricochets % 5 == 0)
		speed = max(0.2, speed - 0.1)
		damage = base_damage + (ricochets / 5) * 5
		if(trajectory)
			trajectory.speed = speed
		playsound(get_turf(src), 'sound/machines/click.ogg', 30 + ricochets, TRUE)

/// On hit — if we've reached max ricochets and hit a wall, explode.
/obj/projectile/pulsing_sphere/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(ricochets >= ricochets_max)
		Explode()

/// Explode in a 5x5 area (range 2) for 100 RED damage, leave flame tiles, then drop the relic.
/obj/projectile/pulsing_sphere/proc/Explode()
	if(exploding)
		return
	exploding = TRUE
	var/turf/T = get_turf(src)
	if(!T)
		return
	new /obj/effect/temp_visual/explosion(T)
	playsound(T, 'sound/effects/explosion1.ogg', 60, TRUE)
	for(var/mob/living/L in range(2, T))
		L.deal_damage(100, RED_DAMAGE)
		L.apply_lc_overheat(3)
	// Leave flame tiles in the blast area
	for(var/turf/flame_turf in range(2, T))
		if(!flame_turf.density)
			new /obj/effect/turf_fire/sphere_fire(flame_turf)
	// Drop the relic
	if(parent_relic && !QDELETED(parent_relic))
		parent_relic.forceMove(T)
		parent_relic = null
	qdel(src)

/obj/projectile/pulsing_sphere/Destroy()
	// Always explode on destruction (e.g. range expiry, unexpected deletion)
	if(!exploding)
		Explode()
	// Safety: drop the relic if Explode didn't handle it (e.g. no turf)
	if(parent_relic && !QDELETED(parent_relic))
		parent_relic.forceMove(get_turf(src) || parent_relic)
		parent_relic = null
	return ..()

/// Short-lived flame tile spawned by the pulsing sphere explosion. Lasts 10 seconds.
/obj/effect/turf_fire/sphere_fire
	burn_time = 10 SECONDS

// ==================== BEEPING DEVICE ====================

/// Beeping Device - Use in hand to transform into a tiny shadebug that can crawl under doors and tables.
/// The human body is stored inside the bug. An action button lets you revert and heal. 2-minute cooldown.
/obj/item/ruin_relic/beeping_device
	name = "???"
	desc = "A boxy device with a cracked screen and a blinking red light. It emits a faint, rhythmic beep that is strangely reassuring."
	icon_state = "oddity1"
	w_class = WEIGHT_CLASS_SMALL
	/// Whether the device is on cooldown
	var/on_cooldown = FALSE

/obj/item/ruin_relic/beeping_device/CheckAttunement(mob/living/carbon/human/user)
	for(var/mob/living/simple_animal/A in view(5, user))
		if(A.stat != DEAD)
			return TRUE
	return FALSE

/obj/item/ruin_relic/beeping_device/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The device scans the area and finds nothing of interest. It needs organic data to collect."))
	// Device malfunctions and shocks the user
	user.Jitter(10)
	user.Stun(10)
	playsound(get_turf(src), 'sound/magic/lightningshock.ogg', 30, TRUE)
	to_chat(user, span_userdanger("The device sparks violently, sending a jolt through your body!"))

/obj/item/ruin_relic/beeping_device/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	if(on_cooldown)
		to_chat(user, span_warning("The device's light is dim. It needs time to recharge."))
		return
	var/mob/living/carbon/human/H = user
	var/turf/T = get_turf(H)
	// Spawn the shadebug
	var/mob/living/simple_animal/hostile/shadebug/bug = new(T)
	bug.stored_human = H
	bug.stored_relic = src
	// Transfer the player's mind into the bug
	H.mind.transfer_to(bug)
	// Hide the human body inside the bug
	H.forceMove(bug)
	// Move relic into the bug as well
	forceMove(bug)
	// Grant the revert action
	var/datum/action/innate/shadebug_revert/revert_action = new()
	revert_action.Grant(bug)
	bug.revert_action = revert_action
	to_chat(bug, span_notice("Your body shrinks and hardens into a small mechanical bug. Click the action button to revert."))
	playsound(T, 'sound/machines/click.ogg', 30, TRUE)

/// Resets the use cooldown.
/obj/item/ruin_relic/beeping_device/proc/ResetCooldown()
	on_cooldown = FALSE

// ==================== SHADEBUG MOB ====================

/// A tiny mechanical bug that a player transforms into via the Beeping Device relic.
/// Can crawl under doors and tables. Stores the original human body inside.
/mob/living/simple_animal/hostile/shadebug
	name = "shadebug"
	desc = "A tiny mechanical insect. Its legs click softly against the floor."
	icon = 'ModularLobotomy/_Lobotomyicons/ruin_relics.dmi'
	icon_state = "shadebug"
	icon_living = "shadebug"
	faction = list("neutral")
	city_faction = FALSE
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	density = FALSE
	layer = ABOVE_NORMAL_TURF_LAYER
	maxHealth = 5
	health = 5
	melee_damage_lower = 0
	melee_damage_upper = 0
	environment_smash = FALSE
	wander = FALSE
	move_to_delay = 2
	a_intent = INTENT_HELP
	gender = NEUTER
	del_on_death = FALSE
	stat_attack = UNCONSCIOUS
	/// The human body stored inside
	var/mob/living/carbon/human/stored_human
	/// The relic that created this bug
	var/obj/item/ruin_relic/beeping_device/stored_relic
	/// The revert action granted to the player
	var/datum/action/innate/shadebug_revert/revert_action

/// Crawl under doors and tables when bumping into them, like cuckoospawn_parasite.
/mob/living/simple_animal/hostile/shadebug/AttackingTarget(atom/attacked_target)
	if(istype(attacked_target, /obj/machinery/door) || istype(attacked_target, /obj/structure/table))
		var/turf/target_turf = get_turf(attacked_target)
		forceMove(target_turf)
		manual_emote("crawls under [attacked_target].")
		return
	return ..()

/// Revert the player back to human form.
/mob/living/simple_animal/hostile/shadebug/proc/RevertToHuman()
	if(!stored_human || QDELETED(stored_human))
		return
	var/turf/T = get_turf(src)
	// Move human body out
	stored_human.forceMove(T)
	// Transfer mind back
	if(mind)
		mind.transfer_to(stored_human)
	// Heal damage and revive
	stored_human.adjustBruteLoss(-stored_human.getBruteLoss())
	stored_human.adjustFireLoss(-stored_human.getFireLoss())
	stored_human.adjustToxLoss(-stored_human.getToxLoss())
	stored_human.adjustOxyLoss(-stored_human.getOxyLoss())
	stored_human.revive(full_heal = FALSE)
	// Move relic back to human and start cooldown
	if(stored_relic && !QDELETED(stored_relic))
		stored_relic.forceMove(stored_human)
		stored_relic.on_cooldown = TRUE
		addtimer(CALLBACK(stored_relic, TYPE_PROC_REF(/obj/item/ruin_relic/beeping_device, ResetCooldown)), 1200)
		if(stored_human.can_hold_items())
			stored_human.put_in_hands(stored_relic)
	to_chat(stored_human, span_notice("Your body snaps back to its original form. The device goes dim."))
	playsound(T, 'sound/machines/click.ogg', 30, TRUE)
	// Clean up
	if(revert_action)
		qdel(revert_action)
	stored_human = null
	stored_relic = null
	qdel(src)

/// On death, force revert the player back to human form.
/mob/living/simple_animal/hostile/shadebug/death(gibbed)
	if(stored_human)
		RevertToHuman()
		return
	return ..()

/mob/living/simple_animal/hostile/shadebug/Destroy()
	if(stored_human && !QDELETED(stored_human))
		stored_human.forceMove(get_turf(src))
		if(mind)
			mind.transfer_to(stored_human)
	if(stored_relic && !QDELETED(stored_relic))
		stored_relic.forceMove(get_turf(src))
	if(revert_action)
		qdel(revert_action)
		revert_action = null
	stored_human = null
	stored_relic = null
	return ..()

// ==================== SHADEBUG REVERT ACTION ====================

/// Action button that lets the shadebug player revert back to human form.
/datum/action/innate/shadebug_revert
	name = "Revert Form"
	desc = "Return to your human body."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/ruin_relics.dmi'
	button_icon_state = "oddity1"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/shadebug_revert/Activate()
	var/mob/living/simple_animal/hostile/shadebug/bug = owner
	if(!istype(bug))
		return
	bug.RevertToHuman()

// ==================== CREEPY DOLL ====================

/// Creepy Doll - While in combat, applies Sinking to nearby mobs. Use in hand to learn random info about a chosen player at the cost of 5 Mental Decay.
/obj/item/ruin_relic/creepy_doll
	name = "???"
	desc = "A small stitched doll with uneven button eyes. You feel a chill when it faces you, as if something behind those buttons is looking back."
	icon_state = "doll"
	w_class = WEIGHT_CLASS_SMALL
	verb_say = "chatters"
	/// Deciseconds between aura ticks
	var/tick_interval = 80
	/// world.time of last tick
	var/last_tick = 0

/obj/item/ruin_relic/creepy_doll/equipped(mob/user, slot)
	. = ..()
	last_tick = world.time
	START_PROCESSING(SSobj, src)

/obj/item/ruin_relic/creepy_doll/dropped(mob/user)
	. = ..()
	STOP_PROCESSING(SSobj, src)

/obj/item/ruin_relic/creepy_doll/process(delta_time)
	if(world.time < last_tick + tick_interval)
		return
	last_tick = world.time
	var/mob/living/holder = GetHolder()
	if(!holder)
		STOP_PROCESSING(SSobj, src)
		return
	if(!IsAttuned(holder))
		return
	if(!in_combat)
		return
	// Apply sinking to nearby mobs
	for(var/mob/living/L in range(2, holder))
		if(L == holder || L.stat == DEAD)
			continue
		L.apply_lc_sinking(5)
	// Occasionally chatter
	if(prob(25))
		var/list/phrases = list(
			"...hehehe...",
			"...don't leave me...",
			"...I see them...",
			"...they're sinking...",
			"...cold...",
		)
		say(pick(phrases))

/obj/item/ruin_relic/creepy_doll/CheckAttunement(mob/living/carbon/human/user)
	var/people_count = 0
	for(var/mob/living/carbon/human/H in view(7, user))
		if(H == user)
			continue
		people_count++
	return people_count >= 4

/obj/item/ruin_relic/creepy_doll/OnAttuneFail(mob/living/carbon/human/user)
	..()
	user.apply_lc_sinking(2)
	to_chat(user, span_warning("The doll's eyes glaze over. 'I need an audience... bring me more souls to watch.'"))
	// The doll gossips about you to everyone nearby
	var/list/gossip = list(
		"...hehe... [user.real_name] thinks they're special enough for me...",
		"...[user.real_name] tried to touch me... how desperate...",
		"...look at [user.real_name]... all alone with no friends to show me...",
		"...[user.real_name] wants my secrets... but has nothing to offer...",
	)
	say(pick(gossip))

/obj/item/ruin_relic/creepy_doll/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	var/mob/living/carbon/human/H = user
	// Build list of valid targets (includes dead)
	var/list/valid_targets = list()
	for(var/mob/living/carbon/human/target in GLOB.player_list)
		if(target == H)
			continue
		valid_targets += target
	if(!length(valid_targets))
		say("...nobody... nobody to whisper about...")
		return
	var/mob/living/carbon/human/chosen = tgui_input_list(H, "Who do you want to ask about?", "Creepy Doll", valid_targets)
	if(!chosen || QDELETED(chosen) || QDELETED(src))
		return
	if(!GetHolder())
		return
	// Cost: 5 Mental Decay
	H.apply_lc_mental_decay(5)
	// Dead targets only reveal death and distance
	if(chosen.stat == DEAD)
		say("...that one is gone... cold... empty...")
		var/dist = get_dist(H, chosen)
		if(H.z != chosen.z)
			to_chat(H, span_warning("[src] chatters: \"...[chosen.real_name] is dead... far away... on a different level...\""))
		else
			to_chat(H, span_warning("[src] chatters: \"...[chosen.real_name] is dead... about [dist] steps away... maybe you should visit...\""))
		return
	// Creepy lead-in dialogue
	var/list/lead_ins = list(
		"...I looked through their eyes... hehe...",
		"...the buttons showed me... yes...",
		"...don't tell them I told you...",
		"...I watched them while they slept...",
		"...they can't hide from me...",
	)
	say(pick(lead_ins))
	// Reveal a random piece of information about the chosen target
	var/list/info_options = list()
	// Health status
	var/health_pct = round((chosen.health / chosen.maxHealth) * 100)
	info_options += "[chosen.real_name] looks [health_pct > 75 ? "healthy" : (health_pct > 40 ? "wounded" : "near death")]... about [health_pct]%..."
	// Location
	var/area/target_area = get_area(chosen)
	if(target_area)
		info_options += "[chosen.real_name] is lurking around [target_area.name]... hehe..."
	// What they're holding
	var/obj/item/held = chosen.get_active_held_item()
	if(held)
		info_options += "[chosen.real_name] is clutching a [held.name]... it looked interesting..."
	else
		info_options += "[chosen.real_name] has empty hands... how boring..."
	// Job role
	if(chosen.mind?.assigned_role)
		info_options += "[chosen.real_name] works as a [chosen.mind.assigned_role]... how fitting..."
	// Sanity
	if(chosen.sanityhealth < chosen.maxSanity * 0.5)
		info_options += "[chosen.real_name]'s mind is fraying... hehehe... just like yours..."
	else
		info_options += "[chosen.real_name]'s mind seems... stable... for now..."
	// Distance
	var/dist = get_dist(H, chosen)
	if(H.z != chosen.z)
		info_options += "[chosen.real_name] is... far away... on a different level... I can barely feel them..."
	else
		info_options += "[chosen.real_name] is about [dist] steps away... [dist < 10 ? "so close... hehe..." : "quite a walk..."]"
	// Nearby people
	var/list/nearby_names = list()
	for(var/mob/living/carbon/human/neighbor in range(5, chosen))
		if(neighbor == chosen)
			continue
		if(neighbor.stat == DEAD)
			continue
		nearby_names += neighbor.real_name
	if(length(nearby_names))
		info_options += "[chosen.real_name] is not alone... I see [english_list(nearby_names)] nearby... how cozy..."
	else
		info_options += "[chosen.real_name] is all alone... nobody around... how sad..."
	// Pick a random piece of info and whisper it
	var/reveal = pick(info_options)
	to_chat(H, span_warning("[src] chatters: \"...[reveal]\""))

// ==================== FLAYED SKIN ====================

/// Flayed Skin - Changes face overlay based on holder's HP. While in combat, grants Offense Level Up at high/low HP
/// and Defense Level Up at mid HP. Below 20% HP, also applies Fragile.
/obj/item/ruin_relic/flayed_skin
	name = "???"
	desc = "A taut piece of skin-like material stretched over a thin frame. A face is visible on its surface, its expression shifting when you aren't looking."
	icon_state = "skin"
	w_class = WEIGHT_CLASS_SMALL
	/// Deciseconds between mood checks
	var/tick_interval = 50
	/// world.time of last tick
	var/last_tick = 0
	/// Current face state for tracking changes
	var/current_face = ""
	/// The face overlay appearance
	var/mutable_appearance/face_overlay

/obj/item/ruin_relic/flayed_skin/equipped(mob/user, slot)
	. = ..()
	last_tick = world.time
	START_PROCESSING(SSobj, src)

/obj/item/ruin_relic/flayed_skin/dropped(mob/user)
	. = ..()
	STOP_PROCESSING(SSobj, src)
	RemoveFace()

/obj/item/ruin_relic/flayed_skin/CheckAttunement(mob/living/carbon/human/user)
	return user.getFireLoss() > 0

/obj/item/ruin_relic/flayed_skin/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The skin writhes and recoils. It wants flesh that knows the kiss of flame."))
	user.apply_lc_burn(3)
	to_chat(user, span_userdanger("The skin flares red-hot, searing your fingers!"))

/obj/item/ruin_relic/flayed_skin/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	to_chat(user, span_notice("The skin shifts its expression in acknowledgment."))

/obj/item/ruin_relic/flayed_skin/process(delta_time)
	if(world.time < last_tick + tick_interval)
		return
	last_tick = world.time
	var/mob/living/holder = GetHolder()
	if(!holder)
		STOP_PROCESSING(SSobj, src)
		RemoveFace()
		return
	if(!IsAttuned(holder))
		RemoveFace()
		return
	var/hp_percent = holder.health / holder.maxHealth
	var/new_face
	if(hp_percent > 0.8)
		new_face = "cheerful"
		if(in_combat)
			holder.apply_lc_offense_level_up(8)
	else if(hp_percent > 0.6)
		new_face = "happy"
		if(in_combat)
			holder.apply_lc_defense_level_up(8)
	else if(hp_percent > 0.4)
		new_face = "neutral"
	else if(hp_percent > 0.2)
		new_face = "sad"
		if(in_combat)
			holder.apply_lc_defense_level_up(12)
			holder.apply_lc_fragile(2)
	else
		new_face = "angry"
		if(in_combat)
			holder.apply_lc_offense_level_up(12)
			holder.apply_lc_fragile(2)
	UpdateFace(new_face)

/// Updates the face overlay on the skin.
/obj/item/ruin_relic/flayed_skin/proc/UpdateFace(new_face)
	if(new_face == current_face)
		return
	RemoveFace()
	current_face = new_face
	face_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects10x10.dmi', new_face)
	add_overlay(face_overlay)

/// Removes the face overlay.
/obj/item/ruin_relic/flayed_skin/proc/RemoveFace()
	if(face_overlay)
		cut_overlay(face_overlay)
		face_overlay = null
	current_face = ""

/obj/item/ruin_relic/flayed_skin/Destroy()
	RemoveFace()
	return ..()

// ==================== PURPLE DEVICE ====================

/// Purple Device - Consume 10% max SP to randomize your appearance for 60 seconds. 90-second cooldown.
/obj/item/ruin_relic/purple_device
	name = "???"
	desc = "A smooth purple device that fits in the palm of your hand. Its surface shimmers faintly, and your reflection in it never quite looks like you."
	icon_state = "oddity"
	w_class = WEIGHT_CLASS_SMALL
	/// Whether the device is on cooldown
	var/on_cooldown = FALSE
	/// Whether the user is currently disguised
	var/is_disguised = FALSE
	/// Weakref to the mob currently disguised by this device
	var/datum/weakref/disguised_mob_ref
	/// Stored original appearance values
	var/original_name
	var/original_hairstyle
	var/original_facial_hairstyle
	var/original_hair_color
	var/original_facial_hair_color
	var/original_skin_tone

/obj/item/ruin_relic/purple_device/CheckAttunement(mob/living/carbon/human/user)
	return !!user.wear_mask

/obj/item/ruin_relic/purple_device/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The device flickers and rejects you. It seeks someone who already hides their face."))
	// Scramble the user's name for 30 seconds — identity confusion
	var/real = user.real_name
	user.real_name = "???"
	user.name = "???"
	to_chat(user, span_userdanger("Your sense of self blurs — you can't remember your own name!"))
	addtimer(CALLBACK(src, PROC_REF(RestoreName), user, real), 30 SECONDS)

/obj/item/ruin_relic/purple_device/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	if(is_disguised)
		to_chat(user, span_warning("The device is already sustaining a disguise."))
		return
	if(on_cooldown)
		to_chat(user, span_warning("The device's surface is dull. It needs time to recharge."))
		return
	var/mob/living/carbon/human/H = user
	// Cost: 10% of max SP
	var/sp_cost = H.maxSanity * 0.1
	if(H.sanityhealth <= sp_cost)
		to_chat(H, span_warning("You don't have enough mental fortitude to use this."))
		return
	H.adjustSanityLoss(sp_cost)
	// Store original appearance
	original_name = H.real_name
	original_hairstyle = H.hairstyle
	original_facial_hairstyle = H.facial_hairstyle
	original_hair_color = H.hair_color
	original_facial_hair_color = H.facial_hair_color
	original_skin_tone = H.skin_tone
	// Randomize appearance
	H.real_name = random_unique_name(H.gender)
	H.name = H.real_name
	H.hairstyle = pick(GLOB.hairstyles_list)
	H.facial_hairstyle = pick(GLOB.facial_hairstyles_list)
	H.hair_color = random_color()
	H.facial_hair_color = random_color()
	H.skin_tone = pick(GLOB.skin_tones)
	H.update_hair()
	H.update_body()
	is_disguised = TRUE
	disguised_mob_ref = WEAKREF(H)
	to_chat(H, span_notice("Your features shift and blur. You feel like someone else."))
	H.visible_message(span_warning("[original_name]'s features ripple and change before your eyes."))
	playsound(src, 'sound/magic/lightningshock.ogg', 30, TRUE)
	// Revert after 60 seconds
	addtimer(CALLBACK(src, PROC_REF(RevertDisguise)), 600)

/// Reverts the disguised mob back to their original appearance.
/obj/item/ruin_relic/purple_device/proc/RevertDisguise()
	var/mob/living/carbon/human/disguised_mob = disguised_mob_ref?.resolve()
	if(!is_disguised || !disguised_mob)
		is_disguised = FALSE
		disguised_mob_ref = null
		StartCooldown()
		return
	disguised_mob.real_name = original_name
	disguised_mob.name = original_name
	disguised_mob.hairstyle = original_hairstyle
	disguised_mob.facial_hairstyle = original_facial_hairstyle
	disguised_mob.hair_color = original_hair_color
	disguised_mob.facial_hair_color = original_facial_hair_color
	disguised_mob.skin_tone = original_skin_tone
	disguised_mob.update_hair()
	disguised_mob.update_body()
	to_chat(disguised_mob, span_notice("Your features snap back to normal. The device goes dim."))
	playsound(src, 'sound/machines/click.ogg', 20, TRUE)
	is_disguised = FALSE
	disguised_mob_ref = null
	StartCooldown()

/// Starts the 90-second use cooldown.
/obj/item/ruin_relic/purple_device/proc/StartCooldown()
	on_cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(ResetCooldown)), 900)

/// Resets the use cooldown.
/obj/item/ruin_relic/purple_device/proc/ResetCooldown()
	on_cooldown = FALSE

/// Restores a user's name after the attunement fail punishment.
/obj/item/ruin_relic/purple_device/proc/RestoreName(mob/living/carbon/human/user, original_real_name)
	if(!user || QDELETED(user))
		return
	// Only restore if still scrambled (don't overwrite a disguise)
	if(user.real_name == "???")
		user.real_name = original_real_name
		user.name = original_real_name
		to_chat(user, span_notice("Your sense of identity returns. You remember who you are."))

// ==================== STRANGE BOX ====================

/// Strange Box - Shake it to produce 1-5 random grown food at the cost of 30 hunger per item. 60-second cooldown.
/obj/item/ruin_relic/strange_box
	name = "???"
	desc = "A small, dark, featureless box. It doesn't open, but something inside shifts when you tilt it."
	icon_state = "oddity5"
	w_class = WEIGHT_CLASS_SMALL
	verb_say = "rattles"
	/// Whether the box is on cooldown
	var/on_cooldown = FALSE
	/// Whether the box is currently being shaken
	var/shaking = FALSE
	/// Hunger cost per item produced
	var/hunger_cost_per_item = 30
	/// Cached list of valid food subtypes
	var/static/list/food_subtypes

/obj/item/ruin_relic/strange_box/CheckAttunement(mob/living/carbon/human/user)
	return user.nutrition < 300

/obj/item/ruin_relic/strange_box/OnAttuneFail(mob/living/carbon/human/user)
	..()
	to_chat(user, span_warning("The box rattles dismissively. Perhaps it wants someone who knows hunger."))
	// The box feeds on you instead
	user.adjust_nutrition(-100)
	to_chat(user, span_userdanger("Your stomach twists painfully as the box drains your nourishment!"))

/obj/item/ruin_relic/strange_box/attack_self(mob/living/user)
	if(!ishuman(user))
		return
	if(!IsAttuned(user))
		TryAttune(user)
		return
	if(shaking)
		return
	if(on_cooldown)
		to_chat(user, span_warning("Whatever is inside has gone quiet. Give it time."))
		return
	if(user.nutrition <= NUTRITION_LEVEL_STARVING)
		to_chat(user, span_warning("You're too hungry to shake the box. You need to eat something first."))
		return
	shaking = TRUE
	user.visible_message(
		span_notice("[user] shakes [src]. Something rattles inside."),
		span_notice("You shake [src]. Something shifts within...")
	)
	if(!do_after(user, 30, src))
		shaking = FALSE
		return
	shaking = FALSE
	// Build the food type cache once
	if(!food_subtypes)
		food_subtypes = subtypesof(/obj/item/food/grown)
	var/food_type = pick(food_subtypes)
	var/amount = rand(1, 5)
	// Hunger cost scales with amount produced
	var/total_cost = hunger_cost_per_item * amount
	user.adjust_nutrition(-total_cost)
	// Spawn the food at the user's feet
	var/turf/T = get_turf(user)
	for(var/i in 1 to amount)
		new food_type(T)
	to_chat(user, span_notice("The box produces [amount] [initial(food_type:name)]\s. Your stomach growls in protest."))
	var/list/phrases = list(
		"...click...",
		"...good...",
		"...again...",
		"...soon...",
		"...yes...",
	)
	say(pick(phrases))
	on_cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(ResetCooldown)), 600)

/// Resets the use cooldown.
/obj/item/ruin_relic/strange_box/proc/ResetCooldown()
	on_cooldown = FALSE

// ==================== RELIC SPAWN LANDMARK ====================

/// Landmark that spawns a random ruin relic weighted by rarity, then deletes itself.
/obj/effect/landmark/relic_spawn
	name = "relic spawn"
	desc = "Spawns a random ruin relic. Notify a coder if you see this."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x4"

/obj/effect/landmark/relic_spawn/Initialize()
	. = ..()
	// Weights: rarity 1 = 30, rarity 2 = 15, rarity 3 = 8, rarity 4 = 3, rarity 5 = 1
	var/relic_type = pick(
		30;/obj/item/ruin_relic/strange_box,
		30;/obj/item/ruin_relic/purple_device,
		30;/obj/item/ruin_relic/creepy_doll,
		30;/obj/item/ruin_relic/beeping_device,
		30;/obj/item/ruin_relic/flayed_skin,
		30;/obj/item/ruin_relic/tesu_doll,
		30;/obj/item/ruin_relic/pulsing_sphere,
		15;/obj/item/ruin_relic/ravenous_vessel,
		15;/obj/item/ruin_relic/violet_mass,
		8;/obj/item/ruin_relic/golden_locket,
		8;/obj/item/ruin_relic/void_reliquary,
		3;/obj/item/ruin_relic/effigy_tablet,
		3;/obj/item/ruin_relic/golden_figure,
		1;/obj/item/ruin_relic/corrupted_skull,
	)
	new relic_type(get_turf(src))
	qdel(src)
