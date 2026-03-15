// ============================================================
// Dieci Association Weapons — Section 4
// ============================================================
// Two weapon types: Fists (defensive, shield HP) and Keys (offensive, OLU).
// Both share the same combo system with knowledge-powered finishers.
// L attacks: WHITE damage (no sinking trigger) + 2 Sinking.
// H attacks: Empower via attack_self (consume knowledge) → PALE damage (50% reduced) + weapon bonus.
// 6 combo finishers consume specific knowledge types for scaled effects.

// ============================================================
// Base Weapon — Dieci Fists
// ============================================================

/// Dieci Association combat gloves. Defensive weapon granting shield HP on empowerment.
/obj/item/ego_weapon/city/dieci
	name = "dieci combat gloves"
	icon_state = "dieci_glove"
	inhand_icon_state = "yun_fist"
	desc = "Heavy gauntlets issued to Dieci Association members. The reinforced plating channels accumulated knowledge into a protective barrier around the wearer."
	special = "Defensive weapon. Light attacks deal WHITE damage + Sinking. Use in hand to empower (knowledge) for PALE heavy attacks. Empowering grants shield HP (level x15)."
	force = 20
	damtype = WHITE_DAMAGE
	extra_damage_flags = DAMAGE_NO_SINKING
	attack_speed = 0.7
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	hitsound = 'sound/weapons/ego/dieci_fist_attack.ogg'
	/// Current combo chain position (1-5)
	var/chain = 0
	/// Whether the next attack is empowered (H attack)
	var/activated = FALSE
	/// Level of the consumed knowledge used for empowerment (1-5)
	var/empowered_level = 0
	/// Free empowers granted by skills (used instead of consuming knowledge)
	var/free_empowers = 0
	/// World.time when combo chain expires
	var/combo_time = 0
	/// Deciseconds before combo resets
	var/combo_wait = 50
	/// Whether a multi-hit finisher sequence is in progress
	var/in_sequence = FALSE

/obj/item/ego_weapon/city/dieci/examine(mob/user)
	. = ..()
	. += span_notice("Light attacks deal WHITE damage + Sinking. Use in hand to empower (knowledge) for PALE heavy attacks.")
	. += span_notice("H - Quick Strike (Behavioral): Sinking burst")
	. += span_notice("LH - Sweeping Blow (Medical): Throw + Sinking")
	. += span_notice("LLH - Pressure Combo (Behavioral): Grab + beatdown + DLD")
	. += span_notice("LLLH - Overwhelming Barrage (Medical): Rapid hits + Sinking")
	. += span_notice("LLLLL - Measured Finisher (Spiritual): Amplify Sinking")
	. += span_notice("LLLLH - Grand Finale (Spiritual): Throw + AoE shockwave")

/// Retrieve the user's knowledge component for knowledge operations.
/obj/item/ego_weapon/city/dieci/proc/get_knowledge_comp(mob/living/user)
	return user.GetComponent(/datum/component/dieci_knowledge)

// ============================================================
// Empowerment System
// ============================================================

/// Empower next attack by consuming knowledge or using free empowers.
/obj/item/ego_weapon/city/dieci/attack_self(mob/living/carbon/user)
	if(activated)
		activated = FALSE
		empowered_level = 0
		to_chat(user, span_danger("You lower your stance."))
		return
	// Try free empowers first
	if(free_empowers > 0)
		free_empowers--
		activated = TRUE
		empowered_level = 3
		to_chat(user, span_nicegreen("You empower your next attack! (free empower)"))
		return
	// Consume knowledge (lowest qualifying entry at L3+)
	var/datum/component/dieci_knowledge/kc = get_knowledge_comp(user)
	if(!kc)
		to_chat(user, span_warning("You lack the knowledge to empower your attacks."))
		return
	var/list/consumed = kc.consume_lowest_knowledge(1, 1)
	if(!length(consumed))
		to_chat(user, span_warning("No knowledge available to empower."))
		return
	var/list/entry = consumed[1]
	empowered_level = entry["level"]
	activated = TRUE
	to_chat(user, span_nicegreen("You consume [entry["type"]] L[empowered_level] to empower your next attack!"))

/// Apply the weapon-specific empowerment bonus. Fists grant shield HP.
/obj/item/ego_weapon/city/dieci/proc/apply_empower_bonus(mob/living/user)
	var/datum/component/dieci_shield_hp/shield = user.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield)
		shield = user.AddComponent(/datum/component/dieci_shield_hp)
	shield.add_shield(empowered_level * 15)

// ============================================================
// Main Attack Handler
// ============================================================

/obj/item/ego_weapon/city/dieci/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	// During multi-hit finisher sequences, just do base damage
	if(in_sequence)
		. = ..()
		return
	// Reset chain on timeout
	if(world.time > combo_time)
		chain = 0
	combo_time = world.time + combo_wait
	chain++
	attack_speed = initial(attack_speed)
	force = initial(force)
	if(activated)
		force = round(force * 0.5)

	var/is_heavy = activated

	// Instant kill: empowered H attacks kill insane (0 SP) carbon targets
	if(is_heavy && ishuman(target))
		var/mob/living/carbon/human/HT = target
		if(HT.sanity_lost)
			HT.death()

	// Set damage type: H = PALE (can trigger sinking), L = WHITE (no sinking trigger)
	if(is_heavy)
		damtype = PALE_DAMAGE
		extra_damage_flags = 0
	else
		damtype = WHITE_DAMAGE
		extra_damage_flags = DAMAGE_NO_SINKING

	// Check for finisher at current chain position
	var/finisher_handled = FALSE
	switch(chain)
		if(1)
			if(is_heavy)
				finisher_handled = quick_strike(target, user)
		if(2)
			if(is_heavy)
				finisher_handled = sweeping_blow(target, user)
		if(3)
			if(is_heavy)
				finisher_handled = pressure_combo(target, user)
		if(4)
			if(is_heavy)
				finisher_handled = overwhelming_barrage(target, user)
		if(5)
			if(!is_heavy)
				finisher_handled = measured_finisher(target, user)
			else
				finisher_handled = grand_finale(target, user)

	// No finisher — normal attack
	if(!finisher_handled)
		if(is_heavy)
			hitsound = 'sound/weapons/fixer/generic/finisher2.ogg'
		. = ..()
		// Post-hit effects
		if(!QDELETED(target))
			if(!is_heavy)
				target.apply_lc_sinking(2)
		if(is_heavy)
			apply_empower_bonus(user)

	// Reset after finisher or heavy attack
	if(finisher_handled || is_heavy)
		chain = 0
	if(is_heavy)
		activated = FALSE
		empowered_level = 0
	// Restore defaults
	if(!in_sequence)
		force = initial(force)
		damtype = initial(damtype)
		extra_damage_flags = initial(extra_damage_flags)
	hitsound = initial(hitsound)

// ============================================================
// Combo Finishers
// ============================================================

/// H — Quick Strike: force x1.3 PALE hit. Behavioral knowledge bonus: level x3 Sinking.
/obj/item/ego_weapon/city/dieci/proc/quick_strike(mob/living/target, mob/living/user)
	// Base hit always happens
	hitsound = 'sound/weapons/fixer/generic/finisher2.ogg'
	force = round(force * 1.3)
	damtype = PALE_DAMAGE
	in_sequence = TRUE
	attack(target, user)
	in_sequence = FALSE
	force = initial(force)
	apply_empower_bonus(user)
	// Bonus: consume Behavioral knowledge for Sinking burst
	var/datum/component/dieci_knowledge/kc = get_knowledge_comp(user)
	var/list/consumed = kc?.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL)
	if(consumed && !QDELETED(target))
		var/level = consumed["level"]
		target.apply_lc_sinking(level * 3)
		to_chat(user, span_danger("Quick Strike! [level * 3] Sinking!"))
	return TRUE

/// LH — Sweeping Blow: force x1.2 PALE hit. Medical knowledge bonus: throw + Sinking.
/obj/item/ego_weapon/city/dieci/proc/sweeping_blow(mob/living/target, mob/living/user)
	// Base hit always happens
	hitsound = 'sound/weapons/fixer/generic/finisher2.ogg'
	force = round(force * 1.2)
	damtype = PALE_DAMAGE
	in_sequence = TRUE
	attack(target, user)
	in_sequence = FALSE
	force = initial(force)
	apply_empower_bonus(user)
	// Bonus: consume Medical knowledge for throw + Sinking
	var/datum/component/dieci_knowledge/kc = get_knowledge_comp(user)
	var/list/consumed = kc?.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_MEDICAL)
	if(consumed && !QDELETED(target))
		var/level = consumed["level"]
		target.apply_lc_sinking(level * 2)
		if(!target.anchored)
			var/throw_dist = 2 + level
			var/atom/throw_target = get_edge_target_turf(target, user.dir)
			target.throw_at(throw_target, throw_dist, 4, user, gentle = TRUE)
		to_chat(user, span_danger("Sweeping Blow! Thrown [2 + level] tiles!"))
	return TRUE

/// LLH — Pressure Combo: force x1.3 PALE hit. Behavioral knowledge bonus: Sinking + DLD.
/obj/item/ego_weapon/city/dieci/proc/pressure_combo(mob/living/target, mob/living/user)
	// Base hit always happens
	hitsound = 'sound/weapons/fixer/generic/finisher2.ogg'
	force = round(force * 1.3)
	damtype = PALE_DAMAGE
	in_sequence = TRUE
	attack(target, user)
	in_sequence = FALSE
	force = initial(force)
	apply_empower_bonus(user)
	// Bonus: consume Behavioral knowledge for Sinking + DLD
	var/datum/component/dieci_knowledge/kc = get_knowledge_comp(user)
	var/list/consumed = kc?.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL)
	if(consumed && !QDELETED(target))
		var/level = consumed["level"]
		target.apply_lc_sinking(level * 2)
		target.apply_lc_defense_level_down(level)
		to_chat(user, span_danger("Pressure Combo! [level * 2] Sinking + [level] DLD!"))
	return TRUE

/// LLLH — Overwhelming Barrage: level*5 rapid hits at force x0.08, 1 Sinking each. Requires Medical knowledge.
/obj/item/ego_weapon/city/dieci/proc/overwhelming_barrage(mob/living/target, mob/living/user)
	// This finisher requires Medical knowledge to determine hit count
	var/datum/component/dieci_knowledge/kc = get_knowledge_comp(user)
	var/list/consumed = kc?.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_MEDICAL)
	if(!consumed)
		// No knowledge — single base hit at force x1 (fallback)
		hitsound = 'sound/weapons/fixer/generic/finisher2.ogg'
		damtype = PALE_DAMAGE
		in_sequence = TRUE
		attack(target, user)
		in_sequence = FALSE
		force = initial(force)
		apply_empower_bonus(user)
		return TRUE
	var/level = consumed["level"]
	var/hits = level * 5
	var/immobilize_time = hits + 5
	target.Immobilize(immobilize_time)
	user.Immobilize(immobilize_time)
	force = round(force * 0.08)
	damtype = WHITE_DAMAGE
	extra_damage_flags = DAMAGE_NO_SINKING
	in_sequence = TRUE
	for(var/i in 1 to hits)
		if(QDELETED(target) || QDELETED(user))
			break
		attack(target, user)
		if(!QDELETED(target))
			target.apply_lc_sinking(1)
		sleep(0.5)
	in_sequence = FALSE
	force = initial(force)
	apply_empower_bonus(user)
	to_chat(user, span_danger("Overwhelming Barrage! [hits] hits!"))
	return TRUE

/// LLLLL — Measured Finisher: force x1.5 PALE hit. Spiritual knowledge bonus: amplify target Sinking.
/obj/item/ego_weapon/city/dieci/proc/measured_finisher(mob/living/target, mob/living/user)
	// Base hit always happens
	hitsound = 'sound/weapons/fixer/generic/finisher2.ogg'
	damtype = PALE_DAMAGE
	force = round(force * 1.5)
	in_sequence = TRUE
	attack(target, user)
	in_sequence = FALSE
	force = initial(force)
	// Bonus: consume Spiritual knowledge for Sinking amplification
	var/datum/component/dieci_knowledge/kc = get_knowledge_comp(user)
	var/list/consumed = kc?.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_SPIRITUAL)
	if(consumed && !QDELETED(target))
		var/level = consumed["level"]
		var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
		var/current_stacks = S ? S.stacks : 0
		var/bonus_sinking = min(round(current_stacks * 0.1 * level), 50)
		if(bonus_sinking > 0)
			target.apply_lc_sinking(bonus_sinking)
		to_chat(user, span_danger("Measured Finisher! +[bonus_sinking] Sinking!"))
	return TRUE

/// LLLLH — Grand Finale: force x1.5 PALE hit. Spiritual knowledge bonus: throw + PALE shockwave.
/obj/item/ego_weapon/city/dieci/proc/grand_finale(mob/living/target, mob/living/user)
	// Base hit always happens
	hitsound = 'sound/weapons/fixer/generic/finisher2.ogg'
	target.Immobilize(25)
	user.Immobilize(25)
	force = round(force * 1.5)
	damtype = PALE_DAMAGE
	in_sequence = TRUE
	attack(target, user)
	in_sequence = FALSE
	force = initial(force)
	apply_empower_bonus(user)
	// Bonus: consume Spiritual knowledge for throw + shockwave
	var/datum/component/dieci_knowledge/kc = get_knowledge_comp(user)
	var/list/consumed = kc?.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_SPIRITUAL)
	if(consumed && !QDELETED(target))
		var/level = consumed["level"]
		// Throw target
		var/throw_dist = 3 + level
		if(!target.anchored)
			var/atom/throw_target = get_edge_target_turf(target, user.dir)
			target.throw_at(throw_target, throw_dist, 4, user)
		sleep(3)
		// PALE shockwave around impact point: level x8 damage + level x3 Sinking
		var/shockwave_radius = 1 + level
		var/shockwave_damage = level * 8
		for(var/mob/living/L in range(shockwave_radius, get_turf(target)))
			if(L == user || L.stat == DEAD)
				continue
			L.deal_damage(shockwave_damage, PALE_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
			L.apply_lc_sinking(level * 3)
		to_chat(user, span_danger("Grand Finale! Shockwave radius [shockwave_radius]!"))
	return TRUE

// ============================================================
// Fist Weapon Tiers
// ============================================================

/// Veteran-tier Dieci fists. Higher force for experienced members.
/obj/item/ego_weapon/city/dieci/vet
	name = "dieci veteran gloves"
	desc = "Reinforced gauntlets worn by veteran members of Dieci Association. The extra plating generates a stronger barrier on empowerment."
	force = 28
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

/// Director-tier Dieci fists. The finest martial weapons for the section leader.
/obj/item/ego_weapon/city/dieci/director
	name = "dieci director fists"
	desc = "Ornate golden gauntlets worn by the Director of Dieci Association. They radiate an unmistakable authority."
	force = 38
	attack_speed = 0.6
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)

// ============================================================
// Key Weapons — Offensive Subtype
// ============================================================
// Keys start small (pocketable/wearable on neck). Use in hand or
// alt-click to deploy them to full combat size. Retract to store again.

/// Dieci Association ceremonial key. Offensive weapon granting OLU on empowerment.
/// Starts retracted — small enough for pockets and neck. Deploy to fight.
/obj/item/ego_weapon/city/dieci/key
	name = "dieci ceremonial key"
	desc = "A ceremonial key carried by Dieci Association members. Its intricate engravings hum with latent energy, sharpening the wielder's focus when activated."
	special = "Offensive weapon. Shares the same combo system as fists, but empowering grants Offense Level Up (level x2) instead of shield HP. Use in hand to deploy for combat."
	icon = 'icons/obj/clothing/ego_gear/dieci_icon.dmi'
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/dieci_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/dieci_right.dmi'
	icon_state = "dieci_key"
	inhand_icon_state = "dieci_key_small"
	worn_icon = 'ModularLobotomy/_Lobotomyicons/dieci_worn.dmi'
	worn_icon_state = "dieci_key"
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	force = 26
	attack_speed = 0.9
	hitsound = 'sound/weapons/ego/dieci_key_attack.ogg'
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_NECK | ITEM_SLOT_POCKETS
	/// Whether the key is deployed to full combat size
	var/deployed = FALSE
	/// Icon state used when deployed
	var/deployed_icon = "dieci_key"

/obj/item/ego_weapon/city/dieci/key/examine(mob/user)
	. = ..()
	if(!deployed)
		. += span_notice("It is currently retracted. Use in hand or alt-click to deploy it for combat.")
	else
		. += span_notice("It is deployed for combat. Alt-click to retract it.")

/// Use in hand: deploy if retracted, empower if deployed.
/obj/item/ego_weapon/city/dieci/key/attack_self(mob/living/carbon/user)
	if(!deployed)
		deploy_key(user)
		return
	..()

/// Alt-click toggles deploy/retract.
/obj/item/ego_weapon/city/dieci/key/AltClick(mob/user)
	. = ..()
	if(!isliving(user))
		return
	if(deployed)
		retract_key(user)
	else
		deploy_key(user)

/// Block attacks while retracted.
/obj/item/ego_weapon/city/dieci/key/attack(mob/living/target, mob/living/user)
	if(!deployed)
		to_chat(user, span_warning("[src] must be deployed first! Use it in hand."))
		return
	..()

/// Extend the key to full combat size.
/obj/item/ego_weapon/city/dieci/key/proc/deploy_key(mob/user)
	deployed = TRUE
	w_class = WEIGHT_CLASS_BULKY
	slot_flags = ITEM_SLOT_BELT
	inhand_icon_state = deployed_icon
	playsound(user, 'sound/weapons/ego/dieci_key_change.ogg', 35, TRUE)
	to_chat(user, span_notice("You extend [src] to its full size."))
	if(isliving(user))
		var/mob/living/L = user
		L.update_inv_hands()

/// Collapse the key to a portable size.
/obj/item/ego_weapon/city/dieci/key/proc/retract_key(mob/user)
	deployed = FALSE
	activated = FALSE
	empowered_level = 0
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_NECK | ITEM_SLOT_POCKETS
	inhand_icon_state = initial(inhand_icon_state)
	playsound(user, 'sound/weapons/ego/dieci_key_change.ogg', 35, TRUE)
	to_chat(user, span_notice("You collapse [src] to a portable size."))
	if(isliving(user))
		var/mob/living/L = user
		L.update_inv_hands()

/// Key empowerment bonus: Offense Level Up instead of shield HP.
/obj/item/ego_weapon/city/dieci/key/apply_empower_bonus(mob/living/user)
	user.apply_lc_offense_level_up(empowered_level * 2)

/// Veteran-tier Dieci key.
/obj/item/ego_weapon/city/dieci/key/vet
	name = "dieci veteran key"
	desc = "A finely crafted ceremonial key wielded by veteran members of Dieci Association. Its polished surface thrums with sharpened intent."
	force = 35
	attack_speed = 0.85
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

/// Director-tier Dieci key.
/obj/item/ego_weapon/city/dieci/key/director
	name = "dieci director key"
	desc = "An ornate golden key carried by the Director of Dieci Association. A symbol of absolute authority that hums with devastating focus."
	force = 48
	attack_speed = 0.8
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 120,
							PRUDENCE_ATTRIBUTE = 120,
							TEMPERANCE_ATTRIBUTE = 120,
							JUSTICE_ATTRIBUTE = 120
							)
