/*
This proc deals damage to a mob.

damage_amount - How much damage we're taking.
damage_type - What kind of damage this is. For example, RED damage, WHITE damage, Stamina damage or Toxin damage. If it is one of the 4 LC13 colours, it may be shuffled if the trait is active.
source - The person or mob or thing in general that caused us to take damage.
flags - Special flags to customize damage behaviour, for example by making the damage untrackable. It is a bitfield. You may find the defines for it in code\__DEFINES\damage.dm
attack_type - What kind of attack is this damage coming from? It is a bitfield. You may find the defines for it in code\__DEFINES\damage.dm
blocked - The armour which will reduce incoming damage. Leave this as null to automatically check for armour corresponding to the incoming damage type. If you want to run your own custom armour check, send it as this argument.
def_zone - The zone that's being hit. You can safely leave this as null.
wound_bonus - Irrelevant to anyone but carbons.
bare_wound_bonus - Irrelevant to anyone but carbons.
sharpness - Irrelevant in most cases.
 */



/mob/living/proc/deal_damage(damage_amount, damage_type = BRUTE, source = null, flags = null, attack_type = null, blocked = null, def_zone = null, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	if(!damage_amount) // There are some extremely rare instances of 0 damage pre-armour reduction, for example King of Greed does a 0 damage HurtInTurf to fill up a hitlist to attack later.
		return FALSE
	say("deal_damage: original damage is [damage_amount] of [damage_type]")
	// Damage shuffler station trait.
	if(GLOB.damage_type_shuffler?.is_enabled && IsColorDamageType(damage_type))
		var/datum/damage_type_shuffler/shuffler = GLOB.damage_type_shuffler
		var/new_damage_type = shuffler.mapping_offense[damage_type]
		damage_type = new_damage_type

	if((!(flags & DAMAGE_FORCED)) && (!PreDamageReaction(damage_amount, damage_type, source, attack_type))) // If our forced argument isn't TRUE, then we expect to receive a TRUE from PreDamageReaction to continue the proc.
		return FALSE

	// We will now send a signal that gives listeners the opportunity to cancel the damage being dealt. For some reason, in the original apply_damage, this happens before a "final damage" calculation, so I have chosen to preserve that behaviour.
	// Some examples of the listeners that may return COMPONENT_MOB_DENY_DAMAGE are manager shields, the Welfare Core reward, or Sweeper Persistence.
	var/signal_return = SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMGE, damage_amount, damage_type, def_zone)
	if(signal_return & COMPONENT_MOB_DENY_DAMAGE)
		return FALSE

	// Automatically run an armour check for the provided damage type if we weren't already provided with a blocked value, and if we aren't taking BRUTE damage.
	if((isnull(blocked)) && (damage_type != BRUTE))
		blocked = run_armor_check(null, damage_type)

	var/hit_percent = (100-blocked)/100
	var/bypass_resistance = flags & DAMAGE_PIERCING

	if(hit_percent <= 0 && !(bypass_resistance))
		return FALSE

	var/final_damage = bypass_resistance ? damage_amount : damage_amount * hit_percent

	// Mind - apparently regular mobs don't have actual armor, their damage coeffs are the ones that handle reducing/increasing damage within the adjustXLoss procs.
	switch(damage_type)
		if(FIRE)
			adjustFireLoss(final_damage, forced = bypass_resistance)
		if(TOX)
			adjustToxLoss(final_damage, forced = bypass_resistance)
		if(OXY)
			adjustOxyLoss(final_damage, forced = bypass_resistance)
		if(CLONE)
			adjustCloneLoss(final_damage, forced = bypass_resistance)
		if(STAMINA)
			adjustStaminaLoss(final_damage, forced = bypass_resistance)
		if(RED_DAMAGE)
			adjustRedLoss(final_damage, forced = bypass_resistance)
		if(WHITE_DAMAGE)
			adjustWhiteLoss(final_damage, forced = bypass_resistance, white_healable = flags & DAMAGE_WHITE_HEALABLE)
		if(BLACK_DAMAGE)
			adjustBlackLoss(final_damage, forced = bypass_resistance, white_healable = flags & DAMAGE_WHITE_HEALABLE)
		if(PALE_DAMAGE)
			adjustPaleLoss(final_damage, forced = bypass_resistance)
		else
			adjustBruteLoss(final_damage, forced = bypass_resistance)

	if(stat < DEAD)
		PostDamageReaction(final_damage, damage_type, flags & DAMAGE_UNTRACKABLE ? null : source, attack_type)

	return final_damage


	/*if(!islist(damage_type)) // they just want to apply a single damage type
		if(islist(overrides))
			var/list/arguments_to_send = list(damage = damage_amount, damagetype = damage_type)
			arguments_to_send.Add(overrides)
			apply_damage(arglist(arguments_to_send))
		else
			apply_damage(damage_amount, damage_type, blocked = (damage_type != BRUTE ? run_armor_check(null, damage_type) : null), spread_damage = TRUE)
	else
		var/list/damage_types = damage_type
		damage_amount = damage_amount / length(damage_types) // make sure the damage amount is still correct by dividing it
		for(var/damage as anything in damage_types)
			if(islist(overrides))
				var/list/arguments_to_send = list(damage = damage_amount, damagetype = damage).Add(overrides)
				apply_damage(arglist(arguments_to_send))
			else
				apply_damage(damage_amount, damage, blocked = (damage_type != BRUTE ? run_armor_check(null, damage) : null), spread_damage = TRUE)
	*/

