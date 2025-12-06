/// This replaces Fairy. It hurts the selected target.
/obj/effect/proc_holder/spell/pointed/thin_line
	name = "Thin Line"
	desc = "Assaults the target with Thin Lines, dealing the damage type corresponding to your active singularity and applying 1 stack of Faltering Justice."
	school = SCHOOL_EVOCATION
	charge_type = "charges"
	charge_max = 4
	clothes_req = FALSE
	invocation_type = "none"
	base_icon_state = "lightning"
	action_icon_state = "lightning0"
	sound = 'sound/magic/arbiter/thinline_cast.ogg'
	aim_assist = TRUE
	var/base_damage = 60 // Yes even PALE does this much
	var/mech_damage_coeff = 6 // I HATE RHINOS I HATE RHINOS
	var/damage_type = BLACK_DAMAGE // Changed by Singularity Swap

	var/powernull_stacks_per_hit = 1

	var/recharge_time_per_charge = 5 SECONDS // Amount of time to regain a charge of this spell
	var/recharge_timer

	var/usage_cooldown_duration = 1.2 SECONDS // Mini cooldown to avoid ultrakilling someone by instantly spamming all your charges on them
	var/usage_cooldown

/obj/effect/proc_holder/spell/pointed/thin_line/cast(list/targets, mob/user = usr)
	var/unfortunate = pick(targets)

	// Target is a mech.
	if(istype(unfortunate, /obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/tin_can = unfortunate // Targeted mech
		if(!tin_can)
			return
		var/mob/living/flesh_cannot

		if(length(tin_can.occupants) > 0)
			flesh_cannot = pick(tin_can.occupants) // Goofball inside the mech

		// Show the VFX as an overlay on the mech
		var/image/cool_overlay = image('ModularLobotomy/_Lobotomyicons/48x48.dmi', loc = tin_can, icon_state = "thin_line", layer = tin_can.layer + 1)
		cool_overlay.pixel_x -= 8
		cool_overlay.pixel_y -= 8
		switch(damage_type)
			if(RED_DAMAGE)
				cool_overlay.color = "#D70000"
			if(WHITE_DAMAGE)
				cool_overlay.color = "#DDDDDD"
			if(BLACK_DAMAGE)
				cool_overlay.color = "#DABB04"
			if(PALE_DAMAGE)
				cool_overlay.color = "#45F7F7"
		flick_overlay_view(cool_overlay, tin_can, 1.4 SECONDS)

		// Deal damage to mech
		tin_can.take_damage(base_damage * mech_damage_coeff, damage_type)
		playsound(tin_can, 'sound/magic/arbiter/thinline_hit.ogg', 100)
		// If we managed to find the occupant, deal 75% damage to them too
		if(flesh_cannot)
			flesh_cannot.deal_damage(base_damage * 0.75, damage_type, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
			flesh_cannot.apply_arbiter_powernull(powernull_stacks_per_hit)

	// Target is a mob.
	else if(istype(unfortunate, /mob/living))
		var/mob/living/gremlin = unfortunate

		var/image/cool_overlay = image('ModularLobotomy/_Lobotomyicons/48x48.dmi', loc = gremlin, icon_state = "thin_line", layer = gremlin.layer + 1)
		cool_overlay.pixel_x -= 8
		cool_overlay.pixel_y -= 8
		switch(damage_type)
			if(RED_DAMAGE)
				cool_overlay.color = "#D70000"
			if(WHITE_DAMAGE)
				cool_overlay.color = "#DDDDDD"
			if(BLACK_DAMAGE)
				cool_overlay.color = "#DABB04"
			if(PALE_DAMAGE)
				cool_overlay.color = "#45F7F7"
		flick_overlay_view(cool_overlay, gremlin, 1.4 SECONDS)

		gremlin.deal_damage(base_damage, damage_type, source = user, attack_type = (ATTACK_TYPE_SPECIAL))
		gremlin.apply_arbiter_powernull(powernull_stacks_per_hit)
		playsound(gremlin, 'sound/magic/arbiter/thinline_hit.ogg', 100)
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

// Calls itself recursively until we're full on charges.
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
		if((faction_check(user.faction, our_target.faction, TRUE)) || (our_target.stat >= DEAD))
			return FALSE
	. = ..()
