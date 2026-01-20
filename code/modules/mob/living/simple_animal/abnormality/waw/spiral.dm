/* Spiral of Contempt
We're currently missing a sprite for it, I might make one myself

----------- Work Mechs -----------
--- Basics ---
> Qlipcounter of 4
> Good Instinct and Insight, horrible Attachment, alright Repression.
> Repression has a 50% chance to raise Qlip by 1.
> Qlipdrop on Bad, Qlipdrop chance on Neutral.
--- Special ---
> Every non-Repression work done by an agent on Spiral without working on another Abnormality gives you an Awe stack, which
increases the PE box amount and work damage dealt for Spiral of Contempt. You can get up to 5 Awe stacks.

> Working on another Abno with Awe on you will cause Spiral to qlipdrop, and remove Awe.

Note: In the context of Spiral, 'Repression' means refusing to face it, not meeting its gaze. Refer to the MD event 'Avert your Eyes' option.

----------- Breach Mechs -----------
--- Basics ---
> Teleports to a department center. Cannot move. Will teleport to another department center every 40 seconds. Maybe also let it go to xenospawns?
> Obnoxiously high resistances (0.1 or 0.2).
> Hitting it while having your zone target set to arms/hands will cause you to gain a stack of Gaze.
Gaze will lower the damage resistance that Spiral has against you (todo: check Pianist code?).
--- Attacks ---
> It Shall Be Insidious: Will periodically attack everyone in the same area as it with an unavoidable blood rain, dealing BLACK damage.
> It Shall Grip: Will periodically try to attack up to 2 people in the same area as it with gripping fists, dealing wind-up telegraphed AoE BLACK damage.
> It Shall Perforate: Can melee attack with a long cooldown and a reach of 3, dealing RED damage and inflicting bleed (todo: check the "allowed limbus status" quota).
> It Shall Shun/Contempt: If you reach 7 Gaze, you will be trapped and incapacitated by clasped hands.
They have X amount of health. If they are destroyed in Y seconds, Spiral gets staggered, which makes it lose all its resistances for a while and be unable to act or escape;
if the hands remain alive, the hands close with a huge AOE. (You need allies to destroy these.)

----------- EGO -----------
--- Weapons ---
> Contempt, Awe: WAW - The current javelin. I might slightly update it
> Perversion: ALEPH - A rankbump weapon concept. The weapon used in the N. Corp EGO; some sort of spear/lance that works as a sheathe for a katana.
I think another dev wanted to design it, but if they don't wanna I also have ideas for it.
--- Armour ---
> Contempt, Awe: WAW - We don't have sprites for this. If I don't see some pop up soon I'll make a codersprite.
I'm feeling [strong BLACK/PALE, weak RED/WHITE] or [strong RED/BLACK, weak WHITE/PALE] but unsure for now.
*/

#define STATUS_EFFECT_GAZE /datum/status_effect/stacking/spiral_gaze
#define STATUS_EFFECT_AWE /datum/status_effect/stacking/spiral_awe
#define STATUS_EFFECT_CONTEMPT /datum/status_effect/spiral_contempt

/// This thing gives you a lot of PE, has good work rates, trains three stats, and has a rankbump weapon, so it must be WAW+ in breach difficulty.
/mob/living/simple_animal/hostile/abnormality/spiral
	name = "Spiral of Contempt"
	threat_level = WAW_LEVEL
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS
	desc = "An imposing and beautiful spiral of gold. \n\
	The upper half is vaguely shaped like a human torso with both arms outstretched towards the sky and sharp 'wings' protruding from the back. \
	Black hands drip with blood, and its 'head' glowers down at you."
	portrait = "heaven"
	being_tested = TRUE // !! REMOVE BEFORE MERGE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	/* --- Appearance --- */
	icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
	icon_state = "heaven"
	icon_living = "heaven"
	pixel_x = -32
	base_pixel_x = -32

	/* --- Defense --- */
	// Should be obscenely tanky. You will need some Gaze if you don't want this fight to turn into a slog meatgrinder
	maxHealth = 4000
	health = 4000
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.4)

	/* --- Work --- */
	// It is intended for Spiral to be hard to please and Awe makes it even harder, but it will always give you a good chunk of PE.
	max_boxes = 22
	var/boxes_per_awe = 3
	var/success_box_percent_required = 0.8
	var/neutral_box_percent_required = 0.6

	start_qliphoth = 4
	neutral_droprate = 50 // You are going to be getting a lot of neutrals
	bad_droprate = 100
	var/repression_qlipraise_chance = 50

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(15, 20, 25, 40, 50),
		ABNORMALITY_WORK_INSIGHT = list(15, 25, 30, 45, 50),
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = list(10, 15, 20, 35, 40),
	)
	work_damage_amount = 10 // Wow! Only 10 damage for a WAW+ abnormality? That's so generous!
	var/work_damage_per_awe_stack = 3 // :stare: (This can actually be so much worse than an ALEPH if you let it stack)
	var/work_delay_reduction_per_awe_stack = 1.1 // Positive: player doesn't need to experience the tedium of works with more boxes than ALEPH abnos. Negative: no time for medipens to save you.
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride
	ego_list = list(
		/datum/ego_datum/weapon/contempt,
		/datum/ego_datum/armor/heaven,
	)
	//gift_type = /datum/ego_gifts/spiral

	/* --- Breach --- */
	can_breach = TRUE
	can_patrol = FALSE

	/* --- Teleport --- */
	var/teleport_timer
	var/teleport_cooldown_duration = 40 SECONDS

	/* --- Autoattack (It Shall Perforate) --- */
	var/perforate_bleed_stacks = 5
	var/perforate_damage = 60

	/* --- Periodic Damage (It Shall Be Insidious) --- */
	var/insidious_damage = 35
	var/insidious_cooldown
	var/insidious_cooldown_duration = 13 SECONDS

	/* --- Periodic Telegraphed AoEs (It Shall Grip) --- */
	var/grip_damage = 90
	var/grip_radius = 1
	var/grip_max_targets = 2
	var/grip_cooldown
	var/grip_cooldown_duration = 9 SECONDS

	/* --- Contempt Punish/Stagger Opportunity (It Shall Shun) --- */
	var/shun_damage = 250
	var/shun_radius = 2
	var/shun_hands_type
	// Balance these three variables to ensure that it's a DPS check that can barely be met by 1 WAW agent using the right damage types.
	var/shun_hands_hp = 750
	var/shun_hands_resistances = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.1, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.5)
	var/shun_windup = 6 SECONDS // 750/6 requires 125 true DPS to kill. This is doable for WAW weapons if factoring in Justice.

	/* --- Stagger (Reward for resolving It Shall Shun) --- */
	var/stagger_duration = 8 SECONDS
	var/stagger_resistances = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 1.5)

/mob/living/simple_animal/hostile/abnormality/spiral/Move(turf/newloc, dir, step_x, step_y)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/spiral/SpeedWorktickOverride(mob/living/carbon/human/user, work_speed, init_work_speed, work_type)
	. = ..()
	var/datum/status_effect/stacking/spiral_awe/awe = user.has_status_effect(STATUS_EFFECT_AWE)
	if(awe)
		return init_work_speed -= (awe.stacks * work_delay_reduction_per_awe_stack)

/mob/living/simple_animal/hostile/abnormality/spiral/AttemptWork(mob/living/carbon/human/user, work_type)
	work_damage_amount = initial(work_damage_amount)
	var/datum/status_effect/stacking/spiral_awe/awe = user.has_status_effect(STATUS_EFFECT_AWE)
	if(awe)
		say("You have Awe. [awe.stacks] stacks raise the work damage from [work_damage_amount] to [work_damage_amount + (work_damage_per_awe_stack * awe.stacks)].")
		say("Also raising PE boxes from [max_boxes] to [max_boxes + (boxes_per_awe * awe.stacks)]")
		work_damage_amount += (awe.stacks * work_damage_per_awe_stack)
		datum_reference.max_boxes = initial(max_boxes) + (awe.stacks * boxes_per_awe)
		datum_reference.success_boxes = floor(datum_reference.max_boxes * success_box_percent_required)
		datum_reference.neutral_boxes = floor(datum_reference.max_boxes * neutral_box_percent_required)
		say("Success boxes required: [datum_reference.success_boxes]")
		say("Neutral boxes required: [datum_reference.neutral_boxes]")
		return TRUE
	datum_reference.max_boxes = initial(max_boxes)
	datum_reference.success_boxes = floor(datum_reference.max_boxes * success_box_percent_required)
	datum_reference.neutral_boxes = floor(datum_reference.max_boxes * neutral_box_percent_required)
	say("You don't have Awe. Damage is [work_damage_amount], Max Boxes are [datum_reference.max_boxes], Success Boxes are [datum_reference.success_boxes], Neutral Boxes are [datum_reference.neutral_boxes].")
	return TRUE

/mob/living/simple_animal/hostile/abnormality/spiral/WorkComplete(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	if(work_type == ABNORMALITY_WORK_REPRESSION)
		if(prob(repression_qlipraise_chance))
			datum_reference.qliphoth_change(1, user)
			to_chat(user, span_notice("You avert your gaze from the Spiral. Its movements slow - you can only guess your actions have placated it."))
			playsound(get_turf(src), 'sound/abnormalities/spiral_contempt/spiral_mark.ogg', 60, 0, 2)
		else
			to_chat(user, span_warning("You avert your gaze from the Spiral. But even as you turn away, you can't help but feel like you're doing the wrong thing..."))
	. = ..()


/mob/living/simple_animal/hostile/abnormality/spiral/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	if(!(work_type == ABNORMALITY_WORK_REPRESSION))
		var/datum/status_effect/stacking/spiral_awe/awe = user.has_status_effect(STATUS_EFFECT_AWE)
		// Stacking status effects have this quirk where you've got to check to see if you already have it, if so, add a stack, otherwise, make a new one...
		if(awe)
			awe.add_stacks(1)
			to_chat(user, span_warning("Even though it's glowering at you with disdain, you can't take your eyes off of it..."))
		else
			user.apply_status_effect(STATUS_EFFECT_AWE)
			to_chat(user, span_warning("As you finish your work, you can't help but meet its gaze. It glares right back at you."))
		playsound(get_turf(src), 'sound/abnormalities/spiral_contempt/spiral_whine.ogg', 60, 0, 2)

	return

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
	var/mutable_appearance/gaze_icon
	var/datum/abnormality/spiral_abno_datum
	var/additive_personal_shred_per_stack = 0.1 // Spiral's resists go down to 0.8/0.8/0.8/0.9 at 6 stacks
	var/extra_damage_coeff_per_stack = 0.25 // Up to 2.5x damage taken from Spiral at 6 stacks

/datum/status_effect/stacking/spiral_gaze/on_creation(mob/living/new_owner, datum/abnormality/spiral_datum)
	gaze_icon = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "guilt", -MUTATIONS_LAYER)
	spiral_abno_datum = spiral_datum
	. = ..()
	playsound(get_turf(owner), 'sound/abnormalities/silentgirl/Guilt_Apply.ogg', 50, 0, 2)
	owner.add_overlay(gaze_icon)
	linked_alert.desc += "[additive_personal_shred_per_stack * stacks], and you are taking [1 + (extra_damage_coeff_per_stack * stacks)]x damage from it."
	return

/datum/status_effect/stacking/spiral_gaze/on_remove()
	owner.cut_overlay(gaze_icon)
	. = ..()

/datum/status_effect/stacking/spiral_gaze/threshold_cross_effect()
	. = ..()
	spiral_abno_datum.current?.say("Threshold on Gaze reached, clearing and casting It Shall Shun.")
	qdel(src)

/datum/status_effect/stacking/spiral_gaze/add_stacks(stacks_added)
	refresh()
	. = ..()

/datum/status_effect/stacking/spiral_gaze/tick()
	if(!can_have_status())
		qdel(src)

/atom/movable/screen/alert/status_effect/spiral_gaze
	name = "Gaze \[Spiral of Contempt\]"
	icon_state = "gaze"
	desc = "The Spiral is glaring at you. Spiral of Contempt's resistances are weakened additively by "

/// Awe stacking status effect. It does nothing, but works on Spiral will check for stacks of this and adjust PE boxes/work damage accordingly. Also if you work something else with Awe on,
/// Awe is cleared and Spiral qlipdrops.
/datum/status_effect/stacking/spiral_awe
	id = "spiral_awe"
	alert_type = /atom/movable/screen/alert/status_effect/spiral_awe
	stacks = 1
	max_stacks = 5
	stack_decay = 0
	duration = -1
	consumed_on_threshold = FALSE

/datum/status_effect/stacking/spiral_awe/tick()
	if(!can_have_status())
		qdel(src)

/datum/status_effect/stacking/spiral_awe/add_stacks(stacks_added)
	. = ..()
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

/atom/movable/screen/alert/status_effect/spiral_awe
	name = "Awe \[Spiral of Contempt\]"
	icon_state = "gaze"
	desc = "Now that you've set eyes on it, don't look away."

#undef STATUS_EFFECT_GAZE
#undef STATUS_EFFECT_AWE
#undef STATUS_EFFECT_CONTEMPT
