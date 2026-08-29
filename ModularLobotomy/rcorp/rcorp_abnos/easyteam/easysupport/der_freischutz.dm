//Support because hes a pure backliner reliant on his portals
/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz
	name = "Der Freischutz"
	desc = "A tall man adorned in grey, gold, and regal blue. His aim is impeccable. His sights are focused on you, a single shot would leave one crippled."
	maxHealth = 900
	health = 900
	ranged = TRUE
	minimum_distance = 10
	retreat_distance = 2
	move_to_delay = 6
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 2, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.5, FIRE = 0.5)
	vision_range = 28 // Fit for a marksman.
	aggro_vision_range = 40
	del_on_death = FALSE
	original_abno = /mob/living/simple_animal/hostile/abnormality/der_freischutz

	var/can_move = TRUE
	var/already_fled = FALSE
	var/bullet_cooldown
	var/bullet_cooldown_time = 7 SECONDS
	var/bullet_fire_delay = 1.5 SECONDS
	var/bullet_max_range = 200
	var/bullet_damage = 200 //This is to account for the fact his attack is highly choreographed and cannot pierce walls
	var/breach_portals_amount = 7
	var/list/portals = list()
	var/zoomed = FALSE
	var/max_portals = 7
	var/current_portal_index = 0
	var/portal_cooldown
	var/portal_cooldown_time = 5 SECONDS
	var/portal_assault_firerate = 2 SECONDS // 2 seconds between each shot of the portal assault.
	var/portal_assault_timer = 0

	//PLAYABLES ATTACKS (action in this case)
	attack_action_types = list(
		/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom,
		/datum/action/cooldown/rca_switch_portals,
		/datum/action/cooldown/rca_remove_portal)

	abno_additional_instructions = "<h1>You are Der Freischutz, A Support Role Abnormality.</h1><br>\
		<b>|Magic Bullet|: When you attack while not scoped in, there will be a 1.5 second delay before you fire a Magic Bullet. \
		The Magic Bullet deals BLACK damage and pieces through mobs. After firing a Magic Bullet, there is a 7 second cooldown between you can fire another one.\
		Hitting your own portals will instantly kill them. <br>\
		<br>\
		|Devil's Contract|: Using the Sniper Sights ability on the top left of your screen you are able to increase your view range, see through walls and gain the ability to place down 'Magic Portals' \
		There is a 10 second cooldown between placing down portals, you can have a max of 7 portals and you can't place them in R-Corp's base or on dense terrain. \
		If you can't place down a portal, you will fire your Magic Bullet instead.<br>\
		<br>\
		|Devil's Sights|: You are able view through your portals using your 'Portal View' button on the top left of your screen, \
		Or you can use a hotkey. (Which is Space by default). When you use that ability, You will be able to toggle your view between the portals you have created. \
		While viewing through a portal, you will be able to cause them to fire towards any target you click on. They deal 25% less damage than your normal bullet, but each portal has their own cooldown between firing. \
		Also, you are able to destroy your own portals while viewing though them using your 'Removing Portal' ability, Or you can use a hotkey. (Which is E by default).<br>\
		<br>\
		|Dark Flame|: Whenever you or your portals hit a target inflict 7 stacks of |Dark Flame|. \
		Targets affected will take WHITE and BURN damage equal to stacks of |Dark Flame| every 5 seconds until effect expires. \
		You may have up to 50 stacks on one target, applying new stacks refreshes duration.</b>"

/datum/action/cooldown/rca_switch_portals
	name = "Portal View"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "freicircle2"
	desc = "Cycle through your currently active portals, to fire through them."
	cooldown_time = 10
	var/original_sight

/datum/action/cooldown/rca_switch_portals/Grant(mob/living/L)
	. = ..()
	original_sight = owner.sight

/datum/action/cooldown/rca_switch_portals/Trigger()
	if(!..())
		return FALSE
	if (!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz))
		return
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/F = owner
	if(F.zoomed)
		return

	if(F.current_portal_index != 0)
		var/mob/living/simple_animal/hostile/rca_der_freis_portal/P = F.portals[F.current_portal_index]
		P.StopSpin()

	F.current_portal_index = (F.current_portal_index + 1) % (F.portals.len + 1)
	if (F.current_portal_index == 0)
		F.client.eye = F
		F.sight = original_sight
	else
		F.client.eye = F.portals[F.current_portal_index]
		F.sight |= SEE_TURFS | SEE_MOBS | SEE_THRU | SEE_OBJS
		F.regenerate_icons()
		var/mob/living/simple_animal/hostile/rca_der_freis_portal/P = F.portals[F.current_portal_index]
		P.StartSpin()




/datum/action/cooldown/rca_remove_portal
	name = "Removing Portal"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "freicircle1"
	desc = "Remove the current portal you are currently viewing through."
	cooldown_time = 10
	var/original_sight

/datum/action/cooldown/rca_remove_portal/Grant(mob/living/L)
	. = ..()
	original_sight = owner.sight

/datum/action/cooldown/rca_remove_portal/Trigger()
	if(!..())
		return FALSE
	if (!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz))
		return
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/F = owner
	F.RemovePortal()
	F.sight = original_sight

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom
	name = "Toggle Sniper Sight"
	button_icon_state = "zoom_toggle0"
	chosen_message = span_warning("You activate your sniper sight.")
	button_icon_toggle_activated = "zoom_toggle1"
	toggle_message = span_warning("You deactivate your sniper sight.")
	button_icon_toggle_deactivated = "zoom_toggle0"
	var/zoom_out_amt = 5.5
	var/zoom_amt = 10
	var/original_sight

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom/Grant(mob/living/L)
	. = ..()
	original_sight = owner.sight

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom/proc/ToggleZoom()
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz))
		var/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/F = owner
		F.zoomed = !F.zoomed

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom/Activate()
	if (istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz))
		var/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/F = owner
		if (F.current_portal_index == 0)
			ActivateSignals()
			F.sight |= SEE_TURFS | SEE_MOBS | SEE_THRU
			F.regenerate_icons()
			F.client.view_size.zoomOut(zoom_out_amt, zoom_amt, owner.dir)
			ToggleZoom()
			return ..()
		else
			to_chat(F, "You are currently looking though a portal!")
			return FALSE
	else
		return FALSE

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom/proc/ActivateSignals()
	SIGNAL_HANDLER

	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(Deactivate))
	RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(Rotate))

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom/Deactivate()
	DeactivateSignals()
	owner.sight = original_sight
	owner.regenerate_icons()
	owner.client.view_size.zoomIn()
	ToggleZoom()
	return ..()

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom/proc/DeactivateSignals()
	SIGNAL_HANDLER

	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)

/datum/action/innate/rca_abnormality_attack/toggle/der_freischutz_zoom/proc/Rotate(old_dir, new_dir)
	SIGNAL_HANDLER

	owner.regenerate_icons()
	owner.client.view_size.zoomOut(zoom_out_amt, zoom_amt, new_dir)


/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/proc/RemovePortal(portal)
	var/P = portal
	if (!portal)
		P = portals[current_portal_index]
	portals.Remove(P)
	if(client)
		if(client.eye == P)
			client.eye = src
			current_portal_index = 0
		else
			if (istype(client.eye, /mob/living/simple_animal/hostile/rca_der_freis_portal))
				var/mob/living/simple_animal/hostile/rca_der_freis_portal/P2 = client.eye
				current_portal_index = portals.Find(P2)
	qdel(P)

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire()

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/OpenFire()
	if(!can_act)
		return
	var/turf/T = get_turf(target)
	var/area/A = get_area(T)
	if (zoomed)
		if (portals.len >= max_portals)
			to_chat(src, "Too many portals already!")
		else if (T.density == 1)
			to_chat(src, "Cannot place the portal there. Its to dense!")
		else if (istype(A, /area/city/outskirts/rcorp_base))
			to_chat(src, "Cannot place the portal inside the enemy base!")
		else if(portal_cooldown <= world.time)
			for(var/mob/living/simple_animal/hostile/rca_der_freis_portal/P in T)
				to_chat(src, "Cannot place the portal on top of another")
				return
			portal_cooldown = world.time + portal_cooldown_time
			var/mob/living/simple_animal/hostile/rca_der_freis_portal/P = new /mob/living/simple_animal/hostile/rca_der_freis_portal(T)
			portals.Add(P)
			P.connected_abno = src
			return
		return
	if (current_portal_index > 0)
		var/mob/living/simple_animal/hostile/rca_der_freis_portal/P = portals[current_portal_index]
		P.OpenFire(target)
	else
		if(bullet_cooldown <= world.time)
			PrepareFireBullet(target)

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/proc/IconChange(firing)
	if(firing)
		if(icon == 'ModularLobotomy/_Lobotomyicons/96x64.dmi')
			return
		pixel_x -= 32
		icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
		update_icon()
		return
	if(icon == 'ModularLobotomy/_Lobotomyicons/32x64.dmi')
		return
	pixel_x += 32
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	update_icon()

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/proc/PrepareFireBullet(atom/target)
	bullet_cooldown = world.time + bullet_cooldown_time
	can_act = FALSE
	IconChange(firing = TRUE)
	var/turf/beam_start = get_turf(src)
	var/turf/target_turf = get_ranged_target_turf_direct(src, target, bullet_max_range, 0)
	var/turf/beam_end = target_turf
	var/list/turfs_to_check = getline(beam_start, target_turf)
	playsound(beam_start, 'sound/abnormalities/freischutz/prepare.ogg', 35, 0, 20)
	face_atom(target)
	for(var/turf/T in turfs_to_check)
		if(T.density)
			beam_end = T
			break
	new /datum/beam(beam_start.Beam(beam_end, "magic_bullet", time = bullet_fire_delay))
	SLEEP_CHECK_DEATH(bullet_fire_delay)
	FireBullet(target, beam_start, beam_end)

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/proc/FireBullet(atom/target, turf/start_turf, turf/end_turf)
	playsound(start_turf, 'sound/abnormalities/freischutz/shoot.ogg', 35, 0, 20)
	var/obj/projectile/ego_bullet/rca_ego_magicbullet/B = new(start_turf) //80 BLACK damage
	B.starting = start_turf
	B.firer = src
	B.fired_from = start_turf
	B.yo = end_turf.y - start_turf.y
	B.xo = end_turf.x - start_turf.x
	B.original = end_turf
	B.preparePixelProjectile(end_turf, start_turf)
	B.range = bullet_max_range
	B.damage = bullet_damage //the 80 BLACK of earlier is now 200
	B.fire()
	new /datum/beam(start_turf.Beam(end_turf, "magic_bullet_tracer", time = 3 SECONDS))
	IconChange(firing = FALSE)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/bullet_act(obj/projectile/P)
	var/firer = P.firer
	if(firer == src || LAZYFIND(portals, firer))
		return
	. = ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/proc/fire_magic_bullet(target = pick(GLOB.xeno_spawn), freidir = pick(EAST,WEST))
	IconChange(firing = TRUE)
	var/offset = -12
	var/list/portal_effects = list()
	var/turf/T = src.loc
	var/turf/barrel = locate(T.x + 2, T.y + 1, T.z)
	var/turf/tpos = target
	if (freidir == EAST)
		T = locate(tpos.x - 5, tpos.y, tpos.z)
	else if (freidir == WEST)
		T = locate(tpos.x + 5, tpos.y, tpos.z)
	else if (freidir == SOUTH)
		T = locate(tpos.x, tpos.y + 5, tpos.z)
	else
		T = locate(tpos.x, tpos.y - 5, tpos.z)
	playsound(T, 'sound/abnormalities/freischutz/prepare.ogg', 100, 0, 20)
	playsound(src.loc, 'sound/abnormalities/freischutz/prepare.ogg', 100, 0)
	for(var/i=1, i<5, i++)
		var/obj/effect/frei_magic/P = new(barrel)
		P.dir = EAST
		P.icon_state = "freicircle[i]"
		P.update_icon()
		P.pixel_x += offset
		portal_effects += P
		var/obj/effect/frei_magic/PX = new(T)
		PX.dir = freidir
		PX.icon_state = "freicircle[i]"
		PX.update_icon()
		if (freidir == EAST)
			PX.pixel_x += offset
		else if (freidir == WEST)
			PX.pixel_x -= offset
		else if (freidir == SOUTH)
			PX.pixel_y -= offset
		else
			PX.pixel_y += offset
		offset += 8
		portal_effects += PX
		sleep(6)
		if(i != 4)
			continue
		else
			var/obj/effect/magic_bullet/B = new(T)
			playsound(get_turf(src), 'sound/abnormalities/freischutz/shoot.ogg', 100, 0, 20)
			B.dir = freidir
			addtimer(CALLBACK(B, TYPE_PROC_REF(/obj/effect/magic_bullet, moveBullet)), 0.1)
			IconChange(firing = FALSE)
			for(var/obj/effect/frei_magic/Port in portal_effects)
				Port.fade_out()
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/death()
	if(portal_assault_timer)
		deltimer(portal_assault_timer)
	for(var/mob/living/simple_animal/hostile/rca_der_freis_portal/P in portals)
		P.death(FALSE)
	density = FALSE
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()


/mob/living/simple_animal/hostile/rca_der_freis_portal
	name = "magic portal"
	desc = "A strange blue portal... You feel like you are being watched though it. Best to run past or destroy it altogether."
	icon = 'icons/effects/effects.dmi'
	icon_state = "freicircle3"
	icon_living = "freicircle3"
	var/icon_selected = "freicircle2"
	maxHealth = 1000
	health = 1000
	can_patrol = FALSE
	wander = 0
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	ranged = TRUE
	ranged_cooldown_time = 1 SECONDS
	obj_damage = 0
	del_on_death = TRUE
	alpha = 0
	density = FALSE
	environment_smash = ENVIRONMENT_SMASH_NONE
	death_message = "fades away..."
	AIStatus = AI_OFF
	var/bullet_cooldown
	var/bullet_cooldown_time = 7 SECONDS
	var/bullet_fire_delay = 1.5 SECONDS
	var/bullet_max_range = 100
	var/bullet_damage = 150
	var/assault_timer = 0

	var/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/connected_abno
	var/datum/component/orbiter/self_orbiter

/mob/living/simple_animal/hostile/rca_der_freis_portal/Login()
	. = ..()
	to_chat(src, "<h1>You are Magic Portal, A Der Freischutz Minion.</h1><br>\
		<b>|Magic Bullet|: When attacking you will perform a ranged attack that pierces all living targets dealing 150 BLACK damage and applying 7 stacks of |Dark Flame|. \
		Piercing does not apply to mechs, if hitting another portal you will kill them instantly. <br>\
		<br>\
		|Dark Flame|: Whenever you hit a target inflict 7 stacks of |Dark Flame|. \
		Targets affected will take WHITE and BURN damage equal to stacks of |Dark Flame| every 5 seconds until effect expires. \
		You may have up to 50 stacks on one target, applying new stacks refreshes duration.</b>")

/mob/living/simple_animal/hostile/rca_der_freis_portal/Initialize()
	. = ..()
	animate(src, alpha = 255, time = 6)
	playsound(get_turf(src), 'sound/abnormalities/freischutz/portal.ogg', 100, 0, 10)

/mob/living/simple_animal/hostile/rca_der_freis_portal/death()
	if(assault_timer)
		deltimer(assault_timer)
	connected_abno.RemovePortal(src)
	..()

/mob/living/simple_animal/hostile/rca_der_freis_portal/Move()
	return FALSE

/mob/living/simple_animal/hostile/rca_der_freis_portal/bullet_act(obj/projectile/P)
	var/firer = P.firer
	if(firer == connected_abno || istype(firer, /mob/living/simple_animal/hostile/rca_der_freis_portal))
		return
	. = ..()

/mob/living/simple_animal/hostile/rca_der_freis_portal/AttackingTarget(atom/attacked_target)
	return OpenFire(attacked_target)

/mob/living/simple_animal/hostile/rca_der_freis_portal/OpenFire(atom/target)
	if(bullet_cooldown <= world.time)
		PrepareFireBullet(target)

/mob/living/simple_animal/hostile/rca_der_freis_portal/proc/PrepareFireBullet(atom/target)
	bullet_cooldown = world.time + bullet_cooldown_time
	var/turf/beam_start = get_turf(src)
	var/turf/target_turf = get_ranged_target_turf_direct(src, target, bullet_max_range, 0)
	var/turf/beam_end = target_turf
	var/list/turfs_to_check = getline(beam_start, target_turf)
	playsound(beam_start, 'sound/abnormalities/freischutz/prepare.ogg', 35, 0, 20)
	face_atom(target)
	for(var/turf/T in turfs_to_check)
		if(T.density)
			beam_end = T
			break
	new /datum/beam(beam_start.Beam(beam_end, "magic_bullet", time = bullet_fire_delay))
	SLEEP_CHECK_DEATH(bullet_fire_delay)
	FireBullet(target, beam_start, beam_end)

/mob/living/simple_animal/hostile/rca_der_freis_portal/proc/FireBullet(atom/target, turf/start_turf, turf/end_turf)
	playsound(start_turf, 'sound/abnormalities/freischutz/shoot.ogg', 35, 0, 20)
	var/obj/projectile/ego_bullet/rca_ego_magicbullet/B = new(start_turf) //80 BLACK damage.
	B.starting = start_turf
	B.firer = src
	B.fired_from = start_turf
	B.yo = end_turf.y - start_turf.y
	B.xo = end_turf.x - start_turf.x
	B.original = end_turf
	B.preparePixelProjectile(end_turf, start_turf)
	B.range = bullet_max_range
	B.damage = bullet_damage //Once again altered, but this time to 150 BLACK
	B.fire()
	new /datum/beam(start_turf.Beam(end_turf, "magic_bullet_tracer", time = 3 SECONDS))

/mob/living/simple_animal/hostile/rca_der_freis_portal/proc/StartSpin()
	icon_state = icon_selected

/mob/living/simple_animal/hostile/rca_der_freis_portal/proc/StopSpin()
	icon_state = icon_living


/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/proc/TriggerPortalView()
	for(var/datum/action/cooldown/rca_switch_portals/A in actions)
		A.Trigger()

/mob/living/simple_animal/hostile/rcorp_abno/easy/der_freischutz/proc/TriggerPortalRemove()
	for(var/datum/action/cooldown/rca_remove_portal/A in actions)
		A.Trigger()

/obj/projectile/ego_bullet/rca_ego_magicbullet
	damage = 70 // Doesnt really matter since we var edit this later

/obj/projectile/ego_bullet/rca_ego_magicbullet/on_hit(atom/target, blocked = FALSE, pierce_hit)
	if(istype(target, /mob/living/simple_animal/hostile/der_freis_portal))
		var/mob/living/simple_animal/hostile/der_freis_portal/P = target
		P.death()
	else if(istype(target, /mob/living))
		var/mob/living/the_target = target
		the_target.apply_rca_dark_flame(7)
	. = ..()

/* TL;DR its LC_BURN but looks at black armor */
/datum/status_effect/stacking/lc_burn/rca_dark_flame
	id = "rca_dark_flame"
	alert_type = /atom/movable/screen/alert/status_effect/dark_flame
	extinguishable = FALSE

/atom/movable/screen/alert/status_effect/rca_dark_flame
	name = "Dark Flame"
	desc = "Dark flames are scorching your body and mind. Take BURN and WHITE damage multiplied by stacks reduced by BLACK armor until this effect expires."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "dark_flame"

/datum/status_effect/stacking/lc_burn/rca_dark_flame/DealDamage()
	owner.deal_damage(stacks, FIRE, attack_type = (ATTACK_TYPE_STATUS), blocked = owner.run_armor_check(null, BLACK_DAMAGE))
	owner.deal_damage(stacks, WHITE_DAMAGE, attack_type = (ATTACK_TYPE_STATUS), blocked = owner.run_armor_check(null, BLACK_DAMAGE))

//Update burn appearance
/datum/status_effect/stacking/lc_burn/rca_dark_flame/Update_Burn_Overlay(mob/living/owner)
	if(stacks && !(owner.on_fire) && ishuman(owner))
		if(stacks >= 15)
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_generic", -FIRE_LAYER))
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_standing", -FIRE_LAYER))
			owner.add_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_standing", -FIRE_LAYER))
		else
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_standing", -FIRE_LAYER))
			owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_generic", -FIRE_LAYER))
			owner.add_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_generic", -FIRE_LAYER))

/datum/status_effect/stacking/lc_burn/rca_dark_flame/on_remove()
	if(!(owner.on_fire) && ishuman(owner))
		owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_generic", -FIRE_LAYER))
		owner.cut_overlay(mutable_appearance('icons/mob/OnFire.dmi', "darkfire_standing", -FIRE_LAYER))
	..()

//Mob Proc
/mob/living/proc/apply_rca_dark_flame(stacks)
	var/datum/status_effect/stacking/lc_burn/B = src.has_status_effect(/datum/status_effect/stacking/lc_burn/rca_dark_flame)
	if(!B)
		src.apply_status_effect(/datum/status_effect/stacking/lc_burn/rca_dark_flame, stacks)
	else
		B.add_stacks(stacks)
