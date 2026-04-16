// Palermitan Role-Specific Passives
// Each duelable role grants one passive with 3 tiers.
// Tiers unlock at 1, 3, 5 duels against that role.
// All passives use only vars + world.time checks, no timers.

/// Base role passive component — all role passives inherit from this
/datum/component/palermitan_role_passive
	/// Reference to the human parent
	var/mob/living/carbon/human/human_parent
	/// Current tier (1-3), set externally based on duel count
	var/tier = 1

/datum/component/palermitan_role_passive/Initialize(_tier = 1)
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	human_parent = parent
	tier = _tier

/datum/component/palermitan_role_passive/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/component/palermitan_role_passive/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_ITEM_ATTACK)
	human_parent = null
	. = ..()

/datum/component/palermitan_role_passive/proc/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	return

/// Helper: get Duel Escalates stacks
/datum/component/palermitan_role_passive/proc/get_duel_stacks(mob/living/target)
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	return D ? D.stacks : 0

/// Updates the tier. Called when duel count changes.
/datum/component/palermitan_role_passive/proc/set_tier(new_tier)
	tier = clamp(new_tier, 1, 3)

////////////////////////////////////////////////////////////
// BUTCHER — "Predator's Instinct"
// On Hit vs <50% HP: +5/10/15% bonus damage. T3: also heal 3 HP
/datum/component/palermitan_role_passive/butcher

/datum/component/palermitan_role_passive/butcher/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(target.health > target.maxHealth * 0.5)
		return
	if(!weapon)
		return
	var/percent = 0.05
	if(tier >= 3)
		percent = 0.15
	else if(tier >= 2)
		percent = 0.10
	var/bonus = round(weapon.force * percent)
	if(bonus > 0)
		weapon.force += bonus
		INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, bonus)
	if(tier >= 3 && ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustBruteLoss(-3)

/datum/component/palermitan_role_passive/butcher/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus

////////////////////////////////////////////////////////////
// BLADE LINEAGE — "Resolve of the Salsu"
// Below 30% HP: +10/15/20% damage. T3: attacks cannot be dodged
/datum/component/palermitan_role_passive/blade_lineage

/datum/component/palermitan_role_passive/blade_lineage/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(!weapon || !ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(H.health > H.maxHealth * 0.3)
		return
	var/percent = 0.10
	if(tier >= 3)
		percent = 0.20
	else if(tier >= 2)
		percent = 0.15
	var/bonus = round(weapon.force * percent)
	if(bonus > 0)
		weapon.force += bonus
		INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, bonus)

/datum/component/palermitan_role_passive/blade_lineage/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus

////////////////////////////////////////////////////////////
// THUMB — "Soldato's Discipline"
// On taking RED damage: +2/3/3 DLU. T3: also +1 OLU
/datum/component/palermitan_role_passive/thumb

/datum/component/palermitan_role_passive/thumb/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))

/datum/component/palermitan_role_passive/thumb/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/palermitan_role_passive/thumb/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	return

/datum/component/palermitan_role_passive/thumb/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!damage || damage <= 0 || damagetype != RED_DAMAGE)
		return
	var/mob/living/user = parent
	if(tier >= 3)
		user.apply_lc_defense_level_up(3)
		user.apply_lc_offense_level_up(1)
	else if(tier >= 2)
		user.apply_lc_defense_level_up(3)
	else
		user.apply_lc_defense_level_up(2)

////////////////////////////////////////////////////////////
// KUROKUMO — "Way of the Drawn Blade"
// On Hit: +1 Poise. T2: crits +5% damage. T3: +10% crit damage + crits inflict 2 Tremor
/datum/component/palermitan_role_passive/kurokumo

/datum/component/palermitan_role_passive/kurokumo/RegisterWithParent()
	. = ..()
	if(tier >= 2)
		RegisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit))

/datum/component/palermitan_role_passive/kurokumo/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER)
	. = ..()

/datum/component/palermitan_role_passive/kurokumo/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	user.apply_lc_poise(1)

/datum/component/palermitan_role_passive/kurokumo/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	// T2: deal extra RED damage equal to 5% of the crit's bonus damage
	if(tier >= 2 && bonus_damage > 0)
		var/extra = round(bonus_damage * 0.05)
		if(extra > 0)
			target.deal_damage(extra, RED_DAMAGE, source = parent, attack_type = ATTACK_TYPE_MELEE)
	// T3: deal 10% instead of 5%, and crits inflict 2 Tremor
	if(tier >= 3 && bonus_damage > 0)
		var/extra = round(bonus_damage * 0.05)
		if(extra > 0)
			target.deal_damage(extra, RED_DAMAGE, source = parent, attack_type = ATTACK_TYPE_MELEE)
		target.apply_lc_tremor(2, INFINITY)

////////////////////////////////////////////////////////////
// INDEX — "Prescript Discipline"
// On Hit: 1 OLD. T2: +1 DLD. T3: 2 OLD +1 DLD
/datum/component/palermitan_role_passive/index

/datum/component/palermitan_role_passive/index/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(tier >= 3)
		target.apply_lc_offense_level_down(2)
		target.apply_lc_defense_level_down(1)
	else if(tier >= 2)
		target.apply_lc_offense_level_down(1)
		target.apply_lc_defense_level_down(1)
	else
		target.apply_lc_offense_level_down(1)

////////////////////////////////////////////////////////////
// INSURGENCE — "Nightwatch Tremors"
// On Hit: 15/20/25% chance for 1/1/2 Tremor (no burst). T3: +5% dmg vs 10+ Tremor
/datum/component/palermitan_role_passive/insurgence

/datum/component/palermitan_role_passive/insurgence/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	var/chance = 15
	var/tremor_amount = 1
	if(tier >= 3)
		chance = 25
		tremor_amount = 2
	else if(tier >= 2)
		chance = 20
	if(prob(chance))
		target.apply_lc_tremor(tremor_amount, INFINITY)

////////////////////////////////////////////////////////////
// MIDDLE — "Vengeance Mark"
// On taking melee damage: +3/5/8% damage next attack. T3: counter inflicts 1 DE
/datum/component/palermitan_role_passive/middle
	var/buffed_next_hit = FALSE
	var/buff_percent = 0

/datum/component/palermitan_role_passive/middle/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))

/datum/component/palermitan_role_passive/middle/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/palermitan_role_passive/middle/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(!buffed_next_hit || !weapon)
		return
	buffed_next_hit = FALSE
	var/bonus = round(weapon.force * buff_percent)
	if(bonus > 0)
		weapon.force += bonus
		INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, bonus)
	if(tier >= 3)
		target.apply_duel_escalates(1, user)

/datum/component/palermitan_role_passive/middle/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return
	buffed_next_hit = TRUE
	if(tier >= 3)
		buff_percent = 0.08
	else if(tier >= 2)
		buff_percent = 0.05
	else
		buff_percent = 0.03

/datum/component/palermitan_role_passive/middle/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus

////////////////////////////////////////////////////////////
// N-CORP — "Methodical Strikes"
// On Hit: 1/1/2 DLD + 1/2/2 Overheat
/datum/component/palermitan_role_passive/ncorp

/datum/component/palermitan_role_passive/ncorp/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(tier >= 3)
		target.apply_lc_defense_level_down(2)
		target.apply_lc_overheat(2)
	else if(tier >= 2)
		target.apply_lc_defense_level_down(1)
		target.apply_lc_overheat(2)
	else
		target.apply_lc_defense_level_down(1)
		target.apply_lc_overheat(1)

////////////////////////////////////////////////////////////
// RAT — "Scavenger's Luck"
// On Hit: 5/8/10% chance +50% bonus damage. T3: lucky strikes +2 Tremor
/datum/component/palermitan_role_passive/rat

/datum/component/palermitan_role_passive/rat/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(!weapon)
		return
	var/chance = 5
	if(tier >= 3)
		chance = 10
	else if(tier >= 2)
		chance = 8
	if(prob(chance))
		var/bonus = round(weapon.force * 0.5)
		if(bonus > 0)
			weapon.force += bonus
			INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, bonus)
		if(tier >= 3)
			target.apply_lc_tremor(2, INFINITY)

/datum/component/palermitan_role_passive/rat/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus

////////////////////////////////////////////////////////////
// CARNIVAL — "Silk Hunter's Patience"
// After 3+ sec without attacking: next hit +10/20/30% damage. T3: +2 Overheat
/datum/component/palermitan_role_passive/carnival
	var/last_attack_time = 0

/datum/component/palermitan_role_passive/carnival/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(!weapon)
		last_attack_time = world.time
		return
	if(world.time >= last_attack_time + 3 SECONDS && last_attack_time > 0)
		var/percent = 0.10
		if(tier >= 3)
			percent = 0.30
		else if(tier >= 2)
			percent = 0.20
		var/bonus = round(weapon.force * percent)
		if(bonus > 0)
			weapon.force += bonus
			INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, bonus)
		if(tier >= 3)
			target.apply_lc_overheat(2)
	last_attack_time = world.time

/datum/component/palermitan_role_passive/carnival/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus

////////////////////////////////////////////////////////////
// ZWEI — "Guardian's Resilience"
// On taking damage: +2/3/3 DLU. T3: +1 OLD on attacker
/datum/component/palermitan_role_passive/zwei

/datum/component/palermitan_role_passive/zwei/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))

/datum/component/palermitan_role_passive/zwei/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/palermitan_role_passive/zwei/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	return

/datum/component/palermitan_role_passive/zwei/proc/on_take_damage(datum/source, damage, damagetype, def_zone, atom/damage_source)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return
	var/mob/living/user = parent
	if(tier >= 3)
		user.apply_lc_defense_level_up(3)
		if(isliving(damage_source))
			var/mob/living/attacker = damage_source
			attacker.apply_lc_offense_level_down(1)
	else if(tier >= 2)
		user.apply_lc_defense_level_up(3)
	else
		user.apply_lc_defense_level_up(2)

////////////////////////////////////////////////////////////
// SEVEN — "Analyst's Eye"
// On Hit vs debuffed target: +1/2/2 OLU. T3: +1 DE
/datum/component/palermitan_role_passive/seven

/datum/component/palermitan_role_passive/seven/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	// Check for any debuff
	var/has_debuff = FALSE
	if(target.has_status_effect(/datum/status_effect/stacking/lc_tremor))
		has_debuff = TRUE
	else if(target.has_status_effect(/datum/status_effect/stacking/lc_burn))
		has_debuff = TRUE
	else if(target.has_status_effect(/datum/status_effect/stacking/lc_bleed))
		has_debuff = TRUE
	else if(target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay))
		has_debuff = TRUE
	else if(target.has_status_effect(/datum/status_effect/stacking/protection/fragile))
		has_debuff = TRUE
	else if(target.has_status_effect(/datum/status_effect/stacking/defense_level_up/defense_level_down))
		has_debuff = TRUE
	else if(target.has_status_effect(/datum/status_effect/stacking/offense_level_up/offense_level_down))
		has_debuff = TRUE
	if(!has_debuff)
		return
	if(tier >= 2)
		user.apply_lc_offense_level_up(2)
	else
		user.apply_lc_offense_level_up(1)
	if(tier >= 3)
		target.apply_duel_escalates(1, user)

////////////////////////////////////////////////////////////
// DIECI — "Scholar's Insight"
// On Hit: +3/5/7% damage per distinct debuff type on target (max 4 types)
/datum/component/palermitan_role_passive/dieci

/datum/component/palermitan_role_passive/dieci/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(!weapon)
		return
	var/count = 0
	if(target.has_status_effect(/datum/status_effect/stacking/lc_tremor))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_burn))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_bleed))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay))
		count++
	if(count <= 0)
		return
	var/percent_per = 0.03
	if(tier >= 3)
		percent_per = 0.07
	else if(tier >= 2)
		percent_per = 0.05
	var/bonus = round(weapon.force * percent_per * count)
	if(bonus > 0)
		weapon.force += bonus
		INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, bonus)

/datum/component/palermitan_role_passive/dieci/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus

////////////////////////////////////////////////////////////
// CINQ — "Duelist's Finesse" (roaming fixer only)
// On Hit: +2/3/3 Poise. T3: halving crit +1 Concentration
/datum/component/palermitan_role_passive/cinq
	var/poise_before_crit = 0

/datum/component/palermitan_role_passive/cinq/RegisterWithParent()
	. = ..()
	if(tier >= 3)
		RegisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER, PROC_REF(on_poise_crit))

/datum/component/palermitan_role_passive/cinq/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_POISE_CRIT_ATTACKER)
	. = ..()

/datum/component/palermitan_role_passive/cinq/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(tier >= 2)
		user.apply_lc_poise(3)
	else
		user.apply_lc_poise(2)
	// Track poise for halving crit detection at T3
	if(tier >= 3)
		var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
		poise_before_crit = P ? P.stacks : 0

/datum/component/palermitan_role_passive/cinq/proc/on_poise_crit(datum/source, mob/living/target, bonus_damage)
	SIGNAL_HANDLER
	var/mob/living/user = parent
	// Only grant Concentration if poise was halved (not saved by Concentration)
	var/datum/status_effect/stacking/poise/P = user.has_status_effect(/datum/status_effect/stacking/poise)
	var/poise_after = P ? P.stacks : 0
	if(poise_before_crit > 0 && poise_after < poise_before_crit * 0.75)
		user.apply_lc_concentration(1)

////////////////////////////////////////////////////////////
// SHI — "Assassin's Sacrifice"
// On Hit vs <30% HP (3s CD): +3/4/5 OLU, lose 3% max HP. T3: +2 Fragile
/datum/component/palermitan_role_passive/shi
	var/last_proc_time = 0

/datum/component/palermitan_role_passive/shi/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(target.health > target.maxHealth * 0.3)
		return
	if(world.time < last_proc_time + 3 SECONDS)
		return
	last_proc_time = world.time
	var/olu = 3
	if(tier >= 3)
		olu = 5
		target.apply_lc_fragile(2)
	else if(tier >= 2)
		olu = 4
	user.apply_lc_offense_level_up(olu)
	// Self-harm: lose 3% max HP
	var/self_damage = round(user.maxHealth * 0.03)
	if(self_damage > 0)
		user.adjustBruteLoss(self_damage)

////////////////////////////////////////////////////////////
// LIU — "Burning Fist"
// On Hit: +1 Overheat. T2: every 4th hit +2 extra. T3: every 3rd hit +3 extra
/datum/component/palermitan_role_passive/liu
	var/hit_count = 0

/datum/component/palermitan_role_passive/liu/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	target.apply_lc_overheat(1)
	hit_count++
	if(tier >= 3 && hit_count >= 3)
		target.apply_lc_overheat(3)
		hit_count = 0
	else if(tier >= 2 && hit_count >= 4)
		target.apply_lc_overheat(2)
		hit_count = 0

////////////////////////////////////////////////////////////
// DEVYAT — "Berserker's Escalation"
// On Hit (3s CD): +2/3/3 OLU, lose 2% max HP. T3: below 50% HP also +2 DLU
/datum/component/palermitan_role_passive/devyat
	var/last_proc_time = 0

/datum/component/palermitan_role_passive/devyat/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(world.time < last_proc_time + 3 SECONDS)
		return
	last_proc_time = world.time
	var/olu = 2
	if(tier >= 2)
		olu = 3
	user.apply_lc_offense_level_up(olu)
	// Self-harm
	var/self_damage = round(user.maxHealth * 0.02)
	if(self_damage > 0)
		user.adjustBruteLoss(self_damage)
	// T3: DLU when low
	if(tier >= 3 && ishuman(user))
		var/mob/living/carbon/human/H = user
		if(H.health < H.maxHealth * 0.5)
			user.apply_lc_defense_level_up(2)

////////////////////////////////////////////////////////////
// HANA — "Adaptive Form"
// On attacking with different weapon than last (5s CD): +2/2+2/3+2 OLU(+DLU)
/datum/component/palermitan_role_passive/hana
	var/obj/item/last_weapon_used
	var/last_switch_bonus_time = 0

/datum/component/palermitan_role_passive/hana/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	if(!isliving(target) || target == user)
		return
	if(weapon && last_weapon_used && weapon != last_weapon_used)
		if(world.time >= last_switch_bonus_time + 5 SECONDS)
			last_switch_bonus_time = world.time
			if(tier >= 3)
				user.apply_lc_offense_level_up(3)
				user.apply_lc_defense_level_up(2)
			else if(tier >= 2)
				user.apply_lc_offense_level_up(2)
				user.apply_lc_defense_level_up(2)
			else
				user.apply_lc_offense_level_up(2)
	last_weapon_used = weapon
