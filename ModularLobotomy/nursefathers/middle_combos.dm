/// Middle Nursefather combo system.
/// Combos are triggered by dashing to a target (afterattack at range on Laevateinn).
/// Without Tattoos: Combo 1 (default). With Tattoos: powered combo based on seal stage.
/// Seal 0 + Tattoos → Combo 2, Seal 1 → Combo 3, Seal 2 → Combo 4, Seal 3 → Combo 5.
/// All combos lock both user and target, with cutscene_duel preventing outside damage.
/// All damage has justice scaling + 2x multiplier vs simple mobs (converted to BRUTE).
/// FIRE damage pierces armor on humans, converted to BRUTE for simple mobs.

/// Checks if a combo should abort (target dead/deleted, user dead/softcrit/deleted).
/// If aborting, resets combo_in_progress on the user's Laevateinn and frees the user.
#define MIDDLE_COMBO_CHECK(target, user) middle_combo_should_abort(target, user)

/// Tracks the current impale overlay on a combo target for cleanup on abort.
GLOBAL_VAR(middle_combo_impale_overlay)
GLOBAL_VAR(middle_combo_impale_target)

/proc/middle_combo_should_abort(mob/living/target, mob/living/carbon/human/user)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD || user.stat == DEAD || user.stat == SOFT_CRIT)
		// Reset combo state
		if(!QDELETED(user))
			user.SetImmobilized(0)
			var/obj/item/ego_weapon/city/laevateinn/sword = locate() in user.contents
			if(!sword && ishuman(user))
				sword = user.s_store
			if(istype(sword))
				sword.combo_in_progress = FALSE
			animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
		// Clean up impale overlay and pixel offsets on the target
		if(!QDELETED(target))
			if(GLOB.middle_combo_impale_overlay && GLOB.middle_combo_impale_target == target)
				target.cut_overlay(GLOB.middle_combo_impale_overlay)
				GLOB.middle_combo_impale_overlay = null
				GLOB.middle_combo_impale_target = null
			animate(target, pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, transform = null, time = 0.1 SECONDS)
		return TRUE
	return FALSE

/// Deals combo damage with justice scaling and 2x simple mob multiplier.
/// FIRE damage is applied with DAMAGE_PIERCING to bypass armor on humans.
/// Simple mobs are immune to FIRE, so FIRE damage is converted to RED_DAMAGE for them.
/proc/middle_combo_damage(mob/living/target, mob/living/carbon/human/user, damage, damage_type = RED_DAMAGE, def_zone = null)
	if(!target || !user)
		return
	var/final_damage = damage
	var/final_type = damage_type
	if(istype(target, /mob/living/simple_animal))
		// Justice scaling + 2x vs simple mobs
		var/userjust = get_modified_attribute_level(user, JUSTICE_ATTRIBUTE)
		var/justicemod = 1 + userjust / 100
		final_damage = damage * justicemod * 2
		// Convert all damage to BRUTE for simple mobs — bypasses damage_coeff, always hits weakness
		final_type = BRUTE
	if(final_type == FIRE)
		target.deal_damage(final_damage, FIRE, source = user, flags = DAMAGE_PIERCING)
	else if(def_zone)
		target.deal_damage(final_damage, final_type, source = user, def_zone = def_zone)
	else
		target.deal_damage(final_damage, final_type, source = user)

/// Immobilizes a target for a combo. Handles both carbons (Immobilize) and simple mobs (AI off).
/proc/middle_combo_lock_target(mob/living/target, duration)
	if(istype(target, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/SM = target
		var/old_ai = SM.AIStatus
		SM.toggle_ai(AI_OFF)
		SM.Goto(get_turf(SM))
		SM.patrol_reset()
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(middle_combo_unlock_simplemob), SM, old_ai), duration)
	else
		target.Immobilize(duration)

/// Restores AI for a simple mob after combo ends.
/proc/middle_combo_unlock_simplemob(mob/living/simple_animal/hostile/SM, old_ai)
	if(!QDELETED(SM))
		SM.toggle_ai(old_ai)

/// Deals AoE damage to all living mobs near the target (excluding attacker and target).
/// Optionally applies Overheat stacks.
/proc/middle_combo_aoe(mob/living/target, mob/living/carbon/human/user, damage, damage_type, aoe_range = 2, overheat_stacks = 0)
	for(var/mob/living/L in orange(aoe_range, target))
		if(L == user)
			continue
		middle_combo_damage(L, user, damage, damage_type)
		if(overheat_stacks > 0)
			L.apply_lc_overheat(overheat_stacks)

/// Combo 1 — "Don't Let Somethin' Like This Break Ya!"
/// Default combo — triggered by dashing to a target without Tattoos active.
/// Seize → punch → two wide Laevateinn slashes → knockback finisher (5 tiles, wall-breaking).
/// Base damage: ~150 RED
/proc/middle_combo_chain_grapple(mob/living/target, mob/living/carbon/human/user, tattoo_tier)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	var/tattoo_bonus = tattoo_tier * 10

	target.AddComponent(/datum/component/cutscene_duel, user, 10 SECONDS)
	user.Immobilize(8 SECONDS)
	middle_combo_lock_target(target, 8 SECONDS)

	// Step 1: Seize
	user.visible_message(span_danger("[user] seizes [target]!"))
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(target))
	animate(target, pixel_x = target.base_pixel_x + (get_dir(target, user) & EAST ? 6 : -6), time = 0.2 SECONDS, easing = BACK_EASING)
	animate(pixel_x = target.base_pixel_x, time = 0.3 SECONDS, easing = QUAD_EASING)
	playsound(user, 'sound/weapons/punch1.ogg', 60, TRUE)
	sleep(0.8 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 2: Purple blast
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	animate(target, pixel_x = target.base_pixel_x + 3, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x - 3, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x, time = 0.05 SECONDS)
	sleep(0.5 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 3: Punch — 25 RED
	animate(user, pixel_x = user.base_pixel_x + (get_dir(user, target) & EAST ? 8 : -8), time = 0.1 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	middle_combo_damage(target, user, 25, RED_DAMAGE)
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	animate(target, pixel_x = target.base_pixel_x + (get_dir(user, target) & EAST ? 4 : -4), time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(target, pixel_x = target.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 2, 2)
	playsound(target, 'sound/weapons/punch1.ogg', 50, TRUE)
	animate(user, pixel_x = user.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	sleep(0.5 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 4: Wide slash — 30 RED + bleed
	animate(user, transform = matrix(45, MATRIX_ROTATE), time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), user.dir)
	middle_combo_damage(target, user, 30, RED_DAMAGE)
	target.apply_lc_bleed(5)
	animate(target, pixel_x = target.base_pixel_x + 6, pixel_y = target.base_pixel_y - 3, time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 2, 3)
	playsound(target, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	sleep(0.4 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 5: Reverse slash — 35 RED
	animate(user, transform = matrix(-60, MATRIX_ROTATE), time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), turn(user.dir, 180))
	middle_combo_damage(target, user, 35, RED_DAMAGE)
	animate(target, pixel_x = target.base_pixel_x - 6, pixel_y = target.base_pixel_y - 2, time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 2, 3)
	playsound(target, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	sleep(0.5 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 6: Finisher — 40 + grudge RED, knockback
	user.SpinAnimation(3, 1)
	sleep(0.2 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	user.visible_message(span_userdanger("[user] sends [target] flying!"))
	middle_combo_damage(target, user, 40 + tattoo_bonus, RED_DAMAGE)
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	shake_camera(target, 3, 5)
	playsound(target, 'sound/weapons/punch1.ogg', 70, TRUE)

	wall_breaking_knockback(target, user, get_dir(user, target), 5)

	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)

/// Combo 2 — "Stomping!"
/// Powered combo at seal stage 0 (full seal) with Tattoos active.
/// Rapid stomps with AoE shockwave → knockback finisher (3 tiles, wall-breaking). Applies Bleed.
/// Base damage: ~155 RED | Max w/ 20 grudge: ~235 RED (extra stomps + bonus)
/proc/middle_combo_stomping(mob/living/target, mob/living/carbon/human/user, tattoo_tier)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	var/extra_stomps = tattoo_tier
	var/tattoo_bonus = tattoo_tier * 10

	target.AddComponent(/datum/component/cutscene_duel, user, 8 SECONDS)
	user.Immobilize(6 SECONDS)
	middle_combo_lock_target(target, 6 SECONDS)
	target.Knockdown(6 SECONDS)

	user.visible_message(span_danger("[user] pins [target] underfoot!"))
	playsound(user, 'sound/weapons/punch1.ogg', 50, TRUE)
	sleep(0.3 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// 5 base stomps — 20 RED each = 100
	var/total_stomps = 5 + extra_stomps
	for(var/i in 1 to total_stomps)
		animate(user, pixel_y = user.base_pixel_y + 4, time = 0.1 SECONDS, easing = QUAD_EASING)
		animate(pixel_y = user.base_pixel_y, time = 0.1 SECONDS, easing = BOUNCE_EASING)
		user.do_attack_animation(target, no_effect = TRUE)
		middle_combo_damage(target, user, 20, RED_DAMAGE, BODY_ZONE_CHEST)
		new /obj/effect/temp_visual/middle_slam(get_turf(target))
		new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
		animate(target, pixel_x = target.base_pixel_x + rand(-4, 4), pixel_y = target.base_pixel_y - 2, time = 0.05 SECONDS)
		animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.15 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 2, 2)
		playsound(target, pick('sound/weapons/punch1.ogg', 'sound/weapons/punch2.ogg', 'sound/weapons/punch3.ogg', 'sound/weapons/punch4.ogg'), 55, TRUE)

		// AoE shockwave on 3rd stomp — 10 RED to nearby
		if(i == 3)
			new /obj/effect/temp_visual/middle_slam(get_turf(user))
			for(var/mob/living/L in orange(1, user))
				if(L == target)
					continue
				middle_combo_damage(L, user, 10, RED_DAMAGE)
				new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(L))
			playsound(user, 'sound/weapons/punch1.ogg', 50, TRUE)
		sleep(0.4 SECONDS)
		if(MIDDLE_COMBO_CHECK(target, user))
			return

	// Final stomp — 25 + grudge RED + bleed
	animate(user, pixel_y = user.base_pixel_y + 16, time = 0.2 SECONDS, easing = QUAD_EASING)
	sleep(0.2 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	animate(user, pixel_y = user.base_pixel_y, time = 0.1 SECONDS, easing = BOUNCE_EASING)
	user.visible_message(span_userdanger("[user] delivers a devastating final stomp!"))
	middle_combo_damage(target, user, 25 + tattoo_bonus, RED_DAMAGE)
	target.apply_lc_bleed(5)
	new /obj/effect/temp_visual/middle_slam(get_turf(target))
	shake_camera(target, 3, 4)

	wall_breaking_knockback(target, user, get_dir(user, target), 3)

	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)

/// Combo 3 — "I'll Gut Ya Like a Fish"
/// Powered combo at seal stage 1 (1 seal removed) with Tattoos active.
/// Rapid punches → burning Laevateinn slashes → fire explosion finisher with AoE.
/// Knockback (4 tiles, wall-breaking). Applies Overheat.
/// Base damage: ~145 RED + 20 FIRE | Max w/ 20 grudge: ~185 RED + 20 FIRE
/proc/middle_combo_gut_fish(mob/living/target, mob/living/carbon/human/user, tattoo_tier)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	var/tattoo_bonus = tattoo_tier * 10

	target.AddComponent(/datum/component/cutscene_duel, user, 10 SECONDS)
	user.Immobilize(8 SECONDS)
	middle_combo_lock_target(target, 8 SECONDS)

	// Grab + shout
	user.say("I'll Gut Ya Like a Fish!")
	playsound(user, 'sound/weapons/punch1.ogg', 50, TRUE)
	sleep(0.3 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// 3 rapid punches — 15 RED each = 45
	for(var/i in 1 to 3)
		var/punch_offset = (i % 2 == 1) ? 6 : -6
		animate(user, pixel_x = user.base_pixel_x + punch_offset, time = 0.08 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target, no_effect = TRUE)
		middle_combo_damage(target, user, 15, RED_DAMAGE)
		animate(target, pixel_x = target.base_pixel_x - punch_offset, time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(pixel_x = target.base_pixel_x, time = 0.15 SECONDS, easing = QUAD_EASING)
		new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
		shake_camera(target, 1, 2)
		playsound(target, pick('sound/weapons/punch1.ogg', 'sound/weapons/punch2.ogg', 'sound/weapons/punch3.ogg', 'sound/weapons/punch4.ogg'), 50, TRUE)
		animate(user, pixel_x = user.base_pixel_x, time = 0.1 SECONDS, easing = QUAD_EASING)
		sleep(0.3 SECONDS)
		if(MIDDLE_COMBO_CHECK(target, user))
			return

	// Ground fire (cosmetic)
	for(var/turf/T in orange(2, user))
		if(prob(40))
			new /obj/effect/temp_visual/fire(T)
	sleep(0.5 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// 4 burning slashes — 20 RED + 5 FIRE each = 80 RED + 20 FIRE
	for(var/i in 1 to 4)
		var/rotation = (i % 2 == 1) ? 45 + (i * 10) : -(45 + (i * 10))
		animate(user, transform = matrix(rotation, MATRIX_ROTATE), time = 0.1 SECONDS, easing = QUAD_EASING)
		animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target, no_effect = TRUE)
		new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), user.dir)
		new /obj/effect/temp_visual/fire/fast(get_turf(target))
		middle_combo_damage(target, user, 20, RED_DAMAGE)
		middle_combo_damage(target, user, 5, FIRE)
		target.apply_lc_overheat(3)
		animate(target, pixel_y = target.base_pixel_y - 3, pixel_x = target.base_pixel_x + rand(-3, 3), time = 0.08 SECONDS)
		animate(pixel_y = target.base_pixel_y, pixel_x = target.base_pixel_x, time = 0.15 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 2, 3)
		playsound(target, 'sound/weapons/bladeslice.ogg', 55, TRUE)
		sleep(0.35 SECONDS)
		if(MIDDLE_COMBO_CHECK(target, user))
			return

	// Fire cleave finisher — 20 + grudge RED
	animate(user, pixel_y = user.base_pixel_y + 20, time = 0.2 SECONDS, easing = QUAD_EASING)
	sleep(0.2 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	animate(user, pixel_y = user.base_pixel_y, transform = matrix(180, MATRIX_ROTATE), time = 0.15 SECONDS, easing = BOUNCE_EASING)
	animate(transform = null, time = 0.1 SECONDS)
	user.visible_message(span_userdanger("[user] brings Laevateinn down in a blazing cleave!"))
	middle_combo_damage(target, user, 20 + tattoo_bonus, RED_DAMAGE)
	target.apply_lc_overheat(5)
	animate(target, pixel_y = target.base_pixel_y - 6, time = 0.05 SECONDS)
	animate(pixel_y = target.base_pixel_y, time = 0.3 SECONDS, easing = BOUNCE_EASING)
	new /obj/effect/temp_visual/explosion(get_turf(target))
	for(var/turf/T in orange(2, target))
		new /obj/effect/temp_visual/fire(T)
	// AoE fire damage to nearby mobs
	middle_combo_aoe(target, user, 15, FIRE, 2, 3)
	for(var/mob/M in viewers(7, get_turf(user)))
		shake_camera(M, 3, 5)
	playsound(target, 'sound/effects/explosion1.ogg', 60, TRUE)

	// Knockback
	wall_breaking_knockback(target, user, get_dir(user, target), 4)

	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)

/// Combo 4 — "Gut Stab [Laevateinn]"
/// Powered combo at seal stage 2 (2 seals removed) with Tattoos active.
/// Positions user to the left, impales target with repeated stabs → burning rip-out with AoE.
/// Knockback (6 tiles, wall-breaking). Heavy Overheat stacking.
/// Base damage: ~150 RED + 28 FIRE | Max w/ 20 grudge: ~230 RED + 28 FIRE
/proc/middle_combo_gut_stab(mob/living/target, mob/living/carbon/human/user, tattoo_tier)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	var/tattoo_bonus = tattoo_tier * 10

	target.AddComponent(/datum/component/cutscene_duel, user, 12 SECONDS)
	user.Immobilize(10 SECONDS)
	middle_combo_lock_target(target, 10 SECONDS)

	// Force user to the left (west) of target
	var/turf/left_turf = get_step(target, WEST)
	if(left_turf && !left_turf.density && get_turf(user) != left_turf)
		user.forceMove(left_turf)
	user.setDir(EAST)

	// Impale — 20 RED, pixel shift user toward target
	animate(user, pixel_x = user.base_pixel_x + 6, time = 0.15 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	user.visible_message(span_danger("[user] drives Laevateinn through [target]'s gut!"))
	middle_combo_damage(target, user, 20, RED_DAMAGE, BODY_ZONE_CHEST)
	new /obj/effect/temp_visual/dir_setting/laevateinn_stab(get_turf(target), EAST)
	playsound(target, 'sound/weapons/bladeslice.ogg', 65, TRUE)
	shake_camera(target, 2, 3)
	sleep(0.6 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Warning
	user.say("Be warned, it's gonna be hot.")
	sleep(0.8 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// 8 stabs — 10 RED + 3 FIRE each = 80 RED + 24 FIRE
	for(var/i in 1 to 8)
		var/twist_angle = 10 + (i * 3)
		animate(user, transform = matrix(twist_angle, MATRIX_ROTATE), time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(transform = matrix(-twist_angle * 0.5, MATRIX_ROTATE), time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(transform = null, time = 0.1 SECONDS)
		// Thrust east toward target then pull back
		animate(user, pixel_x = user.base_pixel_x + 10, time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(pixel_x = user.base_pixel_x + 6, time = 0.15 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target, no_effect = TRUE)
		middle_combo_damage(target, user, 10, RED_DAMAGE)
		middle_combo_damage(target, user, 3, FIRE)
		target.apply_lc_overheat(2)
		new /obj/effect/temp_visual/dir_setting/laevateinn_stab(get_turf(target), EAST)
		new /obj/effect/temp_visual/fire/fast(get_turf(target))
		animate(target, pixel_x = target.base_pixel_x + rand(-2 - i, 2 + i), pixel_y = target.base_pixel_y + rand(-1, 1), time = 0.05 SECONDS)
		animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.1 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 1, 2)
		playsound(target, 'sound/weapons/bladeslice.ogg', 45, TRUE)

		if(i >= 5)
			var/obj/effect/temp_visual/sparks/petal = new(get_turf(target))
			petal.color = pick("#4169E1", "#FF8C00")
		sleep(0.4 SECONDS)
		if(MIDDLE_COMBO_CHECK(target, user))
			return

	// Final twist — 30 + grudge RED + 4 FIRE
	user.SpinAnimation(3, 1)
	sleep(0.2 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	user.visible_message(span_userdanger("[user] twists Laevateinn and rips it free in a burst of flame!"))
	middle_combo_damage(target, user, 30 + tattoo_bonus, RED_DAMAGE)
	middle_combo_damage(target, user, 4, FIRE)
	target.apply_lc_overheat(8)
	// User rips back west, target jolts east
	animate(user, pixel_x = user.base_pixel_x - 4, time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(target, pixel_x = target.base_pixel_x + 10, pixel_y = target.base_pixel_y - 4, time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, time = 0.3 SECONDS, easing = QUAD_EASING)
	new /obj/effect/temp_visual/explosion/fast(get_turf(target))
	for(var/turf/T in orange(1, target))
		new /obj/effect/temp_visual/fire(T)
	// AoE fire damage
	middle_combo_aoe(target, user, 20, FIRE, 2, 5)
	for(var/mob/M in viewers(7, get_turf(user)))
		shake_camera(M, 3, 5)
	playsound(target, 'sound/effects/explosion1.ogg', 65, TRUE)

	user.say("Hot as hell!")

	// Knockback
	wall_breaking_knockback(target, user, get_dir(user, target), 6)

	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	animate(target, pixel_x = target.base_pixel_x, pixel_y = target.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)

/// Combo 5 — "Complete and Total Extermination [Laevateinn]"
/// Ultimate combo at seal stage 3 (fully unsealed) with Tattoos active.
/// Throw Laevateinn → dash + slam → fire dome (AoE) → sword sweep → rapid slashes →
/// impale → kick → final stab (AoE) → massive knockback (8 tiles, wall-breaking).
/// Massive Overheat + FIRE AoE damage to all nearby mobs.
/// Base damage: ~320 RED + 30 FIRE | Max w/ 20 grudge: ~420 RED + 30 FIRE
/proc/middle_combo_total_extermination(mob/living/target, mob/living/carbon/human/user, tattoo_tier)
	set waitfor = FALSE
	if(!target || !user || user.stat == DEAD)
		return

	var/tattoo_bonus = tattoo_tier * 10

	target.AddComponent(/datum/component/cutscene_duel, user, 18 SECONDS)
	user.Immobilize(15 SECONDS)
	middle_combo_lock_target(target, 15 SECONDS)

	// Step 1: Throw Laevateinn at target — 30 RED + 5 FIRE
	user.visible_message(span_userdanger("[user] hurls Laevateinn at [target]!"))
	// Weapon throw visual — beam from user to target
	var/turf/throw_origin = get_turf(user)
	var/datum/beam/sword_beam = throw_origin.Beam(target, "1-full", time = 5)
	if(sword_beam)
		sword_beam.visuals.color = "#FF4500"
	playsound(user, 'sound/weapons/bladeslice.ogg', 70, TRUE)
	sleep(0.3 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	// Impale overlay on target
	var/obj/item/held = user.get_active_held_item()
	var/mutable_appearance/throw_impale
	if(held)
		throw_impale = mutable_appearance(held.icon, held.icon_state, ABOVE_MOB_LAYER)
		throw_impale.pixel_x = -16
		throw_impale.pixel_y = -16
		target.add_overlay(throw_impale)
		GLOB.middle_combo_impale_overlay = throw_impale
		GLOB.middle_combo_impale_target = target
	middle_combo_damage(target, user, 30, RED_DAMAGE)
	middle_combo_damage(target, user, 5, FIRE)
	target.apply_lc_overheat(5)
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(target))
	shake_camera(target, 3, 4)
	sleep(0.5 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	// Remove throw impale before dash
	if(throw_impale)
		target.cut_overlay(throw_impale)
		GLOB.middle_combo_impale_overlay = null
		GLOB.middle_combo_impale_target = null
	sleep(0.1 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 2: Dash + slam — 30 RED
	var/turf/dash_origin = get_turf(user)
	var/dash_dir = get_dir(user, target)
	var/obj/effect/temp_visual/dir_setting/smoke_afterdash/aftersmoke = new(dash_origin, dash_dir)
	aftersmoke.color = "#D8B4FE"
	var/turf/dash_current = dash_origin
	for(var/i in 1 to get_dist(user, target))
		dash_current = get_step(dash_current, dash_dir)
		if(dash_current)
			var/obj/effect/temp_visual/dir_setting/smoke_dash/trailsmoke = new(dash_current, dash_dir)
			trailsmoke.color = "#D8B4FE"
	animate(user, alpha = 0, pixel_y = user.base_pixel_y + 16, time = 0.15 SECONDS, easing = QUAD_EASING)
	sleep(0.15 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	user.forceMove(get_turf(target))
	user.pixel_y = user.base_pixel_y + 20
	animate(user, alpha = 255, pixel_y = user.base_pixel_y, time = 0.15 SECONDS, easing = BOUNCE_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	middle_combo_damage(target, user, 30, RED_DAMAGE)
	target.Knockdown(5 SECONDS)
	animate(target, pixel_y = target.base_pixel_y - 8, time = 0.05 SECONDS)
	animate(pixel_y = target.base_pixel_y, time = 0.3 SECONDS, easing = BOUNCE_EASING)
	new /obj/effect/temp_visual/middle_slam(get_turf(target))
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	shake_camera(target, 3, 5)
	playsound(target, 'sound/weapons/punch1.ogg', 65, TRUE)
	sleep(0.5 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 3: Fire dome — 25 RED + 5 FIRE + AoE fire
	middle_combo_damage(target, user, 25, RED_DAMAGE)
	middle_combo_damage(target, user, 5, FIRE)
	target.apply_lc_overheat(5)
	new /obj/effect/temp_visual/explosion(get_turf(target))
	for(var/turf/T in orange(2, target))
		new /obj/effect/temp_visual/fire(T)
	middle_combo_aoe(target, user, 25, FIRE, 2, 5)
	animate(target, pixel_x = target.base_pixel_x + 5, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x - 5, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x + 4, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x - 4, time = 0.05 SECONDS)
	animate(pixel_x = target.base_pixel_x, time = 0.05 SECONDS)
	for(var/mob/M in viewers(7, get_turf(user)))
		shake_camera(M, 3, 5)
	playsound(target, 'sound/effects/explosion1.ogg', 70, TRUE)
	sleep(0.7 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 4: Sword sweep — 25 RED + 5 FIRE, launch again
	animate(user, transform = matrix(90, MATRIX_ROTATE), time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(transform = null, time = 0.15 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	middle_combo_damage(target, user, 25, RED_DAMAGE)
	middle_combo_damage(target, user, 5, FIRE)
	new /obj/effect/temp_visual/dir_setting/laevateinn_basic_slash(get_turf(user), user.dir)
	new /obj/effect/temp_visual/fire/fast(get_turf(target))
	target.SpinAnimation(5, 1)
	shake_camera(target, 2, 4)
	playsound(target, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	target.throw_at(get_ranged_target_turf_direct(user, target, 4), 4, 4, user, TRUE)
	sleep(0.6 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 5: Dash to target + drag back
	var/turf/dash5_origin = get_turf(user)
	var/dash5_dir = get_dir(user, target)
	var/obj/effect/temp_visual/dir_setting/smoke_afterdash/aftersmoke5 = new(dash5_origin, dash5_dir)
	aftersmoke5.color = "#D8B4FE"
	animate(user, alpha = 0, time = 0.1 SECONDS)
	sleep(0.1 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	user.forceMove(get_turf(target))
	animate(user, alpha = 255, time = 0.1 SECONDS)
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	playsound(target, 'sound/weapons/punch1.ogg', 60, TRUE)
	sleep(0.3 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	target.forceMove(get_step(user, get_dir(user, target)))
	sleep(0.3 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 6: 4 rapid slashes — 15 RED + 2 FIRE each = 60 RED + 8 FIRE
	for(var/i in 1 to 4)
		var/swing_angle = (i % 2 == 1) ? 60 : -60
		animate(user, transform = matrix(swing_angle, MATRIX_ROTATE), time = 0.08 SECONDS, easing = QUAD_EASING)
		animate(transform = null, time = 0.12 SECONDS, easing = QUAD_EASING)
		user.do_attack_animation(target, no_effect = TRUE)
		middle_combo_damage(target, user, 15, RED_DAMAGE)
		middle_combo_damage(target, user, 2, FIRE)
		target.apply_lc_overheat(3)
		new /obj/effect/temp_visual/fire/fast(get_turf(target))
		new /obj/effect/temp_visual/dir_setting/middle_slash(get_turf(target), user.dir)
		animate(target, pixel_x = target.base_pixel_x + (swing_angle > 0 ? 4 : -4), time = 0.05 SECONDS)
		animate(pixel_x = target.base_pixel_x, time = 0.1 SECONDS, easing = QUAD_EASING)
		shake_camera(target, 2, 3)
		playsound(target, 'sound/weapons/bladeslice.ogg', 50, TRUE)
		sleep(0.3 SECONDS)
		if(MIDDLE_COMBO_CHECK(target, user))
			return

	// Step 7: Impale — 30 RED + 2 FIRE
	animate(user, pixel_x = user.base_pixel_x - 6, time = 0.1 SECONDS, easing = QUAD_EASING)
	user.visible_message(span_danger("[user] drives Laevateinn through [target]!"))
	user.do_attack_animation(target, no_effect = TRUE)
	middle_combo_damage(target, user, 30, RED_DAMAGE)
	middle_combo_damage(target, user, 2, FIRE)
	new /obj/effect/temp_visual/dir_setting/laevateinn_stab(get_turf(target), EAST)
	new /obj/effect/temp_visual/dir_setting/laevateinn_blast(get_turf(target))
	var/mutable_appearance/impale_overlay
	if(held)
		impale_overlay = mutable_appearance(held.icon, held.icon_state, ABOVE_MOB_LAYER)
		impale_overlay.pixel_x = -16
		impale_overlay.pixel_y = -16
		target.add_overlay(impale_overlay)
		GLOB.middle_combo_impale_overlay = impale_overlay
		GLOB.middle_combo_impale_target = target
	animate(target, pixel_x = target.base_pixel_x + (get_dir(user, target) & EAST ? 6 : -6), time = 0.08 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = target.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	animate(user, pixel_x = user.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	shake_camera(target, 3, 4)
	playsound(target, 'sound/weapons/bladeslice.ogg', 70, TRUE)
	sleep(0.6 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 8: Kick while impaled — 25 RED
	animate(user, pixel_y = user.base_pixel_y + 4, time = 0.1 SECONDS, easing = QUAD_EASING)
	animate(pixel_y = user.base_pixel_y, time = 0.08 SECONDS, easing = BOUNCE_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	middle_combo_damage(target, user, 25, RED_DAMAGE)
	animate(target, pixel_y = target.base_pixel_y - 4, pixel_x = target.base_pixel_x + rand(-3, 3), time = 0.05 SECONDS)
	animate(pixel_y = target.base_pixel_y, pixel_x = target.base_pixel_x, time = 0.2 SECONDS, easing = QUAD_EASING)
	new /obj/effect/temp_visual/dir_setting/middle_blast(get_turf(target))
	shake_camera(target, 2, 3)
	playsound(target, 'sound/weapons/punch1.ogg', 55, TRUE)
	sleep(0.4 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 9: Final stab — 40 + grudge RED + 3 FIRE
	animate(user, pixel_x = user.base_pixel_x + (get_dir(user, target) & EAST ? 12 : -12), transform = matrix(15, MATRIX_ROTATE), time = 0.15 SECONDS, easing = QUAD_EASING)
	animate(pixel_x = user.base_pixel_x, transform = null, time = 0.2 SECONDS, easing = QUAD_EASING)
	user.do_attack_animation(target, no_effect = TRUE)
	middle_combo_damage(target, user, 40 + tattoo_bonus, RED_DAMAGE)
	middle_combo_damage(target, user, 3, FIRE)
	target.apply_lc_overheat(10)
	animate(target, pixel_x = target.base_pixel_x + 6, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x - 6, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x + 5, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x - 5, time = 0.03 SECONDS)
	animate(pixel_x = target.base_pixel_x, time = 0.05 SECONDS)
	for(var/turf/T in orange(3, target))
		if(prob(60))
			new /obj/effect/temp_visual/fire(T)
	// AoE fire damage
	middle_combo_aoe(target, user, 30, FIRE, 3, 8)
	for(var/mob/M in viewers(10, get_turf(user)))
		shake_camera(M, 4, 6)
	playsound(target, 'sound/effects/explosion1.ogg', 75, TRUE)
	sleep(0.8 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return

	// Step 10: Rip blade + knockback — 30 RED
	user.SpinAnimation(3, 1)
	if(impale_overlay)
		target.cut_overlay(impale_overlay)
		GLOB.middle_combo_impale_overlay = null
		GLOB.middle_combo_impale_target = null
	sleep(0.2 SECONDS)
	if(MIDDLE_COMBO_CHECK(target, user))
		return
	user.say("Hah! Bullseye!")
	middle_combo_damage(target, user, 30, RED_DAMAGE)
	var/obj/effect/temp_visual/explosion/emblem = new(get_turf(target))
	emblem.color = "#9932CC"

	wall_breaking_knockback(target, user, get_dir(user, target), 8)

	animate(user, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, transform = null, time = 0.1 SECONDS)
	user.SetImmobilized(0)
