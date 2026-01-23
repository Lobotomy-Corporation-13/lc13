/// This is a combination of Thin Line and Thick Line that also inflicts Chain.
/obj/effect/proc_holder/spell/pointed/birdcage
	name = "Birdcage"
	desc = "Suppresses the target with Thin Lines, then pierces them with a Line, dealing the damage type corresponding to your active singularity and sealing the target's capacity to move for a short time."
	active_msg = "You activate your Thin Line emitter."
	deactive_msg = "You deactivate your Thin Line emitter for now..."
	school = SCHOOL_EVOCATION
	charge_max = 300
	clothes_req = FALSE
	invocation_type = "none"
	base_icon_state = "birdcage"
	action_icon_state = "birdcage"
	sound = 'sound/magic/arbiter/thinline_cast.ogg'
	aim_assist = TRUE
	var/thinline_damage = 50
	var/thinline_pale_damage_coeff = 0.8 // Only applied when using the PALE version on a mob
	var/line_damage = 120
	var/line_pale_damage_coeff = 0.6
	var/mech_damage_coeff = 6 // I HATE RHINOS I HATE RHINOS
	var/simplemob_coeff = 5 // Multiplies damage dealt by this much vs. Simplemobs (abnos, ordeals)
	var/damage_type = BLACK_DAMAGE // Changed by Singularity Swap
	var/status_inflicted_type = /datum/status_effect/arbiter_chain/birdcage

/obj/effect/proc_holder/spell/pointed/birdcage/cast(list/targets, mob/user = usr)
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
		DisplayVFX(tin_can, appropiate_color)

		// Deal damage to mech
		tin_can.take_damage(thinline_damage * mech_damage_coeff, damage_type)
		playsound(tin_can, 'sound/magic/arbiter/thinline_hit.ogg', 75, FALSE, 6)
		// If we managed to find the occupant, deal 75% damage to them too.
		if(flesh_cannot)
			// Calculate damage
			var/final_damage = thinline_damage * 0.75
			if(damage_type == PALE_DAMAGE)
				final_damage *= thinline_pale_damage_coeff
			if(istype(flesh_cannot, /mob/living/simple_animal))
				final_damage *= simplemob_coeff
			flesh_cannot.deal_damage(final_damage, damage_type, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
			if(ispath(status_inflicted_type)) // sanity check in case someone removes the status from this
				flesh_cannot.apply_status_effect(status_inflicted_type)
			flesh_cannot.visible_message(span_danger("[flesh_cannot] is trapped by an array of thin [damage_type] lines!"), span_userdanger("You're trapped by an array of thin [damage_type] lines!"))

	// Target is a mob.
	else if(istype(unfortunate, /mob/living))
		var/mob/living/gremlin = unfortunate

		DisplayVFX(gremlin, appropiate_color)

		// Calculate damage
		var/final_damage = thinline_damage
		if(damage_type == PALE_DAMAGE)
			final_damage *= thinline_pale_damage_coeff
		if(istype(gremlin, /mob/living/simple_animal))
			final_damage *= simplemob_coeff
		gremlin.deal_damage(final_damage, damage_type, source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))

		if(ispath(status_inflicted_type)) // sanity check in case someone removes the status from this
			gremlin.apply_status_effect(status_inflicted_type)
		gremlin.visible_message(span_danger("[gremlin] is trapped by an array of thin [damage_type] lines!"), span_userdanger("You're trapped by an array of thin [damage_type] lines!"))
		playsound(gremlin, 'sound/magic/arbiter/thinline_hit.ogg', 75, FALSE, 6)

	addtimer(CALLBACK(src, PROC_REF(LineFollowup), unfortunate, user, appropiate_color), 1.2 SECONDS)

// This is the mini-Thick Line that we shoot after the Thin Line. It is guaranteed to hit and has no AoE.
/obj/effect/proc_holder/spell/pointed/birdcage/proc/LineFollowup(target, mob/caster, appropiate_color)
	if((!target) || (!caster))
		return
	var/turf/start_turf = get_turf(caster)
	playsound(caster, 'sound/magic/arbiter/thickline_cast.ogg', 60)
	caster.visible_message(span_danger("[caster] fires a [damage_type] line at [target]!"))
	var/datum/beam/our_line = start_turf.Beam(get_turf(target), "thick_line", time = 2 SECONDS)
	our_line.visuals.color = appropiate_color
	our_line.visuals.transform *= 1.3

	if(istype(target, /obj/vehicle/sealed/mecha))
		var/obj/vehicle/sealed/mecha/tin_can = target // Targeted mech
		if(!tin_can)
			return
		var/mob/living/flesh_cannot

		if(length(tin_can.occupants) > 0)
			flesh_cannot = pick(tin_can.occupants) // Goofball inside the mech

		// Deal damage to mech
		tin_can.take_damage(line_damage * mech_damage_coeff, damage_type)
		playsound(tin_can, 'sound/magic/arbiter/pin.ogg', 100, FALSE, 8)
		// Big slice VFX
		var/obj/effect/temp_visual/dir_setting/slash/temp = new(get_turf(tin_can))
		temp.dir = pick(GLOB.alldirs)
		temp.transform = temp.transform * 2
		temp.color = appropiate_color
		// If we managed to find the occupant, deal 75% damage to them too.
		if(flesh_cannot)
			var/final_damage = line_damage * 0.75
			if(damage_type == PALE_DAMAGE)
				final_damage *= line_pale_damage_coeff
			if(istype(flesh_cannot, /mob/living/simple_animal))
				final_damage *= simplemob_coeff
			flesh_cannot.deal_damage(final_damage, damage_type, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))

	// Target is a mob.
	else if(istype(target, /mob/living))
		var/mob/living/gremlin = target

		var/final_damage = line_damage
		if(damage_type == PALE_DAMAGE)
			final_damage *= line_pale_damage_coeff
		if(istype(gremlin, /mob/living/simple_animal))
			final_damage *= simplemob_coeff
		gremlin.deal_damage(final_damage, damage_type, source = caster, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		playsound(gremlin, 'sound/magic/arbiter/pin.ogg', 100, FALSE, 8)
		// Big slice VFX
		var/obj/effect/temp_visual/dir_setting/slash/temp = new(get_turf(gremlin))
		temp.dir = pick(GLOB.alldirs)
		temp.transform = temp.transform * 2
		temp.color = appropiate_color

// This displays the Thin Line overlay on the target, accounting for where their icon's center actually is
/obj/effect/proc_holder/spell/pointed/birdcage/proc/DisplayVFX(atom/our_target, appropiate_color)
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

// Will only target a. mob/living that aren't in our factions and are alive, or b. mechs like Rhinos. Since this has aim assist, it will find these things in a turf we click on too.
/obj/effect/proc_holder/spell/pointed/birdcage/can_target(atom/target, mob/user, silent)
	if((!istype(target, /mob/living)) && (!istype(target, /obj/vehicle/sealed/mecha)))
		return FALSE

	var/mob/living/our_target = target
	if(istype(our_target))
		if((user.faction_check_mob(our_target, TRUE)) || (our_target.stat >= DEAD))
			return FALSE
	. = ..()

// Lasts less than regular Chain and doesn't show the Chain overlay when being applied
/datum/status_effect/arbiter_chain/birdcage
	duration = 3 SECONDS
	should_show_chain_overlay = FALSE
