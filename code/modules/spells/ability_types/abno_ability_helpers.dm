/*
* Look i know its strange to keep them all here
* but this makes it easy to sift through those
* normal baseline procs and our warped procs.
* -IP
*/

//Easy way of handling immobalization for humans and mobs.
/obj/effect/proc_holder/ability/proc/ToggleAct(mob/living/dude, status = FALSE)
	if(ishostile(dude))
		var/mob/living/simple_animal/hostile/hos = dude
		hos.can_act = status

//Flicks a overlay on a object. Seemed like a cheaper option for stationary effects.
/obj/effect/proc_holder/ability/proc/FlickOnAtom(atom/A, icon_file, icon_file_state, flicktime = 10)
	var/image/effect_flick = image(icon_file,A,icon_file_state,CLOSED_FIREDOOR_LAYER)
	effect_flick.plane = GAME_PLANE
	effect_flick.appearance_flags = APPEARANCE_UI_IGNORE_ALPHA
	flick_overlay_view(effect_flick, A, flicktime)
	return effect_flick

//Returns true if the identifier is in the list, false if not and automatically adds.
/obj/effect/proc_holder/ability/proc/HasIdentList(atom/curwibble)
	var/identifer = AddIdentifier(curwibble)
	if(identifer in hit_identifiers)
		return TRUE
	hit_identifiers += identifer
	return FALSE

//Unique interactions with simplemobs such as var alterations
/obj/effect/proc_holder/ability/proc/AbnoInteraction(mob/living/user)
	return

//If this ability uses abil_charges for their attacks then this is how its increased or decreased
/obj/effect/proc_holder/ability/proc/AlterCharge(amt)
	if(abil_charges == -1)
		return
	cooldown = 0
	abil_charges += amt

//Checks if they are a friend for the LCL gamemode
/obj/effect/proc_holder/ability/proc/IsLimbusFriend(mob/living/simple_animal/hostile/limbus_abno/L, mob/living/trg)
	if(!istype(L, /mob/living/simple_animal/hostile/limbus_abno))
		return
	return L.IsFriend(trg)

//Checks if they are friends with the trg.
/obj/effect/proc_holder/ability/proc/IsSameFaction(mob/living/L, mob/living/trg)
	if(!istype(L, /mob/living) || !istype(trg, /mob/living))
		return
	return L.faction_check_mob(trg)

//Deals damage to thing no matter what it is.
/obj/effect/proc_holder/ability/proc/DamageThing(atom/thing, dam = 0, dam_type = RED_DAMAGE, dam_source = null,  attack_direction = null, thing_flags = null, thing_attack_type = null, mech_damage = 0, break_not_destroy = FALSE,)
	if(!thing || !dam)
		return
	if(isliving(thing))
		var/mob/living/L = thing
		L.deal_damage(dam, dam_type, source = dam_source, flags = (DAMAGE_FORCED), attack_type = thing_attack_type)

	if(isobj(thing))
		var/obj/O = thing
		var/structure_damage = (ismecha(O) && mech_damage) ? mech_damage : dam
		if(break_not_destroy)
			if(O.obj_integrity - structure_damage <= 0)
				return
			structure_damage = O.obj_integrity - 1
		if(ismecha(O))
			var/obj/vehicle/sealed/mecha/M = O
			M.take_damage(structure_damage, dam_type, FALSE, attack_direction)
			return
		O.take_damage(structure_damage, dam_type)
