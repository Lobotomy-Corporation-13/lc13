/* Spiral of Contempt
We're currently missing a sprite for it, I might make one myself

----------- Work Mechs -----------
--- Basics ---
> Qlipcounter of 3
> Good Instinct and Insight, horrible Attachment, alright Repression.
> Repression has a chance to raise Qlip by 1 based on Temperance (guaranteed at Temp V+).
> Qlipdrop on Bad, Qlipdrop chance on Neutral.
--- Special ---
> Every non-Repression work done by an agent on Spiral without working on another Abnormality gives you an Awe stack, which
increases the PE box amount and work damage dealt for Spiral of Contempt. You can get up to 5 Awe stacks.

> Working on another Abno with Awe on you will cause Spiral to qlipdrop, and remove Awe.

Note: In the context of Spiral, 'Repression' means refusing to face it, not meeting its gaze. Refer to the MD event 'Avert your Eyes' option.

----------- Breach Mechs -----------
--- Basics ---
> Teleports to a department center. Cannot move. Will teleport to another department center every 45 seconds. Maybe also let it go to xenospawns?
> Normal-ish base resistances, resisting RED/BLACK and being weak to WHITE and fatal to PALE, but only takes 10% of incoming damage by default. Meant to be obnoxiously tanky without Gaze.
> Hitting it in melee while having your zone target set to arms/hands will cause you to gain a stack of Gaze.
Gaze will lower the damage resistance that Spiral has against you, but make you take more damage from it, too.
> Attacks faster at <25% HP.
--- Attacks ---
> It Shall Be Insidious: Will periodically attack everyone in the same area as it with an unavoidable blood rain, dealing BLACK damage.
> It Shall Grip: Will periodically try to attack up to 2 people in the same area as it with gripping fists, dealing wind-up telegraphed AoE BLACK damage.
> It Shall Perforate: Can melee attack with a long cooldown and a reach of 3, dealing RED damage and inflicting bleed (todo: check the "allowed limbus status" quota).
> It Shall Shun/Contempt: If you reach 7 Gaze, you will be trapped and incapacitated by clasped hands.
They have X amount of health. If they are destroyed in Y seconds, Spiral gets staggered, which makes it lose all its resistances for a while and be unable to act or escape;
if the hands remain alive, the hands close with a huge AOE. (You need allies to destroy these.)

----------- EGO -----------
--- Weapons ---
> Contempt, Awe: WAW - The current javelin.
> Perversion: ALEPH - A rankbump weapon. It's Huan's/Contemptshu's weapon.
--- Armour ---
> Contempt, Awe: WAW - We don't have sprites for this. If I don't see some pop up soon I'll make a codersprite.
I'm feeling [strong BLACK/PALE, weak RED/WHITE] or [strong RED/BLACK, weak WHITE/PALE] but unsure for now.
*/

#define STATUS_EFFECT_GAZE /datum/status_effect/stacking/spiral_gaze
#define STATUS_EFFECT_AWE /datum/status_effect/stacking/spiral_awe
#define STATUS_EFFECT_CONTEMPT /datum/status_effect/display/spiral_contempt
#define VALID_GAZE_GAIN_TARGET_ZONES list("l_arm", "r_arm", "l_hand", "r_hand")
/// This thing gives you a lot of PE, has good work rates, trains three stats, and has a rankbump weapon, so it must be WAW+ in breach difficulty.
/mob/living/simple_animal/hostile/abnormality/spiral
	name = "Spiral of Contempt"
	threat_level = WAW_LEVEL
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS
	desc = "An imposing and beautiful spiral of gold. \n\
	The upper half is vaguely shaped like a human torso with both arms outstretched towards the sky and sharp 'wings' protruding from the back. \
	Black hands drip with blood, and its 'head' glowers down at you."
	portrait = "spiral_of_contempt"

	/* --- Appearance --- */
	icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
	icon_state = "spiral"
	icon_living = "spiral"
	pixel_x = -32
	base_pixel_x = -32

	/* --- Defense --- */
	// Should be obscenely tanky. You will need some Gaze if you don't want this fight to turn into a slog meatgrinder
	maxHealth = 3700
	health = 3700
	// These damage coeffs are basically fake, inbound damage will be severely reduced, you need Gaze stacks to counteract it.
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.5)
	var/base_inbound_damage_coeff = 0.1 // You're gonna be here a while if you try to bruteforce this. Not so bad if you stack Gaze.

	/* --- Work --- */
	// It is intended for Spiral to be hard to please and Awe makes it even harder, but it will always give you a good chunk of PE.
	max_boxes = 22
	var/boxes_per_awe = 3
	var/success_box_percent_required = 0.8 // Standard is 0.7
	var/neutral_box_percent_required = 0.5 // Standard is 0.4

	start_qliphoth = 3
	neutral_droprate = 40 // You are going to be getting a lot of neutrals
	bad_droprate = 100
	var/repression_qlipraise_chance = list("I" = 0, "II" = 0, "III" = 33, "IV" = 66, "V" = 90, "EX" = 100) // !WARNING! Based on Temperance, not Justice.

	/// These lists are only kept so we can wipe them when Spiral breaches/dies. Spiral-corp does not provide any warranty that the people in this list actually have these statuses
	var/list/awed_workers = list()
	var/list/gazed_fighters = list()
	var/list/contempted_fighters = list()

	// These work rates are very gentle, but the abno will still often get Neutral/Bad works due to its stricter box requirements.
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(15, 20, 25, 45, 50),
		ABNORMALITY_WORK_INSIGHT = list(15, 25, 30, 50, 55),
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = list(10, 15, 20, 40, 45),
	)
	work_damage_amount = 10 // Wow! Only 10 damage for a WAW+ abnormality? That's so generous!
	var/work_damage_per_awe_stack = 4 // :malkstare: (This can actually be so much worse than an ALEPH if you let it stack)
	var/work_delay_reduction_per_awe_stack = 1.3 // In deciseconds. Positive: player doesn't need to experience the tedium of works with more boxes than ALEPH abnos. Negative: no time for medipens to save you.
	var/work_chance_per_awe_stack = 2 // Awe was too harsh in testing, this should help counteract Qlip Overload a little.
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride // This is the colour of the egg's gem.
	ego_list = list(
		/datum/ego_datum/weapon/contempt,
		/datum/ego_datum/armor/contempt,
		/datum/ego_datum/weapon/perversion,
	)

	generic_bubbles = list(
		1 = list("%PERSON is evidently not prepared to work with %ABNO...", "%PERSON is anxiously counting the seconds until they're allowed to leave the cell."),
		2 = list("%PERSON can't muster up the courage to face away from %ABNO, but is starting to crack under the pressure of its gaze...", "%PERSON hurriedly flips through the instruction manual for %ABNO."),
		3 = list("%PERSON is torn on whether to look at %ABNO or not.", "%PERSON keeps track of %ABNO's floaty movements..."),
		4 = list("%PERSON knows better than to show any reverence for %ABNO.", "%PERSON acts decisively to keep %ABNO in check."),
		5 = list("%PERSON is unimpressed by %ABNO.", "%PERSON is unaffected by %ABNO's near-magnetic pull.", "%PERSON is counting the seconds until their busywork is concluded."),
	)

	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("%PERSON polishes %ABNO's golden frame, but the bloodstains are there to stay.", "%PERSON mends some cracks on %ABNO."),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON cleans up %ABNO's cell. The land of gold must be spotless."),
		ABNORMALITY_WORK_ATTACHMENT = list("%PERSON seems to think %ABNO cares for conversation. They are wrong.", "%PERSON seems taken by a trance, pleading for %ABNO to acknowledge them. It does not."),
		ABNORMALITY_WORK_REPRESSION = list("%PERSON averts their gaze from %ABNO.", "%PERSON resists %ABNO's effects and glares back at it with contempt of their own."),
	)

	//gift_type = /datum/ego_gifts/spiral

	/* --- Breach --- */
	can_breach = TRUE
	can_patrol = FALSE

	/* --- General Combat --- */
	/// GCD applies to autoattack and all abilities, the only exception is Teleport.
	var/global_cooldown
	var/global_cooldown_duration = 2 SECONDS
	/// Spiral enrages when (health <= (maxHealth * [this var]))
	var/enrage_hp_threshold = 0.25
	/// Becomes TRUE when Spiral enrages.
	var/enraged = FALSE
	/// Enrage: Grip CD is [this var]x as long.
	var/enrage_grip_cd_coeff = 0.8
	/// Enrage: Grip is cast an extra [this var] times.
	var/enrage_grip_extra_iterations = 1
	/// Enrage: Perforate's CD is [this var]x faster.
	var/enrage_perforate_cd_speed_coeff = 1.5

	/* --- Teleport --- */
	var/teleport_timer
	var/teleport_cooldown_duration = 45 SECONDS
	var/teleporting = FALSE

	/* --- Gaze --- */
	// Variables for Gaze outgoing and inbound damage are stored on the Gaze status effect.

	// I'm gonna make the judgement call NOT to add a cooldown on gaining Gaze. This means you can instantly rocket to 5 Gaze by hitting Spiral with Animalism.
	// We'll see if it's the right choice to make. Stuff like lances and Voodoo will be... interesting.

	/* --- Autoattack (It Shall Perforate) --- */
	// RED damage
	var/perforate_bleed_stacks = 8 // dw it attacks very slowly
	melee_damage_lower = 38
	melee_damage_upper = 44
	melee_damage_type = RED_DAMAGE
	melee_reach = 3
	rapid_melee = 0.15
	attack_sound = 'sound/abnormalities/spiral_contempt/spiral_hit.ogg'
	attack_verb_continuous = "perforates"
	attack_verb_simple = "perforate"

	/* --- Periodic Damage (It Shall Be Insidious) --- */
	// BLACK damage
	var/insidious_damage = 28
	var/insidious_cooldown
	var/insidious_cooldown_duration = 9 SECONDS

	/* --- Periodic Telegraphed AoEs (It Shall Grip) --- */
	// BLACK damage
	var/grip_damage = 90 // You should dodge
	/// Radius in tiles.
	var/grip_radius = 1
	/// Telegraph duration for the attack.
	var/grip_windup = 1.2 SECONDS
	var/grip_cooldown
	var/grip_cooldown_duration = 10 SECONDS
	// When using It Shall Grip, we'll cast it up to [grip_iterations] times, each time it will spawn up to [grip_max_targets] AoEs.
	var/grip_iterations = 1
	var/grip_max_targets = 2

	/* --- Contempt Punish/Stagger Opportunity (It Shall Shun) --- */
	// BLACK damage
	var/shun_damage = 200 // Don't flop the DPS check or you get sent directly to Sovngarde (livable with some black res tbh)
	var/shun_radius = 2
	var/shun_hands_type
	// Balance these three variables to ensure that it's a DPS check that can barely be met by 1 WAW agent using the right damage types. Destroying this thing with HE weapons should be EXTREMELY difficult if not impossible.
	var/shun_hands_hp = 440
	var/shun_hands_resistances = list(RED_DAMAGE = 0.9, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)
	var/shun_windup = 7 SECONDS // 440/7 requires 62.9 true DPS to kill. This is doable for WAW weapons if factoring in Justice.
	/// Holds a list of the buckling mobs created by this attack, we need to wipe this if we die/get staggered
	var/list/shun_mobs = list()

	/* --- Stagger (Reward for resolving It Shall Shun) --- */
	var/staggered = FALSE
	var/stagger_duration = 8 SECONDS
	var/stagger_unstagger_time = 100
	var/list/stagger_resistances = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.6, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 2) // WHITE and PALE are slightly higher to keep them as more effective during stagger than just 6 gaze stacks

/mob/living/simple_animal/hostile/abnormality/spiral/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced)
	. = ..()
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 40, TRUE)

/* ------------------------------- Work Code ------------------------------- */
/mob/living/simple_animal/hostile/abnormality/spiral/Worktick(mob/living/carbon/human/user, bubble_type, work_type)
	bubble_type = ABNO_BALLOON_GENERIC | ABNO_BALLOON_WORK
	. = ..()

// Increase work speed based on Awe stacks. This is a double edged sword; you get faster works that generate more PE, but that also means you have less time to heal during the work.
/mob/living/simple_animal/hostile/abnormality/spiral/SpeedWorktickOverride(mob/living/carbon/human/user, work_speed, init_work_speed, work_type)
	. = ..()
	var/datum/status_effect/stacking/spiral_awe/awe = user.has_status_effect(STATUS_EFFECT_AWE)
	if(awe)
		return init_work_speed -= (awe.stacks * work_delay_reduction_per_awe_stack)

// Increase work chance based on Awe stacks. This is a slight countermeasure to getting your rates nuked by Qliphoth Overload.
/mob/living/simple_animal/hostile/abnormality/spiral/WorkChance(mob/living/carbon/human/user, chance, work_type)
	. = ..()
	if(!istype(user))
		return
	var/datum/status_effect/stacking/spiral_awe/awestruck = user.has_status_effect(STATUS_EFFECT_AWE)
	if(awestruck)
		return (. + (work_chance_per_awe_stack * awestruck.stacks))

// Before working: Adjust Max PE boxes, Success PE boxes, Neutral PE boxes and Work Damage based on Awe stacks of the worker.
/mob/living/simple_animal/hostile/abnormality/spiral/AttemptWork(mob/living/carbon/human/user, work_type)
	work_damage_amount = initial(work_damage_amount)
	var/datum/status_effect/stacking/spiral_awe/awe = user.has_status_effect(STATUS_EFFECT_AWE)
	if(awe)
		work_damage_amount += (awe.stacks * work_damage_per_awe_stack)
		datum_reference.max_boxes = initial(max_boxes) + (awe.stacks * boxes_per_awe)
		datum_reference.success_boxes = floor(datum_reference.max_boxes * success_box_percent_required)
		datum_reference.neutral_boxes = floor(datum_reference.max_boxes * neutral_box_percent_required)
		return TRUE
	datum_reference.max_boxes = initial(max_boxes)
	datum_reference.success_boxes = floor(datum_reference.max_boxes * success_box_percent_required)
	datum_reference.neutral_boxes = floor(datum_reference.max_boxes * neutral_box_percent_required)
	return TRUE

// After working, but before a possible qlipdrop: if we Repressed, chance to raise the qlip by 1. So a Neutral/Bad at Q1 can still be saved from breaching.
/mob/living/simple_animal/hostile/abnormality/spiral/WorkComplete(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		var/chance_to_qlipraise = repression_qlipraise_chance[user.get_attribute_text_level(get_modified_attribute_level(user, TEMPERANCE_ATTRIBUTE))] // Yes this is based on Temp, not Just. It's your ability to resist looking at it.
		if(prob(chance_to_qlipraise))
			datum_reference.qliphoth_change(1, user)
			to_chat(user, span_nicegreen("You avert your gaze from the Spiral and resist its almost magnetic pull. Its movements slow - you can only guess your actions have placated it."))
			playsound(get_turf(src), 'sound/abnormalities/spiral_contempt/spiral_mark.ogg', 80, 0, 2)
		else
			to_chat(user, span_warning("You avert your gaze from the Spiral. But even as you turn away, you can't help but feel like you're doing the wrong thing... you anxiously glance at it from the corner of your eye, and see that it is utterly unimpressed."))
	. = ..()

// After working, if we didn't Repress, increase the user's Awe. Starts at 1 and goes up to 5. It doesn't go away until Spiral breaches, dies or you work on a different abno.
/mob/living/simple_animal/hostile/abnormality/spiral/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	if(!(work_type == ABNORMALITY_WORK_REPRESSION))
		var/datum/status_effect/stacking/spiral_awe/awe = user.has_status_effect(STATUS_EFFECT_AWE)
		// Stacking status effects have this quirk where you've got to check to see if you already have it, if so, add a stack, otherwise, make a new one...
		if(awe)
			awe.add_stacks(1)
			to_chat(user, span_warning("Even though it's glowering at you with disdain, you can't take your eyes off of it..."))
		else
			user.apply_status_effect(STATUS_EFFECT_AWE, 0, datum_reference)
			awed_workers |= user
			to_chat(user, span_warning("As you finish your work, you can't help but meet its gaze. It glares right back at you."))
		playsound(get_turf(src), 'sound/abnormalities/spiral_contempt/spiral_whine.ogg', 80, 0, 2)

	return

// This literally only exists because I can't call the qlipchange in a signal because it eventually leads to sleep() in a few abnos.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/AweBroken(mob/living/carbon/human/user)
	awed_workers -= user // This needs to go first
	datum_reference.qliphoth_change(-1)

/* ------------------------------- Breach/Combat Code ------------------------------- */
/mob/living/simple_animal/hostile/abnormality/spiral/BreachEffect(mob/living/carbon/human/user, breach_type)
	for(var/mob/living/awestruck in awed_workers)
		awestruck.remove_status_effect(STATUS_EFFECT_AWE)
		awed_workers -= awestruck
	. = ..()
	Teleport() // Z-level safe

// No regular movement for Spiral. Being able to flee from it is part of the balance.
/mob/living/simple_animal/hostile/abnormality/spiral/Move(turf/newloc, dir, step_x, step_y)
	return FALSE

// Cleanup on death.
/mob/living/simple_animal/hostile/abnormality/spiral/death(gibbed)
	deltimer(teleport_timer)
	// Add up the lists that hold all people affected by our status effects, cleanse everyone in those lists and empty them out.
	var/list/affected_by_stuff = list()
	affected_by_stuff |= awed_workers
	affected_by_stuff |= gazed_fighters
	affected_by_stuff |= contempted_fighters
	for(var/mob/living/survivor in affected_by_stuff)
		survivor.remove_status_effect(STATUS_EFFECT_AWE)
		survivor.remove_status_effect(STATUS_EFFECT_GAZE)
		survivor.remove_status_effect(STATUS_EFFECT_CONTEMPT)
	awed_workers = list()
	gazed_fighters = list()
	contempted_fighters = list()
	// Cleanup any Shun mobs that may be left over.
	for(var/mob/living/simple_animal/spiral_shun/possible_shunners in shun_mobs)
		qdel(possible_shunners)
		shun_mobs -= possible_shunners

	shun_mobs = list()

	playsound(loc, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 50, 1)
	for(var/i in 1 to 5)
		var/atom/temp = new /obj/effect/temp_visual/dir_setting/bloodsplatter(loc, pick(GLOB.alldirs))
		temp.transform *= 1.5
	return ..()

/// Apply Gaze when hit in melee. Always give Gaze if being hit in the hands/arms, otherwise if it's a simplemob give Gaze randomly. Also, enrage if below X% HP.
/mob/living/simple_animal/hostile/abnormality/spiral/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()

	// Don't bother enraging or giving Gaze if we're staggered or teleporting.
	if(staggered || teleporting)
		return
	if(health < 0) // Yes this can happen
		return

	// Check to see if we should enrage.
	if(!enraged)
		if(health <= (maxHealth * enrage_hp_threshold))
			// Warn the players.
			var/warning_message = "[src] begins whirling with greater intensity."
			visible_message(span_userdanger(warning_message))
			for(var/mob/living/L in viewers(8, src))
				balloon_alert(L, warning_message)
			// Buff our abilities, primarily their frequency
			grip_cooldown_duration = (initial(grip_cooldown_duration) * enrage_grip_cd_coeff)
			grip_cooldown = min(world.time + 1 SECONDS, grip_cooldown) // Reset CD
			grip_iterations = (initial(grip_iterations) + enrage_grip_extra_iterations)
			rapid_melee = (initial(rapid_melee) * enrage_perforate_cd_speed_coeff)
			enraged = TRUE

	if(!(isliving(source)) || !(attack_type & ATTACK_TYPE_MELEE))
		return
	// If we were hit by a living source with a melee attack, and they don't have Contempt, give them Gaze.
	var/mob/living/attacker = source
	if(!(attacker.has_status_effect(STATUS_EFFECT_CONTEMPT)))
		// If aiming for hands/arms, always give Gaze. Otherwise, if the source is a simpleanimal, let them gain Gaze randomly.
		if((attacker.zone_selected in VALID_GAZE_GAIN_TARGET_ZONES) || (isanimal(attacker) && prob(50)))
			var/datum/status_effect/stacking/spiral_gaze/gaze = attacker.has_status_effect(STATUS_EFFECT_GAZE)
			if(gaze)
				gaze.add_stacks(1)
			else
				attacker.apply_status_effect(STATUS_EFFECT_GAZE, 0, src)
				gazed_fighters |= attacker

/// Reduce incoming damage. Lower this reduction if the attacker has Gaze, possibly making Spiral take extra damage instead. Doesn't activate for sourceless damage/when staggered.
/mob/living/simple_animal/hostile/abnormality/spiral/deal_damage(damage_amount, damage_type, source, flags, attack_type, blocked, def_zone, wound_bonus, bare_wound_bonus, sharpness)
	if(staggered) // If we're staggered we just take normal damage (with the staggered resistance coeffs)
		return ..()
	if(!isliving(source))
		return ..()
	var/mob/living/attacker = source
	var/inbound_damage_coeff = base_inbound_damage_coeff // Normally take 0.1x damage

	// Increase the 0.1x base damage coeff based on how many Gaze stacks the attacker has. Can go up to 1.3x damage received, if the attacker has 6 Gaze stacks (each is 0.2 additive as of writing)
	var/datum/status_effect/stacking/spiral_gaze/lets_take_a_gaze = attacker.has_status_effect(STATUS_EFFECT_GAZE)
	if(lets_take_a_gaze)
		inbound_damage_coeff += (lets_take_a_gaze.stacks * lets_take_a_gaze.spiral_inbound_damage_coeff_additive_per_gaze)

	damage_amount *= inbound_damage_coeff
	. = ..()

/// Teleport to a department center/xenospawn, if not staggered. Will never cross Z levels.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/Teleport()
	deltimer(teleport_timer)
	if(staggered)
		// Make Teleport fire after we're unstaggered.
		teleport_timer = addtimer(CALLBACK(src, PROC_REF(Teleport)), (stagger_unstagger_time - world.time + 1), TIMER_STOPPABLE)
		return

	teleporting = TRUE
	animate(src, 0.7 SECONDS, alpha = 0)
	var/list/department_centers = GLOB.department_centers.Copy()
	var/list/xenospawns = GLOB.xeno_spawn.Copy()
	var/list/possible_destinations = department_centers + xenospawns
	possible_destinations -= get_turf(src)
	if(!length(possible_destinations))
		warning("Spiral of Contempt has no valid teleport destinations. Did somebody nuke the department centers and xenospawn global lists?")
		alpha = initial(alpha)
		return
	var/turf/destination = pick(possible_destinations)
	SLEEP_CHECK_DEATH(0.7 SECONDS)

	if((stat < DEAD))
		teleport_timer = addtimer(CALLBACK(src, PROC_REF(Teleport)), teleport_cooldown_duration, TIMER_STOPPABLE)
		if(z == destination.z) // Z Level Check; only teleport when breaching on the same level as the facility.
			global_cooldown = world.time + global_cooldown_duration
			forceMove(destination)
		animate(src, 0.7 SECONDS, alpha = initial(alpha))

	teleporting = FALSE

/mob/living/simple_animal/hostile/abnormality/spiral/Life()
	. = ..()
	if(!(.) || status_flags & GODMODE || global_cooldown > world.time)
		return
	var/list/targets_found = AreaScan()
	if(TryUseInsidious(targets_found))
		return
	if(TryUseGrip(targets_found))
		return

/// Don't let Perforate go off if the GCD is rolling
/mob/living/simple_animal/hostile/abnormality/spiral/TryAttack()
	if(global_cooldown > world.time)
		return FALSE
	. = ..()

/// Returns how much damage we should actually deal to the target based on their gaze stacks.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/CalculateDamageFromGazeStacks(mob/living/victim, original_damage)
	if(!victim || !original_damage)
		return 0

	var/final_coeff = 1
	var/datum/status_effect/stacking/spiral_gaze/lets_take_a_gaze = victim.has_status_effect(STATUS_EFFECT_GAZE)
	if(lets_take_a_gaze)
		final_coeff += (lets_take_a_gaze.spiral_outgoing_damage_coeff_additive_per_gaze * lets_take_a_gaze.stacks)
	return (original_damage * final_coeff)

/// Checks the area Spiral is in, with no range limit, for targets, and returns a list of them. Will not target if they pass a faction check/they're dead.
/// Will also include the people in its sight radius, to avoid cheese from standing in an area boundary.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/AreaScan()
	var/area/where_am_i = get_area(src)
	var/list/targets_found = list()
	for(var/key, value in where_am_i.area_living)
		for(var/mob/living/victim in value)
			if(victim.z != src.z) // On second thought, maybe it SHOULD have a Z level check.
				continue
			if((victim.stat < DEAD) && !(faction_check_mob(victim))) // Skip corpses and friendlies
				// If they're working we won't target them out of courtesy
				if(ishuman(victim))
					var/mob/living/carbon/human/unfortunate = victim
					if(unfortunate.is_working)
						continue

				// Add valid targets to our list
				targets_found |= victim

	// In addition to people in our area, check for people in LoS
	for(var/mob/living/pretty_close_to_us in viewers(vision_range, src))
		if((pretty_close_to_us.stat < DEAD) && !(faction_check_mob(pretty_close_to_us))) // Skip corpses and friendlies
			// Even if you're working, if Spiral can LITERALLY SEE YOU you are getting added into the list
			targets_found |= pretty_close_to_us // |= avoids duplicates

	targets_found -= contempted_fighters // Don't target people who are trapped by It Shall Shun.

	return targets_found

/* --------- It Shall Perforate --------- */

/mob/living/simple_animal/hostile/abnormality/spiral/AttackingTarget(atom/attacked_target)
	if(staggered || global_cooldown > world.time)
		return FALSE

	// Increase the damage we should deal based on Gaze stacks on target.
	var/final_damage = CalculateDamageFromGazeStacks(attacked_target, rand(melee_damage_lower, melee_damage_upper))
	// Save these two values to restore them later
	var/old_lower = melee_damage_lower
	var/old_upper = melee_damage_upper
	// We already randomized the damage 4 lines ago
	melee_damage_lower = final_damage
	melee_damage_upper = final_damage

	. = ..()

	// Restore standard damage values
	melee_damage_lower = old_lower
	melee_damage_upper = old_upper

	if(!(.) || !(isliving(attacked_target)))
		return

	global_cooldown = world.time + (global_cooldown_duration * 1.5) // Longer GCD because this thing SLAPS
	var/mob/living/victim = attacked_target
	if(victim && victim.stat < DEAD)
		victim.apply_lc_bleed(perforate_bleed_stacks)

/* --------- It Shall Be Insidious --------- */

/// Try to use It Shall Be Insidious. If there are any targets, go on cooldown and call InsidiousCast with the targets found.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/TryUseInsidious(list/targets_found)
	if(staggered || insidious_cooldown > world.time || global_cooldown > world.time)
		return FALSE

	if(!targets_found || !length(targets_found))
		return FALSE

	insidious_cooldown = world.time + insidious_cooldown_duration
	global_cooldown = world.time + global_cooldown_duration
	INVOKE_ASYNC(src, PROC_REF(InsidiousCast), targets_found)
	return TRUE

/// Hit every mob in the list argument with It Shall Be Insidious.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/InsidiousCast(list/targets_found)
	icon_state = "spiral_cast"
	for(var/mob/living/target in targets_found)
		if(target in contempted_fighters) // Just in case
			continue
		target.deal_damage(CalculateDamageFromGazeStacks(target, insidious_damage), BLACK_DAMAGE, source = src, attack_type = (ATTACK_TYPE_SPECIAL))

		var/turf/target_turf = get_turf(target)
		playsound(target_turf, 'sound/abnormalities/spiral_contempt/spiral_bleed.ogg', 100, FALSE)
		new /obj/effect/temp_visual/contempt_blood(target_turf)

		SLEEP_CHECK_DEATH(rand(2, 5)) // Slight delay so it looks more natural
	icon_state = initial(icon_state)

/* --------- It Shall Grip --------- */

/// Try to use It Shall Grip. If there are any targets provided in the argument list, go on cooldown and call GripCast with the targets found.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/TryUseGrip(list/targets_found)
	if(staggered || grip_cooldown > world.time || global_cooldown > world.time)
		return FALSE

	if(!targets_found || !length(targets_found))
		return FALSE

	grip_cooldown = world.time + grip_cooldown_duration
	global_cooldown = world.time + global_cooldown_duration
	INVOKE_ASYNC(src, PROC_REF(GripCast), targets_found)
	return TRUE

/// Spawn a /temp_visual/spiral_grip on up to [grip_max_targets], repeat up to [grip_iterations] times.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/GripCast(list/targets_found)
	for(var/i in 1 to grip_iterations)
		icon_state = "spiral_cast"
		playsound(get_turf(src), 'sound/abnormalities/spiral_contempt/spiral_grow.ogg', 100, FALSE, 7)
		var/list/iteration_target_list = targets_found.Copy() // We copy it so we can use a different copy of the list for each iteration. This means that each person can only be targeted once per iteration, but multiple times per cast.
		for(var/j in 1 to grip_max_targets)
			if(length(iteration_target_list) < 1)
				break
			var/mob/living/target = pick_n_take(iteration_target_list)

			var/turf/target_turf = get_turf(target)

			new /obj/effect/temp_visual/spiral_grip(target_turf, grip_radius, grip_windup, src)
			SLEEP_CHECK_DEATH(rand(5, 8))
		icon_state = initial(icon_state)
		SLEEP_CHECK_DEATH(1.5 SECONDS)

/// Gets called by /temp_visual/spiral_grip when it resolves.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/GripHit(mob/living/target)
	if(!istype(target) || (target in contempted_fighters))
		return FALSE
	target.deal_damage(CalculateDamageFromGazeStacks(target, grip_damage), BLACK_DAMAGE, source = src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	target.visible_message(span_warning("[target] is hit by an emerging pair of hands!"), span_userdanger("You're hit by an emerging pair of hands!"))

/// Grip effect; gets passed arguments by Spiral's GripCast().
/obj/effect/temp_visual/spiral_grip
	name = "gripping hands"
	desc = "You shall be gripped."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "spiral_grip"
	pixel_x = -16
	base_pixel_x = -16
	randomdir = FALSE
	duration = 5 SECONDS
	layer = POINT_LAYER
	var/final_radius = 1
	var/final_windup = 1.2 SECONDS
	var/fadeout_time = 0.8 SECONDS
	var/list/affected_turfs = list()
	var/list/telegraph_vfx = list()
	var/mob/living/simple_animal/hostile/abnormality/spiral/caster
	var/image/cool_animation

/obj/effect/temp_visual/spiral_grip/Initialize(mapload, radius = 1, windup = 1.2 SECONDS, mob/living/simple_animal/hostile/abnormality/spiral/spiral_ref)
	. = ..()
	if(!istype(spiral_ref))
		qdel(src)
		return
	transform *= 0.8
	final_radius = radius
	final_windup = windup
	caster = spiral_ref
	Telegraph()

/// Warns players about the danger tiles, sets a timer to perform the attack based on windup.
/obj/effect/temp_visual/spiral_grip/proc/Telegraph()
	affected_turfs = RANGE_TURFS(final_radius, src)
	playsound(src, 'sound/weapons/fwoosh.ogg', 100, FALSE, 3)
	for(var/turf/T in affected_turfs)
		new /obj/effect/temp_visual/sparkles/spiral(T, final_windup)
	addtimer(CALLBACK(src, PROC_REF(Resolve)), final_windup)
	addtimer(CALLBACK(src, PROC_REF(PlayAnimation)), final_windup - 6) // 6 is a delay chosen based on the length of the animation

/obj/effect/temp_visual/spiral_grip/proc/PlayAnimation()
	src.alpha = 0
	cool_animation = image('ModularLobotomy/_Lobotomyicons/64x64.dmi', loc = loc, icon_state = "spiral_grip_animated", layer = layer + 2)
	cool_animation.transform = transform
	cool_animation.pixel_x = pixel_x
	cool_animation.pixel_y = pixel_y
	flick_overlay_view(cool_animation, src, 0.8 SECONDS)

/// Causes the damage and fades out the effect.
/obj/effect/temp_visual/spiral_grip/proc/Resolve()
	// Cleanup telegraphs
	for(var/atom/effect in telegraph_vfx)
		qdel(effect)
	QDEL_NULL(telegraph_vfx)

	playsound(get_turf(src), 'sound/abnormalities/so_that_no_cry/attack.ogg', 75)

	var/list/hitlist = list()
	for(var/turf/T in affected_turfs)
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/L in T)
			if(!(L in hitlist) && (L.stat < DEAD))
				hitlist |= L

				if(caster && istype(caster))
					if(caster.faction_check_mob(L)) // Yes I know this is a ridiculous level of nesting
						continue

				if(caster)
					caster.GripHit(L)

	// Cleanup
	deltimer(timerid)
	caster = null
	affected_turfs = null
	// Fade out
	animate(cool_animation, time = fadeout_time * 0.5, alpha = 255)
	animate(time = fadeout_time * 0.5, alpha = 0 )
	QDEL_IN(src, fadeout_time + 1)
	QDEL_IN(cool_animation, fadeout_time + 1)

// Telegraph sparkles with a customizable duration
/obj/effect/temp_visual/sparkles/spiral
	name = "grip telegraph"
	color = COLOR_RED
	duration = 1 SECONDS

/obj/effect/temp_visual/sparkles/spiral/Initialize(mapload, new_duration = 1 SECONDS)
	. = ..()
	deltimer(timerid)
	duration = new_duration
	timerid = QDEL_IN(src, duration)

/* --------- It Shall Shun --------- */

/// Called by the Shun mob we spawn. Check the Contempt status effect section for it.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/ShunHit(mob/living/victim)
	if(!istype(victim))
		return
	victim.deal_damage(CalculateDamageFromGazeStacks(victim, shun_damage), BLACK_DAMAGE, source = src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	victim.visible_message(span_warning("[victim] is brutally crushed by a pair of clasping hands!"), span_userdanger("You're crushed by a pair of clasping hands!"))

/// Called by Contempt status to stall Spiral's teleport until, at least, the status times out.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/ShunDelayTeleport(delay_time)
	var/time_to_teleport = timeleft(teleport_timer)
	if(time_to_teleport)
		deltimer(teleport_timer)
		teleport_timer = addtimer(CALLBACK(src, PROC_REF(Teleport)), (time_to_teleport + delay_time), TIMER_STOPPABLE)

// Don't worry about teleport, it will get delayed to until after the stagger is over.
/mob/living/simple_animal/hostile/abnormality/spiral/proc/Stagger()
	if(staggered)
		return
	staggered = TRUE
	ChangeResistances(stagger_resistances)
	var/mutable_appearance/colored_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "stagger", src.layer + 0.1)
	colored_overlay.pixel_x += 32
	add_overlay(colored_overlay)
	for(var/mob/living/simple_animal/spiral_shun/possible_extras in shun_mobs)
		qdel(possible_extras)
		shun_mobs -= possible_extras
	for(var/mob/living/carbon/human/witness in viewers(vision_range, src))
		balloon_alert(witness, "[src] is staggered!")

	stagger_unstagger_time = world.time + stagger_duration
	SLEEP_CHECK_DEATH(stagger_duration)

	var/list/old_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1.5) // For some reason I can't get initial() to work here
	ChangeResistances(old_coeff)
	staggered = FALSE
	cut_overlay(colored_overlay)

/* ------------------------------- Status Effects ------------------------------- */

/* --------- Awe (Work) --------- */
/// Awe stacking status effect. It does nothing, but works on Spiral will check for stacks of this and adjust PE boxes/work damage/work speed accordingly. Also if you work something else with Awe on,
/// Awe is cleared and Spiral qlipdrops.
/datum/status_effect/stacking/spiral_awe
	id = "spiral_awe"
	alert_type = /atom/movable/screen/alert/status_effect/spiral_awe
	stacks = 1
	max_stacks = 5
	stack_decay = 0
	duration = -1
	consumed_on_threshold = FALSE
	var/datum/abnormality/spiral_abno_datum

/atom/movable/screen/alert/status_effect/spiral_awe
	name = "Awe \[Spiral of Contempt\]"
	icon_state = "gaze"
	desc = "Now that you've set eyes on it, don't look away."

/datum/status_effect/stacking/spiral_awe/proc/BreakAwe(datum/source, datum/abnormality/datum_sent, mob/living/carbon/human/user, work_type)
	SIGNAL_HANDLER
	if(!istype(spiral_abno_datum))
		qdel(src)
		return FALSE
	if((datum_sent != spiral_abno_datum) && !(ispath(datum_sent.abno_path, /mob/living/simple_animal/hostile/abnormality/training_rabbit)))
		INVOKE_ASYNC(spiral_abno_datum.current, TYPE_PROC_REF(/mob/living/simple_animal/hostile/abnormality/spiral, AweBroken), user) // This is so annoying, apparently ZeroQliphoth sleeps so I can't use it in a signal
		to_chat(owner, span_danger("As you finish the work, you snap out of your fascination with the Spiral of Contempt."))
		to_chat(owner, span_phobia("If you were just going to cast a passing glance, you shouldn't have bothered to look in the first place."))
		playsound(get_turf(owner), 'sound/magic/clockwork/invoke_general.ogg', 50, FALSE, 5)
		qdel(src)

/datum/status_effect/stacking/spiral_awe/on_creation(mob/living/new_owner, stacks_to_apply, datum/abnormality/spiral_datum)
	if(istype(spiral_datum))
		spiral_abno_datum = spiral_datum
		if(!(spiral_abno_datum.current.status_flags & GODMODE)) // Breached???
			spiral_abno_datum = null
			qdel(src)
			return FALSE
		return ..()
	else
		qdel(src)
		return FALSE

/datum/status_effect/stacking/spiral_awe/on_apply()
	if(!ishuman(owner))
		return FALSE
	RegisterSignal(owner, COMSIG_WORK_COMPLETED, PROC_REF(BreakAwe))
	return TRUE

/datum/status_effect/stacking/spiral_awe/on_remove()
	UnregisterSignal(owner, COMSIG_WORK_COMPLETED)
	var/mob/living/simple_animal/hostile/abnormality/spiral/our_spiral = spiral_abno_datum.current
	if(!spiral_abno_datum || !our_spiral)
		return
	our_spiral.awed_workers -= owner
	spiral_abno_datum = null

/// Override to avoid decay
/datum/status_effect/stacking/spiral_awe/tick()
	if(!can_have_status())
		qdel(src)

/// Complete override of add_stacks to avoid some behaviour we don't want, also we stick a roman numeral to show how many stacks we have.
/datum/status_effect/stacking/spiral_awe/add_stacks(stacks_added)
	if(!stacks_added)
		return
	stacks = clamp((stacks + stacks_added), 1, max_stacks)
	linked_alert.name = initial(linked_alert.name)
	var/adding_to_name = " - "
	switch(stacks)
		if(1)
			adding_to_name += "I"
		if(2)
			adding_to_name += "II"
		if(3)
			adding_to_name += "III"
		if(4)
			adding_to_name += "IV"
		if(5)
			adding_to_name += "V"
		else
			adding_to_name += "???"

	linked_alert.name += adding_to_name

/* --------- Gaze (Combat) --------- */
/// Gaze stacking status effect. It allows you to deal some actual damage to the Spiral, and causes It Shall Shun to happen if you max it out. You will also take extra damage from Spiral.
/datum/status_effect/stacking/spiral_gaze
	id = "spiral_gaze"
	alert_type = /atom/movable/screen/alert/status_effect/spiral_gaze
	stacks = 1
	max_stacks = 7
	stack_decay = 0
	duration = 20 SECONDS
	stack_threshold = 7
	consumed_on_threshold = TRUE
	var/mob/living/simple_animal/hostile/abnormality/spiral/spiral_ref
	var/spiral_outgoing_damage_coeff_additive_per_gaze = 0.25 // At 6 stacks, Spiral deals 2.5x damage to you. A bad time. (Starts at 1x)
	var/spiral_inbound_damage_coeff_additive_per_gaze = 0.2 // At 6 stacks, Spiral takes up to 1.3x damage from you. (Starts at 0.1x)
	/// We wanna display an overlaid 10x10 icon on the target, status_effect/display has the framework for this but we're in the /stacking subtype...
	/// ...thus, we're making a dummy status effect just to display the overlay.
	var/datum/status_effect/display/attached_visual_status

/atom/movable/screen/alert/status_effect/spiral_gaze
	name = "Gaze \[Spiral of Contempt\]"
	icon_state = "gaze"
	desc = "The Spiral is glaring at you."

/datum/status_effect/stacking/spiral_gaze/on_creation(mob/living/new_owner, stacks_to_apply, mob/living/simple_animal/hostile/abnormality/spiral/spiral_mob)
	if(!istype(spiral_mob))
		qdel(src)
		return FALSE
	spiral_ref = spiral_mob
	. = ..()
	playsound(get_turf(owner), 'sound/abnormalities/silentgirl/Guilt_Apply.ogg', 25, 0, 2)
	// Set up the desc to explain what this status even does in case people didn't read the book.
	linked_alert.desc += " Taking [1 + (spiral_outgoing_damage_coeff_additive_per_gaze * stacks)]x damage from Spiral of Contempt, and dealing [0.1 + (spiral_inbound_damage_coeff_additive_per_gaze * stacks)]x damage to it (normal: 0.1x)."
	return

/datum/status_effect/stacking/spiral_gaze/on_remove()
	QDEL_NULL(attached_visual_status)
	if(!spiral_ref)
		return
	spiral_ref.gazed_fighters -= owner
	spiral_ref = null

/datum/status_effect/stacking/spiral_gaze/threshold_cross_effect()
	owner.apply_status_effect(STATUS_EFFECT_CONTEMPT, spiral_ref, spiral_ref.shun_windup, spiral_ref.shun_hands_hp, spiral_ref.shun_hands_resistances, spiral_ref.shun_radius)
	qdel(src)

/// Refresh the duration when gaining stacks, also adjust name and description to match the stack amount.
/datum/status_effect/stacking/spiral_gaze/add_stacks(stacks_added)
	if(!stacks_added)
		GenerateAttachedVisualStatus()
		return
	refresh()
	. = ..()
	GenerateAttachedVisualStatus()
	if(!linked_alert)
		return
	linked_alert.name = initial(linked_alert.name)
	linked_alert.desc = initial(linked_alert.desc)
	var/adding_to_name = " - "
	switch(stacks)
		if(1)
			adding_to_name += "I"
		if(2)
			adding_to_name += "II"
		if(3)
			adding_to_name += "III"
		if(4)
			adding_to_name += "IV"
		if(5)
			adding_to_name += "V"
		if(6)
			adding_to_name += "VI"
		else
			adding_to_name += "???"

	linked_alert.name += adding_to_name
	linked_alert.desc += " Taking [1 + (spiral_outgoing_damage_coeff_additive_per_gaze * stacks)]x damage from Spiral of Contempt, and dealing [0.1 + (spiral_inbound_damage_coeff_additive_per_gaze * stacks)]x damage to it (normal: 0.1x)."

/datum/status_effect/stacking/spiral_gaze/proc/GenerateAttachedVisualStatus()
	QDEL_NULL(attached_visual_status)
	if(owner)
		attached_visual_status = owner.apply_status_effect(/datum/status_effect/display/gaze_display, stacks)

/datum/status_effect/stacking/spiral_gaze/tick()
	if(!can_have_status())
		qdel(src)

/datum/status_effect/display/gaze_display
	id = "gaze_display_spiral"
	duration = -1
	display_icon = 'ModularLobotomy/_Lobotomyicons/status_icons_10x10.dmi'
	display_name = "gaze"
	alert_type = null

/datum/status_effect/display/gaze_display/on_creation(mob/living/new_owner, amount)
	if(isnum(amount) && (amount in 1 to 6))
		display_name += "_[amount]"
	. = ..()

/* --------- Contempt/It Shall Shun (Combat) --------- */
/// Contempt status effect. This spawns a clasped hands mob that must be defeated to pass the DPS check.
/datum/status_effect/display/spiral_contempt
	id = "spiral_contempt"
	alert_type = /atom/movable/screen/alert/status_effect/spiral_contempt
	duration = 10 SECONDS
	display_name = "contempt"
	var/mob/living/simple_animal/hostile/abnormality/spiral/spiral_ref // Passed on creation
	var/mob/living/simple_animal/spiral_shun/clasped_hands // We create this ourselves
	// These values have defaults but they are a failsafe. If you want to edit this status' stats or the mobs' stats then check Spiral's vars.
	var/clasped_duration = 6 SECONDS // We get passed a duration on creation
	var/clasped_hand_hp = 400 // We get passed HP on creation
	var/list/clasped_hand_resists = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1) // We get passed a resist list on creation
	var/clasped_attack_radius = 2 // We get passed an AOE radius on creation

/atom/movable/screen/alert/status_effect/spiral_contempt
	name = "Contempt \[Spiral of Contempt\]"
	icon_state = "weaken"
	desc = "You're nothing."

/datum/status_effect/display/spiral_contempt/on_apply()
	. = ..()
	if(!owner || !isliving(owner))
		return FALSE

/datum/status_effect/display/spiral_contempt/on_creation(mob/living/new_owner, mob/living/simple_animal/hostile/abnormality/spiral/spiral_abno, duration = 6.5 SECONDS, hand_hp = 400, hand_resists = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1), attack_radius = 2)
	if(!istype(spiral_abno) || !istype(new_owner) || !islist(hand_resists))
		qdel(src)
		return FALSE
	. = ..()
	// We need to update our vars with what we got passed on creation
	spiral_ref = spiral_abno
	spiral_ref.contempted_fighters |= owner
	clasped_duration = duration
	spiral_ref.ShunDelayTeleport(clasped_duration) // Stop Spiral from teleporting until this resolves
	clasped_hand_hp = hand_hp
	clasped_hand_resists = hand_resists
	clasped_attack_radius = attack_radius

	TrapVictim() // Immobilize our victim

	clasped_hands = new /mob/living/simple_animal/spiral_shun(get_turf(owner), src, owner) // Create the hands mob that must be killed to pass the DPS check. It will also serve to buckle the victim.
	clasped_hands.buckle_mob(owner, force = TRUE, check_loc = FALSE) // Buckle the victim so it becomes evident that you have to break them out.
	for(var/mob/living/carbon/human/witnesses in viewers(9, clasped_hands))
		clasped_hands.balloon_alert(witnesses, "A pair of blackened, bloody hands seize [owner]!")

/datum/status_effect/display/spiral_contempt/on_remove()
	. = ..()
	FreeVictim()
	clasped_hands = null
	spiral_ref = null

/// Called with TRUE when the hands are killed, called with FALSE if they time out. Not called at all if it's force deleted.
/datum/status_effect/display/spiral_contempt/proc/DPSCheckResult(passed = FALSE)
	if(passed && spiral_ref)
		INVOKE_ASYNC(spiral_ref, TYPE_PROC_REF(/mob/living/simple_animal/hostile/abnormality/spiral, Stagger))
		qdel(src)
		return

/// Don't let our victim move or do anything. They're at the mercy of their allies.
/datum/status_effect/display/spiral_contempt/proc/TrapVictim()
	var/mob/living/simple_animal/animal_owner = owner
	if(istype(animal_owner))
		animal_owner.toggle_ai(AI_OFF)
		walk(animal_owner, 0)
		animal_owner.Immobilize(clasped_duration, TRUE)
	else
		owner.Stun(clasped_duration, TRUE)

/// Let them go now.
/datum/status_effect/display/spiral_contempt/proc/FreeVictim()
	spiral_ref.contempted_fighters -= owner
	var/mob/living/simple_animal/animal_owner = owner
	if(istype(animal_owner))
		animal_owner.toggle_ai(AI_ON)
		walk(animal_owner, 0)
		animal_owner.remove_status_effect(STATUS_EFFECT_IMMOBILIZED)
	else
		owner.remove_status_effect(STATUS_EFFECT_STUN)

/// This is the hands mob that has to be killed
/mob/living/simple_animal/spiral_shun
	name = "clasping hands"
	desc = "You shall be shunned."
	icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
	icon_state = "spiral_grip"
	icon_dead = "spiral_grip"
	pixel_x = -16
	base_pixel_x = -16
	layer = POINT_LAYER
	del_on_death = FALSE
	// These three values are pulled from the status effect's vars, which in turn come from Spiral's vars.
	var/final_radius = 2
	var/final_windup = 0.5 SECONDS
	var/fadeout_time = 0.8 SECONDS

	var/list/affected_turfs = list()
	var/list/telegraph_vfx = list()
	var/datum/status_effect/display/spiral_contempt/contempt_status
	var/mob/living/victim
	var/failure_timer
	var/its_over = FALSE

	var/image/cool_animation


/mob/living/simple_animal/spiral_shun/Initialize(mapload, datum/status_effect/display/spiral_contempt/status, mob/living/target)
	. = ..()
	if(!istype(status) || !istype(target))
		qdel(src)
		return

	toggle_ai(AI_OFF)

	victim = target
	contempt_status = status
	faction = contempt_status.spiral_ref.faction.Copy()

	transform *= 1.3

	final_radius = contempt_status.clasped_attack_radius
	maxHealth = contempt_status.clasped_hand_hp
	health = contempt_status.clasped_hand_hp
	ChangeResistances(contempt_status.clasped_hand_resists)

	buckle_mob(victim, force = TRUE, check_loc = FALSE)
	failure_timer = addtimer(CALLBACK(src, PROC_REF(DPSCheckFailed)), contempt_status.clasped_duration, TIMER_STOPPABLE)

	src.add_filter("attack_this_thing_dummies", 3, list("type"="drop_shadow", "x"=0, "y"=0, "size" = 3, "offset" = 2, "color"= COLOR_RED, "name" = "attack_this_thing_dummies"))

/mob/living/simple_animal/spiral_shun/Move(atom/newloc, direct, glide_size_override)
	return FALSE

/mob/living/simple_animal/spiral_shun/Destroy(force)
	unbuckle_all_mobs(force = TRUE)
	QDEL_NULL(contempt_status)
	victim = null
	return ..()

/mob/living/simple_animal/spiral_shun/death(gibbed)
	deltimer(failure_timer)
	unbuckle_all_mobs(force = TRUE)
	if(!its_over)
		contempt_status.DPSCheckResult(TRUE)
	. = ..()
	animate(src, fadeout_time, alpha = 0)
	QDEL_IN(src, fadeout_time + 1)

/mob/living/simple_animal/spiral_shun/gib()
	if(its_over)
		return FALSE
	. = ..()

/mob/living/simple_animal/spiral_shun/proc/DPSCheckFailed()
	if(!contempt_status)
		return
	its_over = TRUE
	status_flags |= GODMODE
	contempt_status.DPSCheckResult(FALSE)
	Telegraph()

/// Called by the Contempt Status when it expires.
/mob/living/simple_animal/spiral_shun/proc/Telegraph()
	affected_turfs = RANGE_TURFS(final_radius, src)
	playsound(src, 'sound/weapons/fwoosh.ogg', 100, FALSE, 3)
	for(var/turf/T in affected_turfs)
		new /obj/effect/temp_visual/sparkles/spiral(T, final_windup)
	PlayAnimation()
	addtimer(CALLBACK(src, PROC_REF(Resolve)), final_windup)

/mob/living/simple_animal/spiral_shun/proc/PlayAnimation()
	src.alpha = 0
	cool_animation = image('ModularLobotomy/_Lobotomyicons/64x64.dmi', loc = loc, icon_state = "spiral_grip_animated", layer = layer + 2)
	cool_animation.transform = transform
	cool_animation.pixel_x = pixel_x
	cool_animation.pixel_y = pixel_y
	flick_overlay_view(cool_animation, src, 0.8 SECONDS)

/// Causes the damage and fades out the mob.
/mob/living/simple_animal/spiral_shun/proc/Resolve()
	// Cleanup telegraphs
	for(var/atom/effect in telegraph_vfx)
		qdel(effect)
	QDEL_NULL(telegraph_vfx)

	if(stat >= DEAD)
		return

	playsound(get_turf(src), 'sound/abnormalities/so_that_no_cry/attack.ogg', 75)

	var/list/hitlist = list()
	for(var/turf/T in affected_turfs)
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/L in T)
			if(!(L in hitlist) && (L.stat < DEAD))
				hitlist |= L

				if(istype(contempt_status) && istype(contempt_status.spiral_ref, /mob/living/simple_animal/hostile/abnormality/spiral))
					if(contempt_status.spiral_ref && !(contempt_status.spiral_ref.faction_check_mob(L))) // Yes I know this is a ridiculous level of nesting
						contempt_status.spiral_ref.ShunHit(L)

	if(!(victim in hitlist) && contempt_status && contempt_status.spiral_ref) // Main target may not actually have been picked up due to weirdness with buckling stuff?
		contempt_status.spiral_ref.ShunHit(victim)

	QDEL_NULL(contempt_status) // Also frees the victim
	affected_turfs = null
	// Fade out
	animate(cool_animation, time = fadeout_time * 0.5, alpha = 255)
	animate(time = fadeout_time * 0.5, alpha = 0)
	QDEL_IN(src, fadeout_time + 1)
	QDEL_IN(cool_animation, fadeout_time + 1)

#undef STATUS_EFFECT_GAZE
#undef STATUS_EFFECT_AWE
#undef STATUS_EFFECT_CONTEMPT
#undef VALID_GAZE_GAIN_TARGET_ZONES
