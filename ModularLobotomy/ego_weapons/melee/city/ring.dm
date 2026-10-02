/obj/item/ego_weapon/city/pointillist
	name = "Pointillist Brush"
	icon_state = "pointillist"
	inhand_icon_state = "pointillist"
	desc = "A brush used by students of the Ring School of Pointillism."
	force = 25
	reach = 2
	attack_speed = 0.6
	stuntime = 5
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_THRUST

	hitsound = 'sound/weapons/fixer/generic/spear2.ogg'
	attack_verb_continuous = list("pierces", "stabs")
	attack_verb_simple = list("pierce", "stab")
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 100,
		PRUDENCE_ATTRIBUTE = 80,
		TEMPERANCE_ATTRIBUTE = 80,
		JUSTICE_ATTRIBUTE = 60,
	)
	var/status_list = list(/datum/status_effect/stacking/lc_tremor,
							/datum/status_effect/stacking/lc_burn,
							/datum/status_effect/stacking/sinking,
							/datum/status_effect/stacking/rupture,
							/datum/status_effect/stacking/lc_bleed,)
	var/stacks = 2
	var/special_toggled = FALSE
	var/special_cooldown
	var/special_cooldown_time = 80
	var/damage_mult = 0.25
	var/attack_mult

/obj/item/ego_weapon/city/pointillist/attack(mob/living/target, mob/living/carbon/human/user)
	var/rolled_status = status_list[rand(1, length(status_list))]
	var/has_status = target.has_status_effect(rolled_status)
	if(!special_toggled)
		..()
		if(!has_status)
			target.apply_status_effect(rolled_status, stacks)
		else
			has_status:add_stacks(stacks)
	else
		balloon_alert(user, "Your brush pierces [target] with a vibrant swash.")
		balloon_alert(target, "[user]'s brush pierces through you.")
		to_chat(user, "Your brush pierces [target] with a vibrant swash.")
		to_chat(target, "[user]'s brush pierces through you.")
		var/target_statuses = list()
		if(target.has_status_effect(/datum/status_effect/stacking/lc_bleed))
			target_statuses += "bleeding"
		if(target.has_status_effect(/datum/status_effect/stacking/lc_burn))
			target_statuses += "burning"
		if(target.has_status_effect(/datum/status_effect/stacking/rupture))
			target_statuses += "rupturing"
		if(target.has_status_effect(/datum/status_effect/stacking/lc_tremor))
			target_statuses += "tremoring"
		if(target.has_status_effect(/datum/status_effect/stacking/sinking))
			target_statuses += "sinking"
		var/justice_mod = 1 + (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE)/100)
		attack_mult = (1+(length(target_statuses)*damage_mult))
		target.apply_damage_type(force*justice_mod*attack_mult, damtype)
		special_cooldown = world.time + special_cooldown_time
		special_toggled = FALSE

/obj/item/ego_weapon/city/pointillist/attack_self(mob/user)
	..()
	if(!special_toggled)
		if(world.time >= special_cooldown)
			balloon_alert(user, "You prepare to use your special on your next hit.")
			special_toggled = TRUE
		else
			balloon_alert(user, "Cooldown: [(special_cooldown-world.time)/10] seconds." )
	else
		balloon_alert(user, "You decide against using your ability.")
		special_toggled = FALSE