/*
 * The Knight — Phase 2 support mob (kill condition mover).
 *
 * Build-order step 2: bare mob shell. No charge mechanic, no slash, no
 * AI loop, no melee. The Knight just stands at its fixed tile and fades
 * in. The charge mechanic + slash + finisher visuals land in steps 3-5.
 */

/mob/living/simple_animal/hostile/serio_knight
	name = "the Knight"
	desc = "A figure who came to swing once. They are waiting on the right moment."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "knight"
	icon_living = "knight"
	icon_dead = "knight"
	faction = list("neutral")
	maxHealth = 1500
	health = 1500
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
	/// Back-ref to the Overseer that brought the Knight onto the stage.
	var/mob/living/simple_animal/hostile/serio_overseer/parent_overseer
	/// Sibling support mob.
	var/mob/living/simple_animal/hostile/serio_sage/sage_ref
	// ---- Charge mechanic ----
	/// Current charge percent, 0-100. Slash fires at 100.
	var/charge_progress = 0
	/// Charge added per tick. 1.66 * 2 ticks/s = 3.33%/s = 100% in 30s.
	var/charge_per_tick = 1.66
	/// Charge tick interval in deciseconds. 5 ds = twice per second.
	var/charge_tick_interval = 5
	/// Bracket mirror — tracks the Overseer's current bracket so the
	/// per-bracket slash finisher animation picks the right visual.
	/// Updated when the Overseer calls back from OnKnightSlashLanded.
	var/current_bracket = 1
	/// Set TRUE while a slash animation is mid-play. Suppresses further
	/// charge ticks so we don't queue a second slash mid-cinematic.
	var/firing_slash = FALSE
	/// One-shot flag set by serio_void_macro_aoe.Blowup() when a player
	/// is standing on the Knight's tile during the B3 K-aware AoE
	/// telegraph. Consumed (cleared) the next time OnAntiKnightHit
	/// fires; until then, the Knight is exempt from damage + charge
	/// loss for that one hit.
	var/knight_aware_aoe_exempt = FALSE
	/// Set TRUE while the Knight is in the soft-fail stagger window
	/// (HP dropped to ≤30%). ChargeTick skips while set, then
	/// EndStagger clears it.
	var/in_stagger = FALSE
	/// Number of Murmurs currently maintaining a charge-tether beam
	/// onto the Knight. Each beam scales the charge tick — at 4+ the
	/// tick is zeroed or negative (per GetChargeMultiplier).
	var/active_murmur_beams = 0

/mob/living/simple_animal/hostile/serio_knight/Initialize(mapload)
	. = ..()
	toggle_ai(AI_OFF)
	alpha = 0
	animate(src, alpha = 255, time = 1 SECONDS)
	UpdateChargeMaptext()
	addtimer(CALLBACK(src, PROC_REF(ChargeTick)), charge_tick_interval, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_knight/Destroy()
	if(parent_overseer && !QDELETED(parent_overseer) && parent_overseer.knight_ref == src)
		parent_overseer.knight_ref = null
	parent_overseer = null
	sage_ref = null
	return ..()

/// Stationary for the duration of Phase 2.
/mob/living/simple_animal/hostile/serio_knight/Move()
	return FALSE

/mob/living/simple_animal/hostile/serio_knight/AttackingTarget(atom/attacked_target)
	return FALSE

// ---------- Charge mechanic ----------

/// 0.5s tick. Advances the charge bar by `charge_per_tick` × the
/// Murmur-beam multiplier; fires the slash sequence when it reaches
/// 100%. Skips while a slash animation is mid-play or while staggered.
/mob/living/simple_animal/hostile/serio_knight/proc/ChargeTick()
	if(QDELETED(src) || stat == DEAD)
		return
	if(!firing_slash && !in_stagger)
		var/multiplier = GetChargeMultiplier()
		charge_progress = clamp(charge_progress + (charge_per_tick * multiplier), 0, 100)
		UpdateChargeMaptext()
		if(charge_progress >= 100)
			FireSlash()
	addtimer(CALLBACK(src, PROC_REF(ChargeTick)), charge_tick_interval, TIMER_STOPPABLE)

/// Per-beam Murmur multiplier on the charge tick. Linear reduction up
/// to 4 beams (stall), then negative (drain).
/mob/living/simple_animal/hostile/serio_knight/proc/GetChargeMultiplier()
	switch(active_murmur_beams)
		if(0)
			return 1.0
		if(1)
			return 0.75
		if(2)
			return 0.5
		if(3)
			return 0.25
		if(4)
			return 0
		if(5)
			return -0.1
		else
			return -0.25

/// Floating "CHARGE NN%" label above the Knight's head. Colour shifts
/// red → yellow → green as the bar fills so players can read progress
/// without needing the exact number.
/mob/living/simple_animal/hostile/serio_knight/proc/UpdateChargeMaptext()
	maptext_width = 96
	maptext_height = 32
	maptext_x = -32
	maptext_y = 40
	var/p = round(charge_progress)
	var/color
	if(p >= 75)
		color = "#79ff79"
	else if(p >= 25)
		color = "#ffd86b"
	else
		color = "#ff6f6f"
	maptext = MAPTEXT("<font color='[color]'><b>CHARGE [p]%</b></font>")

// ---------- Slash trigger ----------

/// Triggered when charge reaches 100. Resets the bar and hands off to
/// PlaySlashFinisher, which owns the per-bracket animation timing,
/// the NotifyOverseer schedule, and the firing_slash release.
/mob/living/simple_animal/hostile/serio_knight/proc/FireSlash()
	if(firing_slash)
		return
	firing_slash = TRUE
	charge_progress = 0
	UpdateChargeMaptext()
	PlaySlashFinisher(current_bracket)

/// Tells the Overseer the slash landed. Called by an addtimer scheduled
/// in PlaySlashFinisher at the impact moment (when the Knight has slid
/// onto the crystal). The Overseer handles the crystal HP snap +
/// bracket transition; we mirror the new bracket here so the next
/// slash's finisher animation picks the right visual.
/mob/living/simple_animal/hostile/serio_knight/proc/NotifyOverseer()
	if(QDELETED(parent_overseer))
		return
	var/cleared = current_bracket
	current_bracket = min(current_bracket + 1, 3)
	parent_overseer.OnKnightSlashLanded(cleared)

/// Releases the charge lock after the slide-back animation completes,
/// so the next charge cycle can start cleanly.
/mob/living/simple_animal/hostile/serio_knight/proc/UnlockChargeAfterSlash()
	firing_slash = FALSE

/// Applied by anti-Knight attacks (lance / salvo / seeker / K-aware
/// AoE) that successfully reach the Knight. `damage_amount` is passed
/// as 0 for the lance/salvo path since the projectile's parent on_hit
/// already applied HP damage; only the seeker and the K-aware AoE
/// pass non-zero here. `knight_aware_aoe_exempt` is a one-shot gate
/// the K-aware AoE Blowup() flips when a player body-shields on the
/// Knight's tile — when set, this hit is fully absorbed.
/mob/living/simple_animal/hostile/serio_knight/proc/OnAntiKnightHit(damage_amount, charge_loss)
	if(knight_aware_aoe_exempt)
		knight_aware_aoe_exempt = FALSE
		return
	if(damage_amount > 0)
		deal_damage(damage_amount, BLACK_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL))
	if(charge_loss > 0)
		charge_progress = max(0, charge_progress - charge_loss)
		UpdateChargeMaptext()

/// Soft-fail trigger. Any damage path that drops HP at or below 30%
/// of maxHealth flips the Knight into a 3-second stagger: charge
/// resets to 0, ChargeTick skips, then the Knight is partially healed
/// back up and resumes charging from 0. Catches lance / seeker /
/// K-aware AoE hits + any other direct damage uniformly.
/mob/living/simple_animal/hostile/serio_knight/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(. > 0 && !in_stagger && stat != DEAD && health <= maxHealth * 0.3)
		TriggerStagger()

/mob/living/simple_animal/hostile/serio_knight/proc/TriggerStagger()
	if(in_stagger || stat == DEAD)
		return
	in_stagger = TRUE
	charge_progress = 0
	UpdateChargeMaptext()
	visible_message(span_userdanger("[src] staggers — the charge unravels!"))
	// Partial heal back to ~80% so the Knight can resume on a fresh
	// HP pool. adjustBruteLoss takes a negative amount for healing.
	adjustBruteLoss(-maxHealth * 0.5, forced = TRUE)
	addtimer(CALLBACK(src, PROC_REF(EndStagger)), 3 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/serio_knight/proc/EndStagger()
	in_stagger = FALSE

/// Helper for the per-bracket camera shake. Called via addtimer at the
/// impact moment so the shake lines up with the crystal flash rather
/// than with the wind-up frame.
/mob/living/simple_animal/hostile/serio_knight/proc/ShakeViewersAt(atom/A, range_tiles, duration, strength)
	if(!A)
		return
	for(var/mob/M in viewers(range_tiles, A))
		shake_camera(M, duration, strength)

// ---------- Per-bracket slash finishers ----------

/// Per-bracket animation for the slash. The Knight moves through a
/// multi-segment pixel-offset path onto the crystal's tile (visually
/// only — the logical tile is unchanged), the crystal flashes for the
/// impact beat, then the Knight returns to its starting tile.
/// NotifyOverseer fires at the impact moment; the charge lock
/// releases when the slide-back ends. Each bracket has its own
/// movement signature — horizontal sweep, diagonal cleave arc,
/// overhead rise + slam.
/mob/living/simple_animal/hostile/serio_knight/proc/PlaySlashFinisher(bracket)
	if(QDELETED(parent_overseer) || QDELETED(parent_overseer.parent_crystal))
		firing_slash = FALSE
		return
	var/atom/crystal = parent_overseer.parent_crystal
	var/saved_color = crystal.color
	// Knight starts 2 tiles east of the crystal (32 px/tile × 2 = 64 px).
	// pixel_x = -64 brings the sprite over the crystal's tile.
	var/impact_delay
	var/hold_time
	var/recovery_time
	switch(bracket)
		if(1)
			// Horizontal sweep. Quick lunge with a light vertical bob to
			// suggest the slash motion, then return.
			impact_delay = 0.15 SECONDS
			hold_time = 0.10 SECONDS
			recovery_time = 0.35 SECONDS
			visible_message(span_userdanger("[src] sweeps onto the crystal and cuts horizontally. A bright line lights its face."))
			// Knight path: 0,0 → -64,+6 (lunge in with slight rise) → hold → back to 0,0.
			animate(src, pixel_x = -64, pixel_y = 6, time = impact_delay, easing = QUAD_EASING)
			animate(time = hold_time)
			animate(pixel_x = 0, pixel_y = 0, time = recovery_time, easing = QUAD_EASING)
			// Crystal flash in parallel — first animate is a no-op delay to
			// land the white pulse on impact.
			animate(crystal, time = impact_delay)
			animate(color = "#ffffff", time = hold_time)
			animate(color = saved_color, time = recovery_time)
		if(2)
			// Diagonal cleave arc. Knight raises up-and-forward in a windup,
			// then drops diagonally onto the impact tile, then recovers.
			var/windup_time = 0.10 SECONDS
			var/slam_time = 0.10 SECONDS
			impact_delay = windup_time + slam_time  // 0.20 SECONDS
			hold_time = 0.20 SECONDS
			recovery_time = 0.50 SECONDS
			visible_message(span_userdanger("[src] arcs onto the crystal and cleaves diagonally. A fracture forks across its face."))
			// Knight path: 0,0 → -32,+28 (windup, blade up) → -64,-10 (slam down-left) → hold → 0,0.
			animate(src, pixel_x = -32, pixel_y = 28, time = windup_time, easing = QUAD_EASING)
			animate(pixel_x = -64, pixel_y = -10, time = slam_time, easing = QUAD_EASING)
			animate(time = hold_time)
			animate(pixel_x = 0, pixel_y = 0, time = recovery_time, easing = QUAD_EASING)
			animate(crystal, time = impact_delay)
			animate(color = "#ffaa55", time = hold_time)
			animate(color = saved_color, time = recovery_time)
			addtimer(CALLBACK(src, PROC_REF(ShakeViewersAt), crystal, 7, 1 SECONDS, 2), impact_delay, TIMER_STOPPABLE)
		if(3)
			// Overhead strike. Deliberate rise to apex above the crystal,
			// hard slam straight down, long extended impact, slow recovery.
			// The dissolve sequence in step 17 picks up from here.
			var/rise_time = 0.20 SECONDS
			var/slam_time = 0.10 SECONDS
			impact_delay = rise_time + slam_time  // 0.30 SECONDS
			hold_time = 0.80 SECONDS
			recovery_time = 0.70 SECONDS
			visible_message(span_userdanger("[src] lifts over the crystal and strikes downward. The whole face fractures."))
			// Knight path: 0,0 → -32,+44 (rise high over crystal, SINE) →
			//              -64,-14 (slam straight down, QUAD) → hold → 0,0 (slow SINE recovery).
			animate(src, pixel_x = -32, pixel_y = 44, time = rise_time, easing = SINE_EASING)
			animate(pixel_x = -64, pixel_y = -14, time = slam_time, easing = QUAD_EASING)
			animate(time = hold_time)
			animate(pixel_x = 0, pixel_y = 0, time = recovery_time, easing = SINE_EASING)
			animate(crystal, time = impact_delay)
			animate(color = "#c30fff", time = 0.30 SECONDS)
			animate(color = "#ffffff", time = 0.50 SECONDS)
			animate(color = saved_color, time = recovery_time)
			addtimer(CALLBACK(src, PROC_REF(ShakeViewersAt), crystal, 10, 2 SECONDS, 4), impact_delay, TIMER_STOPPABLE)
	// Bracket transition fires on impact (when Knight reaches the crystal).
	// Charge lock releases after the recovery animation completes.
	addtimer(CALLBACK(src, PROC_REF(NotifyOverseer)), impact_delay, TIMER_STOPPABLE)
	addtimer(CALLBACK(src, PROC_REF(UnlockChargeAfterSlash)), impact_delay + hold_time + recovery_time, TIMER_STOPPABLE)
