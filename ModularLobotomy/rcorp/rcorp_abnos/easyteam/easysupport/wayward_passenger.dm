/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward
	name = "Wayward Passenger"
	desc = "A large humanoid with its torso caved open and lined with teeth. Thread-like projections cover its open wounds. It's form seems unstable, watch carefully for any rifts it may open."
	del_on_death = FALSE
	maxHealth = 1200
	health = 1200
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)//lovetown residents LOVE physical pain, so high
	ranged = TRUE
	melee_damage_lower = 20
	melee_damage_upper = 24
	melee_damage_type = RED_DAMAGE
	vision_range = 14
	original_abno = /mob/living/simple_animal/hostile/abnormality/wayward

	abno_additional_instructions = "<h1>You are Wayward Passenger, A Support Role Abnormality.</h1><br>\
		<b>|Dimensional Escape|:</b> You may select one of two abilities to use at range, the first one being your portal.<br>\
		Upon use you will open a portal to the tile you selected then cross that portal yourself, others may cross this portal in it's 3 seconds of existence.<br>\
		<br>\
		<b>|Rip Space|:</b> You may select one of two abilities to use at range, the second one being your dash.<br>\
		Upon using the dash you will initiate a 2 second windup.<br>\
		When windup is complete you will perform a 3 tile wide dash in the direction you selected."

	attack_action_types = list(
		/datum/action/innate/rca_abnormality_attack/wayward_tele,
		/datum/action/innate/rca_abnormality_attack/wayward_dash,
	)

	//teleport vars
	var/teleport_cooldown
	var/teleport_cooldown_time = 10 SECONDS
	//dash vars
	var/charging = FALSE
	var/can_dash = FALSE
	var/dash_cooldown = 0
	var/dash_cooldown_time = 4 SECONDS
	var/obj/effect/proc_holder/ability/aimed/rca_dash/wayward/ourdash

/obj/effect/proc_holder/ability/aimed/rca_dash/wayward
	name = "wayward dash"
	dash_speed =  1
	dash_damage = 60
	dash_range = 6
	windup_delay = 2 SECONDS
	cooldown_time = 4 SECONDS
	env_breaking = TRUE

/obj/effect/proc_holder/ability/aimed/rca_dash/wayward/TurfEffects(turf/T, mob/living/ourthing)
	playsound(T,"sound/abnormalities/thunderbird/tbird_peck.ogg", rand(50, 70), 1)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			FlickOnAtom(U,'icons/effects/effects.dmi',"smash",5)
		var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, flags = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)//damage applied to targets in range
			if(!ourthing.faction_check_mob(L))
				L.visible_message(span_boldwarning("[ourthing] slices through [L]!"), span_userdanger("[ourthing] rushes past you, searing you with its blades!"))
				if(!flicks)
					playsound(U, 'sound/abnormalities/wayward_passenger/attack2.ogg', 75, 1)
					FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
					flicks = TRUE
		for(var/obj/vehicle/sealed/mecha/V in new_hits)
			V.visible_message(span_boldwarning("[ourthing] slices through [V]!"))
			to_chat(V.occupants, span_userdanger("[ourthing] rushes past you, searing your mech with its blades!"))
			playsound(U, 'sound/abnormalities/wayward_passenger/attack2.ogg', 75, 1)
			if(!flicks)
				FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
				flicks = TRUE
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/wayward/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/rcorp_abno/easy/wayward))
		return
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/abno = user
	ToggleAct(abno,TRUE)
	abno.endCharge()

/datum/action/innate/rca_abnormality_attack/wayward_tele
	name = "Teleport"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "rift"
	chosen_message = span_colossus("You will now teleport to your target.")
	chosen_attack_num = 1

/datum/action/innate/rca_abnormality_attack/wayward_dash
	name = "Dash"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "plasmasoul"
	chosen_message = span_colossus("You will now charge towards your target.")
	chosen_attack_num = 2

//*** Simple mob procs ***
/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/death(gibbed)
	playsound(src, 'sound/effects/limbus_death.ogg', 100, 1)
	icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/he.dmi'
	pixel_x = -16
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/Initialize()
	. = ..()
	ourdash = new()
	icon_state = "wayward_breach"
	playsound(src, 'sound/abnormalities/thunderbird/tbird_zombify.ogg', 45, FALSE, 5)//this is the sound effect used for Tomerry in the lovetown reception

/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/OpenFire()
	if(client)
		switch(chosen_attack)
			if(1)
				if(!LAZYLEN(get_path_to(src,target, TYPE_PROC_REF(/turf, Distance), 0, 30)))
					to_chat(src, span_notice("Invalid target."))
					return
				TryTeleport(get_turf(target))
			if(2)
				Dash(target)
		return

	if(dash_cooldown <= world.time && can_dash)
		Dash(target)

//*** Teleport code ***//
/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/proc/TryTeleport(turf/teleport_target)//argument is used when the proc is called with a client
	if(teleport_cooldown > world.time || !can_act)
		return FALSE
	teleport_cooldown = world.time + teleport_cooldown_time//so it doesn't get called twice by life()
	icon_state = "wayward_tpstart"
	playsound(src, 'sound/abnormalities/wayward_passenger/teleport.ogg', 600, 1)
	can_act = FALSE
	LoseTarget()
	SLEEP_CHECK_DEATH(4)
	playsound(src, 'sound/abnormalities/wayward_passenger/teleport2.ogg', 100, 1)
	density = FALSE
	var/obj/effect/portal/abno_warp/P1 = new(get_turf(src))
	forceMove(teleport_target)
	var/obj/effect/portal/abno_warp/P2 = new(teleport_target)
	P1.link_portal(P2)
	P2.link_portal(P1)
	icon_state = "wayward_tpend"
	playsound(src, 'sound/abnormalities/wayward_passenger/teleport2.ogg', 100, 1)
	SLEEP_CHECK_DEATH(2 SECONDS) //2 seconds to teleport
	density = TRUE
	SLEEP_CHECK_DEATH(4)
	can_act = TRUE
	icon_state = "wayward_breach"
	can_dash = TRUE

/*** Dash code ***/
/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/proc/Dash(target)
	if(charging || dash_cooldown > world.time)
		return
	if(!can_act)
		return
	can_dash = FALSE
	update_icon()//TODO: dash sprite
	dash_cooldown = world.time + dash_cooldown_time
	charging = TRUE
	playsound(src, 'sound/abnormalities/wayward_passenger/attack1.ogg', 300, 1)
	icon_state = "wayward_charge"
	ourdash.Perform(target,src)

/mob/living/simple_animal/hostile/rcorp_abno/easy/wayward/proc/endCharge()
	playsound(src, 'sound/abnormalities/thunderbird/tbird_bolt.ogg', 75, 1)
	charging = FALSE
	icon_state = "wayward_breach"
	can_dash = TRUE
	update_icon()

/obj/effect/portal/rca_abno_warp
	name = "dimensional rift"
	desc = "A glowing, pulsating rift through space and time. You may cross this rift but so too may others."
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_state = "rift_big"
	base_pixel_x = -8
	pixel_x = -8
	teleport_channel = TELEPORT_CHANNEL_FREE

/obj/effect/portal/rca_abno_warp/Crossed(atom/movable/AM, oldloc, force_stop = 0)
	if(istype(AM, /mob/living/simple_animal/hostile/rcorp_abno/easy/wayward))
		return
	playsound(src, 'sound/abnormalities/wayward_passenger/teleport2.ogg', 50, TRUE)
	return ..()

/obj/effect/portal/rca_abno_warp/Initialize()
	QDEL_IN(src, 3 SECONDS)
	return ..()
