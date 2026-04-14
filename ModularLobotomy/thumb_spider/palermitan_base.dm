/// Palermitan Apprentice Base Component
/// Grants the "Duello" and "Palermitan Style" base passives.
/// Also handles nursefather interactions (drinks, glass bottles, post-duel correction).
/// Attached to the apprentice mob on recruitment.
/datum/component/palermitan_apprentice
	/// Reference to the nursefather mentor
	var/mob/living/nursefather_ref
	/// How many times the nursefather has corrected the apprentice after a duel loss
	var/correction_count = 0
	/// Whether the apprentice is currently eligible for a post-duel correction
	var/correction_eligible = FALSE
	/// world.time deadline for correction eligibility
	var/correction_deadline = 0
	/// Attribute gain that would be granted by a correction (0.25x of the lost duel's win value)
	var/potential_correction_attrs = 0
	/// world.time of last drink EXP grant (2 min cooldown)
	var/last_drink_exp_time = 0
	/// world.time of last glass bottle EXP grant (30 sec cooldown)
	var/last_glass_exp_time = 0
	/// Tremor burst threshold — INFINITY by default (no bursting). Set by Terremoto T2 skills.
	var/tremor_burst_threshold = INFINITY
	/// world.time of last food offering EXP grant (2 min cooldown)
	var/last_food_exp_time = 0
	/// world.time of last bow emote EXP grant (2 min cooldown)
	var/last_bow_exp_time = 0
	/// world.time of last daily training EXP grant (3 min cooldown)
	var/last_training_exp_time = 0

/datum/component/palermitan_apprentice/Initialize(mob/living/_nursefather)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	if(_nursefather)
		nursefather_ref = _nursefather

/datum/component/palermitan_apprentice/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))
	RegisterSignal(parent, COMSIG_ATOM_HITBY, PROC_REF(on_hitby))
	RegisterSignal(parent, COMSIG_PARENT_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(parent, COMSIG_MOB_EMOTE, PROC_REF(on_emote))

/datum/component/palermitan_apprentice/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_ATOM_HITBY,
		COMSIG_PARENT_ATTACKBY,
		COMSIG_MOB_EMOTE,
	))

////////////////////////////////////////////////////////////
// DUELLO + PALERMITAN STYLE (base passives)

/// Core attack handler — applies Duello and Palermitan Style passives + food offering check
/datum/component/palermitan_apprentice/proc/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(!isliving(target) || target == user)
		return

	// === SHARING A MEAL: Offering food to nursefather grants EXP ===
	if(weapon && is_nursefather(target) && istype(weapon, /obj/item/reagent_containers/food))
		if(world.time >= last_food_exp_time + 2 MINUTES)
			last_food_exp_time = world.time
			var/datum/component/palermitan_exp/exp_comp = user.GetComponent(/datum/component/palermitan_exp)
			if(exp_comp)
				exp_comp.modify_exp(3)
			to_chat(user, span_notice("You offer a meal to your mentor. (+3 EXP)"))

	// === DUELLO: Inflict 1 Duel Escalates on target ===
	target.apply_duel_escalates(1, user)

	// === DUELLO: Heal sanity if target has Duel Escalates ===
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	if(D && D.stacks > 0 && ishuman(user))
		var/sanity_heal = min(D.stacks * 3, 15)
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(-sanity_heal)

	// === PALERMITAN STYLE: Bonus damage based on Duel Escalates stacks ===
	if(D && D.stacks > 0 && weapon)
		var/stacks = D.stacks
		var/percent_bonus = stacks * 0.02
		var/force_bonus = round(weapon.force * percent_bonus)
		if(stacks >= 10)
			force_bonus += 10
		else if(stacks >= 5)
			force_bonus += 5
		if(force_bonus > 0)
			weapon.force += force_bonus
			INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, force_bonus)

/// Restores the temporary force bonus after a brief delay
/datum/component/palermitan_apprentice/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus

////////////////////////////////////////////////////////////
// EXP FROM EMOTES AND TRAINING

/// Showing Respect: Bow emote near higher-ranked players grants EXP
/datum/component/palermitan_apprentice/proc/on_emote(datum/source, emote_key)
	SIGNAL_HANDLER
	if(emote_key != "bow" && emote_key != "salute")
		return
	if(world.time < last_bow_exp_time + 2 MINUTES)
		return
	var/mob/living/carbon/human/apprentice = parent
	if(!istype(apprentice))
		return
	// Check for nearby players with higher average attributes
	for(var/mob/living/carbon/human/H in view(3, get_turf(apprentice)))
		if(H == apprentice)
			continue
		if(!H.client)
			continue
		// Check if they have higher avg attributes or are the nursefather
		var/target_higher = is_nursefather(H)
		if(!target_higher)
			var/app_avg = 0
			var/target_avg = 0
			for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
				var/datum/attribute/A1 = apprentice.attributes[attr_name]
				var/datum/attribute/A2 = H.attributes[attr_name]
				if(A1)
					app_avg += A1.level
				if(A2)
					target_avg += A2.level
			target_higher = (target_avg > app_avg)
		if(target_higher)
			last_bow_exp_time = world.time
			var/datum/component/palermitan_exp/exp_comp = apprentice.GetComponent(/datum/component/palermitan_exp)
			if(exp_comp)
				exp_comp.modify_exp(3)
			to_chat(apprentice, span_notice("You show respect to your betters. (+3 EXP)"))
			return

////////////////////////////////////////////////////////////
// NURSEFATHER INTERACTIONS

/// Helper to check if a mob is the nursefather
/datum/component/palermitan_apprentice/proc/is_nursefather(mob/living/M)
	if(nursefather_ref && M == nursefather_ref)
		return TRUE
	// Fallback: check assigned role
	if(M?.mind?.assigned_role == "Ex Thumb Sottocapo")
		return TRUE
	return FALSE

/// Thrown item impact — check for glass bottle from nursefather
/datum/component/palermitan_apprentice/proc/on_hitby(datum/source, atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!istype(AM, /obj/item/reagent_containers/food/drinks))
		return
	var/obj/item/reagent_containers/food/drinks/D = AM
	if(!D.isGlass)
		return
	if(!throwingdatum?.thrower || !is_nursefather(throwingdatum.thrower))
		return
	// Cooldown check
	if(world.time < last_glass_exp_time + 30 SECONDS)
		return
	last_glass_exp_time = world.time
	// Grant EXP
	var/mob/living/carbon/human/apprentice = parent
	var/datum/component/palermitan_exp/exp_comp = apprentice.GetComponent(/datum/component/palermitan_exp)
	if(exp_comp)
		exp_comp.modify_exp(3)
	to_chat(apprentice, span_notice("The glass shattering against you sharpens your resolve. (+3 EXP)"))

/// Melee attack on the apprentice — check for nursefather unarmed correction OR glass bottle hit
/datum/component/palermitan_apprentice/proc/on_attackby(datum/source, obj/item/W, mob/living/user, params)
	SIGNAL_HANDLER
	// Check for glass bottle melee hit from nursefather
	if(istype(W, /obj/item/reagent_containers/food/drinks))
		var/obj/item/reagent_containers/food/drinks/D = W
		if(D.isGlass && is_nursefather(user))
			if(world.time >= last_glass_exp_time + 30 SECONDS)
				last_glass_exp_time = world.time
				var/mob/living/carbon/human/apprentice = parent
				var/datum/component/palermitan_exp/exp_comp = apprentice.GetComponent(/datum/component/palermitan_exp)
				if(exp_comp)
					exp_comp.modify_exp(3)
				to_chat(apprentice, span_notice("The bottle impact sharpens your resolve. (+3 EXP)"))
	// Daily Training: nursefather hits apprentice with a weapon — grants EXP
	if(W && is_nursefather(user))
		if(world.time >= last_training_exp_time + 3 MINUTES)
			last_training_exp_time = world.time
			var/mob/living/carbon/human/apprentice = parent
			var/datum/component/palermitan_exp/exp_comp = apprentice.GetComponent(/datum/component/palermitan_exp)
			if(exp_comp)
				exp_comp.modify_exp(2)
			to_chat(apprentice, span_notice("Your mentor's training strike sharpens your resolve. (+2 EXP)"))
	// Check for nursefather unarmed correction
	if(!W && is_nursefather(user))
		// Unarmed attack from nursefather — check correction eligibility
		if(correction_eligible && world.time < correction_deadline)
			INVOKE_ASYNC(src, PROC_REF(perform_correction), user)

/// Grants drink-sharing EXP. Called externally (from debug kit or give/take signal).
/datum/component/palermitan_apprentice/proc/grant_drink_exp()
	if(world.time < last_drink_exp_time + 2 MINUTES)
		var/mob/living/apprentice = parent
		to_chat(apprentice, span_warning("You've shared a drink too recently. (Cooldown: 2 minutes)"))
		return FALSE
	last_drink_exp_time = world.time
	var/mob/living/carbon/human/apprentice = parent
	var/datum/component/palermitan_exp/exp_comp = apprentice.GetComponent(/datum/component/palermitan_exp)
	if(exp_comp)
		exp_comp.modify_exp(5)
	to_chat(apprentice, span_notice("Offering a drink to your mentor strengthens your bond. (+5 EXP)"))
	return TRUE

////////////////////////////////////////////////////////////
// POST-DUEL CORRECTION

/// Performs the nursefather correction animation and grants rewards
/datum/component/palermitan_apprentice/proc/perform_correction(mob/living/nursefather)
	var/mob/living/carbon/human/apprentice = parent
	if(!istype(apprentice) || QDELETED(apprentice) || QDELETED(nursefather))
		return

	correction_eligible = FALSE

	// Calculate animation tier (upgrades every 2 corrections)
	var/anim_tier = clamp(round(correction_count / 2) + 1, 1, 5)
	var/list/damage_percents = list(0.05, 0.10, 0.20, 0.30, 0.50)
	var/damage = apprentice.health * damage_percents[anim_tier]

	switch(anim_tier)
		if(1)
			nursefather.visible_message(
				span_warning("[nursefather] lightly slaps [apprentice]."),
				span_warning("You correct [apprentice] with a light slap."))
			playsound(apprentice, 'sound/weapons/punch1.ogg', 25)
			nursefather.do_attack_animation(apprentice)
			apprentice.deal_damage(damage, RED_DAMAGE, nursefather)
		if(2)
			nursefather.visible_message(
				span_warning("[nursefather] backhands [apprentice] across the face."),
				span_warning("You backhand [apprentice]."))
			playsound(apprentice, 'sound/weapons/punch2.ogg', 35)
			nursefather.do_attack_animation(apprentice)
			animate(apprentice, pixel_x = apprentice.base_pixel_x + 4, time = 1)
			animate(pixel_x = apprentice.base_pixel_x, time = 2)
			apprentice.deal_damage(damage, RED_DAMAGE, nursefather)
		if(3)
			// Cutscene: 2-hit combo
			var/combo_duration = 1.5 SECONDS
			nursefather.Immobilize(combo_duration)
			nursefather.changeNext_move(combo_duration)
			apprentice.Immobilize(combo_duration)
			apprentice.AddComponent(/datum/component/cutscene_duel, nursefather)
			nursefather.face_atom(apprentice)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch3.ogg', 45)
			animate(apprentice, pixel_x = apprentice.base_pixel_x + 8, time = 1)
			apprentice.deal_damage(damage * 0.5, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			sleep(0.4 SECONDS)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch4.ogg', 50)
			animate(apprentice, pixel_x = apprentice.base_pixel_x - 6, time = 1)
			apprentice.deal_damage(damage * 0.5, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			shake_camera(apprentice, 1, 2)
			sleep(0.4 SECONDS)

			animate(apprentice, pixel_x = apprentice.base_pixel_x, pixel_y = apprentice.base_pixel_y, time = 2)
			qdel(apprentice.GetComponent(/datum/component/cutscene_duel))

			nursefather.visible_message(
				span_danger("[nursefather] strikes [apprentice] twice in quick succession."),
				span_danger("You discipline [apprentice] with two hard strikes."))
		if(4)
			// Cutscene: 3-hit combo
			var/combo_duration = 2.5 SECONDS
			nursefather.Immobilize(combo_duration)
			nursefather.changeNext_move(combo_duration)
			apprentice.Immobilize(combo_duration)
			apprentice.AddComponent(/datum/component/cutscene_duel, nursefather)
			nursefather.face_atom(apprentice)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch3.ogg', 50)
			animate(apprentice, pixel_y = apprentice.base_pixel_y - 4, pixel_x = apprentice.base_pixel_x + 2, time = 1)
			apprentice.deal_damage(damage * 0.33, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			sleep(0.5 SECONDS)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch4.ogg', 55)
			animate(apprentice, pixel_y = apprentice.base_pixel_y + 6, pixel_x = apprentice.base_pixel_x - 4, time = 1)
			apprentice.deal_damage(damage * 0.33, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			shake_camera(apprentice, 2, 2)
			sleep(0.5 SECONDS)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch4.ogg', 65)
			animate(apprentice, pixel_y = apprentice.base_pixel_y - 8, pixel_x = apprentice.base_pixel_x, time = 1)
			apprentice.deal_damage(damage * 0.34, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			shake_camera(apprentice, 3, 3)
			apprentice.Knockdown(10)
			sleep(0.5 SECONDS)

			animate(apprentice, pixel_x = apprentice.base_pixel_x, pixel_y = apprentice.base_pixel_y, time = 3)
			qdel(apprentice.GetComponent(/datum/component/cutscene_duel))

			nursefather.visible_message(
				span_danger("[nursefather] beats [apprentice] with a brutal three-hit combination."),
				span_danger("You beat some sense into [apprentice]."))
		if(5)
			// Cutscene: 5-hit full beating
			var/combo_duration = 4 SECONDS
			nursefather.Immobilize(combo_duration)
			nursefather.changeNext_move(combo_duration)
			apprentice.Immobilize(combo_duration)
			apprentice.AddComponent(/datum/component/cutscene_duel, nursefather)
			nursefather.face_atom(apprentice)

			var/hit_damage = damage / 5

			playsound(apprentice, 'sound/weapons/thudswoosh.ogg', 40)
			animate(apprentice, pixel_x = apprentice.base_pixel_x + 10, time = 1)
			sleep(0.3 SECONDS)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch3.ogg', 55)
			animate(apprentice, pixel_y = apprentice.base_pixel_y - 6, pixel_x = apprentice.base_pixel_x + 4, time = 1)
			apprentice.deal_damage(hit_damage, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			sleep(0.4 SECONDS)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch4.ogg', 60)
			animate(apprentice, pixel_x = apprentice.base_pixel_x - 10, pixel_y = apprentice.base_pixel_y, time = 1)
			apprentice.deal_damage(hit_damage, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			shake_camera(apprentice, 2, 3)
			sleep(0.4 SECONDS)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch4.ogg', 65)
			animate(apprentice, pixel_y = apprentice.base_pixel_y - 10, pixel_x = apprentice.base_pixel_x - 2, time = 1)
			apprentice.deal_damage(hit_damage, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			shake_camera(apprentice, 3, 3)
			sleep(0.5 SECONDS)

			nursefather.do_attack_animation(apprentice)
			playsound(apprentice, 'sound/weapons/punch4.ogg', 75)
			animate(apprentice, pixel_y = apprentice.base_pixel_y - 14, pixel_x = apprentice.base_pixel_x, time = 1)
			apprentice.deal_damage(hit_damage * 2, RED_DAMAGE, nursefather, DAMAGE_FORCED)
			shake_camera(apprentice, 4, 4)
			apprentice.Knockdown(20)
			sleep(0.6 SECONDS)

			animate(apprentice, pixel_x = apprentice.base_pixel_x, pixel_y = apprentice.base_pixel_y, time = 5, easing = QUAD_EASING)
			qdel(apprentice.GetComponent(/datum/component/cutscene_duel))

			nursefather.visible_message(
				span_userdanger("[nursefather] gives [apprentice] a thorough, brutal beating."),
				span_userdanger("You give [apprentice] the correction they deserve."))

	// Grant correction rewards
	correction_count++
	if(potential_correction_attrs > 0)
		for(var/attr_name in list(FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE))
			var/datum/attribute/A = apprentice.attributes[attr_name]
			if(A)
				A.level = min(200, A.level + potential_correction_attrs)
				A.on_update(apprentice)
		to_chat(apprentice, span_notice("The correction grants you [potential_correction_attrs] to each attribute."))
		potential_correction_attrs = 0

	// Grant EXP
	var/datum/component/palermitan_exp/exp_comp = apprentice.GetComponent(/datum/component/palermitan_exp)
	if(exp_comp)
		exp_comp.modify_exp(5)

	// Check gear tier-up
	check_gear_tierup(apprentice)
