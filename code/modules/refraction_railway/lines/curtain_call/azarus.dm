/*
 * Curtain Call - zeal_s1n2: Azarus, the House.
 * A gambling demon staged by the Game Master. Reuses the lavaland Herald
 * sprites. Its fight is a dice mini-game: Azarus scatters oversized dice
 * (each starting on 1, kept 2+ tiles apart); shooting or striking one spins
 * it (3s) onto a random face. The table total weakens the unavoidable Wager
 * and each landing buys time before it fires.
 *
 * Rolling is risky: a roll can draw a Snake Eyes, and every die slams the
 * floor for BLACK damage when it lands (3x3, scaling with the face; 5x5 on a
 * 6). All of Azarus's attacks deal BLACK except the Wager (PALE). The
 * dealer's own AoEs knock loose any die showing 4+ for a fresh spin.
 *
 * After a Wager resolves the whole table clears for a 15s dead window, then
 * re-deals. Taking damage rushes the Wager clock. Phase 2 (<=50% HP) forces
 * any pending Wager off, then conjures four stationary mirror-doubles that
 * mimic the dealer's attacks; each has 25% of his HP and is broken normally.
 */

// ---------- Telegraph and warning effects ----------

/obj/effect/temp_visual/azarus_snake_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#ffd700"
	duration = 10

/obj/effect/temp_visual/azarus_house_warning
	name = "danger"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#c41e3a"
	duration = 9

/obj/effect/temp_visual/azarus_wager_warning
	name = "the house calls the bet"
	icon = 'icons/mob/actions/actions_items.dmi'
	icon_state = "sniper_zoom"
	layer = BELOW_MOB_LAYER
	color = "#c41e3a"
	duration = 30

// Flicked-die visual for Snake Eyes; arcs to the target tile then expires.
/obj/effect/temp_visual/azarus_thrown_die
	name = "thrown die"
	icon = 'icons/obj/dice.dmi'
	icon_state = "de6"
	layer = ABOVE_MOB_LAYER
	duration = 10

// ---------- The oversized gambling die ----------
/obj/structure/azarus_die
	name = "loaded die"
	desc = "An enormous ebony die the dealer tossed onto the floor. Hit it to \
		make it spin, and pray it lands high."
	icon = 'icons/obj/dice.dmi'
	icon_state = "de6"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_ICON
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF

	var/result = 1
	var/spinning = FALSE
	var/locked = FALSE
	/// Face counted toward the table while airborne (no mid-spin exploit).
	var/score_value = 1
	var/spin_timer
	var/mob/living/simple_animal/hostile/azarus/owner
	/// Landing-blast BLACK damage per pip (result * this). A 6 also widens
	/// the blast from 3x3 to 5x5.
	var/dice_impact_per_pip = 6

/obj/structure/azarus_die/Initialize(mapload)
	. = ..()
	transform = matrix(1.5, MATRIX_SCALE)
	// Dice land on the table showing 1 — players have to spin them up.
	result = 1
	score_value = 1
	update_icon()

/obj/structure/azarus_die/Destroy()
	deltimer(spin_timer)
	if(owner)
		owner.live_dice -= src
		owner = null
	return ..()

/obj/structure/azarus_die/update_overlays()
	. = ..()
	. += "[icon_state]-[result]"

/obj/structure/azarus_die/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	if(!spinning && !locked)
		StartSpin()
	return BULLET_ACT_HIT

/obj/structure/azarus_die/attackby(obj/item/W, mob/user, params)
	if(W.force && !spinning && !locked)
		user.changeNext_move(CLICK_CD_MELEE)
		user.do_attack_animation(src)
		if(W.hitsound)
			playsound(src, W.hitsound, 50, TRUE)
		StartSpin()
		return TRUE
	return ..()

/obj/structure/azarus_die/proc/StartSpin()
	spinning = TRUE
	score_value = result
	playsound(src, 'sound/items/coinflip.ogg', 60, TRUE, 4)
	animate(src, pixel_z = 24, time = 6, easing = QUAD_EASING)
	spin_timer = addtimer(CALLBACK(src, PROC_REF(SpinTick)), 1, TIMER_LOOP | TIMER_STOPPABLE)
	addtimer(CALLBACK(src, PROC_REF(Land)), 3 SECONDS)
	// Touching the table tempts the dealer — rolling can draw an attack.
	if(owner && !QDELETED(owner))
		owner.OnDieRolled(src)

/obj/structure/azarus_die/proc/SpinTick()
	result = roll(6)
	update_icon()

/obj/structure/azarus_die/proc/Land()
	deltimer(spin_timer)
	spin_timer = null
	result = roll(6)
	spinning = FALSE
	update_icon()
	animate(src, pixel_z = 0, time = 2, easing = BOUNCE_EASING)
	playsound(src, 'sound/items/dodgeball.ogg', 70, TRUE, 5)
	if(result == 6)
		LockIn()
	DiceImpact()
	if(owner && !QDELETED(owner))
		owner.OnDieLanded(src)

// Landing slams the floor: BLACK damage scaling with the rolled face, in a
// 3x3 — or 5x5 on a 6. The higher you gamble, the harder the tile bites.
/obj/structure/azarus_die/proc/DiceImpact()
	var/turf/center = get_turf(src)
	if(!center)
		return
	var/radius = (result >= 6) ? 2 : 1
	var/dmg = result * dice_impact_per_pip
	for(var/turf/T in range(radius, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
	if(!owner || QDELETED(owner))
		return
	var/list/been_hit = list()
	for(var/turf/T in range(radius, center))
		been_hit = owner.HurtInTurf(T, been_hit, dmg, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_SPECIAL))

/obj/structure/azarus_die/proc/LockIn()
	locked = TRUE
	add_filter("lock_glow", 1, list("type" = "outline", "size" = 1, "color" = "#ffd700"))

// Knocked loose by one of the dealer's own AoEs — unlocks and re-spins even
// a locked six.
/obj/structure/azarus_die/proc/ForceRoll()
	if(spinning)
		return
	locked = FALSE
	remove_filter("lock_glow")
	StartSpin()

// ---------- Azarus, the House (Node zeal_s1n2: boss) ----------
/mob/living/simple_animal/hostile/azarus
	name = "Azarus, the House"
	desc = "A demon dealt into the show to run a game of chance. Its grin never \
		reaches the mirror it carries for a face. The House always wins."
	icon = 'icons/mob/lavaland/lavaland_elites.dmi'
	icon_state = "herald"
	icon_living = "herald"
	icon_dead = "herald_dying"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("serio_zeal")
	maxHealth = 2400
	health = 2400
	melee_damage_lower = 5
	melee_damage_upper = 7
	// Everything but the Wager (which is PALE) deals BLACK.
	melee_damage_type = BLACK_DAMAGE
	attack_verb_continuous = "deals a blow to"
	attack_verb_simple = "deal a blow to"
	attack_sound = 'sound/magic/clockwork/ratvar_attack.ogg'
	speak_chance = 0
	turns_per_move = 5
	move_to_delay = 10
	speed = 2
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.5)
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()

	// The Wager.
	var/list/live_dice = list()
	var/wager_deadline = 0
	var/wager_cooldown_time = 40 SECONDS
	var/wager_base_damage = 200
	var/score_target = 24
	/// Each die landing pushes the Wager clock back by this much.
	var/roll_delay = 1 SECONDS
	/// Hard ceiling on how far landings can push the Wager clock out.
	var/wager_max_countdown = 20 SECONDS
	var/wager_telegraph = 3 SECONDS
	/// TRUE from the moment a Wager begins its telegraph until it resolves.
	var/wager_casting = FALSE
	/// Dead-table window after a Wager resolves: no dice, no countdown.
	var/in_intermission = FALSE
	var/wager_intermission_time = 15 SECONDS
	/// Deciseconds shaved off the Wager clock per point of damage taken.
	var/wager_speedup_per_damage = 0.25
	/// Looping timer that refreshes the over-head countdown + score readout.
	var/hud_timer

	var/dice_count = 5
	var/table_set = FALSE
	/// The turf the dice scatter around — fixed at Azarus's spawn point.
	var/turf/table_center
	/// Chance, per player-initiated roll, that the dealer fires a Snake Eyes.
	var/roll_attack_chance = 35

	// Side attacks.
	var/snake_cooldown = 0
	var/snake_cooldown_time = 10 SECONDS
	var/snake_damage = 35
	var/house_cooldown = 0
	var/house_cooldown_time = 12 SECONDS
	var/house_damage = 30

	// Phase 2 (<=50% HP).
	var/phase = 1
	var/is_mirror = FALSE
	var/mob/living/simple_animal/hostile/azarus/owner
	/// Phase-2 mirror-doubles. The boss qdel's them on death.
	var/list/mirrors = list()
	var/mirror_count = 4
	/// Min spacing (tiles) a mirror must keep from the boss and other mirrors.
	var/mirror_spacing = 3
	/// Stagger for mimicked attacks: the Nth mirror waits base + N*step (plus
	/// a little jitter) so they cascade instead of all firing at once.
	var/mirror_mimic_base_delay = 4
	var/mirror_mimic_stagger = 6

	var/list/wager_taunts = list(
		"Place your bets, ladies and gents! The House is calling it in!",
		"Ante's up! Let's see what the table's holdin'!",
		"Round's closed! Pay the House what you owe!",
	)
	var/list/wager_early_lines = list(
		"No time to dawdle - the House calls this bet NOW!",
		"Change of plans! We settle up early, right this instant!",
		"Stakes just got steeper - the bet comes due AHEAD of schedule!",
	)
	var/list/bust_lines = list(
		"...bust. The House folds this hand. Well played.",
		"Hah! Y'all read the table. Take the pot - this round.",
		"Snake eyes for the dealer. Don't get used to it.",
	)
	var/list/reroll_six_lines = list(
		"Tsk - a six gone to waste! The House giveth and taketh.",
		"Shame to scatter such a fine roll. Spin it again!",
		"Can't have y'all sittin' pretty on a six. Reshuffle!",
	)
	var/list/phase_lines = list(
		"Now the stakes get interesting. Double the dice!",
		"The House never sweats - it just raises the bet.",
	)
	var/list/death_lines = list(
		"The House... finally lost a hand...",
		"Funny... I never figured the odds... for this...",
		"Take it. Take... the whole pot. The show's... yours...",
	)
	var/death_fade_time = 1 SECONDS
	var/dying = FALSE

/mob/living/simple_animal/hostile/azarus/refracted

/mob/living/simple_animal/hostile/azarus/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	. = ..()
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)

/mob/living/simple_animal/hostile/azarus/Initialize(mapload)
	. = ..()
	// Only the real House carries the table readout + the table; the mirror
	// has neither. The table stays anchored to where Azarus first drops in.
	if(!is_mirror)
		table_center = get_turf(src)
		hud_timer = addtimer(CALLBACK(src, PROC_REF(UpdateHUD)), 1 SECONDS, TIMER_LOOP | TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/azarus/Destroy()
	deltimer(hud_timer)
	hud_timer = null
	// Catch-all so any removal path — death fade, or being deleted because a
	// player failed the fight and the run tore the boss down — also clears
	// the table and the mirrors.
	if(!is_mirror)
		CleanupBoard()
	return ..()

// Removes every live die and mirror this House owns. Iterates copies so the
// children deregistering themselves mid-loop can't make us skip any.
/mob/living/simple_animal/hostile/azarus/proc/CleanupBoard()
	for(var/obj/structure/azarus_die/die in live_dice.Copy())
		if(!QDELETED(die))
			qdel(die)
	live_dice.Cut()
	for(var/mob/living/simple_animal/hostile/azarus/mirror/M in mirrors.Copy())
		if(!QDELETED(M))
			qdel(M)
	mirrors.Cut()

// Over-head readout: red = seconds until the next Wager, gold = the current
// table score. Refreshed once a second by hud_timer.
/mob/living/simple_animal/hostile/azarus/proc/UpdateHUD()
	if(QDELETED(src))
		return
	if(is_mirror || stat == DEAD || dying || !table_set)
		maptext = ""
		return
	var/countdown = 0
	if(wager_deadline > 0)
		countdown = max(0, round((wager_deadline - world.time) / 10))
	maptext_width = 64
	maptext_height = 32
	maptext_x = -16
	maptext_y = 32
	maptext = MAPTEXT("<font color='#ff3030'>[countdown]</font> <font color='#ffd700'>[TableScore()]</font>")

// Block self-movement during any special; forceMove still works.
/mob/living/simple_animal/hostile/azarus/Move(atom/newloc, dir, step_x, step_y)
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/azarus/handle_automated_action()
	// The mirror chains here via ..(); it has no table or Wager, so fall
	// straight through to the base movement/melee AI.
	if(is_mirror)
		return ..()
	if(!can_act || dying)
		return
	if(!table_set)
		SetupTable()
	if(target && !QDELETED(target) && !in_intermission && wager_deadline <= 0)
		wager_deadline = world.time + wager_cooldown_time
	if(wager_deadline > 0 && world.time >= wager_deadline)
		walk(src, 0)
		INVOKE_ASYNC(src, PROC_REF(CastWager))
		return
	if(target && !QDELETED(target) && stat != DEAD)
		var/d = get_dist(src, target)
		if(d >= 3 && d <= 7 && world.time >= snake_cooldown)
			walk(src, 0)
			INVOKE_ASYNC(src, PROC_REF(SnakeEyes), target)
			return
		if(d <= 1 && world.time >= house_cooldown)
			walk(src, 0)
			INVOKE_ASYNC(src, PROC_REF(HouseEdge))
			return
	return ..()

// Throws the opening hand onto the floor.
/mob/living/simple_animal/hostile/azarus/proc/SetupTable()
	table_set = TRUE
	ThrowDice(dice_count)

// Scatters `count` dice onto open floor in range. Dice keep at least 2
// tiles between one another (and away from existing ones on the table).
/mob/living/simple_animal/hostile/azarus/proc/ThrowDice(count)
	var/turf/center = table_center || get_turf(src)
	var/list/spots = list()
	for(var/turf/open/T in range(6, center))
		if(T.density || istype(T, /turf/open/water))
			continue
		if(locate(/obj/structure/azarus_die) in T)
			continue
		spots += T
	if(!LAZYLEN(spots))
		return
	// Seed the spacing check with dice already on the table.
	var/list/placed_turfs = list()
	for(var/obj/structure/azarus_die/existing in live_dice)
		if(!QDELETED(existing))
			placed_turfs += get_turf(existing)
	var/thrown = 0
	for(var/i in 1 to count)
		if(!LAZYLEN(spots))
			break
		var/turf/T = pick(spots)
		spots -= T
		// Reject tiles within 2 of an already-placed die; fall through to the
		// next candidate if none is far enough.
		var/too_close = FALSE
		for(var/turf/P in placed_turfs)
			if(get_dist(T, P) < 2)
				too_close = TRUE
				break
		if(too_close)
			continue
		var/obj/structure/azarus_die/die = new(T)
		die.owner = src
		live_dice += die
		placed_turfs += T
		thrown++
	if(thrown)
		visible_message(span_warning("[src] flings a fistful of dice across the floor!"))
		playsound(get_turf(src), 'sound/items/cardshuffle.ogg', 70, TRUE, 6)

// Each landing buys time, but never past one full cooldown window.
/mob/living/simple_animal/hostile/azarus/proc/OnDieLanded(obj/structure/azarus_die/die)
	if(wager_deadline <= 0)
		return
	wager_deadline = min(wager_deadline + roll_delay, world.time + wager_max_countdown)

// A player rolling a die may draw a Snake Eyes at that die's tile. Gated by
// can_act (no interrupt mid-special) and the normal Snake Eyes cooldown, so
// it can't chain.
/mob/living/simple_animal/hostile/azarus/proc/OnDieRolled(obj/structure/azarus_die/die)
	if(is_mirror || stat == DEAD || dying || !can_act)
		return
	if(world.time < snake_cooldown || !prob(roll_attack_chance))
		return
	INVOKE_ASYNC(src, PROC_REF(SnakeEyes), die)

// One of the dealer's own AoEs sweeping the table knocks any die showing 4+
// loose for a fresh spin; losing a locked six earns a remark.
/mob/living/simple_animal/hostile/azarus/proc/RattleDiceInRange(turf/center, radius)
	if(!center)
		return
	var/rerolled_six = FALSE
	for(var/turf/T in range(radius, center))
		var/obj/structure/azarus_die/die = locate(/obj/structure/azarus_die) in T
		if(!die || die.spinning || die.result < 4)
			continue
		if(die.result >= 6)
			rerolled_six = TRUE
		die.ForceRoll()
	if(rerolled_six && !is_mirror)
		say(pick(reroll_six_lines))

// Sum of every live die's current face (airborne dice use their snapshot).
/mob/living/simple_animal/hostile/azarus/proc/TableScore()
	var/total = 0
	for(var/obj/structure/azarus_die/die in live_dice)
		if(QDELETED(die))
			continue
		total += die.spinning ? die.score_value : die.result
	return total

/mob/living/simple_animal/hostile/azarus/proc/CastWager(early = FALSE)
	if(!can_act || stat == DEAD || dying)
		return
	can_act = FALSE
	wager_casting = TRUE
	walk(src, 0)
	icon_state = "herald_enraged"
	var/mutable_appearance/wager_die = mutable_appearance('icons/obj/dice.dmi', "de6")
	wager_die.pixel_x = 1
	wager_die.pixel_y = 35
	add_overlay(wager_die)
	// A forced (phase-change) Wager gets its own callout in place of the
	// usual one.
	say(pick(early ? wager_early_lines : wager_taunts))
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 80, FALSE, 12)
	for(var/mob/M in GLOB.player_list)
		if(M.z == z && M.client)
			flash_color(M, flash_color = "#c41e3a", flash_time = 40)
			shake_camera(M, 30, 1)
	for(var/turf/open/T in view(7, src))
		if(prob(60))
			new /obj/effect/temp_visual/azarus_wager_warning(T)
	SLEEP_CHECK_DEATH(wager_telegraph)
	cut_overlay(wager_die)
	icon_state = icon_living
	wager_casting = FALSE
	if(stat == DEAD || dying)
		can_act = TRUE
		return
	var/ratio = clamp(TableScore() / score_target, 0, 1)
	playsound(get_turf(src), 'sound/magic/clockwork/narsie_attack.ogg', 90, FALSE, 14)
	if(ratio >= 1)
		WagerBust()
		return
	var/dealt = round(wager_base_damage * (1 - ratio))
	for(var/mob/living/L in livinginrange(20, src))
		if(L == src || faction_check_mob(L))
			continue
		flash_color(L, flash_color = "#c41e3a", flash_time = 25)
		L.deal_damage(dealt, PALE_DAMAGE, src,
			attack_type = (ATTACK_TYPE_SPECIAL))
	WagerResolved()
	can_act = TRUE

// Maxed table: the House folds. The Wager whiffs and Azarus is left open.
/mob/living/simple_animal/hostile/azarus/proc/WagerBust()
	say(pick(bust_lines))
	playsound(get_turf(src), 'sound/magic/demon_dies.ogg', 80, FALSE, 10)
	visible_message(span_nicegreen("[src] busts! The House is left wide open!"))
	new /obj/effect/temp_visual/cult/sparks(get_turf(src))
	apply_lc_defense_level_down(8)
	WagerResolved()
	// Stagger window: stays put and vulnerable before recovering.
	addtimer(CALLBACK(src, PROC_REF(EndStagger)), 5 SECONDS)

/mob/living/simple_animal/hostile/azarus/proc/EndStagger()
	if(stat == DEAD || dying)
		return
	can_act = TRUE

// A resolved Wager clears the whole table and opens a dead-table window:
// no dice, no countdown, for wager_intermission_time. OpenTable re-deals.
/mob/living/simple_animal/hostile/azarus/proc/WagerResolved()
	for(var/obj/structure/azarus_die/die in live_dice)
		if(!QDELETED(die))
			qdel(die)
	live_dice.Cut()
	in_intermission = TRUE
	wager_deadline = 0
	addtimer(CALLBACK(src, PROC_REF(OpenTable)), wager_intermission_time)

// End of the intermission: deal a fresh table and restart the Wager clock.
/mob/living/simple_animal/hostile/azarus/proc/OpenTable()
	if(stat == DEAD || dying)
		return
	in_intermission = FALSE
	ThrowDice(dice_count)
	wager_deadline = world.time + wager_cooldown_time

// Flicks a die at the target tile; it lands in a 3x3 blast.
/mob/living/simple_animal/hostile/azarus/proc/SnakeEyes(atom/S_target)
	if(!can_act || stat == DEAD || dying || QDELETED(S_target))
		return
	can_act = FALSE
	walk(src, 0)
	snake_cooldown = world.time + snake_cooldown_time
	if(!is_mirror)
		MirrorMimic("snake", S_target)
	face_atom(S_target)
	var/turf/center = get_turf(S_target)
	var/turf/origin = get_turf(src)
	if(!center || !origin)
		can_act = TRUE
		return
	var/obj/effect/temp_visual/azarus_thrown_die/flick = new(origin)
	flick.transform = matrix(1.5, MATRIX_SCALE)
	animate(flick, pixel_x = (center.x - origin.x) * 32, pixel_y = (center.y - origin.y) * 32 + 16, time = 8, easing = QUAD_EASING)
	playsound(get_turf(src), 'sound/items/dodgeball.ogg', 80, FALSE, 7)
	for(var/turf/T in range(1, center))
		new /obj/effect/temp_visual/azarus_snake_warning(T)
	SLEEP_CHECK_DEATH(10)
	var/list/been_hit = list()
	for(var/turf/T in range(1, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, snake_damage, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_SPECIAL))
	RattleDiceInRange(center, 1)
	playsound(get_turf(src), 'sound/magic/clockwork/ratvar_attack.ogg', 70, FALSE, 6)
	can_act = TRUE

// Anti-crowding 5x5 cleave with knockback when players stack on the dealer.
/mob/living/simple_animal/hostile/azarus/proc/HouseEdge()
	if(!can_act || stat == DEAD || dying)
		return
	can_act = FALSE
	walk(src, 0)
	house_cooldown = world.time + house_cooldown_time
	if(!is_mirror)
		MirrorMimic("house", null)
	var/turf/center = get_turf(src)
	if(!center)
		can_act = TRUE
		return
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/azarus_house_warning(T)
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 70, FALSE, 5)
	SLEEP_CHECK_DEATH(9)
	var/list/been_hit = list()
	for(var/turf/T in range(2, center))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		been_hit = HurtInTurf(T, been_hit, house_damage, BLACK_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			var/throw_dir = get_dir(center, L)
			var/turf/throw_at_turf = get_ranged_target_turf(L, throw_dir, 3)
			if(throw_at_turf)
				L.throw_at(throw_at_turf, 3, 2, src)
	RattleDiceInRange(center, 2)
	playsound(get_turf(src), 'sound/magic/clockwork/ratvar_attack.ogg', 70, FALSE, 6)
	can_act = TRUE

// ---- Phase 2 ----
/mob/living/simple_animal/hostile/azarus/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	// Taking damage rushes the bet — but only while a Wager is actually
	// counting down (not mid-cast, not during the dead-table window).
	if(!is_mirror && amount > 0 && wager_deadline > 0 && !wager_casting && !in_intermission)
		wager_deadline = max(world.time, wager_deadline - round(amount * wager_speedup_per_damage))
	CheckPhase()

/mob/living/simple_animal/hostile/azarus/proc/CheckPhase()
	if(is_mirror || stat == DEAD || dying || !maxHealth || health <= 0)
		return
	if(phase >= 2 || health > maxHealth * 0.5)
		return
	// Latch the phase immediately so repeated adjustHealth calls don't queue
	// the transition twice, then resolve it asynchronously.
	phase = 2
	INVOKE_ASYNC(src, PROC_REF(EnterPhase2))

// If a Wager is still counting down (not yet resolved) when phase 2 hits,
// force it to fire first, then apply the phase-2 changes.
/mob/living/simple_animal/hostile/azarus/proc/EnterPhase2()
	if(stat == DEAD || dying)
		return
	// A Wager already mid-telegraph counts as "triggered" — wait it out and
	// phase in afterward without stacking a second one.
	if(wager_casting)
		addtimer(CALLBACK(src, PROC_REF(EnterPhase2)), 0.5 SECONDS)
		return
	// Busy with another special (Snake Eyes / House Edge) — wait, then decide.
	if(!can_act)
		addtimer(CALLBACK(src, PROC_REF(EnterPhase2)), 0.5 SECONDS)
		return
	// A pending Wager countdown is forced off right now, before phasing in.
	if(wager_deadline > 0)
		CastWager(early = TRUE)
		if(stat == DEAD || dying)
			return
	ApplyPhase2()

/mob/living/simple_animal/hostile/azarus/proc/ApplyPhase2()
	if(stat == DEAD || dying)
		return
	dice_count = 9
	score_target = 42
	wager_cooldown_time = 30 SECONDS
	say(pick(phase_lines))
	playsound(get_turf(src), 'sound/magic/clockwork/narsie_attack.ogg', 75, FALSE, 8)
	// Don't deal a fresh table mid-intermission — OpenTable will deal all 9
	// when the dead-table window ends.
	if(!in_intermission)
		ThrowDice(dice_count - LAZYLEN(live_dice))
	SpawnMirrors()

// Conjures mirror-doubles that stand guard and echo the dealer's attacks,
// each with a quarter of the House's HP. They keep mirror_spacing tiles from
// the boss and from each other.
/mob/living/simple_animal/hostile/azarus/proc/SpawnMirrors()
	var/list/spots = list()
	for(var/turf/open/T in range(9, src))
		if(T.density || istype(T, /turf/open/water))
			continue
		if(get_dist(T, src) < mirror_spacing)
			continue
		spots += T
	var/placed = 0
	while(placed < mirror_count && LAZYLEN(spots))
		var/turf/T = pick(spots)
		spots -= T
		var/ok = TRUE
		for(var/mob/living/simple_animal/hostile/azarus/mirror/M in mirrors)
			if(QDELETED(M))
				continue
			if(get_dist(T, M) < mirror_spacing)
				ok = FALSE
				break
		if(!ok)
			continue
		var/mob/living/simple_animal/hostile/azarus/mirror/M = new(T)
		M.owner = src
		// Real HP equal to a quarter of the House's own maximum.
		M.maxHealth = round(maxHealth * 0.25)
		M.health = M.maxHealth
		mirrors += M
		placed++
	if(placed)
		visible_message(span_warning("[src] conjures mirror-doubles to raise the stakes!"))

// Tells every living mirror to replay the attack the House just cast. Each
// mirror waits a bit longer than the last (base + N*step + jitter) so the
// copies cascade across the room instead of landing all at once. For Snake
// Eyes the mirrors are handed distinct targets (round-robin over a pool that
// deprioritizes the House's own mark) so they spread out — only doubling up
// when there are fewer players than attackers.
/mob/living/simple_animal/hostile/azarus/proc/MirrorMimic(what, atom/the_target)
	var/list/living_mirrors = list()
	for(var/mob/living/simple_animal/hostile/azarus/mirror/M in mirrors)
		if(!QDELETED(M) && M.stat != DEAD)
			living_mirrors += M
	if(!length(living_mirrors))
		return
	var/list/snake_pool
	if(what == "snake")
		snake_pool = BuildMirrorTargetPool(the_target)
	var/index = 0
	for(var/mob/living/simple_animal/hostile/azarus/mirror/M in living_mirrors)
		index++
		var/delay = mirror_mimic_base_delay + (index * mirror_mimic_stagger) + rand(0, 3)
		if(what == "snake")
			var/atom/assigned = the_target
			if(length(snake_pool))
				assigned = snake_pool[((index - 1) % length(snake_pool)) + 1]
			addtimer(CALLBACK(M, TYPE_PROC_REF(/mob/living/simple_animal/hostile/azarus/mirror, MimicSnake), assigned), delay)
		else if(what == "house")
			addtimer(CALLBACK(M, TYPE_PROC_REF(/mob/living/simple_animal/hostile/azarus/mirror, MimicHouse)), delay)

// Candidate Snake Eyes targets for the mirrors, with the House's own mark
// pushed to the back so the doubles hit the other players first.
/mob/living/simple_animal/hostile/azarus/proc/BuildMirrorTargetPool(atom/boss_target)
	var/list/pool = list()
	for(var/mob/living/L in livinginrange(20, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		pool += L
	if(boss_target && (boss_target in pool))
		pool -= boss_target
		pool += boss_target
	return pool

/mob/living/simple_animal/hostile/azarus/death(gibbed)
	// A mirror that somehow dies just deregisters; only the real boss runs
	// the fade-out and cleans up the table + mirrors.
	if(is_mirror)
		if(owner && !QDELETED(owner))
			owner.mirrors -= src
		return ..()
	if(dying)
		return ..()
	dying = TRUE
	say(pick(death_lines))
	. = ..()
	can_act = FALSE
	walk(src, 0)
	CleanupBoard()
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Mirror-double (phase 2 add) ----------
// A stationary double with real HP (set to 25% of the House's max on spawn).
// It never moves and never melees - it only echoes the dealer's Snake Eyes /
// House Edge. Shatter one to remove that extra pressure.
/mob/living/simple_animal/hostile/azarus/mirror
	name = "the dealer's mirror"
	desc = "A mirror with the dealer's face leering out of it. Shatter it to \
		stop it echoing the House's attacks."
	icon_state = "herald_mirror"
	icon_living = "herald_mirror"
	icon_dead = "herald_mirror"
	maxHealth = 600
	health = 600
	melee_damage_lower = 0
	melee_damage_upper = 0
	is_mirror = TRUE
	del_on_death = TRUE
	refraction_manages_own_death = FALSE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)

// Stationary — never takes a step.
/mob/living/simple_animal/hostile/azarus/mirror/Move(atom/newloc, dir, step_x, step_y)
	return FALSE

/mob/living/simple_animal/hostile/azarus/mirror/handle_automated_action()
	if(stat == DEAD)
		return
	if(!owner || QDELETED(owner) || owner.stat == DEAD)
		qdel(src)
		return
	// Otherwise idle: it doesn't chase or attack on its own — it only
	// mirrors the House via MimicSnake / MimicHouse timers.
	return

// Nearest living non-faction target to the mirror itself, so the mirrors
// cover their own corners of the room.
/mob/living/simple_animal/hostile/azarus/mirror/proc/FindMimicTarget()
	var/mob/living/best
	var/best_dist = INFINITY
	for(var/mob/living/L in livinginrange(9, src))
		if(L == src || faction_check_mob(L) || L.stat == DEAD)
			continue
		var/d = get_dist(src, L)
		if(d < best_dist)
			best_dist = d
			best = L
	return best

// Uses the target the House assigned (kept distinct from the other mirrors),
// falling back to its own nearest if that one died or vanished mid-stagger.
/mob/living/simple_animal/hostile/azarus/mirror/proc/MimicSnake(atom/the_target)
	if(stat == DEAD || QDELETED(src))
		return
	var/atom/t
	if(the_target && !QDELETED(the_target) && isliving(the_target))
		var/mob/living/L = the_target
		if(L.stat != DEAD)
			t = the_target
	if(!t)
		t = FindMimicTarget()
	if(t)
		SnakeEyes(t)

/mob/living/simple_animal/hostile/azarus/mirror/proc/MimicHouse()
	if(stat == DEAD || QDELETED(src))
		return
	HouseEdge()
