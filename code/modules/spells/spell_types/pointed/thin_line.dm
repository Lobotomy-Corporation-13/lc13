/// This replaces Fairy. It hurts the selected target.
/obj/effect/proc_holder/spell/pointed/thin_line
	name = "Thin Line"
	desc = "Assaults the target with Thin Lines, dealing the damage type corresponding to your active singularity and applying 1 stack of Faltering Justice, up to 10."
	active_msg = "You activate your Thin Line emitter."
	deactive_msg = "You deactivate your Thin Line emitter for now..."
	school = SCHOOL_EVOCATION
	charge_type = "charges"
	charge_max = 4
	clothes_req = FALSE
	invocation_type = "none"
	base_icon_state = "thin_line"
	action_icon_state = "thin_line"
	sound = 'sound/magic/arbiter/thinline_cast.ogg'
	aim_assist = TRUE
	var/base_damage = 60
	var/pale_damage_coeff = 0.8 // Only applied when using the PALE version on a mob
	var/mech_damage_coeff = 6 // I HATE RHINOS I HATE RHINOS
	var/simplemob_coeff = 5 // Multiplies damage dealt by this much vs. Simplemobs (abnos, ordeals)
	var/damage_type = BLACK_DAMAGE // Changed by Singularity Swap

	var/powernull_stacks_per_hit = 1

	var/recharge_time_per_charge = 5 SECONDS // Amount of time to regain a charge of this spell
	var/recharge_timer // This timer is always running when we're missing charges. It isn't running when we're full. Only 1 version of this timer can exist.

	var/usage_cooldown_duration = 1.2 SECONDS // Mini cooldown to avoid ultrakilling someone by instantly spamming all your charges on them. Feel free to VV this but there's a hard cooldown from casting spells or clicking or something anyways.
	var/usage_cooldown

/obj/effect/proc_holder/spell/pointed/thin_line/cast(list/targets, mob/user = usr)
	var/unfortunate = pick(targets)
	var/appropiate_color = "#DABB04"
	switch(damage_type)
		if(RED_DAMAGE)
			appropiate_color = "#D70000"
		if(WHITE_DAMAGE)
			appropiate_color = "#DDDDDD"
		if(BLACK_DAMAGE)
			appropiate_color = "#DABB04"
		if(PALE_DAMAGE)
			appropiate_color = "#45F7F7"

	// Target is a mech.
	if(istype(unfortunate, /obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/tin_can = unfortunate // Targeted mech
		if(!tin_can)
			return
		var/mob/living/flesh_cannot

		if(length(tin_can.occupants) > 0)
			flesh_cannot = pick(tin_can.occupants) // Goofball inside the mech

		// Show the VFX as an overlay on the mech
		DisplayVFX(flesh_cannot, appropiate_color)

		// Deal damage to mech
		tin_can.take_damage(base_damage * mech_damage_coeff, damage_type)
		playsound(tin_can, 'sound/magic/arbiter/thinline_hit.ogg', 100, FALSE, 6)
		// If we managed to find the occupant, deal 75% damage to them too.
		if(flesh_cannot)
			var/final_damage = base_damage * 0.75
			if(damage_type == PALE_DAMAGE)
				final_damage *= pale_damage_coeff
			if(istype(flesh_cannot, /mob/living/simple_animal))
				final_damage *= simplemob_coeff
			flesh_cannot.deal_damage(final_damage, damage_type, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
			flesh_cannot.apply_arbiter_powernull(powernull_stacks_per_hit)
			flesh_cannot.visible_message(span_danger("[flesh_cannot] is pierced by an array of thin [damage_type] lines!"), span_userdanger("You're pierced by an array of thin [damage_type] lines!"))

	// Target is a mob.
	else if(istype(unfortunate, /mob/living))
		var/mob/living/gremlin = unfortunate

		DisplayVFX(gremlin, appropiate_color)

		var/final_damage = base_damage
		if(damage_type == PALE_DAMAGE)
			final_damage *= pale_damage_coeff
		if(istype(gremlin, /mob/living/simple_animal))
			final_damage *= simplemob_coeff
		gremlin.deal_damage(final_damage, damage_type, source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		gremlin.apply_arbiter_powernull(powernull_stacks_per_hit)
		gremlin.visible_message(span_danger("[gremlin] is pierced by an array of thin [damage_type] lines!"), span_userdanger("You're pierced by an array of thin [damage_type] lines!"))
		playsound(gremlin, 'sound/magic/arbiter/thinline_hit.ogg', 100, FALSE, 6)
	usage_cooldown = usage_cooldown_duration + world.time

	if(!recharge_timer)
		recharge_timer = addtimer(CALLBACK(src, PROC_REF(StartRecharge)), recharge_time_per_charge, TIMER_STOPPABLE)

// When clicking on something...
/obj/effect/proc_holder/spell/pointed/thin_line/InterceptClickOn(mob/living/requester, params, atom/target)
	. = ..()
	if(charge_counter > 0) // If we haven't run out of charges, allow us to keep using Thin Line without having to select it again. (..() will remove ranged ability here, but overriding it is a mess)
		add_ranged_ability(requester)

/obj/effect/proc_holder/spell/pointed/thin_line/cast_check(skipcharge, mob/user)
	if(usage_cooldown > world.time)
		to_chat(user, span_warning("Your Singularity is cooling down, wait a moment!"))
		return FALSE
	return ..()

/obj/effect/proc_holder/spell/pointed/thin_line/proc/DisplayVFX(atom/our_target, appropiate_color)
	var/image/cool_overlay = image('ModularLobotomy/_Lobotomyicons/48x48.dmi', loc = our_target, icon_state = "thin_line", layer = our_target.layer + 2)
	var/icon/target_icon = icon(our_target.icon, our_target.icon_state, our_target.dir)
	var/icon_height = target_icon.Height()
	var/icon_width = target_icon.Width()
	var/height_diff = 48 - icon_height
	var/width_diff = 48 - icon_width
	cool_overlay.pixel_y -= (height_diff * 0.5)
	cool_overlay.pixel_x -= (width_diff * 0.5)
	cool_overlay.color = appropiate_color
	flick_overlay_view(cool_overlay, our_target, 1.4 SECONDS)

// Recharge calls itself recursively until we're full on charges.
/obj/effect/proc_holder/spell/pointed/thin_line/proc/StartRecharge()
	deltimer(recharge_timer)
	recharge_timer = null
	charge_counter = clamp(charge_counter + 1, 1, charge_max)
	action.UpdateButtonIcon()
	usr.balloon_alert(usr, "Thin Line charges: [charge_counter]/[charge_max].")
	if(charge_counter < charge_max)
		recharge_timer = addtimer(CALLBACK(src, PROC_REF(StartRecharge)), recharge_time_per_charge, TIMER_STOPPABLE)

// Will only target a. mob/living that aren't in our factions and are alive, or b. mechs like Rhinos. Since this has aim assist, it will find these things in a turf we click on too.
/obj/effect/proc_holder/spell/pointed/thin_line/can_target(atom/target, mob/user, silent)
	if((!istype(target, /mob/living)) && (!istype(target, /obj/vehicle/sealed/mecha)))
		return FALSE

	var/mob/living/our_target = target
	if(istype(our_target))
		if((user.faction_check_mob(our_target, TRUE)) || (our_target.stat >= DEAD))
			return FALSE
	. = ..()
