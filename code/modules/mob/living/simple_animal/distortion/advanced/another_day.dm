/mob/living/simple_animal/hostile/distortion/advanced/another_day
	name = "Another Day at Work"
	desc = "A man covered in... ties?"
	icon = 'ModularLobotomy/_Lobotomyicons/48x96.dmi'
	icon_state = "work"
	maxHealth = 1400
	health = 1400
	pixel_x = -8
	base_pixel_x = -8
	fear_level = TETH_LEVEL
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.1, PALE_DAMAGE = 0.3)
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	ranged = FALSE
	ego_list = list(
		/obj/item/ego_weapon/waging,
		/obj/item/clothing/suit/armor/ego_gear/teth/waging,
	)
	egoist_names = list("Paige Turner", "Larry Sal", "Nota Dollar", "Donnar Profit", "Collin Beck")
	gender = MALE
	sin_reward = /obj/item/solidified_sin/gloom
	monolith_abnormality = /mob/living/simple_animal/hostile/abnormality/black_swan
	territory_cap = 1000
	territory_stages = list(50, 200, 500)
	//This will make it so the territory grows quickly at first, then slows down.
	territory_growth_rate = 467
	gimmick_stage = 3
	//Lists of people, drained colours, and drain overlays for tracking the state of the mob.
	//It could look like: people = list("boss" = "Paige Turner", "coworker" = "Larry Sal", "friend" = "Nota Dollar", "self" = "Donnar Profit")
	var/list/people = list()
	//Defines the roles associated with each colour tie.
	var/list/colour_roles = list("red" = "boss", "blue" = "coworker", "yellow" = "friend")
	var/obj/item/clothing/neck/tie/horrible/another_day/name_tie
	//All of the humans within its territory.
	var/list/listening = list()
	var/forced_whisper_text
	//Colours that are currently drained and their remaining duration.
	var/list/drained = list()
	var/list/drain_overlays = list()
	var/drain_duration = 60 SECONDS
	var/tie_overlay_icon = 'ModularLobotomy/_Lobotomyicons/another_day_ties.dmi'
	var/undistort_timer
	var/undistort_time = 30 SECONDS
	var/gives_workload = TRUE
	var/list/next_taboo = list()
	var/taboo_cooldown = 2 SECONDS
	var/sulk_damage = 15
	var/sulk_sanity = 2
	var/hang_threshold = 0.1
	var/list/mind_prefixes = list(
		"A voice moves through your mind.",
		"Something tired speaks from behind your eyes.",
		"A thought that is not yours surfaces.",
		"Someone sighs, very close, inside your head.",
	)
	var/whisper_cooldown = 20 SECONDS
	var/next_whisper = 0
	var/list/sulk_lines = list(
		"I just want to go home.",
		"Nobody asked me.",
		"It will be done by Monday.",
		"I said I was fine.",
		"Please. Not today.",
	)
	//For changing the turfs around the center of the territory.
	var/floor_type = /turf/open/floor/distortion/another_day
	var/wall_type = /turf/closed/indestructible/city/another_day
	var/list/quilt_turf_types = list(/turf/open/floor, /turf/open/indestructible)
	var/list/converted = list()
	var/quilt_fraction = 0.35
	var/quilt_growth_power = 0.5
	//The passive pressure that turns on, once the gimmick stage is reached.
	var/drain_sanity = 1
	var/drain_interval = 10 SECONDS
	var/drain_interval_fast = 3 SECONDS
	var/next_drain = 0
	var/idle_message_chance = 25
	var/list/idle_messages = list(
		"It is later than you think.",
		"Is it still Monday?",
		"The lights have been humming all week.",
		"Just one more thing before I go.",
	)
	//A list of ties that are hanging people! How wonderful...
	var/list/ties = list()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Initialize(mapload)
	. = ..()
	if(!territory)
		return
	//Creates a list of people for each colour tie.
	for(var/colour in colour_roles)
		people[colour_roles[colour]] = random_unique_name(pick(MALE, FEMALE))
	people["self"] = pick(egoist_names)
	egoist_names = list(people["self"])
	SpawnNameTie()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Move()
	return FALSE

/mob/living/simple_animal/hostile/distortion/advanced/another_day/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/distortion/advanced/another_day/PostUnmanifest(mob/living/carbon/human/egoist)
	new /obj/item/clothing/neck/tie/horrible(get_turf(src))

//Creates a tie with the egoist's name on it, on a random turf in the territory.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/SpawnNameTie()
	name_tie = new(territory.RandomTurf(), people["self"])
	Own(name_tie)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnOwnedDeleted(datum/source)
	. = ..()
	if(source == name_tie)
		name_tie = null

/mob/living/simple_animal/hostile/distortion/advanced/another_day/Life()
	. = ..()
	if(stat == DEAD)
		return
	TerritoryTick()

//Got to remove the speech signal from every human we are listening to, and the timers for drained colours and other things that the distortion is tracking.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/Teardown()
	if(torn_down)
		return
	for(var/turf/T in converted)
		if(istype(T, floor_type) || istype(T, wall_type))
			T.ChangeTurf(converted[T])
	converted.Cut()
	for(var/obj/structure/another_day_tie/tie in ties)
		qdel(tie)
	for(var/mob/living/carbon/human/H in listening)
		UnregisterSignal(H, COMSIG_MOB_SAY)
	listening.Cut()
	for(var/colour in drained)
		deltimer(drained[colour])
	drained.Cut()
	if(undistort_timer)
		deltimer(undistort_timer)
		undistort_timer = null
	return ..()

//Simply checks every human to see if they are inside the territory.
//I am mainly doing this since it would be cheaper then checking every turf in the territory, and seeing if a human is on that tile.
//I am not imagining there would be more than like 50 humans alive, even in the worse case.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/HumansInside()
	var/list/inside = list()
	for(var/mob/living/carbon/human/H as anything in GLOB.human_list)
		if(H.z == z && H.stat != DEAD && territory.Contains(get_turf(H)))
			inside += H
	return inside

// The check that happens every life tick, where it will register new humans inside the territory and unregister those who have left.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/TerritoryTick()
	var/list/inside = HumansInside()
	for(var/mob/living/carbon/human/H in inside)
		if(H in listening)
			continue
		RegisterSignal(H, COMSIG_MOB_SAY, PROC_REF(OnSpeech))
		listening += H
	for(var/mob/living/carbon/human/H in listening)
		if(QDELETED(H) || !(H in inside))
			UnregisterSignal(H, COMSIG_MOB_SAY)
			listening -= H
	for(var/attacker in next_taboo)
		if(next_taboo[attacker] <= world.time)
			next_taboo -= attacker
	PassiveEffects(inside)
	TryHang(inside)
	if(!name_tie)
		SpawnNameTie()

//If they say the correct name, tada! They remove one of the colours. Also, got to hear his own name after saying the other 3 names to undistort.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/OnSpeech(mob/living/carbon/human/speaker, list/speech_args)
	SIGNAL_HANDLER
	var/message = speech_args[SPEECH_MESSAGE]
	if(forced_whisper_text)
		speech_args[SPEECH_MESSAGE] = forced_whisper_text
		return
	if(!message)
		return
	for(var/colour in colour_roles)
		if(findtext(message, people[colour_roles[colour]]))
			DrainColour(colour, speaker)
	if(findtext(message, people["self"]))
		HearOwnName(speaker)
	// If the cap on territory has been reached and the presence is active, force the speaker to whisper.
	if(territory.Size() < territory.cap || !PresenceActive())
		return
	// Clear the original message before forcing the whisper by placing a # before their messsage. We prevent an endless loop by checking whether a forced whisper is already in progress.
	speech_args[SPEECH_MESSAGE] = ""
	forced_whisper_text = message
	INVOKE_ASYNC(speaker, TYPE_PROC_REF(/atom/movable, say), "#[message]", null, null, FALSE, speech_args[SPEECH_LANGUAGE])
	forced_whisper_text = null

//Removes a color from the distortion, adds a gray overlay to hide that color and sets a timer to restore it after a while!
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/DrainColour(colour, mob/living/carbon/human/speaker)
	if(colour in drained)
		deltimer(drained[colour])
		drained[colour] = addtimer(CALLBACK(src, PROC_REF(RestoreColour), colour), drain_duration, TIMER_STOPPABLE)
		to_chat(speaker, span_warning("It is already hurting from that name."))
		return
	speaker.Shake(3, 3, 2.5 SECONDS)
	to_chat(speaker, span_nicegreen("Something in this place flinches at that name."))
	drained[colour] = addtimer(CALLBACK(src, PROC_REF(RestoreColour), colour), drain_duration, TIMER_STOPPABLE)
	var/mutable_appearance/MA = mutable_appearance(tie_overlay_icon, colour)
	drain_overlays[colour] = MA
	add_overlay(MA)
	ApplyColour(colour, FALSE)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/RestoreColour(colour)
	if(!(colour in drained))
		return
	drained -= colour
	cut_overlay(drain_overlays[colour])
	drain_overlays -= colour
	ApplyColour(colour, TRUE)

//Toggles the effect of a specific colour on the distortion, with present determining whether it is turning the effect on or off.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/ApplyColour(colour, present)
	switch(colour)
		if("red")
			gives_workload = present
		if("blue")
			UpdatePaused()
		if("yellow")
			if(present)
				RemoveModifier(/datum/dc_change/another_day_exposed)
			else
				AddModifier(/datum/dc_change/another_day_exposed)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/PresenceActive()
	return !("blue" in drained) && !undistort_timer

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/UpdatePaused()
	territory.paused = !PresenceActive()

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/HearOwnName(mob/living/carbon/human/speaker)
	if(undistort_timer)
		return
	if(drained.len < colour_roles.len)
		to_chat(speaker, span_nicegreen("You were close. Other voices are drowning yours out."))
		return
	if(!(src in view(speaker)))
		to_chat(speaker, span_nicegreen("You need to be heard more clearly."))
		return
	StartUndistorting(speaker)

//Basically, restores all drained colours and starts a rays effect around them, then unmanifests after a delay.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/StartUndistorting(mob/living/carbon/human/speaker)
	for(var/colour in drained.Copy())
		RestoreColour(colour)
	undistort_timer = addtimer(CALLBACK(src, PROC_REF(Unmanifest)), undistort_time, TIMER_STOPPABLE)
	UpdatePaused()
	visible_message(span_notice("The ties go slack, one after another, and something behind them starts to shine."))
	to_chat(speaker, span_nicegreen("He looks up."))
	add_filter("undistort", 1, rays_filter(size = 4, color = "#FFF1B8", offset = 0, density = 10, threshold = 0.15))
	transition_filter("undistort", undistort_time, list(size = 120, offset = 90), SINE_EASING | EASE_IN)

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/CancelUndistort()
	if(!undistort_timer)
		return
	deltimer(undistort_timer)
	undistort_timer = null
	remove_filter("undistort")
	UpdatePaused()
	visible_message(span_warning("The light goes out. The ties pull tight again."))

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

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/MindSpeak(mob/living/carbon/human/H, line)
	to_chat(H, span_notice("[pick(mind_prefixes)] <i>\"[line]\"</i>"))

/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/Mutter(line)
	if(world.time < next_whisper)
		return
	next_whisper = world.time + whisper_cooldown
	whisper(line)

// Workload status effect, where you start gaining slowdown, blurry vision, and sleepiness at the max stack.
/datum/status_effect/stacking/distortion_workload
	id = "distortion_workload"
	alert_type = /atom/movable/screen/alert/status_effect/distortion_workload
	max_stacks = 6
	stack_threshold = 6
	consumed_on_threshold = FALSE
	tick_interval = 1 SECONDS
	overlay_file = 'ModularLobotomy/_Lobotomyicons/another_day_workload.dmi'
	overlay_state = "workload_"
	var/mob/living/simple_animal/hostile/distortion/advanced/another_day/distortion
	var/decay_interval = 20 SECONDS
	var/next_decay = 0
	var/sleep_time = 3 SECONDS
	var/asleep_until = 0
	var/blur_per_stack = 2

/atom/movable/screen/alert/status_effect/distortion_workload
	name = "Workload"
	desc = "It is piling up. You could put it down if you stepped away."
	icon = 'ModularLobotomy/_Lobotomyicons/another_day_workload.dmi'
	icon_state = "alert"

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
		linked_alert.icon_state = inside ? "alert_inside" : "alert"
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
	if(territory.stage < gimmick_stage || !PresenceActive())
		return
	var/list/colours = list()
	for(var/colour in colour_roles)
		if(!(colour in drained))
			colours += colour
	if(!colours.len)
		return
	for(var/mob/living/carbon/human/H in inside)
		if(H.buckled || H.sanityhealth > H.maxSanity * hang_threshold)
			continue
		var/obj/structure/another_day_tie/tie = new(get_turf(H), src, pick(colours))
		ties += tie
		tie.Drop(H)

/obj/structure/another_day_tie
	name = "long tie"
	desc = "A tie that reaches up past where the ceiling should be. It is pulled very tight."
	icon = 'ModularLobotomy/_Lobotomyicons/another_day_hang.dmi'
	icon_state = "rope_red"
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
	var/colour = "red"
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

/obj/structure/another_day_tie/Initialize(mapload, mob/living/simple_animal/hostile/distortion/advanced/another_day/new_owner, new_colour)
	. = ..()
	owner = new_owner
	colour = new_colour
	icon_state = "rope_[colour]"
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
	tie_part = mutable_appearance(icon, "tie_[colour]", new_layer)
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
	icon = 'ModularLobotomy/_Lobotomyicons/another_day_hang.dmi'
	icon_state = "shadow"
	pixel_x = -8
	base_pixel_x = -8
	alpha = 0
	layer = BELOW_MOB_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/mob/living/simple_animal/hostile/distortion/advanced/another_day/OnTerritoryGrown()
	UpdateQuilt()

// Adds the corrupted tiles around the center of the territory, once gimmick stage is reached.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/UpdateQuilt()
	if(territory.stage < gimmick_stage)
		return
	ApplyCenterEffects(territory.NearestTurfs(QuiltSize()))

// Returns the size of the quilt based on the territory's growth. Which means it increases as the territory grows.
/mob/living/simple_animal/hostile/distortion/advanced/another_day/proc/QuiltSize()
	var/growth = territory.Size() / max(1, territory_start_size)
	return max(1, round(quilt_fraction * territory_start_size * (growth ** quilt_growth_power)))

/mob/living/simple_animal/hostile/distortion/advanced/another_day/ApplyCenterEffects(list/turfs)
	for(var/turf/open/T in turfs)
		if(!is_type_in_list(T, quilt_turf_types))
			continue
		if(!converted[T] && !istype(T, floor_type))
			converted[T] = T.type
			T.ChangeTurf(floor_type)
		//This is done to create a border of walls around the quilt, since NearestTurfs does not find closed turfs.
		for(var/dir in GLOB.cardinals)
			var/turf/next = get_step(T, dir)
			if(!next || converted[next] || !isclosedturf(next) || istype(next, wall_type))
				continue
			converted[next] = next.type
			next.ChangeTurf(wall_type)

/turf/open/floor/distortion/another_day/Initialize(mapload)
	. = ..()
	icon_state = pick("another_day1", "another_day2", "another_day3", "another_day4")

/turf/closed/indestructible/city/another_day
	name = "quilted wall"
	desc = "Ties, hundreds of them, stitched edge to edge and hung over whatever was here before."
	icon = 'icons/turf/walls/city_another_day.dmi'
	icon_state = "another_day-0"
	base_icon_state = "another_day"

/datum/dc_change/another_day_exposed
	potency = 4
	damage_type = list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)

/obj/item/clothing/neck/tie/horrible/another_day
	desc = "A neosilk clip-on tie. This one is disgusting. There is a name on the label."
	var/lifetime = 3 MINUTES
	var/fade_time = 10 SECONDS

/obj/item/clothing/neck/tie/horrible/another_day/Initialize(mapload, who)
	. = ..()
	desc = "A neosilk clip-on tie. This one is disgusting. The label reads: [who]."
	addtimer(CALLBACK(src, PROC_REF(Expire)), lifetime)

/obj/item/clothing/neck/tie/horrible/another_day/proc/Expire()
	animate(src, alpha = 0, time = fade_time)
	QDEL_IN(src, fade_time)
