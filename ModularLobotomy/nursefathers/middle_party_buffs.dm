// Middle Nursefather — Party Buff Status Effects
// Applied to all attendees when a party concludes. Each area grants a unique buff.

/datum/movespeed_modifier/party_showtime
	multiplicative_slowdown = -0.3

/// Base party buff — 25 minutes, passive sanity heal, purple glow.
/datum/status_effect/party_buff
	id = "party_buff"
	duration = 15000
	tick_interval = 100
	alert_type = /atom/movable/screen/alert/status_effect/party_buff
	/// Attribute buffs applied on_apply, reversed on_remove
	var/fort_buff = 0
	var/prud_buff = 0
	var/temp_buff = 0
	var/just_buff = 0
	/// Sanity heal per tick (default -2, clinic overrides to -5)
	var/sanity_heal = -2
	/// Display name for this buff
	var/buff_name = "Party Buff"
	/// Description of this buff's effects
	var/buff_desc = "Passive sanity healing and a purple glow."

/atom/movable/screen/alert/status_effect/party_buff
	name = "Party Buff"
	desc = "You attended a Middle party. You feel great."
	icon_state = "blooddrunk"

/datum/status_effect/party_buff/on_apply()
	. = ..()
	if(!.)
		return
	if(linked_alert)
		linked_alert.name = buff_name
		linked_alert.desc = buff_desc
	owner.set_light(2, 1, "#9932CC")
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(fort_buff)
			H.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, fort_buff)
		if(prud_buff)
			H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, prud_buff)
		if(temp_buff)
			H.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, temp_buff)
		if(just_buff)
			H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, just_buff)

/datum/status_effect/party_buff/tick()
	if(!owner || owner.stat == DEAD)
		return
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.adjustSanityLoss(sanity_heal)

/datum/status_effect/party_buff/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(fort_buff)
			H.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, -fort_buff)
		if(prud_buff)
			H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -prud_buff)
		if(temp_buff)
			H.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -temp_buff)
		if(just_buff)
			H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -just_buff)
	owner.set_light(0)
	return ..()

// ==================== TIER 1 — Safe Locations ====================

/// Employee Housing — "Home Comfort": +10 Prudence, 10% less WHITE damage
/datum/status_effect/party_buff/home_comfort
	id = "party_buff_home_comfort"
	prud_buff = 10
	buff_name = "Home Comfort"
	buff_desc = "+10 Prudence, 10% less WHITE damage. Passive sanity healing."

/datum/status_effect/party_buff/home_comfort/on_apply()
	. = ..()
	if(!. || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.physiology.white_mod *= 0.9

/datum/status_effect/party_buff/home_comfort/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.white_mod /= 0.9
	return ..()

/// The Alibi — "Liquid Courage": +15 Fortitude, 10% more RED damage on hit
/datum/status_effect/party_buff/liquid_courage
	id = "party_buff_liquid_courage"
	fort_buff = 15
	buff_name = "Liquid Courage"
	buff_desc = "+15 Fortitude, bonus RED damage on hit. Passive sanity healing."
	var/bonus_damage_mult = 0.1

/datum/status_effect/party_buff/liquid_courage/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/status_effect/party_buff/liquid_courage/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_ITEM_ATTACK)
	return ..()

/datum/status_effect/party_buff/liquid_courage/proc/on_attack(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target) || target.stat == DEAD)
		return
	var/bonus = 3
	target.deal_damage(bonus, RED_DAMAGE)

/// Shop — "Retail Therapy": +10 Fortitude, +10 Prudence
/datum/status_effect/party_buff/retail_therapy
	id = "party_buff_retail_therapy"
	fort_buff = 10
	prud_buff = 10
	buff_name = "Retail Therapy"
	buff_desc = "+10 Fortitude, +10 Prudence. Passive sanity healing."

/// Library — "Studied Mind": +10 Prudence, +10 Justice, 10% less BLACK damage
/datum/status_effect/party_buff/studied_mind
	id = "party_buff_studied_mind"
	prud_buff = 10
	just_buff = 10
	buff_name = "Studied Mind"
	buff_desc = "+10 Prudence, +10 Justice, 10% less BLACK damage. Passive sanity healing."

/datum/status_effect/party_buff/studied_mind/on_apply()
	. = ..()
	if(!. || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.physiology.black_mod *= 0.9

/datum/status_effect/party_buff/studied_mind/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.black_mod /= 0.9
	return ..()

/// The Bistro — "Well Fed": +10 Fortitude, +10 Prudence, passive HP regen
/datum/status_effect/party_buff/well_fed
	id = "party_buff_well_fed"
	fort_buff = 10
	prud_buff = 10
	buff_name = "Well Fed"
	buff_desc = "+10 Fortitude, +10 Prudence, passive HP regen. Passive sanity healing."

/datum/status_effect/party_buff/well_fed/tick()
	..()
	if(!owner || owner.stat == DEAD)
		return
	owner.adjustBruteLoss(-1)
	owner.adjustFireLoss(-1)

/// Carnival Base — "Showtime": +15 Justice, movement speed boost
/datum/status_effect/party_buff/showtime
	id = "party_buff_showtime"
	just_buff = 15
	buff_name = "Showtime"
	buff_desc = "+15 Justice, movement speed boost. Passive sanity healing."

/datum/status_effect/party_buff/showtime/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_movespeed_modifier(/datum/movespeed_modifier/party_showtime)

/datum/status_effect/party_buff/showtime/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/party_showtime)
	return ..()

/// Clinic — "Patched Up": +10 Prudence, enhanced sanity heal, 10% less PALE damage
/datum/status_effect/party_buff/patched_up
	id = "party_buff_patched_up"
	prud_buff = 10
	sanity_heal = -5
	buff_name = "Patched Up"
	buff_desc = "+10 Prudence, enhanced sanity heal, 10% less PALE damage."

/datum/status_effect/party_buff/patched_up/on_apply()
	. = ..()
	if(!. || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.physiology.pale_mod *= 0.9

/datum/status_effect/party_buff/patched_up/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.pale_mod /= 0.9
	return ..()

// ==================== TIER 2 — Moderate Risk ====================

/// HamHamPangPang — "Masterwork Cooking": +15 Fortitude, +10 Justice, inflict 2 Bleed on hit (10s cooldown)
/datum/status_effect/party_buff/masterwork_cooking
	id = "party_buff_masterwork_cooking"
	fort_buff = 15
	just_buff = 10
	buff_name = "Masterwork Cooking"
	buff_desc = "+15 Fortitude, +10 Justice, inflict 2 Bleed on hit (10s cooldown). Passive sanity healing."
	COOLDOWN_DECLARE(bleed_cd)

/datum/status_effect/party_buff/masterwork_cooking/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/status_effect/party_buff/masterwork_cooking/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_ITEM_ATTACK)
	return ..()

/datum/status_effect/party_buff/masterwork_cooking/proc/on_attack(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target) || target.stat == DEAD)
		return
	if(!COOLDOWN_FINISHED(src, bleed_cd))
		return
	COOLDOWN_START(src, bleed_cd, 10 SECONDS)
	target.apply_lc_bleed(2)

/// Fixer Office — "Professional Edge": +15 Justice, +10 Fortitude, 10% more BLACK damage on hit
/datum/status_effect/party_buff/professional_edge
	id = "party_buff_professional_edge"
	just_buff = 15
	fort_buff = 10
	buff_name = "Professional Edge"
	buff_desc = "+15 Justice, +10 Fortitude, bonus BLACK damage on hit. Passive sanity healing."

/datum/status_effect/party_buff/professional_edge/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/status_effect/party_buff/professional_edge/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_ITEM_ATTACK)
	return ..()

/datum/status_effect/party_buff/professional_edge/proc/on_attack(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target) || target.stat == DEAD)
		return
	var/bonus = 3
	target.deal_damage(bonus, BLACK_DAMAGE)

/// Roaming Fixers Office — "Freelancer's Grit": +15 Fortitude, +15 Justice, 15% less RED damage
/datum/status_effect/party_buff/freelancers_grit
	id = "party_buff_freelancers_grit"
	fort_buff = 15
	just_buff = 15
	buff_name = "Freelancer's Grit"
	buff_desc = "+15 Fortitude, +15 Justice, 15% less RED damage. Passive sanity healing."

/datum/status_effect/party_buff/freelancers_grit/on_apply()
	. = ..()
	if(!. || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.physiology.red_mod *= 0.85

/datum/status_effect/party_buff/freelancers_grit/on_remove()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.red_mod /= 0.85
	return ..()

// ==================== TIER 3 — High Risk ====================

/// Hana Office — "Corporate Raid": +10 Fort/Prud/Just, 5% lifesteal on hit
/datum/status_effect/party_buff/corporate_raid
	id = "party_buff_corporate_raid"
	fort_buff = 10
	prud_buff = 10
	just_buff = 10
	buff_name = "Corporate Raid"
	buff_desc = "+10 Fortitude, +10 Prudence, +10 Justice, 5% lifesteal on hit. Passive sanity healing."

/datum/status_effect/party_buff/corporate_raid/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/status_effect/party_buff/corporate_raid/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_ITEM_ATTACK)
	return ..()

/datum/status_effect/party_buff/corporate_raid/proc/on_attack(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target) || target.stat == DEAD)
		return
	var/damage_dealt = 5
	owner.adjustBruteLoss(-max(1, round(damage_dealt * 0.05)))

/// Association Office — "Syndicate Bonds": +10 Fort/Prud/Just, inflict 2 Overheat on hit (10s cooldown)
/datum/status_effect/party_buff/syndicate_bonds
	id = "party_buff_syndicate_bonds"
	fort_buff = 10
	prud_buff = 10
	just_buff = 10
	buff_name = "Syndicate Bonds"
	buff_desc = "+10 Fortitude, +10 Prudence, +10 Justice, inflict 2 Overheat on hit (10s cooldown). Passive sanity healing."
	COOLDOWN_DECLARE(overheat_cd)

/datum/status_effect/party_buff/syndicate_bonds/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/status_effect/party_buff/syndicate_bonds/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_ITEM_ATTACK)
	return ..()

/datum/status_effect/party_buff/syndicate_bonds/proc/on_attack(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target) || target.stat == DEAD)
		return
	if(!COOLDOWN_FINISHED(src, overheat_cd))
		return
	COOLDOWN_START(src, overheat_cd, 10 SECONDS)
	target.apply_lc_overheat(2)

/// Abandoned Hideout — "Hideout Hustle": +20 Fortitude, +20 Justice, 15% more RED on hit, 10% less all 4 core
/datum/status_effect/party_buff/hideout_hustle
	id = "party_buff_hideout_hustle"
	fort_buff = 20
	just_buff = 20
	buff_name = "Hideout Hustle"
	buff_desc = "+20 Fortitude, +20 Justice, 15% more RED damage, 10% less all core damage. Passive sanity healing."

/datum/status_effect/party_buff/hideout_hustle/on_apply()
	. = ..()
	if(!. || !ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.physiology.red_mod *= 0.9
	H.physiology.white_mod *= 0.9
	H.physiology.black_mod *= 0.9
	H.physiology.pale_mod *= 0.9
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/status_effect/party_buff/hideout_hustle/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_ITEM_ATTACK)
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.physiology.red_mod /= 0.9
		H.physiology.white_mod /= 0.9
		H.physiology.black_mod /= 0.9
		H.physiology.pale_mod /= 0.9
	return ..()

/datum/status_effect/party_buff/hideout_hustle/proc/on_attack(datum/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(target) || target.stat == DEAD)
		return
	var/bonus = 5
	target.deal_damage(bonus, RED_DAMAGE)
