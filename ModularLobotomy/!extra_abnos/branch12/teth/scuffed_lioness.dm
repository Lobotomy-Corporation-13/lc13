// Scuffed Lioness - a standard, forgiving TETH beast built around wounded pride.
// Feed her and she settles; study her clinically and she reads it as pity.
/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness
	name = "Scuffed Lioness"
	desc = "A scrawny, grey-coated lioness baring her teeth in a wretched grin. Her front half still \
		prowls on solid legs, but her hindquarters are bare, drifting bone."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/48x48.dmi'
	icon_state = "lioness"
	icon_living = "lioness"
	icon_dead = "lioness_dead"
	pixel_x = -8
	base_pixel_x = -8
	del_on_death = FALSE
	faction = list("hostile")
	maxHealth = 1100
	health = 1100
	rapid_melee = 1
	melee_queue_distance = 2
	move_to_delay = 4
	// Pounce: she uses the AI's ranged tick to leap the gap (see OpenFire/Pounce).
	ranged = TRUE
	ranged_cooldown_time = 2 SECONDS
	damage_coeff = list(RED_DAMAGE = 1.1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	melee_damage_lower = 6
	melee_damage_upper = 10
	melee_damage_type = RED_DAMAGE
	attack_sound = 'sound/weapons/bladeslice.ogg'
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	friendly_verb_continuous = "nuzzles"
	friendly_verb_simple = "nuzzle"
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(65, 65, 60, 60, 55),
		ABNORMALITY_WORK_INSIGHT = list(55, 50, 45, 35, 25),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 50, 45, 45),
		ABNORMALITY_WORK_REPRESSION = list(45, 35, 25, 10, -20),
	)
	work_damage_amount = 5
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride
	ego_list = list(
		/datum/ego_datum/weapon/branch12/pelt,
		/datum/ego_datum/armor/branch12/pelt,
	)
	gift_type = /datum/ego_gifts/branch12/pelt
	death_message = "collapses with a final, ragged breath."
	speak_chance = 2
	emote_see = list("licks at an old wound...", "lets out a low, rattling growl...")
	wander = FALSE
	observation_prompt = "The scuffed lioness meets your eyes, too proud to look away. What will you do?"
	observation_choices = list(
		"Hold her gaze" = list(TRUE, "You neither flinch nor pity her. She accepts you as an equal, and marks you as one of her own."),
		"Look away" = list(FALSE, "Your eyes drop first. She reads it as pity, and turns from you with a wounded growl."),
	)

	being_tested = TRUE

	generic_bubbles = alist(
		1 = list("%PERSON works stiffly under %ABNO's unblinking stare.", "%PERSON tries to keep their nerve near the drifting bone."),
		2 = list("%PERSON works quickly under %ABNO's steady gaze.", "%PERSON keeps their face carefully blank."),
		3 = list("%PERSON meets %ABNO's eyes and does not look away.", "%PERSON holds their ground as %ABNO watches."),
		4 = list("%PERSON regards %ABNO the way one predator regards another.", "%PERSON works beside %ABNO without a trace of pity."),
		5 = list("%PERSON returns %ABNO's stare, unhurried and unafraid.", "%PERSON treats %ABNO as the equal she demands to be."),
	)
	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("%PERSON sets down meat and lets %ABNO take it first."),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON studies where %ABNO's hindquarters fade into bone."),
		ABNORMALITY_WORK_ATTACHMENT = list("%PERSON speaks to %ABNO as one proud thing to another."),
		ABNORMALITY_WORK_REPRESSION = list("%PERSON holds %ABNO's gaze, refusing to be first to look away."),
	)

	/// Timer gating her ambient work emotes.
	var/work_emote_cooldown = 0
	/// Current "wounded fury" tier (0 calm, 1 frantic, 2 cornered), driven by her own health.
	var/fury_stage = 0
	/// TRUE while mid-leap; blocks re-triggering the pounce.
	var/leaping = FALSE
	/// RED damage dealt to everyone adjacent when she lands a pounce.
	var/pounce_damage = 20

// Bad results wear down her patience directly, like the Forsaken Murderer.
/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/Worktick(mob/living/carbon/human/user, bubble_type = ABNO_BALLOON_GENERIC | ABNO_BALLOON_SPECIFIC, work_type)
	. = ..()
	if(client || work_emote_cooldown > world.time || !prob(35))
		return
	switch(roll(1, 6))
		if(1 to 3)
			emote(pick("growls", "twitches an ear"))
		if(4 to 5)
			to_chat(user, span_notice("She tenses, watching your hands with a predator's patience."))
		if(6)
			visible_message(span_warning("[src] bares her teeth in a silent, warning snarl!"))
	work_emote_cooldown = world.time + (25 SECONDS)

// On breach she becomes a mobile bleeder: her rakes shove, and she can pounce.
/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	AddComponent(/datum/component/knockback, 1, FALSE, TRUE)
	UpdateFury()

// Pounce - when a target slips out of melee range, she springs the gap along a
// straight line and rakes everything where she lands, knocking it back.
/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/OpenFire(atom/A)
	if(!A || !isliving(A) || (status_flags & GODMODE))
		return
	if(leaping || ranged_cooldown > world.time)
		return
	if(get_dist(A, src) > 2)
		Pounce(A)

/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/proc/Pounce(atom/target)
	leaping = TRUE
	setDir(get_dir(src, target))
	update_icon()
	ranged_cooldown = world.time + ranged_cooldown_time
	visible_message(span_danger("[src] coils low, then springs at [target]!"))
	playsound(get_turf(src), 'sound/effects/ordeals/gold/growl1.ogg', 60, TRUE, 4)
	for(var/turf/leap_turf in getline(src, target))
		if(leap_turf.is_blocked_turf(exclude_mobs = TRUE))
			break
		forceMove(leap_turf)
		SLEEP_CHECK_DEATH(1)
	// Landing rake: claw everyone adjacent and shove them away from her.
	for(var/mob/living/carbon/human/H in orange(1, src))
		H.deal_damage(pounce_damage, RED_DAMAGE, src, attack_type = ATTACK_TYPE_MELEE)
		H.safe_throw_at(get_edge_target_turf(H, get_dir(src, H)), 2, 3, src)
	leaping = FALSE
	update_icon()

/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/Life()
	. = ..()
	if(!.)
		return
	UpdateFury()

// Wounded Queen: the more hurt she is, the faster and more vicious she fights.
/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/proc/UpdateFury()
	if(status_flags & GODMODE) // Still contained.
		return
	var/ratio = health / maxHealth
	var/new_stage = 0
	if(ratio <= 0.25)
		new_stage = 2
	else if(ratio <= 0.5)
		new_stage = 1
	if(new_stage == fury_stage)
		return
	fury_stage = new_stage
	switch(fury_stage)
		if(0)
			rapid_melee = 1
			move_to_delay = 4
		if(1)
			rapid_melee = 2
			move_to_delay = 3
			visible_message(span_danger("[src]'s movements turn frantic and vicious!"))
		if(2)
			rapid_melee = 3
			move_to_delay = 2
			visible_message(span_userdanger("Cornered and bleeding, [src] fights like a beast possessed!"))
	UpdateSpeed()
	update_icon()

/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/abnormality/branch12/scuffed_lioness/update_icon_state()
	if(stat == DEAD)
		icon_state = "lioness_dead"
	else if(leaping)
		icon_state = fury_stage ? "lioness_leap[fury_stage]" : "lioness_leap"
	else
		icon_state = fury_stage ? "lioness_scar[fury_stage]" : "lioness"
