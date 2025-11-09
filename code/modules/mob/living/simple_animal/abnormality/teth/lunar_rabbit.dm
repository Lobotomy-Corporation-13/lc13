//Very simple, funny little guy.
#define STATUS_EFFECT_LUNAR_FLOW /datum/status_effect/lunar_flow
/mob/living/simple_animal/hostile/abnormality/lunar_rabbit
	name = "Lunar Physician"
	desc = "A little rabbit girl in a nurse outfit."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "lunar_rabbit"
	icon_living = "lunar_rabbit"
	del_on_death = TRUE
	maxHealth = 300	//She's a fast motherfucker.
	health = 300
	rapid_melee = 2
	move_to_delay = 1.2
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 2		//Varies a lot.
	melee_damage_upper = 25
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cut"
	attack_sound = 'sound/abnormalities/cleave.ogg'
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 1

	ranged = 1
	retreat_distance = 3
	minimum_distance = 1
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = 30,
		ABNORMALITY_WORK_REPRESSION = 60,
	)
	work_damage_amount = 5
	work_damage_type = BLACK_DAMAGE

	attack_action_types = list(/datum/action/innate/abnormality_attack/lunar_dust)

	var/lunar_dust_cooldown = 0
	var/lunar_dust_cooldown_time = 10 SECONDS

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	to_chat(src, "<h1>You are Lunar Physician, A Support Role Abnormality.</h1><br>\
		<b>|Melee Attacks|: Your attacks deal BLACK damage and apply various toxic effects.<br>\
		Enemies you strike will suffer from space drugs, confusion, blindness, or other debilitating status effects.<br>\
		These toxic effects cannot be healed easily, making you a dangerous debuffer in close combat.<br>\
		<br>\
		|Lunar Dust|: You have an ability to buff nearby abnormalities.<br>\
		When activated, you will channel for 2 seconds, showing warning overlays on adjacent tiles.<br>\
		If you complete the channel, all abnormalities within 1 tile will receive the Lunar Flow buff.<br>\
		<br>\
		|Lunar Flow Effect|: Buffed abnormalities will:<br>\
		- Move significantly faster for 8 seconds<br>\
		- Turn dark blue and see the world with a light blue tint<br>\
		- Become more fragile, taking 30% more damage<br>\
		<br>\
		Use this ability strategically to help your fellow abnormalities in combat, but be careful - the fragile effect makes them more vulnerable!</b>")

	ego_list = list(
		/datum/ego_datum/weapon/patch,
		/datum/ego_datum/armor/patch
	)
	gift_message = "your prescription is in, let's make sure you don't ever forget to take it."
	gift_type =  /datum/ego_gifts/acupuncture
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	generic_bubbles = alist(
		1 = list("%ABNO watches you from the corner of her eye."),
		2 = list("%ABNO skips around the cell."),
		3 = list("%ABNO is flicking the tip of her syringe to remove air bubbles."),
		4 = list("%ABNO is munching on a little bit of mochi."),
		5 = list("%PERSON seems very willing to take the medicine."),
	)
	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("%ABNO starts mortaring ingredients."),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON cleans up some used needles.", "%PERSON restocks some ingredients in the cell"),
		ABNORMALITY_WORK_ATTACHMENT = list("%ABNO tugs on your sleeve.", "%ABNO hands you a little handmade mochi.",
				"$%ABNO places a bandage on %PERSON's arm.", "%ABNO appreciates your gestures of kindness"),
		ABNORMALITY_WORK_REPRESSION = list("%ABNO swats at %PERSON with a pawed hand.", "%ABNO tries to bite %PERSON's arm."),
	)


/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/Initialize(atom/attacked_target)
	.=..()
	var/breachtime = 5 MINUTES + rand(1, 10 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(BreachMe)), breachtime)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/proc/BreachMe(atom/attacked_target)
	datum_reference.qliphoth_change(-99)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/AttackingTarget(atom/attacked_target)
	. = ..()
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/L = attacked_target

		//Give it the same effects as space drugs
		L.set_drugginess(25)
		if(prob(20))
			L.emote(pick("twitch","drool","moan","giggle"))
		L.apply_lc_fragile(2)

		//Also get a random between Blind, Confusion, Mute and drowsy, and none.
		var/effect_choice = rand(1,4)
		switch(effect_choice)
			if(1)
				L.set_confusion(10)
			if(2)
				L.silent = 100
			if(3)
				L.adjust_blindness(5)
			if(4)
				return

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	..()
	say("The doctor is in. Please, show me your arm.")
	SLEEP_CHECK_DEATH(10)
	to_chat(user, span_notice("You feel a tiny prick."))
	SLEEP_CHECK_DEATH(10)
	say("There you are! All better.")

	//Always give you drugs but like it's funny
	user.set_drugginess(15)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	..()
	user.client?.give_award(/datum/award/achievement/abno/drugging, user)
	user.adjustBruteLoss(-40)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	..()
	user.deal_damage(45, BLACK_DAMAGE, flags = (DAMAGE_FORCED))

// Player control actions
/datum/action/innate/abnormality_attack/lunar_dust
	name = "Lunar Dust"
	button_icon_state = "wrath_dash"
	chosen_attack_num = 1

/datum/action/innate/abnormality_attack/lunar_dust/Activate()
	if(!isliving(owner))
		return
	var/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/L = owner
	if(!istype(L))
		return

	// Check cooldown
	if(L.lunar_dust_cooldown > world.time)
		to_chat(L, span_warning("Lunar Dust is on cooldown! ([round((L.lunar_dust_cooldown - world.time) / 10, 0.1)]s remaining)"))
		return

	// Show warning overlays on adjacent tiles
	var/list/affected_turfs = list()
	for(var/turf/T in range(1, L))
		if(T == get_turf(L))
			continue
		T.add_overlay(icon('icons/effects/effects.dmi', "galaxy_aura"))
		affected_turfs += T

	to_chat(L, span_notice("You begin gathering lunar dust..."))

	// Do the 2 second wait
	if(!do_after(L, 2 SECONDS, L))
		// Failed, remove overlays
		for(var/turf/T in affected_turfs)
			T.cut_overlay(icon('icons/effects/effects.dmi', "galaxy_aura"))
		to_chat(L, span_warning("You were interrupted!"))
		return

	// Remove overlays
	for(var/turf/T in affected_turfs)
		T.cut_overlay(icon('icons/effects/effects.dmi', "galaxy_aura"))

	// Apply effect to adjacent abnormalities
	var/affected_count = 0
	for(var/mob/living/simple_animal/hostile/abnormality/A in range(1, L))
		if(A == L)
			continue
		if(istype(A, /mob/living/simple_animal/hostile/abnormality/cleaner))
			continue
		A.apply_status_effect(STATUS_EFFECT_LUNAR_FLOW)
		affected_count++

	if(affected_count > 0)
		L.visible_message(span_notice("[L] releases a shower of lunar dust!"))
		to_chat(L, span_nicegreen("You buffed [affected_count] abnormalit[affected_count == 1 ? "y" : "ies"]!"))
		L.lunar_dust_cooldown = world.time + L.lunar_dust_cooldown_time
	else
		to_chat(L, span_warning("There are no abnormalities nearby to buff!"))

// Lunar Flow status effect
/datum/movespeed_modifier/lunar_flow
	multiplicative_slowdown = -2.5

#define MOB_LUNAR_FLOW /datum/movespeed_modifier/lunar_flow
/datum/status_effect/lunar_flow
	id = "lunar flow"
	duration = 8 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH
	var/statuseffectvisual
	var/client/C
	var/initial_color
	var/initial_mob_color

/datum/status_effect/lunar_flow/on_apply()
	. = ..()

	// Add speed boost
	owner.add_movespeed_modifier(MOB_LUNAR_FLOW)

	// Apply fragile
	if(isliving(owner))
		var/mob/living/L = owner
		L.apply_lc_fragile(3)

	// Save original colors and change to dark blue
	initial_mob_color = owner.color
	owner.color = "#0000aa" // Dark blue

	// Change client vision to light blue if they have a client
	if(ismob(owner))
		var/mob/M = owner
		if(M.client)
			C = M.client
			initial_color = C.color
			C.color = "#aaccffff" // Light blue

	// Add visual overlay
	var/mutable_appearance/effectvisual = mutable_appearance('icons/obj/clockwork_objects.dmi', "vanguard")
	effectvisual.color = "#0066ff" // Blue-ish overlay
	effectvisual.pixel_x = -owner.pixel_x
	effectvisual.pixel_y = -owner.pixel_y
	statuseffectvisual = effectvisual
	owner.add_overlay(statuseffectvisual)

/datum/status_effect/lunar_flow/on_remove()
	// Remove speed modifier
	owner.remove_movespeed_modifier(MOB_LUNAR_FLOW)

	// Restore mob color
	owner.color = initial_mob_color

	// Restore client vision color
	if(C)
		C.color = initial_color

	// Remove overlay
	owner.cut_overlay(statuseffectvisual)

	return ..()

#undef STATUS_EFFECT_LUNAR_FLOW
#undef MOB_LUNAR_FLOW


