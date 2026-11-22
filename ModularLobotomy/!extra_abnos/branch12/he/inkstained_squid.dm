// Inkstained Squid - HE abnormality (a winged fountain-pen squid).
//
// Work (containment): the four work types are pen actions. Draw/Calculate/Letter each add a stroke of
//   their paint colour (RED/WHITE/BLACK) to the sheet; success for all three is driven by how BALANCED
//   the three paints are (even = ~80%, lopsided = down to 20%). Erase is a flat 50% and washes every
//   paint back to one. The head bar shows the balance.
//
// Combat (breach): it has no melee attack. It stores the damage each colour actually deals to it and grows
//   resistant to whatever it has been fed (a colour nears immunity around 40% of max HP stored). Storing
//   the post-resistance damage means the total stored can never exceed the HP it has lost, so it can only
//   ever saturate one or two colours - never all three core types at once.
//   Its two attacks - a retaliation AoE when meleed, and a mark-behind-target laser - split their damage
//   by the colours it has stored (plain BLACK ink while it holds none). Stored colour + resistances hold
//   for the whole breach and reset only when it is re-contained. While breached the head bar shows one
//   segment per 10% of max HP stored of each colour.

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid
	name = "Inkstained Squid"
	desc = "A great fountain pen given a squid's body, its nib a beak and its wings spread like split \
		quills. It weeps a slow, coloured ink that never seems to run the same shade twice."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/64x96.dmi'
	icon_state = "squid"
	icon_living = "squid"
	icon_dead = "squid"
	pixel_x = -16
	base_pixel_x = -16
	maxHealth = 2000
	health = 2000
	stat_attack = HARD_CRIT
	move_to_delay = 5
	del_on_death = FALSE
	can_breach = TRUE
	start_qliphoth = 2
	threat_level = HE_LEVEL
	// No melee - it only retaliates and lasers at range.
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	ranged = TRUE
	ranged_cooldown_time = 10
	minimum_distance = 3
	retreat_distance = 2
	rapid = FALSE
	faction = list("hostile")
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)

	work_damage_amount = 8
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride
	max_boxes = 15
	success_boxes = 11
	neutral_boxes = 6
	neutral_droprate = 50	// neutral work: 50% chance to drop the qliphoth counter by 1
	bad_droprate = 100		// bad work: always drops it by 1
	work_chances = list(
		"Draw" = 80,
		"Calculate" = 80,
		"Letter" = 80,
		"Erase" = 50,
	)
	work_attribute_types = list(
		"Draw" = FORTITUDE_ATTRIBUTE,		// Instinct   -> RED paint
		"Calculate" = PRUDENCE_ATTRIBUTE,	// Insight     -> WHITE paint
		"Letter" = TEMPERANCE_ATTRIBUTE,	// Attachment -> BLACK paint
		"Erase" = JUSTICE_ATTRIBUTE,		// Repression -> the reset
	)

	ego_list = list(
		/datum/ego_datum/weapon/branch12/flourish,
		/datum/ego_datum/armor/branch12/flourish,
	)
	gift_type = /datum/ego_gifts/branch12/flourish
	gift_message = "A bead of ink wells at the nib and refuses to fall - it would rather you kept writing."

	observation_prompt = "The pen hangs nib-down in its cell, wings half-open, and lets a bead of ink \
		gather at its tip. <br>It waits, as if for you to hand it a page."
	observation_choices = list(
		"Offer it a page" = list(TRUE, "It sets to work at once, drawing, tallying, lettering - the ink \
			runs every colour in turn, and none of it stains you. The best pages are the balanced ones."),
		"Take the pen away" = list(FALSE, "The bead of ink swells and drops, and where it lands the floor \
			drinks a colour you cannot name. It does not like an empty hand."),
	)

	generic_bubbles = alist(
		1 = list("%PERSON grips the pen too hard, and the ink runs where it shouldn't.", "%PERSON watches the colours shift across the sheet, unsure which one to add."),
		2 = list("%PERSON blots a stroke and hopes %ABNO doesn't mind.", "%PERSON keeps glancing at the little bar, trying to hold the three colours level."),
		3 = list("%PERSON works the pen in steady strokes.", "%PERSON tops up whichever colour the sheet is short of."),
		4 = list("%PERSON writes with an easy, practiced hand.", "%PERSON keeps the palette in comfortable balance."),
		5 = list("%PERSON lets the pen do the work, the colours even without a thought.", "%PERSON and %ABNO fill the page together, unhurried."),
	)
	work_bubbles = list(
		"Draw" = list("%PERSON sketches a quick figure, and the nib bleeds red into the line."),
		"Calculate" = list("%PERSON runs a column of sums, the ink drying to a pale white."),
		"Letter" = list("%PERSON pens a careful letter, the words settling in black."),
		"Erase" = list("%PERSON wets a rag and wipes the sheet back to an even grey."),
	)

	being_tested = TRUE

	var/list/paint = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1)
	var/list/work_to_paint = list(
		"Draw" = RED_DAMAGE,
		"Calculate" = WHITE_DAMAGE,
		"Letter" = BLACK_DAMAGE,
	)

	var/list/stored_damage = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	/// maxHealth * 0.4; the raw amount of one colour needed for full immunity.
	var/resist_threshold = 0
	/// TRUE while breached; gates all combat behaviour and switches the head bar's data source.
	var/breached = FALSE
	var/busy = FALSE

	COOLDOWN_DECLARE(ink_aoe)
	COOLDOWN_DECLARE(ink_laser)
	var/aoe_cooldown = 3 SECONDS
	var/aoe_damage = 30
	var/aoe_range = 2
	var/laser_cooldown = 5 SECONDS
	var/laser_damage = 55
	var/laser_distance = 18

	/// Colour -> body-fill / bar-segment lookups.
	var/list/paint_hex = list(
		RED_DAMAGE = "#b83232",
		WHITE_DAMAGE = "#dcdcdc",
		BLACK_DAMAGE = "#26262c",
		PALE_DAMAGE = "#8a6fb0",
	)
	var/list/seg_state = list(
		RED_DAMAGE = "seg_red",
		WHITE_DAMAGE = "seg_white",
		BLACK_DAMAGE = "seg_black",
		PALE_DAMAGE = "seg_pale",
	)

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/Initialize(mapload)
	. = ..()
	resist_threshold = maxHealth * 0.4
	RefreshVisuals()

// Re-containment (respawn) wipes the combat state clean.
/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/PostSpawn()
	. = ..()
	breached = FALSE
	busy = FALSE
	stored_damage = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	ChangeResistances(list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1))
	RefreshVisuals()

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/WorkChance(mob/living/carbon/human/user, chance, work_type)
	if(work_type == "Erase")
		return 50
	var/mx = max(paint[RED_DAMAGE], paint[WHITE_DAMAGE], paint[BLACK_DAMAGE])
	var/mn = min(paint[RED_DAMAGE], paint[WHITE_DAMAGE], paint[BLACK_DAMAGE])
	return round(clamp(20 + 60 * (mn / mx), 20, 80))

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	. = ..()
	if(work_type == "Erase")
		paint[RED_DAMAGE] = 1
		paint[WHITE_DAMAGE] = 1
		paint[BLACK_DAMAGE] = 1
		visible_message(span_notice("[src]'s sheet is washed back to a clean, even grey."))
	else
		var/pcol = work_to_paint[work_type]
		if(pcol)
			paint[pcol] += 1
	RefreshVisuals()

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	breached = TRUE
	RefreshVisuals()

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/AttackingTarget(atom/attacked_target)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(!breached)
		return
	// Store the damage AFTER its own resistance - the HP the hit actually cost us, not the raw hit. This is
	// what makes triple-immunity impossible: the running total of stored ink can never exceed the HP the
	// squid has actually lost, and saturating three colours (120% of max HP) would kill it long first. As a
	// colour grows resistant each further hit of it is absorbed less and so stores less, climbing toward
	// immunity ever more slowly - only one or two colours can realistically get there.
	if(IsColorDamageType(damage_type) && damage_amount > 0)
		var/absorbed = damage_amount * damage_coeff.getCoeff(damage_type)
		if(absorbed > 0)
			stored_damage[damage_type] = min(resist_threshold, stored_damage[damage_type] + absorbed)
			UpdateInkResistances()
			RefreshVisuals()
	// Retaliate against a melee attacker with a telegraphed ink burst.
	if(isliving(source) && get_dist(src, source) <= 2 && !(attack_type & (ATTACK_TYPE_RANGED|ATTACK_TYPE_SPECIAL|ATTACK_TYPE_STATUS|ATTACK_TYPE_ENVIRONMENT)))
		if(COOLDOWN_FINISHED(src, ink_aoe))
			COOLDOWN_START(src, ink_aoe, aoe_cooldown)
			INVOKE_ASYNC(src, PROC_REF(InkBurst))

// coeff = 1 while a colour is under 20% maxHP stored, ramping to 0 (immune) at 40% maxHP stored.
// The half-ramp (rather than a full linear fade) keeps it killable and forces damage-type diversity.
/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/proc/UpdateInkResistances()
	var/half = resist_threshold * 0.5
	if(half <= 0)
		return
	ChangeResistances(list(
		RED_DAMAGE = clamp((resist_threshold - stored_damage[RED_DAMAGE]) / half, 0, 1),
		WHITE_DAMAGE = clamp((resist_threshold - stored_damage[WHITE_DAMAGE]) / half, 0, 1),
		BLACK_DAMAGE = clamp((resist_threshold - stored_damage[BLACK_DAMAGE]) / half, 0, 1),
		PALE_DAMAGE = clamp((resist_threshold - stored_damage[PALE_DAMAGE]) / half, 0, 1),
	))

// Deal 'total' to a target, split into one instance per stored colour by its share.
// With nothing stored yet, it is plain black ink.
/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/proc/DealInkDamage(mob/living/target, total, atk_type = ATTACK_TYPE_SPECIAL)
	if(QDELETED(target) || total <= 0)
		return
	var/tot = stored_damage[RED_DAMAGE] + stored_damage[WHITE_DAMAGE] + stored_damage[BLACK_DAMAGE] + stored_damage[PALE_DAMAGE]
	if(tot <= 0)
		target.deal_damage(total, BLACK_DAMAGE, source = src, attack_type = atk_type)
		return
	for(var/dt in list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE))
		if(stored_damage[dt] <= 0)
			continue
		target.deal_damage(total * (stored_damage[dt] / tot), dt, source = src, attack_type = atk_type)

// Retaliation AoE: telegraph the ring around itself, then splash everything in it.
/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/proc/InkBurst()
	playsound(src, 'sound/effects/splat.ogg', 60, TRUE)
	var/list/turfs = list()
	for(var/turf/T in range(aoe_range, src))
		turfs += T
		new /obj/effect/temp_visual/inkstained_warning(T)
	SLEEP_CHECK_DEATH(10)
	var/list/hit = list()
	for(var/turf/T in turfs)
		new /obj/effect/temp_visual/inkstained_splat(T)
		for(var/mob/living/L in T)
			if(L == src || (L in hit) || faction_check(L.faction, faction))
				continue
			hit += L
			DealInkDamage(L, aoe_damage)

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/OpenFire()
	if(busy || !breached || !target)
		return
	if(!COOLDOWN_FINISHED(src, ink_laser))
		return
	FireInkLine(target)

// Mark a turf 2-3 tiles behind the target and tell it, then lance an ink line out to the mark and
// drag it back into itself - the drag-back splashes a 3x3 of ink and deals the damage as it retracts.
/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/proc/FireInkLine(mob/living/fire_target)
	if(QDELETED(fire_target) || busy)
		return FALSE
	busy = TRUE
	COOLDOWN_START(src, ink_laser, laser_cooldown)
	face_atom(fire_target)
	var/reach = min(get_dist(src, fire_target) + rand(2, 3), laser_distance)
	var/turf/mark = get_ranged_target_turf_direct(src, fire_target, reach)
	new /obj/effect/temp_visual/inkstained_warning(mark)
	SLEEP_CHECK_DEATH(7.5)	// 0.75s tell
	// Reachable path out to the mark, stopping at the first wall.
	var/list/path = list()
	for(var/turf/T in getline(src, mark))
		if(!isturf(T) || T.density)
			break
		path += T
	if(!length(path))
		busy = FALSE
		return FALSE
	var/datum/beam/beam = Beam(get_turf(src), "volt_ray")
	// Phase 1 - the line lances out to the mark.
	for(var/turf/T in path)
		if(QDELETED(src))
			qdel(beam)
			busy = FALSE
			return FALSE
		beam.target = T
		beam.redrawing()
		sleep(1)
	// Phase 2 - it drags the line back into itself, splashing a 3x3 of ink and dealing damage.
	var/list/hit = list()
	var/list/splatted = list()
	for(var/i = length(path) to 1 step -1)
		if(QDELETED(src))
			break
		var/turf/center = path[i]
		for(var/turf/AT in range(1, center))
			if(!(AT in splatted))
				splatted += AT
				new /obj/effect/temp_visual/inkstained_splat(AT)
			for(var/mob/living/L in AT)
				if(L == src || (L in hit) || faction_check(L.faction, faction))
					continue
				hit += L
				DealInkDamage(L, laser_damage)
		beam.target = center
		beam.redrawing()
		sleep(1)
	qdel(beam)
	busy = FALSE
	return TRUE

/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/proc/RefreshVisuals()
	cut_overlays()
	// Body "fills" toward its dominant stored colour while breached.
	var/total_stored = stored_damage[RED_DAMAGE] + stored_damage[WHITE_DAMAGE] + stored_damage[BLACK_DAMAGE] + stored_damage[PALE_DAMAGE]
	if(breached && total_stored > 0)
		var/dom = RED_DAMAGE
		for(var/dt in list(WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE))
			if(stored_damage[dt] > stored_damage[dom])
				dom = dt
		var/mutable_appearance/fill = mutable_appearance(icon, "squid_fill", -ABOVE_MOB_LAYER)
		fill.color = paint_hex[dom]
		fill.alpha = clamp(round(200 * (total_stored / (4 * resist_threshold))) + 35, 35, 210)
		add_overlay(fill)
	DrawColorBar()

// The head bar. Contained: relative balance of the three paints, largest colour leftmost. Breached: one
// segment per 10% of max HP (200) of each stored colour, so it reads how close each colour is to immunity.
/mob/living/simple_animal/hostile/abnormality/branch12/inkstained_squid/proc/DrawColorBar()
	var/segs = 12
	var/seg_w = 2
	var/bar_left = 2	// tucked to the left of its head
	var/bar_y = 62		// lowered off the pen so it reads clearly
	// The ordered list of segment colours to draw, left to right.
	var/list/seg_colors = list()
	if(breached)
		var/unit = maxHealth * 0.1	// one segment per 200 stored ink of a colour
		for(var/dt in list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE))
			for(var/s in 1 to round(stored_damage[dt] / unit))
				if(length(seg_colors) >= segs)
					break
				seg_colors += dt
	else
		var/list/vals = list(
			RED_DAMAGE = paint[RED_DAMAGE],
			WHITE_DAMAGE = paint[WHITE_DAMAGE],
			BLACK_DAMAGE = paint[BLACK_DAMAGE],
		)
		var/total = 0
		for(var/k in vals)
			total += vals[k]
		if(total > 0)
			// Colours present, sorted by value descending (selection sort - at most three entries).
			var/list/order = list()
			for(var/k in vals)
				if(vals[k] > 0)
					order += k
			for(var/i in 1 to order.len - 1)
				var/best = i
				for(var/j in i + 1 to order.len)
					if(vals[order[j]] > vals[order[best]])
						best = j
				if(best != i)
					var/tmp = order[i]
					order[i] = order[best]
					order[best] = tmp
			var/assigned = 0
			for(var/i in 1 to order.len)
				var/color = order[i]
				var/cnt = (i == order.len) ? (segs - assigned) : round(vals[color] / total * segs)
				cnt = clamp(cnt, 0, segs - assigned)
				assigned += cnt
				for(var/s in 1 to cnt)
					seg_colors += color
	if(!length(seg_colors))
		return
	// progressbar-style border behind the segments; its transparent interior lines up with them.
	var/mutable_appearance/frame = mutable_appearance('ModularLobotomy/_Lobotomyicons/branch12/effects/squid_bar_frame.dmi', "frame", -ABOVE_ALL_MOB_LAYER)
	frame.pixel_x = bar_left - 4
	frame.pixel_y = bar_y - 14
	add_overlay(frame)
	var/idx = 0
	for(var/color in seg_colors)
		var/mutable_appearance/seg = mutable_appearance('ModularLobotomy/_Lobotomyicons/branch12/effects/squid_bar.dmi', seg_state[color], -ABOVE_ALL_MOB_LAYER)
		seg.pixel_x = bar_left + idx * seg_w
		seg.pixel_y = bar_y
		add_overlay(seg)
		idx++

/obj/effect/temp_visual/inkstained_warning
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/effects//squid_fx.dmi'
	icon_state = "ink_warning"
	duration = 1 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/inkstained_splat
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/effects/squid_fx.dmi'
	icon_state = "ink_splat1"
	duration = 9
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/inkstained_splat/Initialize(mapload)
	. = ..()
	icon_state = "ink_splat[rand(1, 4)]"
	var/matrix/M = matrix()
	M.Turn(pick(0, 90, 180, 270))
	transform = M * 0.35
	animate(src, transform = M * 1, time = 2, easing = SINE_EASING)			// grow
	animate(transform = M * 1.15, alpha = 0, time = duration - 2, easing = SINE_EASING | EASE_IN)	// then fade
