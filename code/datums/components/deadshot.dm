/**
 * Gives whoever holds the parent gun a Deadshot action. Use it, then click a mob to lock on.
 * After lock_time the gun fires one shot that only hits the locked target, deals damage_mult
 * times its normal damage and flies at shot_speed. The gun cannot fire while locking on.
 * Add it with AddComponent(/datum/component/deadshot) in the gun's Initialize().
 */
/datum/component/deadshot
	var/lock_time
	var/cooldown_time
	var/damage_mult
	var/shot_speed
	var/datum/action/deadshot/action
	/// The mob currently holding the gun and owning the action
	var/mob/living/holder
	/// Waiting for the holder to click a target
	var/aiming = FALSE
	var/mob/living/locked_target
	var/datum/beam/lock_beam
	/// The gunpoint reticle shown on the locked target
	var/obj/effect/overlay/gunpoint_effect/lock_marker
	var/lock_timer
	/// The next projectile the gun fires is the deadshot
	var/firing = FALSE
	var/next_use = 0

/datum/component/deadshot/Initialize(lock_time = 2 SECONDS, cooldown_time = 5 SECONDS, damage_mult = 4, shot_speed = 0.1)
	if(!isgun(parent))
		return COMPONENT_INCOMPATIBLE
	src.lock_time = lock_time
	src.cooldown_time = cooldown_time
	src.damage_mult = damage_mult
	src.shot_speed = shot_speed
	action = new(parent)

/datum/component/deadshot/Destroy(force, silent)
	. = ..() // Unregisters from the gun first, which still needs the action
	QDEL_NULL(action)

/datum/component/deadshot/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(OnEquipped))
	RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(OnDropped))
	RegisterSignal(parent, COMSIG_GUN_FIRED, PROC_REF(OnGunFired))
	// Admins can add the component to a gun that is already in someone's hand
	var/obj/item/gun/gun = parent
	if(isliving(gun.loc))
		var/mob/living/carrier = gun.loc
		if(carrier.is_holding(gun))
			SetHolder(carrier)

/datum/component/deadshot/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_EQUIPPED, COMSIG_ITEM_DROPPED, COMSIG_GUN_FIRED))
	ClearHolder()

/datum/component/deadshot/proc/OnEquipped(datum/source, mob/equipper, slot)
	SIGNAL_HANDLER
	if(slot == ITEM_SLOT_HANDS && isliving(equipper))
		SetHolder(equipper)
	else
		ClearHolder()

/datum/component/deadshot/proc/OnDropped(datum/source, mob/user)
	SIGNAL_HANDLER
	ClearHolder()

/datum/component/deadshot/proc/SetHolder(mob/living/user)
	if(holder == user)
		return
	ClearHolder()
	holder = user
	action.Grant(user)

/datum/component/deadshot/proc/ClearHolder()
	CancelLock()
	if(holder)
		action.Remove(holder)
	holder = null

/// Called by the action button. Turns aiming on, or turns it off and cancels any lock in progress.
/datum/component/deadshot/proc/ToggleAim(mob/living/user)
	if(aiming || locked_target)
		if(locked_target)
			playsound(get_turf(user), 'code/modules/gunpoint/sound/targetoff.ogg', 50, TRUE)
		CancelLock()
		to_chat(user, span_notice("You lower [parent] and stop lining up a deadshot."))
		return
	if(user.get_active_held_item() != parent)
		to_chat(user, span_warning("You need [parent] in your active hand."))
		return
	aiming = TRUE
	RegisterSignal(user, COMSIG_MOB_CLICKON, PROC_REF(OnClick))
	action.SetActive(TRUE)
	to_chat(user, span_notice("You line up a deadshot. Click a target to lock on."))

/datum/component/deadshot/proc/StopAiming()
	aiming = FALSE
	action.SetActive(FALSE)
	if(holder)
		UnregisterSignal(holder, COMSIG_MOB_CLICKON)

/// While aiming, a click picks the target. While locked on, clicks with the gun are blocked.
/datum/component/deadshot/proc/OnClick(mob/living/user, atom/clicked, params)
	SIGNAL_HANDLER
	if(user.get_active_held_item() != parent)
		return
	if(locked_target)
		return COMSIG_MOB_CANCEL_CLICKON
	if(!isliving(clicked) || clicked == user)
		to_chat(user, span_warning("You need to lock onto a living target."))
		return COMSIG_MOB_CANCEL_CLICKON
	StartLock(user, clicked)
	return COMSIG_MOB_CANCEL_CLICKON

/datum/component/deadshot/proc/StartLock(mob/living/user, mob/living/target)
	aiming = FALSE
	locked_target = target
	RegisterSignal(target, COMSIG_PARENT_QDELETING, PROC_REF(CancelLock))
	var/datum/beam/deadshot/beam = new(user, target, 'icons/effects/beam.dmi', "1-full", lock_time, INFINITY, /obj/effect/ebeam/deadshot)
	beam.fade_start = world.time
	beam.fade_time = lock_time
	INVOKE_ASYNC(beam, TYPE_PROC_REF(/datum/beam, Start))
	lock_beam = beam
	lock_marker = new
	target.vis_contents += lock_marker
	playsound(get_turf(user), 'code/modules/gunpoint/sound/targeton.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] locks [parent] onto [target]!"), span_notice("You lock onto [target]. Hold steady..."))
	to_chat(target, span_userdanger("[user] has you in [user.p_their()] sights!"))
	lock_timer = addtimer(CALLBACK(src, PROC_REF(FireDeadshot), user), lock_time, TIMER_STOPPABLE)

/datum/component/deadshot/proc/CancelLock()
	SIGNAL_HANDLER
	if(lock_timer)
		deltimer(lock_timer)
		lock_timer = null
	QDEL_NULL(lock_beam)
	if(locked_target)
		locked_target.vis_contents -= lock_marker
		UnregisterSignal(locked_target, COMSIG_PARENT_QDELETING)
		locked_target = null
	QDEL_NULL(lock_marker)
	StopAiming()

/// Fires through the gun's normal afterattack so pins, two-handing and role bans still apply.
/datum/component/deadshot/proc/FireDeadshot(mob/living/user)
	lock_timer = null
	var/mob/living/target = locked_target
	CancelLock()
	if(target.stat == DEAD || target.z != user.z)
		to_chat(user, span_warning("You lose your lock on [target]."))
		return
	var/obj/item/gun/gun = parent
	gun.semicd = FALSE // The lock-on replaces the gun's normal fire delay
	firing = TRUE
	gun.afterattack(target, user, FALSE)
	firing = FALSE

/// Upgrades the chambered projectile right before the gun launches it.
/datum/component/deadshot/proc/OnGunFired(obj/item/gun/source, mob/living/user, atom/target, params, zone_override)
	SIGNAL_HANDLER
	if(!firing)
		return
	firing = FALSE
	var/obj/projectile/shot = source.chambered?.BB
	if(!shot)
		return
	next_use = world.time + cooldown_time
	action.UpdateButtonIcon(status_only = TRUE)
	addtimer(CALLBACK(action, TYPE_PROC_REF(/datum/action, UpdateButtonIcon), TRUE), cooldown_time)
	shot.damage *= damage_mult
	shot.speed = shot_speed
	shot.projectile_phasing = PASSMOB // Passes through every mob...
	shot.phasing_ignore_direct_target = TRUE // ...except the locked target
	shot.projectile_piercing = NONE

/datum/action/deadshot
	name = "Deadshot"
	desc = "Lock onto a target, then fire one fast, heavy shot that only hits them."
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_HANDS_BLOCKED|AB_CHECK_IMMOBILE
	icon_icon = 'icons/mob/actions/actions_ability.dmi'
	button_icon_state = "deadshot"
	/// Aiming or locked on; shows the spell_template frame
	var/active = FALSE

/datum/action/deadshot/Trigger()
	. = ..()
	if(!.)
		return
	var/datum/component/deadshot/deadshot = target.GetComponent(/datum/component/deadshot)
	deadshot.ToggleAim(owner)

/// Greyed out like other actions while the deadshot is on cooldown.
/datum/action/deadshot/IsAvailable()
	. = ..()
	if(!.)
		return
	var/datum/component/deadshot/deadshot = target.GetComponent(/datum/component/deadshot)
	return world.time >= deadshot.next_use

/datum/action/deadshot/ApplyIcon(atom/movable/screen/movable/action_button/current_button, force = FALSE)
	. = ..()
	var/mutable_appearance/frame = mutable_appearance('icons/mob/actions/actions_abnormality.dmi', "spell_template")
	current_button.cut_overlay(frame)
	if(active)
		current_button.add_overlay(frame)

/datum/action/deadshot/proc/SetActive(new_active)
	active = new_active
	UpdateButtonIcon()

/obj/effect/ebeam/deadshot
	color = "#FFF59A"

/// Fades in from 0 to 255 alpha over fade_time. Segments are rebuilt whenever either end moves,
/// so each redraw picks up the fade from the time already elapsed.
/datum/beam/deadshot
	var/fade_start = 0
	var/fade_time = 0

/datum/beam/deadshot/Draw()
	. = ..()
	var/elapsed = world.time - fade_start
	var/remaining = fade_time - elapsed
	var/start_alpha = remaining > 0 ? round(255 * elapsed / fade_time) : 255
	for(var/obj/effect/ebeam/segment as anything in elements)
		segment.alpha = start_alpha
		if(remaining > 0)
			animate(segment, alpha = 255, time = remaining)
