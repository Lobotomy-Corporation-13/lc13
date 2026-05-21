/*
 * Curtain Call - zeal_s1n2: Azarus, the House.
 * A gambling demon staged by the Game Master. Reuses the lavaland Herald
 * sprites. Its fight is a dice mini-game: Azarus scatters oversized dice;
 * shooting or striking one spins it (3s) onto a random face. The table total
 * weakens the unavoidable Wager and each landing buys time before it fires.
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
	duration = 60

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

/obj/structure/azarus_die/Initialize(mapload)
	. = ..()
	transform = matrix(2, MATRIX_SCALE)
	result = roll(6)
	score_value = result
	if(result == 6)
		LockIn()
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
	if(owner && !QDELETED(owner))
		owner.OnDieLanded(src)

/obj/structure/azarus_die/proc/LockIn()
	locked = TRUE
	add_filter("lock_glow", 1, list("type" = "outline", "size" = 1, "color" = "#ffd700"))

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
	melee_damage_lower = 18
	melee_damage_upper = 24
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "deals a blow to"
	attack_verb_simple = "deal a blow to"
	attack_sound = 'sound/weapons/punch1.ogg'
	speak_chance = 0
	turns_per_move = 5
	move_to_delay = 8
	speed = 2
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	del_on_death = FALSE
	refraction_manages_own_death = TRUE
	loot = list()

	// The Wager.
	var/list/live_dice = list()
	var/wager_deadline = 0
	var/wager_cooldown_time = 40 SECONDS
	var/wager_base_damage = 200
	var/score_target = 24
	var/roll_delay = 3 SECONDS
	var/wager_telegraph = 6 SECONDS

	var/dice_count = 5
	var/table_set = FALSE

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
	var/mob/living/simple_animal/hostile/azarus/mirror/my_mirror

	var/list/wager_taunts = list(
		"Place your bets, ladies and gents! The House is calling it in!",
		"Ante's up! Let's see what the table's holdin'!",
		"Round's closed! Pay the House what you owe!",
	)
	var/list/bust_lines = list(
		"...bust. The House folds this hand. Well played.",
		"Hah! Y'all read the table. Take the pot - this round.",
		"Snake eyes for the dealer. Don't get used to it.",
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
	if(target && !QDELETED(target) && wager_deadline <= 0)
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

// Scatters `count` dice onto open floor in range, skipping occupied tiles.
/mob/living/simple_animal/hostile/azarus/proc/ThrowDice(count)
	var/list/spots = list()
	for(var/turf/open/T in range(6, src))
		if(T.density || istype(T, /turf/open/water))
			continue
		if(locate(/obj/structure/azarus_die) in T)
			continue
		spots += T
	if(!LAZYLEN(spots))
		return
	var/thrown = 0
	for(var/i in 1 to count)
		if(!LAZYLEN(spots))
			break
		var/turf/T = pick(spots)
		spots -= T
		var/obj/structure/azarus_die/die = new(T)
		die.owner = src
		live_dice += die
		thrown++
	if(thrown)
		visible_message(span_warning("[src] flings a fistful of dice across the floor!"))
		playsound(get_turf(src), 'sound/items/cardshuffle.ogg', 70, TRUE, 6)

// Each landing buys time, but never past one full cooldown window.
/mob/living/simple_animal/hostile/azarus/proc/OnDieLanded(obj/structure/azarus_die/die)
	if(wager_deadline <= 0)
		return
	wager_deadline = min(wager_deadline + roll_delay, world.time + wager_cooldown_time)

// Sum of every live die's current face (airborne dice use their snapshot).
/mob/living/simple_animal/hostile/azarus/proc/TableScore()
	var/total = 0
	for(var/obj/structure/azarus_die/die in live_dice)
		if(QDELETED(die))
			continue
		total += die.spinning ? die.score_value : die.result
	return total

/mob/living/simple_animal/hostile/azarus/proc/CastWager()
	if(!can_act || stat == DEAD || dying)
		return
	can_act = FALSE
	walk(src, 0)
	icon_state = "herald_enraged"
	var/mutable_appearance/wager_die = mutable_appearance('icons/obj/dice.dmi', "de6")
	wager_die.pixel_x = 1
	wager_die.pixel_y = 35
	add_overlay(wager_die)
	say(pick(wager_taunts))
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
	if(stat == DEAD || dying)
		can_act = TRUE
		return
	var/ratio = clamp(TableScore() / score_target, 0, 1)
	playsound(get_turf(src), 'sound/magic/clockwork/narsie_attack.ogg', 90, FALSE, 14)
	if(ratio >= 1)
		WagerBust()
		return
	var/dealt = round(wager_base_damage * (1 - ratio))
	for(var/mob/living/L in livinginrange(40, src))
		if(L == src || faction_check_mob(L))
			continue
		flash_color(L, flash_color = "#c41e3a", flash_time = 25)
		L.deal_damage(dealt, PALE_DAMAGE, src,
			attack_type = (ATTACK_TYPE_SPECIAL))
	ResetTable()
	can_act = TRUE

// Maxed table: the House folds. The Wager whiffs and Azarus is left open.
/mob/living/simple_animal/hostile/azarus/proc/WagerBust()
	say(pick(bust_lines))
	playsound(get_turf(src), 'sound/magic/demon_dies.ogg', 80, FALSE, 10)
	visible_message(span_nicegreen("[src] busts! The House is left wide open!"))
	new /obj/effect/temp_visual/cult/sparks(get_turf(src))
	apply_lc_defense_level_down(8)
	ResetTable()
	// Stagger window: stays put and vulnerable before recovering.
	addtimer(CALLBACK(src, PROC_REF(EndStagger)), 5 SECONDS)

/mob/living/simple_animal/hostile/azarus/proc/EndStagger()
	if(stat == DEAD || dying)
		return
	can_act = TRUE

// Re-arms the clock and tops the table back up to the current dice count.
/mob/living/simple_animal/hostile/azarus/proc/ResetTable()
	for(var/obj/structure/azarus_die/die in live_dice)
		if(!QDELETED(die))
			qdel(die)
	live_dice.Cut()
	ThrowDice(dice_count)
	wager_deadline = world.time + wager_cooldown_time

// Flicks a die at the target tile; it lands in a 3x3 blast.
/mob/living/simple_animal/hostile/azarus/proc/SnakeEyes(atom/S_target)
	if(!can_act || stat == DEAD || dying || QDELETED(S_target))
		return
	can_act = FALSE
	walk(src, 0)
	snake_cooldown = world.time + snake_cooldown_time
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
		been_hit = HurtInTurf(T, been_hit, snake_damage, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_SPECIAL))
	playsound(get_turf(src), 'sound/magic/clockwork/ratvar_attack.ogg', 70, FALSE, 6)
	can_act = TRUE

// Anti-crowding 5x5 cleave with knockback when players stack on the dealer.
/mob/living/simple_animal/hostile/azarus/proc/HouseEdge()
	if(!can_act || stat == DEAD || dying)
		return
	can_act = FALSE
	walk(src, 0)
	house_cooldown = world.time + house_cooldown_time
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
		been_hit = HurtInTurf(T, been_hit, house_damage, RED_DAMAGE,
			check_faction = TRUE, hurt_mechs = TRUE,
			attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in T)
			if(L == src || faction_check_mob(L))
				continue
			var/throw_dir = get_dir(center, L)
			var/turf/throw_at_turf = get_ranged_target_turf(L, throw_dir, 3)
			if(throw_at_turf)
				L.throw_at(throw_at_turf, 3, 2, src)
	can_act = TRUE

// ---- Phase 2 ----
/mob/living/simple_animal/hostile/azarus/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	CheckPhase()

/mob/living/simple_animal/hostile/azarus/proc/CheckPhase()
	if(is_mirror || stat == DEAD || dying || !maxHealth || health <= 0)
		return
	if(phase >= 2 || health > maxHealth * 0.5)
		return
	phase = 2
	dice_count = 9
	score_target = 42
	wager_cooldown_time = 30 SECONDS
	say(pick(phase_lines))
	playsound(get_turf(src), 'sound/magic/clockwork/narsie_attack.ogg', 75, FALSE, 8)
	ThrowDice(dice_count - LAZYLEN(live_dice))
	MirrorGambit()

// Spawns a fragile mirror-double that keeps feeding the table while it lives.
/mob/living/simple_animal/hostile/azarus/proc/MirrorGambit()
	if(my_mirror && !QDELETED(my_mirror))
		return
	var/turf/T = get_step(src, pick(GLOB.cardinals)) || get_turf(src)
	my_mirror = new /mob/living/simple_animal/hostile/azarus/mirror(T)
	my_mirror.owner = src
	visible_message(span_warning("[src] conjures a mirror-double to raise the stakes!"))

/mob/living/simple_animal/hostile/azarus/death(gibbed)
	// The mirror-double just clears its master's handle and dies normally
	// (del_on_death is TRUE for it); only the real boss runs the fade-out.
	if(is_mirror)
		if(owner && !QDELETED(owner) && owner.my_mirror == src)
			owner.my_mirror = null
		return ..()
	if(dying)
		return ..()
	dying = TRUE
	say(pick(death_lines))
	. = ..()
	can_act = FALSE
	walk(src, 0)
	for(var/obj/structure/azarus_die/die in live_dice)
		if(!QDELETED(die))
			qdel(die)
	live_dice.Cut()
	if(my_mirror && !QDELETED(my_mirror))
		qdel(my_mirror)
	animate(src, alpha = 0, time = death_fade_time)
	QDEL_IN(src, death_fade_time)

// ---------- Mirror-double (phase 2 add) ----------
/mob/living/simple_animal/hostile/azarus/mirror
	name = "the dealer's mirror"
	desc = "A mirror with the dealer's face leering out of it. It keeps tossing \
		more dice onto the table."
	icon_state = "herald_mirror"
	icon_living = "herald_mirror"
	icon_dead = "herald_mirror"
	maxHealth = 250
	health = 250
	is_mirror = TRUE
	del_on_death = TRUE
	refraction_manages_own_death = FALSE
	var/mirror_throw_cooldown = 0
	var/mirror_throw_time = 6 SECONDS

/mob/living/simple_animal/hostile/azarus/mirror/handle_automated_action()
	if(stat == DEAD)
		return
	if(!owner || QDELETED(owner) || owner.stat == DEAD)
		qdel(src)
		return
	if(world.time >= mirror_throw_cooldown)
		mirror_throw_cooldown = world.time + mirror_throw_time
		MirrorThrow()
	return ..()

// Adds dice straight onto the master's table so they buy the master time.
/mob/living/simple_animal/hostile/azarus/mirror/proc/MirrorThrow()
	if(!owner || QDELETED(owner))
		return
	var/turf/spot
	for(var/turf/open/T in range(5, src))
		if(T.density || istype(T, /turf/open/water))
			continue
		if(locate(/obj/structure/azarus_die) in T)
			continue
		spot = T
		break
	if(!spot)
		return
	var/obj/structure/azarus_die/die = new(spot)
	die.owner = owner
	owner.live_dice += die
	playsound(get_turf(src), 'sound/items/coinflip.ogg', 50, TRUE, 4)
