/*
 * The Sage — Phase 3 support mob (counter-argument + heals).
 *
 * Build-order step 2: bare mob shell + fade-in.
 * Build-order step 15: support kit — healing wells, cleanse pulse,
 * defense bubble, plus the TickSupport() AI dispatcher.
 */

/mob/living/simple_animal/hostile/serio_sage
	name = "the Sage"
	desc = "A figure whose voice has been waiting for this exchange."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "priest"
	icon_living = "priest"
	icon_dead = "priest"
	faction = list("neutral")
	maxHealth = 800
	health = 800
	melee_damage_lower = 0
	melee_damage_upper = 0
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	density = TRUE
	speed = 4
	move_to_delay = 999
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()
	gold_core_spawnable = NO_SPAWN
	/// Back-ref to the Caretaker that brought the Sage onto the stage.
	var/mob/living/simple_animal/hostile/serio_caretaker/parent_caretaker
	/// Sibling support mob.
	var/mob/living/simple_animal/hostile/serio_knight/knight_ref
	// ---- Support kit state ----
	var/well_cooldown_until = 0
	var/cleanse_cooldown_until = 0
	var/bubble_cooldown_until = 0

/mob/living/simple_animal/hostile/serio_sage/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF)
	alpha = 0
	animate(src, alpha = 255, time = 1 SECONDS)
	// Start the support AI loop after the fade-in completes so the
	// Sage doesn't try to act mid-arrival.
	addtimer(CALLBACK(src, PROC_REF(TickSupport)), 2 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_sage/Destroy()
	if(parent_caretaker && !QDELETED(parent_caretaker) && parent_caretaker.sage_ref == src)
		parent_caretaker.sage_ref = null
	parent_caretaker = null
	knight_ref = null
	return ..()

/// Stationary for the duration of Phase 3.
/mob/living/simple_animal/hostile/serio_sage/Move()
	return FALSE

/mob/living/simple_animal/hostile/serio_sage/AttackingTarget(atom/attacked_target)
	return FALSE

// ---------- Support kit AI loop ----------

/// 1s tick. Each branch evaluates its own cooldown and trigger
/// independently — healing well drops on a slow timer, cleanse fires
/// when a nearby human has enough decay stacks, defense bubble fires
/// when an anti-Knight projectile is in flight toward the Knight.
/mob/living/simple_animal/hostile/serio_sage/proc/TickSupport()
	if(QDELETED(src) || stat == DEAD)
		return
	if(world.time >= well_cooldown_until)
		DropHealingWell()
	if(world.time >= cleanse_cooldown_until && FindCleanseTarget())
		FireCleansePulse()
	if(world.time >= bubble_cooldown_until && FindIncomingAntiKnightProjectile())
		var/mob/living/carbon/human/target = FindBubbleTarget()
		if(target)
			ProjectDefenseBubble(target)
	addtimer(CALLBACK(src, PROC_REF(TickSupport)), 1 SECONDS, TIMER_STOPPABLE)

// ---------- Healing well ----------

/// Drops a healing word marker on a tile near a player. Marker is
/// inert until a player melee-hits it; on hit it charges 3s then
/// pulses a 5×5 heal.
/mob/living/simple_animal/hostile/serio_sage/proc/DropHealingWell()
	var/list/turf/candidates = list()
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H.stat == DEAD)
			continue
		for(var/turf/T in range(2, get_turf(H)))
			if(T.density)
				continue
			candidates += T
	if(!length(candidates))
		return
	var/turf/picked = pick(candidates)
	new /obj/effect/serio_healing_well(picked, src)
	visible_message(span_nicegreen("[src] places a healing word on the floor."))
	well_cooldown_until = world.time + 30 SECONDS

/obj/effect/serio_healing_well
	name = "healing word"
	desc = "Gold light gathers at the floor. Strike it to make it bloom."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	color = "#ffd56b"
	alpha = 220
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_ICON
	anchored = TRUE
	density = FALSE
	var/activated = FALSE
	var/heal_amount = 80
	var/mob/living/source

/obj/effect/serio_healing_well/Initialize(mapload, mob/living/new_source)
	. = ..()
	source = new_source

/obj/effect/serio_healing_well/attack_hand(mob/user)
	if(activated)
		return
	if(!ishuman(user))
		return
	activated = TRUE
	visible_message(span_nicegreen("The healing word brightens, gathering its bloom."))
	animate(src, alpha = 255, time = 3 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(Pulse)), 3 SECONDS, TIMER_STOPPABLE)

/obj/effect/serio_healing_well/proc/Pulse()
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return
	new /obj/effect/temp_visual/serio_heal_burst(T)
	for(var/mob/living/carbon/human/H in range(2, T))
		if(H.stat == DEAD)
			continue
		H.adjustBruteLoss(-heal_amount, forced = TRUE)
		H.adjustFireLoss(-heal_amount, forced = TRUE)
		H.adjustSanityLoss(-heal_amount, forced = TRUE)
	qdel(src)

/obj/effect/temp_visual/serio_heal_burst
	name = "healing bloom"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	color = "#ffd56b"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1 SECONDS
	alpha = 220

// ---------- Cleanse pulse ----------

/// Finds the first human in cleanse range with ≥15 decay stacks.
/// Returns the human, or null if no qualifying target.
/mob/living/simple_animal/hostile/serio_sage/proc/FindCleanseTarget()
	for(var/mob/living/carbon/human/H in view(6, src))
		if(H.stat == DEAD)
			continue
		var/datum/status_effect/stacking/lc_mental_decay/D = H.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
		if(D && D.stacks >= 15)
			return H
	return null

/// Sends a wave that clears mental_decay stacks and safely removes
/// mental_detonate primers without triggering the shatter payoff.
/mob/living/simple_animal/hostile/serio_sage/proc/FireCleansePulse()
	visible_message(span_nicegreen("[src] speaks; the decay quiets."))
	new /obj/effect/temp_visual/serio_cleanse_wave(get_turf(src))
	for(var/mob/living/carbon/human/H in view(6, src))
		if(H.stat == DEAD)
			continue
		var/datum/status_effect/stacking/lc_mental_decay/D = H.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
		if(D)
			qdel(D)
		var/datum/status_effect/mental_detonate/MD = H.has_status_effect(/datum/status_effect/mental_detonate)
		if(MD)
			// qdel'ing the status removes it cleanly via the standard
			// status-effect Destroy path — does NOT call shatter().
			qdel(MD)
	cleanse_cooldown_until = world.time + 15 SECONDS

/obj/effect/temp_visual/serio_cleanse_wave
	name = "cleanse"
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldsparkles"
	color = "#ffd56b"
	alpha = 220
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	duration = 1 SECONDS

// ---------- Defense bubble ----------

/// Iterates projectiles in view of the Sage looking for an in-flight
/// serio_lance aimed at the Knight. Returns the projectile or null.
/mob/living/simple_animal/hostile/serio_sage/proc/FindIncomingAntiKnightProjectile()
	if(QDELETED(knight_ref))
		return null
	for(var/obj/projectile/serio_lance/P in view(15, src))
		if(P.fired)
			return P
	return null

/// Finds a player without a defense bubble already on them. Picks a
/// human within view 15 of the Sage; null if no eligible target.
/mob/living/simple_animal/hostile/serio_sage/proc/FindBubbleTarget()
	for(var/mob/living/carbon/human/H in view(15, src))
		if(H.stat == DEAD)
			continue
		if(H.has_status_effect(/datum/status_effect/serio_defense_bubble))
			continue
		return H
	return null

/// Projects a defense bubble onto a player. The player can take up to
/// N anti-Knight lance hits without losing HP — the bubble absorbs
/// them. N scales by bracket: 1/2/3 for B1/B2/B3.
/mob/living/simple_animal/hostile/serio_sage/proc/ProjectDefenseBubble(mob/living/carbon/human/H)
	if(QDELETED(H))
		return
	var/charges = 1
	if(parent_caretaker && !QDELETED(parent_caretaker.parent_crystal))
		switch(parent_caretaker.parent_crystal.current_bracket)
			if(1)
				charges = 1
			if(2)
				charges = 2
			else
				charges = 3
	var/datum/status_effect/serio_defense_bubble/B = H.apply_status_effect(/datum/status_effect/serio_defense_bubble)
	if(B)
		B.charges = charges
	visible_message(span_nicegreen("[src] projects a shimmering bubble onto [H]."))
	bubble_cooldown_until = world.time + 20 SECONDS

/datum/status_effect/serio_defense_bubble
	id = "serio_defense_bubble"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = null
	var/charges = 1
	var/mutable_appearance/bubble_overlay

/datum/status_effect/serio_defense_bubble/on_apply()
	. = ..()
	if(!owner)
		return FALSE
	bubble_overlay = mutable_appearance('icons/effects/effects.dmi', "shieldsparkles", ABOVE_MOB_LAYER)
	bubble_overlay.color = "#ffd56b"
	bubble_overlay.alpha = 220
	owner.add_overlay(bubble_overlay)

/datum/status_effect/serio_defense_bubble/on_remove()
	if(owner && bubble_overlay)
		owner.cut_overlay(bubble_overlay)
	bubble_overlay = null
	return ..()

/datum/status_effect/serio_defense_bubble/proc/ConsumeCharge()
	if(charges <= 0)
		return
	charges--
	if(owner)
		owner.visible_message(span_warning("The bubble around [owner] absorbs the lance!"))
	if(charges <= 0)
		if(owner)
			owner.visible_message(span_warning("The bubble pops."))
		qdel(src)
