// ============================================
// SANCHO - Allied Bloodfiend Boss (Helps R-Corp)
// ============================================

/// Sancho - An allied bloodfiend who stands with humanity against the Heart of Greed
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho
	name = "Sancho"
	desc = "A bloodfiend who chose to stand with humanity against the Heart of Greed. Her loyalty to Don Quixote's original dream of coexistence drives her to fight alongside R-Corp."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_32x32.dmi'
	icon_state = "sancho"
	icon_living = "sancho"
	// Health like Dulcinea (second kindred)
	maxHealth = 6500
	health = 6500
	// Custom attack stats
	rapid_melee = 5
	move_to_delay = 2.5
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 10
	melee_damage_upper = 14
	base_damage_lower = 10
	base_damage_upper = 14
	attack_sound = 'sound/weapons/fixer/generic/fist1.ogg'
	bleed_stacks = 6
	// Resistances similar to Dulcinea
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.2)
	ranged = TRUE
	/// Whether Sancho can currently act
	var/can_act = TRUE
	// Topple/Wound Attack (Skill 1)
	/// Cooldown tracker for Topple/Wound
	var/topple_cooldown = 0
	/// Time between Topple/Wound attacks
	var/topple_cooldown_time = 12 SECONDS
	/// Base damage for Topple/Wound
	var/topple_damage = 60
	/// Base number of dashes
	var/topple_base_dashes = 5
	/// Bleed stacks applied per dash
	var/topple_bleed_per_dash = 1
	// Sanguine Joy Attack (Skill 2)
	/// Cooldown tracker for Sanguine Joy
	var/joy_cooldown = 0
	/// Time between Sanguine Joy attacks
	var/joy_cooldown_time = 8 SECONDS
	/// Base damage for Sanguine Joy
	var/joy_damage = 40
	/// Range of Sanguine Joy attack
	var/joy_range = 5
	/// Windup time before Sanguine Joy hits
	var/joy_windup = 1.5 SECONDS
	/// Knockback distance for Sanguine Joy
	var/joy_knockback = 3
	/// Cooldown for sibling speech
	var/sibling_speech_cooldown = 0
	/// Time between sibling speeches
	var/sibling_speech_cooldown_time = 30 SECONDS
	/// Lines spoken when fighting The Barber
	var/list/barber_lines = list(
		"...Your obsession with beauty was always annoying. But I never wanted this.",
		"Two centuries of starvation broke you. I get it. Doesn't mean I'll let you continue.",
		"You gave visitors makeovers they never asked for... now the Heart gives you purpose you never needed.",
		"...Sorry. Father's dream died, and you couldn't handle it. Neither could I, honestly."
	)
	/// Lines spoken when fighting The Priest
	var/list/priest_lines = list(
		"You told everyone to suppress their doubts. Look where that got you.",
		"...You rotted in that confessional for centuries. The Heart just finished what isolation started.",
		"Your faith was misplaced before. Now it's just... twisted.",
		"Of all of us, you actually cared. That's why this is harder."
	)
	/// Lines spoken when fighting Dulcinea
	var/list/dulcinea_lines = list(
		"Princess of the Parade... you always saw yourself as powerless. The Heart proved you right.",
		"...You envied Father's ignorance. Now you have your own.",
		"Two hundred years of despair, and the Heart offered you meaning in hoarding. Pathetic.",
		"You spoke poorly of everyone, including yourself. At least that was honest."
	)
	/// General lines about the family's fall
	var/list/family_lines = list(
		"...We all failed Father's dream. Some of us just failed differently.",
		"The Heart didn't corrupt you. It just gave shape to what starvation already broke.",
		"I ran away. You stayed and rotted. Neither choice was right.",
		"...This isn't mercy. It's just... necessary."
	)

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/Initialize()
	. = ..()
	// Set to neutral faction - allies with R-Corp against hostile bloodfiends
	faction = list("neutral")

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/face_atom(atom/A)
	if(!can_act)
		return
	. = ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/Move()
	if(!can_act)
		return FALSE
	return ..()

// ============================================
// MELEE ATTACK - 130% More Damage to Simple Mobs
// ============================================

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	// Check for sibling speech
	TrySiblingSpeech(attacked_target)
	// Try to use skills even while in melee
	if(attacked_target)
		// Priority: Topple/Wound first, then Sanguine Joy when Topple is on cooldown
		if(topple_cooldown <= world.time)
			ToppleWound(attacked_target)
			return FALSE
		if(joy_cooldown <= world.time && get_dist(src, attacked_target) <= joy_range)
			SanguineJoy(attacked_target)
			return FALSE
	// Check if target is a simple mob
	if(istype(attacked_target, /mob/living/simple_animal))
		// Temporarily boost damage by 130% (2.3x total)
		var/old_lower = melee_damage_lower
		var/old_upper = melee_damage_upper
		melee_damage_lower = round(melee_damage_lower * 2.3)
		melee_damage_upper = round(melee_damage_upper * 2.3)
		. = ..()
		melee_damage_lower = old_lower
		melee_damage_upper = old_upper
	else
		. = ..()

/// Speaks a line when fighting siblings (Barber, Priest, Dulcinea)
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/proc/TrySiblingSpeech(atom/target_atom)
	if(sibling_speech_cooldown > world.time)
		return
	if(!isliving(target_atom))
		return
	if(!prob(20))
		return
	var/list/lines_to_use
	// Check for specific siblings
	if(istype(target_atom, /mob/living/simple_animal/hostile/bloodfiend_boss/barber))
		lines_to_use = barber_lines
	else if(istype(target_atom, /mob/living/simple_animal/hostile/bloodfiend_boss/priest))
		lines_to_use = priest_lines
	else if(istype(target_atom, /mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea))
		lines_to_use = dulcinea_lines
	// Check for generic bloodfiend mooks/bloodbags - use family lines
	else if(istype(target_atom, /mob/living/simple_animal/hostile/bloodfiend_mook) || istype(target_atom, /mob/living/simple_animal/hostile/bloodbag))
		lines_to_use = family_lines
	if(!lines_to_use)
		return
	sibling_speech_cooldown = world.time + sibling_speech_cooldown_time
	say(pick(lines_to_use))

// ============================================
// OPENFIRE - Skill Usage Integration
// ============================================

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/OpenFire()
	if(!can_act)
		return
	if(!target)
		return
	// Priority: Topple/Wound first, then Sanguine Joy when Topple is on cooldown
	if(topple_cooldown <= world.time)
		ToppleWound(target)
		return
	if(joy_cooldown <= world.time && get_dist(src, target) <= joy_range)
		SanguineJoy(target)

// ============================================
// SKILL 1: TOPPLE/WOUND - Rapid Dash Attack
// ============================================

/// Rapidly dash through enemies, dealing damage along the path
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/proc/ToppleWound(mob/living/main_target)
	if(!isliving(main_target) || QDELETED(main_target))
		return
	can_act = FALSE

	// Calculate dash count based on bloodfeast
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/blood_percent = 0
	if(bloodfeast)
		blood_percent = bloodfeast.blood_amount / max_blood
	var/num_dashes = topple_base_dashes + FLOOR(blood_percent / 0.2, 1) * 5
	num_dashes = clamp(num_dashes, 5, 30)

	playsound(src, 'sound/abnormalities/nosferatu/special_start.ogg', 75, TRUE)
	manual_emote("prepares to strike!")

	var/mob/living/current_target = main_target

	for(var/i in 1 to num_dashes)
		if(QDELETED(src) || stat == DEAD)
			break

		// If current target is dead/deleted, find a new hostile target
		if(!isliving(current_target) || QDELETED(current_target) || current_target.stat == DEAD)
			current_target = FindNewHostileTarget()
			if(!current_target)
				break

		// Perform the dash
		DashToTarget(current_target, current_target == main_target)
		SLEEP_CHECK_DEATH(2)

	// Cooldown starts after all dashes complete
	topple_cooldown = world.time + topple_cooldown_time
	can_act = TRUE

/// Find a new hostile target for Topple/Wound
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/proc/FindNewHostileTarget()
	var/list/potential_targets = list()
	for(var/mob/living/L in view(9, src))
		if(faction_check_mob(L))
			continue
		if(L == src)
			continue
		if(L.stat == DEAD)
			continue
		potential_targets += L
	if(!LAZYLEN(potential_targets))
		return null
	return pick(potential_targets)

/// Perform a single dash to target location
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/proc/DashToTarget(mob/living/dash_target, is_main_target = FALSE)
	// Consume 150 bloodfeast per dash
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(bloodfeast)
		bloodfeast.AdjustBlood(-150)
	var/turf/start_turf = get_turf(src)
	// Get a turf past the target
	var/turf/target_turf = get_step(get_turf(dash_target), pick(GLOB.cardinals))
	// Extend 1-2 tiles past target
	for(var/i in 1 to 2)
		var/turf/next = get_step(target_turf, get_dir(start_turf, target_turf))
		if(next)
			target_turf = next

	// Telegraph the attack
	for(var/turf/T in getline(start_turf, target_turf))
		new /obj/effect/temp_visual/cult/sparks(T)

	face_atom(target_turf)
	SLEEP_CHECK_DEATH(1)

	if(!isliving(dash_target) || QDELETED(dash_target))
		return

	// Move to target location
	forceMove(target_turf)
	playsound(src, 'sound/abnormalities/nosferatu/attack_special.ogg', 25, TRUE)

	// Deal damage along the path
	var/list/hit_mobs = list()
	for(var/turf/T in getline(start_turf, target_turf))
		for(var/turf/TT in range(1, T))
			new /obj/effect/temp_visual/small_smoke/halfsecond(TT)
			for(var/mob/living/victim in TT)
				if(faction_check_mob(victim))
					continue
				if(victim in hit_mobs)
					continue
				hit_mobs += victim

				// Calculate damage
				var/actual_damage = topple_damage
				// Main target takes 75% less damage
				if(victim == dash_target && is_main_target)
					actual_damage = round(topple_damage * 0.25)
				// Simple mobs take 100% more damage
				else if(istype(victim, /mob/living/simple_animal))
					actual_damage = round(topple_damage * 2)

				victim.deal_damage(actual_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				victim.apply_lc_bleed(topple_bleed_per_dash)
				new /obj/effect/temp_visual/cleave(victim.loc)
				playsound(victim, 'sound/weapons/fixer/generic/fist1.ogg', 35, TRUE)

	// If we ended up in a wall, go back
	var/turf/current_turf = get_turf(src)
	if(current_turf.density || isclosedturf(current_turf))
		forceMove(start_turf)

// ============================================
// SKILL 2: SANGUINE JOY - Charged Punch Attack
// ============================================

/// Charge up a devastating punch that deals bonus damage based on target's bleed
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/proc/SanguineJoy(atom/punch_target)
	joy_cooldown = world.time + joy_cooldown_time
	can_act = FALSE

	// Consume 400 bloodfeast
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(bloodfeast)
		bloodfeast.AdjustBlood(-400)

	face_atom(punch_target)
	manual_emote("charges up a devastating punch!")

	var/turf/target_turf = get_turf(punch_target)
	var/turf/source_turf = get_turf(src)

	// Calculate extended end turf (4 tiles past target, max 6 total length)
	var/dir_to_target = get_dir(source_turf, target_turf)
	var/turf/extended_turf = target_turf
	for(var/i in 1 to 4)
		var/turf/next = get_step(extended_turf, dir_to_target)
		if(next)
			extended_turf = next
	// Get the attack line and limit to max 6 tiles
	var/list/attack_line = getline(source_turf, extended_turf)
	if(length(attack_line) > 6)
		attack_line = attack_line.Copy(1, 7) // Keep first 6 tiles

	// Warning phase - show sparks along the line
	var/broken = FALSE
	for(var/turf/T in attack_line)
		if(T.density)
			if(broken)
				break
			broken = TRUE
		for(var/turf/TF in range(1, T))
			if(TF.density)
				continue
			new /obj/effect/temp_visual/cult/sparks(TF)

	playsound(src, 'sound/weapons/fixer/generic/energy3.ogg', 75, TRUE)
	SLEEP_CHECK_DEATH(joy_windup)

	// Damage phase
	playsound(src, 'sound/weapons/fixer/generic/energyfinisher1.ogg', 75, TRUE)
	broken = FALSE
	var/list/hit_mobs = list()

	for(var/turf/T in attack_line)
		if(T.density)
			if(broken)
				break
			broken = TRUE
		for(var/turf/TF in range(1, T))
			if(TF.density)
				continue
			new /obj/effect/temp_visual/smash_effect(TF)
			for(var/mob/living/victim in TF)
				if(faction_check_mob(victim))
					continue
				if(victim in hit_mobs)
					continue
				hit_mobs += victim

				// Calculate damage with bleed bonus (+2% per bleed stack)
				var/bleed_stacks_on_target = 0
				var/datum/status_effect/stacking/lc_bleed/BE = victim.has_status_effect(/datum/status_effect/stacking/lc_bleed)
				if(BE)
					bleed_stacks_on_target = BE.stacks
				var/damage_mult = 1 + (bleed_stacks_on_target * 0.02)
				var/actual_damage = round(joy_damage * damage_mult)

				victim.deal_damage(actual_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				to_chat(victim, span_userdanger("[src] delivers a crushing blow!"))

	// Knockback phase - push all hit mobs away
	for(var/mob/living/victim in hit_mobs)
		if(QDELETED(victim) || victim.stat == DEAD)
			continue
		var/dir_away = get_dir(src, victim)
		if(!dir_away)
			dir_away = pick(GLOB.cardinals)
		for(var/i in 1 to joy_knockback)
			var/turf/next = get_step(victim, dir_away)
			if(!next || next.density || isclosedturf(next))
				break
			victim.forceMove(next)

	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE

// ============================================
// HIDDEN SANCHO - Mysterious Silhouette Variant
// ============================================

/// Hidden variant of Sancho - appears as a black silhouette for 10 seconds before vanishing
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/hidden
	name = "???"
	desc = "A mysterious silhouette shrouded in darkness."
	icon_state = "sancho_hidden"
	/// Time before this variant disappears
	var/existence_time = 10 SECONDS

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/hidden/Initialize()
	. = ..()
	// Start with 75% bloodfeast
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(bloodfeast)
		bloodfeast.blood_amount = max_blood * 0.75
	// Teleport in effect
	var/obj/effect/temp_visual/beam_in/B = new(get_turf(src))
	B.color = "#FF5050"
	playsound(src, 'sound/effects/ordeals/white/pale_teleport_in.ogg', 75, TRUE)
	// Schedule disappearance
	addtimer(CALLBACK(src, PROC_REF(vanish)), existence_time)

/// Called when the hidden Sancho's time is up
/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/hidden/proc/vanish()
	if(QDELETED(src))
		return
	// Teleport out effect
	var/obj/effect/temp_visual/beam_out/B = new(get_turf(src))
	B.color = "#FF5050"
	playsound(src, 'sound/effects/ordeals/white/pale_teleport_out.ogg', 75, TRUE)
	qdel(src)

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/hidden/death(gibbed)
	// Override death to just vanish instead
	vanish()

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/hidden/long
	existence_time = 30 SECONDS

/mob/living/simple_animal/hostile/bloodfiend_boss/sancho/hidden/short
	existence_time = 5 SECONDS
