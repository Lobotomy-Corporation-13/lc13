// The Rain Can Always Get Worse - a Zayin marionette rain-machine.
// Working it charges its eye to the colour of the last work type. Repeating the
// work type its eye already shows stacks a permanent -10% success penalty on ALL
// work, cleared only by releasing it. A "Release" work breaches it: for a while it
// wanders NON-HOSTILE, following whoever last poked it and raining its eye colour's
// damage-type protection on everyone caught in the rain. On return it is "shocked"
// and cannot be released again for a short time.

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can
	name = "The Rain Can Always Get Worse"
	desc = "A limp marionette of a machine - a boxy screen-head on a battered, can-like body, \
		strung up on cords that vanish into the air above. Its lens weeps a thin, steady drizzle."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/96x96.dmi'
	icon_state = "raincan_contained"
	icon_living = "raincan"
	icon_dead = "raincan_dead"
	pixel_x = -32
	base_pixel_x = -32
	maxHealth = 1600
	health = 1600
	threat_level = ZAYIN_LEVEL
	can_breach = TRUE
	start_qliphoth = 1
	move_to_delay = 4
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	can_patrol = FALSE
	environment_smash = FALSE
	faction = list("neutral")
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 65,
		ABNORMALITY_WORK_INSIGHT = 65,
		ABNORMALITY_WORK_ATTACHMENT = 65,
		ABNORMALITY_WORK_REPRESSION = 65,
		"Release" = 100,
	)
	max_boxes = 8
	work_damage_amount = 4
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gloom
	ego_list = list(
		/datum/ego_datum/weapon/branch12/rainfall,
		/datum/ego_datum/armor/branch12/rainfall,
	)
	gift_type = /datum/ego_gifts/branch12/rainfall
	observation_prompt = "The hulking machine hangs slack on its strings, screen dark. \
		As you step closer its lens blinks awake and a fine rain begins to patter around your feet. \
		<br>A tinny voice crackles: \"It's raining. It can always get worse... unless you'd like it not to?\""
	observation_choices = list(
		"Stand in the rain" = list(TRUE, "You let the drizzle settle on your shoulders. It is oddly warm, \
			and where it falls the world feels a little softer, a little safer. The machine's lens glows, content."),
		"Step out of the rain" = list(FALSE, "You back away from the drizzle. The lens dims, and the patter follows \
			you a few steps before giving up. \"...Suit yourself,\" it crackles, sounding almost hurt."),
	)

	generic_bubbles = alist(
		1 = list("%PERSON keeps a wary distance from the slumped, looming machine.", "%PERSON eyes the cords vanishing up into the ceiling."),
		2 = list("%PERSON works through the checklist for %ABNO.", "%PERSON wipes the dust from %ABNO's dark screen."),
		3 = list("%PERSON checks %ABNO's cords for fraying.", "%PERSON hums quietly to themselves as they work."),
		4 = list("%PERSON works through %ABNO's paperwork from memory.", "%PERSON taps %ABNO's dented tin body idly."),
		5 = list("%PERSON leans against %ABNO's unit, unhurried.", "%PERSON works without once glancing up at the looming machine."),
	)
	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("%PERSON checks the joints of %ABNO's dangling shoes."),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON traces the cords that hold %ABNO aloft."),
		ABNORMALITY_WORK_ATTACHMENT = list("%PERSON talks quietly to the silent machine."),
		ABNORMALITY_WORK_REPRESSION = list("%PERSON makes sure %ABNO's cords are wound tight and still."),
	)

	being_tested = TRUE

	/// Current eye colour ("red"/"white"/"black"/"pale"), drives the overlay + rain protection type.
	var/current_eye_color
	/// The last work type performed - repeating it stacks the penalty.
	var/current_eye_work
	/// Accumulated -% success on all work. Only a breach clears it.
	var/work_penalty = 0
	/// Flicker toggle for the glowing eye overlay.
	var/eye_bright = FALSE
	/// The last person to poke it while breaching - it follows them.
	var/mob/living/carbon/human/last_poker
	/// How far the rain (and its protection) reaches while breaching.
	var/rain_radius = 9
	/// How long a breach lasts before it returns to its cell on its own.
	var/breach_time = 60 SECONDS
	/// How long after returning it cannot be released again.
	var/shock_time = 5 MINUTES
	/// world.time until which "Release" is unavailable.
	var/shocked_until = 0
	/// Handle for the auto-return timer.
	var/breach_timer
	/// world.time before which it will not speak again (anti-spam cooldown).
	var/next_vox = 0
	/// Silence enforced after any spoken phrase.
	var/vox_cooldown_time = 15 SECONDS
	/// Cryptic VOX word-chains it mutters (fed a coin, or rarely while worked on).
	var/list/vox_phrases = list(
		list("come", "down", "come", "down"),
		list("you", "are", "safe", "no", "you", "are", "not"),
		list("pressure", "low", "low"),
		list("ninety", "percent", "cold"),
		list("mercy", "no", "mercy"),
		list("look", "up"),
		list("hide", "it", "come"),
		list("condition", "severe", "severe"),
		list("sorry", "sorry", "sorry"),
	)

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/proc/WorkColor(work_type)
	switch(work_type)
		if(ABNORMALITY_WORK_INSTINCT)
			return "red"
		if(ABNORMALITY_WORK_INSIGHT)
			return "white"
		if(ABNORMALITY_WORK_ATTACHMENT)
			return "black"
		if(ABNORMALITY_WORK_REPRESSION)
			return "pale"
	return null

// Release stays reliable; the four real work types eat the accumulated penalty.
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/WorkChance(mob/living/carbon/human/user, chance, work_type)
	if(work_type == "Release")
		return chance
	return max(5, chance - work_penalty)

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/AttemptWork(mob/living/carbon/human/user, work_type)
	if(work_type == "Release")
		if(world.time < shocked_until)
			to_chat(user, span_warning("[src] is still reeling from its last outing - it won't budge."))
			return FALSE
		if(!current_eye_color)
			to_chat(user, span_warning("[src]'s lens is dark. Work it first to charge its element."))
			return FALSE
	return ..()

// Small helpful heal on a good result (Release excluded).
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(work_type == "Release")
		return
	user.adjustSanityLoss(-(user.maxSanity * 0.05))

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	. = ..()
	if(work_type == "Release")
		if(!current_eye_color)
			return
		say("It's raining! It can always get worse...")
		datum_reference.qliphoth_change(-9999) // drop to 0 -> ZeroQliphoth -> BreachEffect
		return
	var/new_color = WorkColor(work_type)
	if(!new_color)
		return
	if(work_type == current_eye_work) // repeated the colour it already shows
		work_penalty = min(work_penalty + 10, 90)
		to_chat(user, span_warning("[src] shudders - the same current again. Its readings grow noisier."))
	current_eye_work = work_type
	current_eye_color = new_color
	update_icon()

// Quietly chains VOX word clips to those nearby (wait = 1 queues them in order).
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/proc/SayVox(list/words)
	if(!islist(words))
		return
	for(var/word in words)
		var/sound_file = GLOB.vox_sounds[word]
		if(!sound_file)
			continue
		var/sound/voice = sound(sound_file, wait = 1, channel = CHANNEL_VOX)
		voice.status = SOUND_STREAM
		voice.volume = 25
		for(var/mob/M in hearers(7, src))
			if(M.can_hear())
				SEND_SOUND(M, voice)

// Low chance to mutter quietly while being worked on (respects the cooldown).
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/Worktick(mob/living/carbon/human/user, bubble_type = ABNO_BALLOON_GENERIC | ABNO_BALLOON_SPECIFIC, work_type)
	. = ..()
	if(world.time >= next_vox && prob(8))
		next_vox = world.time + vox_cooldown_time
		SayVox(pick(vox_phrases))

// Feed it a coin and, after a beat, it speaks - like the arcade machine it was.
// It refuses another coin until its post-speech cooldown passes, so it cannot be
// spammed into chattering.
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/coin))
		if(world.time < next_vox)
			to_chat(user, span_warning("[src] whirs and spits the coin back out - it is still working through the last one."))
			return
		visible_message(span_notice("[user] feeds [W] into [src], and it swallows the coin with a mechanical clunk."))
		qdel(W)
		playsound(get_turf(src), 'sound/effects/cashregister.ogg', 40, FALSE, 3)
		var/delay = rand(2 SECONDS, 5 SECONDS)
		next_vox = world.time + delay + vox_cooldown_time
		addtimer(CALLBACK(src, PROC_REF(SayVox), pick(vox_phrases)), delay)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/BreachEffect(mob/living/carbon/human/user, breach_type = BREACH_NORMAL)
	. = ..()
	work_penalty = 0 // letting it out resets its readings
	last_poker = user
	playsound(get_turf(src), 'sound/ambience/acidrain_start.ogg', 50, TRUE, 6)
	visible_message(span_warning("[src] shudders loose, and the drizzle around it swells into a steady rain."))
	if(breach_timer)
		deltimer(breach_timer)
	breach_timer = addtimer(CALLBACK(src, PROC_REF(Recontain)), breach_time, TIMER_STOPPABLE)
	update_icon()

// Poke it (empty hand) to make it follow you while it is out.
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/attack_hand(mob/living/carbon/M)
	if(!IsContained() && stat != DEAD && ishuman(M))
		last_poker = M
		visible_message(span_notice("[M] pokes [src]; its lens swivels to fix on them."))
		walk_to(src, last_poker, 1, move_to_delay)
		return
	return ..()

// Non-hostile: never targets or strikes anyone.
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/ListTargets()
	return list()

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/AttackingTarget(atom/attacked_target)
	return

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/Life()
	. = ..()
	if(stat == DEAD)
		return
	if(current_eye_color) // flicker the glowing eye
		eye_bright = !eye_bright
		update_icon()
	if(IsContained())
		return
	RainTick()
	FollowPoker()

// Tint of the passive rain, matching the current protection (eye) colour.
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/proc/RainColor()
	switch(current_eye_color)
		if("red")
			return "#ee4747"
		if("white")
			return "#849ef8"
		if("black")
			return "#8453be"
		if("pale")
			return "#27b0b0"
	return null

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/proc/RainTick()
	var/rain_color = RainColor()
	for(var/turf/open/T in view(rain_radius, src))
		if(isspaceturf(T))
			continue
		var/obj/effect/rain_can_rain/R = new(T)
		R.color = rain_color
	if(!current_eye_color)
		return
	for(var/mob/living/carbon/human/H in view(rain_radius, src))
		RainProtect(H)

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/proc/RainProtect(mob/living/carbon/human/H)
	var/prot_type
	switch(current_eye_color)
		if("red")
			prot_type = /datum/status_effect/stacking/damtype_protection
		if("white")
			prot_type = /datum/status_effect/stacking/damtype_protection/white
		if("black")
			prot_type = /datum/status_effect/stacking/damtype_protection/black
		if("pale")
			prot_type = /datum/status_effect/stacking/damtype_protection/pale
	if(!prot_type || H.has_status_effect(prot_type)) // already sheltered - don't re-shield
		return
	switch(current_eye_color)
		if("red")
			H.apply_lc_red_protection(3)
		if("white")
			H.apply_lc_white_protection(3)
		if("black")
			H.apply_lc_black_protection(3)
		if("pale")
			H.apply_lc_pale_protection(3)
	playsound(get_turf(H), 'sound/mecha/mech_shield_deflect.ogg', 40, TRUE, 3)
	new /obj/effect/temp_visual/rain_shield(get_turf(H))

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/proc/FollowPoker()
	if(last_poker && last_poker.stat != DEAD && last_poker.z == z)
		walk_to(src, last_poker, 1, move_to_delay)
	else
		last_poker = null
		walk(src, 0)

// Suppressing it (to 0 HP) sends it home early instead of killing it.
/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/death(gibbed)
	if(!IsContained() && datum_reference)
		Recontain()
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/proc/Recontain()
	if(IsContained() || !datum_reference)
		return
	if(breach_timer)
		deltimer(breach_timer)
		breach_timer = null
	walk(src, 0)
	last_poker = null
	for(var/obj/effect/rain_can_rain/R in view(rain_radius + 1, src))
		qdel(R)
	adjustBruteLoss(-maxHealth, forced = TRUE)
	toggle_ai(AI_OFF)
	status_flags |= GODMODE
	forceMove(get_turf(datum_reference.landmark))
	dir = SOUTH
	datum_reference.qliphoth_change(start_qliphoth)
	shocked_until = world.time + shock_time
	playsound(get_turf(src), 'sound/ambience/acidrain_end.ogg', 50, TRUE, 6)
	say("...too much. Putting it away. Give me a moment.")
	update_icon()

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/Destroy()
	if(breach_timer)
		deltimer(breach_timer)
		breach_timer = null
	last_poker = null
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/update_icon_state()
	if(stat == DEAD)
		icon_state = "raincan_dead"
	else if(IsContained())
		icon_state = "raincan_contained"
	else
		icon_state = "raincan"
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/rain_can/update_overlays()
	. = ..()
	if(!current_eye_color || stat == DEAD)
		return
	var/eye_state = IsContained() ? "contained_eye_[current_eye_color]" : "eye_[current_eye_color]"
	var/mutable_appearance/eye = mutable_appearance('ModularLobotomy/_Lobotomyicons/branch12/96x96.dmi', eye_state)
	eye.alpha = eye_bright ? 255 : 160
	. += eye

/obj/effect/rain_can_rain
	name = "rain"
	desc = "A curtain of warm, steady rain."
	icon = 'icons/effects/weather_effects.dmi'
	icon_state = "rain_storm"
	layer = ABOVE_MOB_LAYER
	alpha = 200
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/rain_can_rain/Initialize(mapload)
	. = ..()
	QDEL_IN(src, 2 SECONDS)

// Small shielding pop shown when someone is first sheltered by the rain.
// Same base + frame-based fade as the lc13_coloreffect indicators.
/obj/effect/temp_visual/rain_shield
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/effects/abnoeffects.dmi'
	icon_state = "shield"
	layer = ABOVE_ALL_MOB_LAYER
	duration = 8
