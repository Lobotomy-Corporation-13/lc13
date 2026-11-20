/*
The file for Another Day at Work's taboo mechanics.

For a quick summary here, the way it is supposed to work is that when
Another Day takes damage through PostDamageReaction, it will apply a few negative effects on them.

1. It will add a workload status effect, which will slow down, blur, and sleep the target at different stacks.
Basically trying my best to make it as inconvenient as possible to attack them while they have not found the boss's name.
2. It will deal WHITE damage to the attacker, that ignores brute sanity for the sake of working in Neo City.
3. It will deal a smaller amount of SP damage to all targets within its territory.

Below that, you can also find the passive damage it deals once it reaches it's gimmick stage (3).

Lastly, you can find the Hanging gimmick, where once a target's sanity drops to or below the hang threshold,
it will summon a tie noose to start hanging them. Which will result in a small animation of them swaying
from side to side once they are dead after taking OXY damage repeatedly.
*/

//Make sure to punish anyone who hits the distortion, no matter how they hit them.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	Taboo(source)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/Taboo(mob/living/attacker)
	if(!istype(attacker) || attacker == src || stat == DEAD)
		return
	CancelUndistort()
	if(next_taboo[attacker] > world.time)
		return
	next_taboo[attacker] = world.time + taboo_cooldown
	//Said the bosses name? Well, the taboo will not be triggered!
	if(gives_workload)
		AddWorkload(attacker)
	Sulk(attacker)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/AddWorkload(mob/living/L)
	var/datum/status_effect/stacking/distortion_workload/W = L.has_status_effect(/datum/status_effect/stacking/distortion_workload)
	if(W)
		W.add_stacks(1)
		return
	W = L.apply_status_effect(/datum/status_effect/stacking/distortion_workload, 1)
	if(W)
		W.SetDistortion(src)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/Sulk(mob/living/attacker)
	var/line = pick(sulk_lines)
	for(var/mob/living/carbon/human/H in HumansInside())
		MindSpeak(H, line)
		if(H != attacker)
			WearDown(H, sulk_sanity)
	Mutter(line)
	if(ishuman(attacker))
		var/mob/living/carbon/human/victim = attacker
		WearDown(victim, sulk_damage * (1 - victim.getarmor(null, WHITE_DAMAGE) / 100))
		new /obj/effect/temp_visual/damage_effect/white(get_turf(victim))

// Wear down a human's sanity, stopping at the hang threshold.
//This is done to reduce human's SP even if they have TRAIT_BRUTESANITY.
//The reason why I want to make it damage SP directly, is due to it feeling more unique, compared to just hanging them when they have low HP.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/WearDown(mob/living/carbon/human/H, amount)
	var/sanity_floor = H.maxSanity * hang_threshold
	if(H.sanityhealth <= sanity_floor)
		return
	H.adjustSanityLoss(min(amount, H.sanityhealth - sanity_floor))

// Workload status effect, where you start gaining slowdown, blurry vision, and sleepiness at the max stack.
/datum/status_effect/stacking/distortion_workload
	id = "distortion_workload"
	alert_type = /atom/movable/screen/alert/status_effect/distortion_workload
	max_stacks = 6
	stack_threshold = 6
	consumed_on_threshold = FALSE
	tick_interval = 1 SECONDS
	overlay_file = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	overlay_state = "another_day_workload_"
	var/mob/living/simple_animal/hostile/distortion/advanced/another_day/distortion
	var/decay_interval = 20 SECONDS
	var/next_decay = 0
	var/sleep_time = 3 SECONDS
	var/asleep_until = 0
	var/blur_per_stack = 2

/atom/movable/screen/alert/status_effect/distortion_workload
	name = "Workload"
	desc = "It is piling up. You could put it down if you stepped away."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "another_day_workload"

/datum/status_effect/stacking/distortion_workload/on_apply()
	. = ..()
	if(!.)
		return
	next_decay = world.time + decay_interval
	InsetOverlay()

/datum/status_effect/stacking/distortion_workload/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/distortion_workload)
	return ..()

/datum/status_effect/stacking/distortion_workload/can_gain_stacks()
	return ..() && world.time >= asleep_until

/datum/status_effect/stacking/distortion_workload/add_stacks(stacks_added)
	var/before = stacks
	. = ..()
	if(QDELETED(src))
		return
	if(stacks > before)
		switch(stacks)
			if(1)
				to_chat(owner, span_warning("A tie coils around your wrist and lets go. Your arms feel heavy."))
			if(2)
				to_chat(owner, span_warning("You can't remember the last time you slept."))
			if(3)
				to_chat(owner, span_warning("The weight of it settles on your shoulders."))
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/distortion_workload, multiplicative_slowdown = max(0, stacks - 2) * 0.5)

/datum/status_effect/stacking/distortion_workload/tick()
	if(!can_have_status())
		qdel(src)
		return
	if(stacks >= 2 && world.time >= asleep_until && owner.eye_blurry < (stacks - 1) * blur_per_stack)
		owner.adjust_blurriness(1)
	var/inside = distortion && distortion.territory.Contains(get_turf(owner))
	if(linked_alert)
		linked_alert.icon_state = inside ? "another_day_workload_inside" : "another_day_workload"
	if(world.time < next_decay)
		return
	next_decay = world.time + decay_interval
	if(inside)
		return
	add_stacks(-1)

/datum/status_effect/stacking/distortion_workload/proc/SetDistortion(mob/living/simple_animal/hostile/distortion/advanced/another_day/new_distortion)
	distortion = new_distortion
	RegisterSignal(distortion, COMSIG_PARENT_QDELETING, PROC_REF(OnDistortionDeleted))

/datum/status_effect/stacking/distortion_workload/proc/OnDistortionDeleted(datum/source)
	SIGNAL_HANDLER
	distortion = null

/datum/status_effect/stacking/distortion_workload/threshold_cross_effect()
	to_chat(owner, span_userdanger("You sit down for a moment. Just a moment."))
	asleep_until = world.time + sleep_time
	owner.Sleeping(sleep_time)
	addtimer(CALLBACK(src, PROC_REF(WakeUp)), sleep_time)

/datum/status_effect/stacking/distortion_workload/proc/WakeUp()
	add_stacks(3 - stacks)

/datum/status_effect/stacking/distortion_workload/proc/InsetOverlay()
	owner.cut_overlay(status_overlay)
	status_overlay = mutable_appearance(overlay_file, "[overlay_state][stacks]")
	status_overlay.blend_mode = BLEND_INSET_OVERLAY
	status_overlay.pixel_x = -owner.pixel_x
	owner.add_overlay(status_overlay)

/datum/movespeed_modifier/distortion_workload
	multiplicative_slowdown = 0
	variable = TRUE

// Once the gimmick stage has been reached and the presence is active, drains the sanity of nearby humans and occasionally speaks to them.
// The presence can be turned off by saying the coworker's name.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/PassiveEffects(list/inside)
	if(territory.stage < gimmick_stage || !PresenceActive() || world.time < next_drain)
		return
	next_drain = world.time + (territory.Size() >= territory.cap ? drain_interval_fast : drain_interval)
	var/line = pick(idle_messages)
	var/heard = FALSE
	for(var/mob/living/carbon/human/H in inside)
		WearDown(H, drain_sanity)
		if(!prob(idle_message_chance))
			continue
		MindSpeak(H, line)
		heard = TRUE
	if(heard)
		Mutter(line)

//Checks if there is a human with sanity below the hang_threshold, if there is one and it has at least one color, it will hang them.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/TryHang(list/inside)
	if(!PresenceActive())
		return
	var/list/tie_colors = list()
	for(var/tie_color in color_roles)
		if(!(tie_color in drained))
			tie_colors += tie_color
	if(!tie_colors.len)
		return
	for(var/mob/living/carbon/human/H in inside)
		if(H.buckled || H.sanityhealth > H.maxSanity * hang_threshold)
			continue
		var/obj/structure/another_day_tie/tie = new(get_turf(H), src, pick(tie_colors))
		ties += tie
		tie.Drop(H)
		territory.Grow()

/obj/structure/another_day_tie
	name = "long tie"
	desc = "A tie that reaches up past where the ceiling should be. It is pulled very tight."
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_state = "work_rope_red"
	pixel_x = -8
	base_pixel_x = -8
	pixel_y = 96
	alpha = 0
	layer = BELOW_MOB_LAYER
	max_integrity = 40
	density = FALSE
	anchored = TRUE
	can_buckle = TRUE
	buckle_lying = 0
	buckle_prevents_pull = TRUE
	var/tie_color = "red"
	var/mutable_appearance/tie_part
	var/mob/living/simple_animal/hostile/distortion/advanced/another_day/owner
	var/mob/living/carbon/human/victim
	var/obj/effect/another_day_shadow/shadow
	var/fall_time = 1 SECONDS
	var/lift_time = 1 SECONDS
	var/lift_height = 48
	var/oxy_per_tick = 30
	var/choke_interval = 1 SECONDS
	var/choke_timer
	var/hold_source = "another_day_tie"

/obj/structure/another_day_tie/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/another_day/new_owner, new_tie_color)
	. = ..()
	owner = new_owner
	tie_color = new_tie_color
	icon_state = "work_rope_[tie_color]"
	SetTieLayer(BELOW_MOB_LAYER)

/obj/structure/another_day_tie/Destroy()
	Release()
	if(owner)
		owner.ties -= src
		owner = null
	QDEL_NULL(shadow)
	return ..()

/obj/structure/another_day_tie/proc/Drop(mob/living/carbon/human/H)
	victim = H
	H.Stun(fall_time + lift_time + 2 SECONDS, TRUE)
	ADD_TRAIT(H, TRAIT_IMMOBILIZED, hold_source)
	ADD_TRAIT(H, TRAIT_HANDS_BLOCKED, hold_source)
	buckle_mob(H, TRUE, FALSE)
	H.density = FALSE
	//Just incase they are panicing, disable their AI so it doesn't mess with things.
	H.ai_controller?.set_ai_status(AI_STATUS_OFF)
	H.setDir(SOUTH)
	H.visible_message(span_warning("Something long and dark drops out of the air above [H]."), span_userdanger("Something drops out of the air above you."))
	animate(src, pixel_y = 0, alpha = 255, time = fall_time, easing = QUAD_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(Tighten)), fall_time)

/obj/structure/another_day_tie/proc/Tighten()
	if(QDELETED(victim) || victim.buckled != src)
		qdel(src)
		return
	playsound(src, 'sound/abnormalities/judgementbird/hang.ogg', 60, TRUE)
	animate(src, transform = matrix().Scale(1.4, 1), time = 1.5)
	animate(transform = matrix(), time = 1.5)
	victim.setDir(SOUTH)
	SetTieLayer(ABOVE_MOB_LAYER)
	victim.visible_message(span_danger("The tie winds around [victim]'s neck and pulls tight."), span_userdanger("The tie winds around your neck and pulls tight."))
	RegisterSignal(victim, COMSIG_LIVING_DEATH, PROC_REF(OnDeath))
	addtimer(CALLBACK(src, PROC_REF(Lift)), 3)

//Creates an overlay over the target, to make it look like the tie is wrapped around their neck.
/obj/structure/another_day_tie/proc/SetTieLayer(new_layer)
	if(tie_part)
		cut_overlay(tie_part)
	tie_part = mutable_appearance(icon, "work_tie_[tie_color]", new_layer)
	add_overlay(tie_part)

// And then animate them moving up from the floor, and then begin choking them.
/obj/structure/another_day_tie/proc/Lift()
	if(QDELETED(victim))
		qdel(src)
		return
	animate(victim, pixel_z = lift_height, time = lift_time, easing = SINE_EASING | EASE_OUT)
	animate(src, pixel_y = lift_height, time = lift_time, easing = SINE_EASING | EASE_OUT)
	shadow = new(loc)
	animate(shadow, alpha = 255, time = lift_time)
	victim.visible_message(span_danger("[victim] is hauled up off the floor."), span_userdanger("Your feet leave the floor."))
	choke_timer = addtimer(CALLBACK(src, PROC_REF(Choke)), choke_interval, TIMER_STOPPABLE | TIMER_LOOP)

/obj/structure/another_day_tie/proc/Choke()
	if(QDELETED(victim) || victim.buckled != src)
		qdel(src)
		return
	if(victim.stat == DEAD)
		return
	victim.deal_damage(oxy_per_tick, OXY, owner, null, ATTACK_TYPE_SPECIAL)

//They died, well time to make them sway.
/obj/structure/another_day_tie/proc/OnDeath(datum/source, gibbed)
	SIGNAL_HANDLER
	if(choke_timer)
		deltimer(choke_timer)
		choke_timer = null
	if(gibbed)
		qdel(src)
		return
	victim.visible_message(span_danger("[victim] goes still."))
	Sway()

//Fun animation of them swaying back and forth. Adds atmosphere once it has killed a few people!
/obj/structure/another_day_tie/proc/Sway(angle = 6, period = 2 SECONDS)
	var/shift = round(80 * sin(angle))
	animate(src, transform = PivotTurn(48, -angle), time = period, loop = -1, easing = SINE_EASING)
	animate(transform = PivotTurn(48, angle), time = period, easing = SINE_EASING)
	animate(victim, transform = PivotTurn(80, -angle), time = period, loop = -1, easing = SINE_EASING)
	animate(transform = PivotTurn(80, angle), time = period, easing = SINE_EASING)
	animate(shadow, pixel_x = shadow.base_pixel_x + shift, time = period, loop = -1, easing = SINE_EASING)
	animate(pixel_x = shadow.base_pixel_x - shift, time = period, easing = SINE_EASING)

/obj/structure/another_day_tie/proc/PivotTurn(pivot, angle)
	var/matrix/M = matrix()
	M.Translate(0, -pivot)
	M.Turn(angle)
	M.Translate(0, pivot)
	return M

//Well, once the distortion is killed or the tie is destroyed, release the victim. Removing
//traits like immobilized and hands blocked.
/obj/structure/another_day_tie/proc/Release()
	if(!victim)
		return
	var/mob/living/carbon/human/H = victim
	victim = null
	if(choke_timer)
		deltimer(choke_timer)
		choke_timer = null
	if(QDELETED(H))
		return
	UnregisterSignal(H, COMSIG_LIVING_DEATH)
	H.density = TRUE
	if(H.buckled == src)
		unbuckle_mob(H, TRUE)
	REMOVE_TRAIT(H, TRAIT_IMMOBILIZED, hold_source)
	REMOVE_TRAIT(H, TRAIT_HANDS_BLOCKED, hold_source)
	animate(H)
	H.pixel_z = 0
	H.update_transform()
	if(H.stat != DEAD)
		H.Knockdown(2 SECONDS)
		if(H.sanity_lost)
			H.ai_controller?.set_ai_status(AI_STATUS_ON)
	H.visible_message(span_danger("[H] falls free of the tie!"))

//It's far too high in the sky to unbuckle.
/obj/structure/another_day_tie/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	to_chat(user, span_warning("The knot is too tight to loosen."))
	return FALSE

/obj/structure/another_day_tie/unbuckle_mob(mob/living/buckled_mob, force = FALSE)
	if(!force)
		return
	return ..()

/obj/structure/another_day_tie/attacked_by(obj/item/I, mob/living/user)
	if(I.reach < 2)
		to_chat(user, span_warning("You cannot reach the knot with [I]."))
		return
	return ..()

/obj/effect/another_day_shadow
	name = "shadow"
	desc = "The shadow of someone who is not standing there."
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_state = "work_shadow"
	pixel_x = -8
	base_pixel_x = -8
	alpha = 0
	layer = BELOW_MOB_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
