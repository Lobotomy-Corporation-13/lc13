/**
 * The deal damage proc is a replacement for apply_damage() aimed to reduce copy-paste.
 * In comparison to apply_damage() it:
 * * Automatically checks for armor, and applies its damage reduction effects
 * * Can deal with multiple damages, read damage_type point 1
 *
 * damage_amount = The amount of damage you want to apply.
 *
 * damage_type = The damage types you want to apply, can be a list.
 * * if damage_type is a list, it will divide the damage_amount by the list lenght to always be at the "same" damage then it will apply each damage in the list equally, considering their individual armor values.
 *
 * source = The mob that the damage is being received from. This can be null. It's passed onto PreDamageReaction() and PostDamageReaction().
 *
 * forced = If TRUE, will not call PreDamageReaction().
 *
 * trackable = If FALSE, will null source before calling PostDamageReaction().
 *
 * overrides = An arglist that contains the arguments for apply_damage if you want to get really custom with how you call your damage (example: dealing PALE damage based on RED armour.)
 * * In most cases, you should not send an overrides list. If you do, please make sure to specify the armour check to run in 'blocked' and whether you want to 'spread_damage'. Also, if dealing WHITE or BLACK, you can specify 'white_healable' to resane.

 */
/mob/living/proc/deal_damage(damage_amount, damage_type, source = null, forced = FALSE, trackable = TRUE, list/overrides = null)
	if((!forced) && (!PreDamageReaction(damage_amount, damage_type, source))) // If our forced argument isn't TRUE, then we expect to receive a TRUE from PreDamageReaction to continue the proc
		return

	if(!islist(damage_type)) // they just want to apply a single damage type
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

	if(!trackable)
		source = null
	PostDamageReaction(damage_amount, damage_type, source)
