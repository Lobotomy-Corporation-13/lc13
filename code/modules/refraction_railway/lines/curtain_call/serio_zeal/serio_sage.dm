/*
 * The Sage — Phase 2 support mob (counter-argument + heals).
 *
 * Build-order step 2: bare mob shell + fade-in.
 * Build-order step 15: support kit — healing wells, cleanse pulse,
 * defense bubble, plus the TickSupport() AI dispatcher.
 */

/mob/living/simple_animal/hostile/serio_sage
	name = "the Sage"
	desc = "A figure whose voice has been waiting for this exchange."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "sage"
	icon_living = "sage"
	icon_dead = "sage"
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
	/// Back-ref to the Overseer that brought the Sage onto the stage.
	var/mob/living/simple_animal/hostile/serio_overseer/parent_overseer
	/// Sibling support mob.
	var/mob/living/simple_animal/hostile/serio_knight/knight_ref
	// ---- Support kit state ----
	/// Unified aura cooldown. Every 20s the Sage fires one aura, picked
	/// by TryAura: cleanse if any player within 7 has 15+ decay stacks,
	/// heal otherwise.
	var/aura_cooldown_until = 0
	var/bubble_cooldown_until = 0
	/// Reusable visual pool for the aura sparkles. Created lazily on
	/// the first aura cast so we don't allocate before Phase 2.
	var/datum/reusable_visual_pool/sage_rvp
	// ---- Healing crystal state ----
	/// Cooldown timer for placing healing crystals.
	var/crystal_cooldown_until = 0
	/// Max alive at once.
	var/crystal_max_alive = 3
	/// Live healing-word refs the Sage placed. Lets us cap the count
	/// + clean up on Destroy without iterating world.
	var/list/spawned_wells = list()
	/// Humans currently carrying a Sage-projected defense bubble.
	/// Walked on Destroy so dead-with-shield carriers don't keep the
	/// "shield1" overlay after the Sage is gone.
	var/list/bubbled_humans = list()
	/// Minimum tile spacing between two crystals at spawn time.
	var/crystal_min_spacing = 2
	/// One-time tutorial line on the first crystal drop.
	var/crystal_tutorial_said = FALSE

/mob/living/simple_animal/hostile/serio_sage/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF)
	alpha = 0
	animate(src, alpha = 255, time = 1 SECONDS)
	// Start the support AI loop after the fade-in completes so the
	// Sage doesn't try to act mid-arrival.
	addtimer(CALLBACK(src, PROC_REF(TickSupport)), 2 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_sage/Destroy()
	// Clean up every healing word this Sage placed by walking the
	// tracking list — no world iteration. Each well may already have
	// qdel'd itself (struck, charged, pulsed) so QDELETED-skip first.
	for(var/obj/structure/serio_healing_well/W as anything in spawned_wells)
		if(!QDELETED(W))
			qdel(W)
	spawned_wells.Cut()
	// Clean up the defense-bubble status on every player the Sage ever
	// shielded — dead carriers with un-consumed charges would otherwise
	// keep the "shield1" overlay forever after the Sage is gone.
	for(var/mob/living/carbon/human/H as anything in bubbled_humans)
		if(QDELETED(H))
			continue
		var/datum/status_effect/serio_defense_bubble/B = H.has_status_effect(/datum/status_effect/serio_defense_bubble)
		if(B)
			qdel(B)
	bubbled_humans.Cut()
	if(parent_overseer && !QDELETED(parent_overseer) && parent_overseer.sage_ref == src)
		parent_overseer.sage_ref = null
	parent_overseer = null
	knight_ref = null
	return ..()

/// Stationary for the duration of Phase 2.
/mob/living/simple_animal/hostile/serio_sage/Move()
	return FALSE

/mob/living/simple_animal/hostile/serio_sage/AttackingTarget(atom/attacked_target)
	return FALSE

// ---------- Support kit AI loop ----------

/// 1s tick. Aura branch fires on a unified 20s cooldown — TryAura picks
/// cleanse if any player within 7 has 15+ decay stacks, otherwise heal.
/// Bubble branch fires independently when an anti-Knight lance is in
/// flight toward the Knight and a player without a bubble exists.
/mob/living/simple_animal/hostile/serio_sage/proc/TickSupport()
	if(QDELETED(src) || stat == DEAD)
		return
	if(world.time >= aura_cooldown_until)
		TryAura()
	if(world.time >= crystal_cooldown_until)
		DropHealingCrystal()
	if(world.time >= bubble_cooldown_until && FindIncomingAntiKnightProjectile())
		var/mob/living/carbon/human/target = FindBubbleTarget()
		if(target)
			ProjectDefenseBubble(target)
	addtimer(CALLBACK(src, PROC_REF(TickSupport)), 1 SECONDS, TIMER_STOPPABLE)

// ---------- Aura dispatcher ----------

/// Locks the 20s aura cooldown, then picks cleanse or heal. Triggered
/// every 20s by TickSupport.
/mob/living/simple_animal/hostile/serio_sage/proc/TryAura()
	aura_cooldown_until = world.time + 20 SECONDS
	if(HasNearbyDecayTarget())
		FireCleansePulse()
	else
		FireHealPulse()

/// Returns TRUE if any live human within 7 tiles of the Sage has 15+
/// stacks of mental decay — the cleanse-aura trigger condition.
/mob/living/simple_animal/hostile/serio_sage/proc/HasNearbyDecayTarget()
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H.stat == DEAD)
			continue
		var/datum/status_effect/stacking/lc_mental_decay/D = H.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
		if(D && D.stacks >= 15)
			return TRUE
	return FALSE

// ---------- Heal aura ----------

/// Expanding-ring heal cast directly from the Sage. Gold sparkles
/// ripple outward 5 rings (11×11 footprint), restoring 50 HP / SP to
/// every human the ring sweeps over (de-duped — each player heals
/// once per cast). Same expansion pattern as FireCleansePulse for
/// visual consistency; colour swap is the only differentiator.
/mob/living/simple_animal/hostile/serio_sage/proc/FireHealPulse()
	set waitfor = FALSE
	visible_message(span_nicegreen("[src] hums; the air warms."))
	if(!sage_rvp)
		sage_rvp = new(100)
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/list/healed = list()
	sage_rvp.NewSparkles(center, 10, "#ffd56b")
	HealTargetsOnTile(center, healed)
	// 8 rings — 17×17 footprint.
	for(var/i = 1 to 8)
		var/list/ring = SerioGetExpandingRing(center, i)
		for(var/turf/T as anything in ring)
			if(!isturf(T))
				continue
			sage_rvp.NewSparkles(T, 10, "#ffd56b")
			HealTargetsOnTile(T, healed)
		SLEEP_CHECK_DEATH(1.5)

/mob/living/simple_animal/hostile/serio_sage/proc/HealTargetsOnTile(turf/T, list/healed)
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		if(H in healed)
			continue
		healed += H
		H.adjustBruteLoss(-50, forced = TRUE)
		H.adjustFireLoss(-50, forced = TRUE)
		H.adjustSanityLoss(-50, forced = TRUE)

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
	// 3s duration matches the crystal's charge window so the warning
	// telegraphs the full pre-pulse charge time.
	duration = 3 SECONDS
	alpha = 220

// ---------- Cleanse aura ----------

/// Expanding-ring cleanse: cyan sparkles ripple outward from the Sage
/// over 5 rings (11×11 footprint), clearing mental_decay stacks and
/// removing mental_detonate primers (without firing shatter()) from
/// any human the ring sweeps over.
/mob/living/simple_animal/hostile/serio_sage/proc/FireCleansePulse()
	set waitfor = FALSE
	visible_message(span_nicegreen("[src] speaks; the decay quiets."))
	if(!sage_rvp)
		sage_rvp = new(100)
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/list/cleansed = list()
	sage_rvp.NewSparkles(center, 10, "#b3e0ff")
	CleanseTargetsOnTile(center, cleansed)
	// 8 rings — matches the heal aura footprint.
	for(var/i = 1 to 8)
		var/list/ring = SerioGetExpandingRing(center, i)
		for(var/turf/T as anything in ring)
			if(!isturf(T))
				continue
			sage_rvp.NewSparkles(T, 10, "#b3e0ff")
			CleanseTargetsOnTile(T, cleansed)
		SLEEP_CHECK_DEATH(1.5)

/mob/living/simple_animal/hostile/serio_sage/proc/CleanseTargetsOnTile(turf/T, list/cleansed)
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		if(H in cleansed)
			continue
		cleansed += H
		var/datum/status_effect/stacking/lc_mental_decay/D = H.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
		if(D)
			qdel(D)
		var/datum/status_effect/mental_detonate/MD = H.has_status_effect(/datum/status_effect/mental_detonate)
		if(MD)
			// qdel'ing the status removes it cleanly via the standard
			// status-effect Destroy path — does NOT call shatter().
			qdel(MD)

/// Returns the 1-tile-wide perimeter ring of `radius` around `center`.
/// 4 getline() edges per ring, mirroring white_night.dm:151. Used by
/// both the Sage's cleanse pulse and the healing word's heal pulse to
/// produce expanding-AoE visuals.
/proc/SerioGetExpandingRing(turf/center, radius)
	if(!center || radius <= 0)
		return list()
	var/cx = center.x
	var/cy = center.y
	var/cz = center.z
	var/list/ring = list()
	if(cy - radius > 0)
		ring += getline(locate(max(cx - radius, 1), cy - radius, cz), locate(min(cx + radius - 1, world.maxx), cy - radius, cz))
	if(cx + radius <= world.maxx)
		ring += getline(locate(cx + radius, max(cy - radius, 1), cz), locate(cx + radius, min(cy + radius - 1, world.maxy), cz))
	if(cy + radius <= world.maxy)
		ring += getline(locate(min(cx + radius, world.maxx), cy + radius, cz), locate(max(cx - radius + 1, 1), cy + radius, cz))
	if(cx - radius > 0)
		ring += getline(locate(cx - radius, min(cy + radius, world.maxy), cz), locate(cx - radius, max(cy - radius + 1, 1), cz))
	return ring

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
	if(parent_overseer && !QDELETED(parent_overseer.parent_crystal))
		switch(parent_overseer.parent_crystal.current_bracket)
			if(1)
				charges = 1
			if(2)
				charges = 2
			else
				charges = 3
	// 1-second beam from the Sage to the target so the projection
	// reads as a connection — players see *who* is being shielded.
	Beam(H, "light_beam", time = 1 SECONDS, beam_type = /obj/effect/ebeam/serio_sage_shield)
	var/datum/status_effect/serio_defense_bubble/B = H.apply_status_effect(/datum/status_effect/serio_defense_bubble)
	if(B)
		B.charges = charges
		bubbled_humans |= H
	visible_message(span_nicegreen("[src] projects a shimmering bubble onto [H]."))
	bubble_cooldown_until = world.time + 20 SECONDS

/obj/effect/ebeam/serio_sage_shield
	color = "#1e2a8c"

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
	bubble_overlay = mutable_appearance('icons/effects/effects.dmi', "shield1", ABOVE_MOB_LAYER)
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

// ---------- Healing crystals (struck-to-bloom) ----------

/// Drops one healing crystal on a tile near a player. Crystal is inert
/// until struck with a weapon or bullet; on strike it charges 3s and
/// pulses a 5×5 heal. Capped at `crystal_max_alive`, with a
/// `crystal_min_spacing` tile buffer between any two.
/mob/living/simple_animal/hostile/serio_sage/proc/DropHealingCrystal()
	crystal_cooldown_until = world.time + 15 SECONDS
	// Compact the tracking list (drop qdel'd wells) and use it as the
	// cap source — no world iteration.
	listclearnulls(spawned_wells)
	for(var/obj/structure/serio_healing_well/W as anything in spawned_wells)
		if(QDELETED(W))
			spawned_wells -= W
	if(length(spawned_wells) >= crystal_max_alive)
		return
	var/list/turf/candidates = list()
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H.stat == DEAD)
			continue
		for(var/turf/T in range(2, get_turf(H)))
			if(T.density)
				continue
			// Skip tiles with a mob already on them — no overlapping
			// wells with players, the Knight, the Sage, etc.
			var/blocked = FALSE
			for(var/mob/living/L in T)
				if(L.stat == DEAD)
					continue
				blocked = TRUE
				break
			if(blocked)
				continue
			var/too_close = FALSE
			for(var/obj/structure/serio_healing_well/W as anything in spawned_wells)
				if(get_dist(T, get_turf(W)) <= crystal_min_spacing)
					too_close = TRUE
					break
			if(too_close)
				continue
			candidates += T
	if(!length(candidates))
		return
	var/turf/picked = pick(candidates)
	spawned_wells += new /obj/structure/serio_healing_well(picked, src)
	visible_message(span_nicegreen("[src] places a healing word on the floor."))
	if(!crystal_tutorial_said)
		crystal_tutorial_said = TRUE
		say("Strike the ice with a weapon — it holds what you need to mend.")

/obj/structure/serio_healing_well
	name = "healing word"
	desc = "A chunk of resonant ice. Strike it with a weapon or a bullet to release its bloom."
	icon = 'icons/obj/flora/icedecor.dmi'
	icon_state = "ice_chunk1"
	color = "#88ffaa"
	density = FALSE
	anchored = TRUE
	max_integrity = 1000
	var/activated = FALSE
	var/heal_amount = 80
	var/mob/living/source

/obj/structure/serio_healing_well/Initialize(mapload, mob/living/new_source)
	. = ..()
	source = new_source

/// Both attack hooks call ..() so the parent's normal hit-feedback
/// path runs (sound, animation, integrity tick). Activate() is
/// idempotent so subsequent hits don't restart the charge.
/obj/structure/serio_healing_well/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	Activate()
	return ..()

/obj/structure/serio_healing_well/attackby(obj/item/I, mob/user, params)
	Activate()
	return ..()

/obj/structure/serio_healing_well/proc/Activate()
	if(activated)
		return
	activated = TRUE
	visible_message(span_nicegreen("The healing word brightens, gathering its bloom."))
	// 3-second warning that telegraphs where the bloom will land.
	// Duration matches the Pulse charge time so the visual fades right
	// as the heal triggers.
	new /obj/effect/temp_visual/serio_heal_burst(get_turf(src))
	addtimer(CALLBACK(src, PROC_REF(Pulse)), 3 SECONDS, TIMER_STOPPABLE)

/obj/structure/serio_healing_well/proc/Pulse()
	set waitfor = FALSE
	if(QDELETED(src))
		return
	var/turf/T = get_turf(src)
	if(!T)
		qdel(src)
		return
	// Warning visual spawned at Activate carries through to here; the
	// expanding ring is the bloom itself.
	var/datum/reusable_visual_pool/pool = new(30)
	var/list/healed = list()
	pool.NewSparkles(T, 10, "#ffd56b")
	HealOnTile(T, healed)
	for(var/i = 1 to 2)
		var/list/ring = SerioGetExpandingRing(T, i)
		for(var/turf/tile as anything in ring)
			if(!isturf(tile))
				continue
			pool.NewSparkles(tile, 10, "#ffd56b")
			HealOnTile(tile, healed)
		sleep(1.5)
		if(QDELETED(src))
			return
	qdel(src)

/obj/structure/serio_healing_well/proc/HealOnTile(turf/T, list/healed)
	for(var/mob/living/carbon/human/H in T)
		if(H.stat == DEAD)
			continue
		if(H in healed)
			continue
		healed += H
		H.adjustBruteLoss(-heal_amount, forced = TRUE)
		H.adjustFireLoss(-heal_amount, forced = TRUE)
		H.adjustSanityLoss(-heal_amount, forced = TRUE)
