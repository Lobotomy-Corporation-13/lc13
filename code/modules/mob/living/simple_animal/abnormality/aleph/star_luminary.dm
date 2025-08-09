#define STATUS_EFFECT_STARCULTIST /datum/status_effect/starcultist

/mob/living/simple_animal/hostile/abnormality/star_luminary
	name = "Star Luminary"
	desc = "PLACEHOLDER"
	health = 4000
	maxHealth = 4000
	icon = 'ModularTegustation/Teguicons/128x128.dmi'
	pixel_x = -48
	base_pixel_x = -48
	pixel_y = -10
	base_pixel_y = -10
	icon_state = "star_lum"
	icon_living = "star_lum"
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 1.2)
	is_flying_animal = TRUE
	del_on_death = FALSE
	can_breach = TRUE
	threat_level = ALEPH_LEVEL
	start_qliphoth = 4
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = -100,
		ABNORMALITY_WORK_INSIGHT = list(0, 0, 0, 10, 15),
		ABNORMALITY_WORK_ATTACHMENT = list(0, 0, 0, 15, 25),
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 0, 25, 35),
	)
	work_damage_amount = 16
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/lust
	can_patrol = FALSE

	wander = FALSE
	light_color = COLOR_BLUE
	light_range = 36
	light_power = 5

	del_on_death = FALSE

	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	observation_prompt = "Stars glow blue in the dark. <br>\
		But looking at them up close, those weren't actually stars <br>The abnormality was just waving their arms with blue marbles in their hands. <br>\
		These are stars. <brThe abnormality declares, as if they knew what I was thinking."
	observation_choices = list(
		"Tell them those are marbles." = list(TRUE, "\"You sound pretty confident. Do you know what a star is in the first place?\" <br>\
		\"Speckles of light floating in the dark. That's what we call stars.\"<br>They gently wave the marbles in their hands.<br>\"Stars are what's in your mind. So these blue marbles are stars.\" <br>And you, too, can be a star."),
		"Agree that they are stars." = list(FALSE, "\"Right, but...\" <br>\"I know. That I can't go back to it anymore.\"<br>\
		\"Their multiple arms shiver in unison. <br>\"That I'm just waving my arms and emitting the blue glow to become a star myself.\" <br>Will we truly meet again as stars, someday?"),
	)

	var/list/cult = list()
	var/meltdown_tick = 180 SECONDS
	var/meltdown_timer


	var/pulse_cooldown
	var/pulse_cooldown_time = 12 SECONDS
	var/pulse_damage = 120 // Scales with distance.
	var/cult_workchance_boost = 30

/mob/living/simple_animal/hostile/abnormality/star_luminary/Initialize()
	. = ..()
	meltdown_timer = world.time + meltdown_tick

/mob/living/simple_animal/hostile/abnormality/star_luminary/Destroy()
	QDEL_NULL(cult)
	return ..()

/mob/living/simple_animal/hostile/abnormality/star_luminary/death(gibbed)
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	for(var/mob/living/carbon/human/cultist in cult)
		var/datum/status_effect/obsession = cultist.has_status_effect(/datum/status_effect/starcultist)
		if(obsession)
			qdel(obsession)
	..()

/mob/living/simple_animal/hostile/abnormality/star_luminary/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/star_luminary/Life()
	. = ..()
	if(IsContained())
		if(meltdown_timer < world.time && !datum_reference?.working)
			if(datum_reference.qliphoth_meter)
				meltdown_timer = world.time + meltdown_tick
				HandleQli(-1)
		return
	if((pulse_cooldown < world.time))
		Pulse()

/mob/living/simple_animal/hostile/abnormality/star_luminary/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/star_luminary/proc/Pulse()
	var/cultist_amount = length(cult)
	pulse_cooldown = world.time + (pulse_cooldown_time - (floor(cultist_amount/3) SECONDS))
	playsound(src, 'sound/abnormalities/bluestar/pulse.ogg', 100, FALSE, 40, falloff_distance = 10)
	var/matrix/init_transform = transform
	animate(src, transform = transform*1.5, time = 3, easing = BACK_EASING|EASE_OUT)
	icon_state = "star_lum_a"
	for(var/mob/living/L in livinginrange(48, src))
		if(L.z != z)
			continue
		if(faction_check_mob(L) && !attack_same)
			continue
		flash_color(L, flash_color = COLOR_BLUE_LIGHT, flash_time = 70)
		if(!ishuman(L))
			L.deal_damage((pulse_damage + (cultist_amount * 10) - get_dist(src, L)), BLACK_DAMAGE)
			continue
		var/mob/living/carbon/human/H = L
		if(H.has_status_effect(/datum/status_effect/starcultist))
			H.deal_damage(((pulse_damage + (cultist_amount * 10) - get_dist(src, L))/2), WHITE_DAMAGE)
		if(!H.sanity_lost)
			H.deal_damage((pulse_damage + (cultist_amount * 10) - get_dist(src, L)), BLACK_DAMAGE)
			continue // Remember to Change this.
		else if(!H.has_status_effect(/datum/status_effect/starcultist))
			H.apply_status_effect(STATUS_EFFECT_STARCULTIST, src, datum_reference.qliphoth_meter)
	SLEEP_CHECK_DEATH(3)
	animate(src, transform = init_transform, time = 5)
	SLEEP_CHECK_DEATH(4)
	icon_state = "star_lum"

/mob/living/simple_animal/hostile/abnormality/star_luminary/ChanceWorktickOverride(mob/living/carbon/human/user, work_chance, init_work_chance, work_type)
	if(LAZYFIND(cult, user))
		if(work_type != ABNORMALITY_WORK_REPRESSION)
			return work_chance + cult_workchance_boost
		else
			return work_chance + (cult_workchance_boost/3)

/mob/living/simple_animal/hostile/abnormality/star_luminary/AttemptWork(mob/living/carbon/human/user, work_type)
	meltdown_timer = world.time + meltdown_tick
	meltdown_tick = floor(180 SECONDS / (1 + (length(cult)/10)))
	// if(get_attribute_level(user, TEMPERANCE_ATTRIBUTE) < 80)
	// 	datum_reference.qliphoth_change(-1)
	// 	playsound(src, 'sound/abnormalities/bluestar/pulse.ogg', 25, FALSE, 28)
	// 	user.death()
	// 	animate(user, transform = user.transform*0.01, time = 5)
	// 	QDEL_IN(user, 5)
	// 	return FALSE
	return TRUE

/mob/living/simple_animal/hostile/abnormality/star_luminary/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	if(work_type != ABNORMALITY_WORK_REPRESSION)
		if(!LAZYFIND(cult, user))
			HandleQli(1)
			user.apply_status_effect(STATUS_EFFECT_STARCULTIST, src, datum_reference.qliphoth_meter)
	else
		if(!LAZYFIND(cult, user))
			var/cultist_amount = length(cult)
			for(var/mob/living/carbon/human/cultist in cult)
				cultist.adjustSanityLoss(-(15 * cultist_amount))
			HandleQli(-1)
	return

/mob/living/simple_animal/hostile/abnormality/star_luminary/proc/HandleQli(amount)
	if(!datum_reference)
		return
	datum_reference.qliphoth_change(amount)
	var/datum/status_effect/starcultist/obsession
	for(var/mob/living/carbon/human/cultist in cult)
		obsession = cultist.has_status_effect(/datum/status_effect/starcultist)
		obsession.cult_level = datum_reference.qliphoth_meter
		obsession.update()

/mob/living/simple_animal/hostile/abnormality/star_luminary/proc/CultistDeathRage()
	var/cultist_amount = length(cult)
	for(var/mob/living/carbon/human/cultist in cult)
		playsound(get_turf(cultist), "shatter", 50, TRUE)
		cultist.deal_damage((70 + (30 * cultist_amount)), list(WHITE_DAMAGE, BLACK_DAMAGE))

/mob/living/simple_animal/hostile/abnormality/star_luminary/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	var/turf/T = pick(GLOB.department_centers)
	if(breach_type != BREACH_MINING)
		forceMove(T)
	Pulse()
	return

/datum/status_effect/starcultist
	id = "starcultist"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = null
	tick_interval = 2 SECONDS
	var/mob/living/simple_animal/hostile/abnormality/star_luminary/luminary
	var/cult_level
	var/cache
	var/praying = FALSE

/datum/status_effect/starcultist/on_creation(mob/living/new_owner, parent, luminaryqli)
	luminary = parent
	cult_level = luminaryqli
	return ..()

/datum/status_effect/starcultist/on_apply()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	RegisterSignal(status_holder, COMSIG_LIVING_DEATH, PROC_REF(CultistDeath))
	RegisterSignal(status_holder, COMSIG_HUMAN_INSANE, PROC_REF(StartInsanity))
	luminary.cult += status_holder
	cache = cult_level
	status_holder.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, (10 * cult_level))

/datum/status_effect/starcultist/on_remove()
	. = ..()
	var/mob/living/carbon/human/status_holder = owner
	UnregisterSignal(status_holder, COMSIG_LIVING_DEATH)
	if(LAZYFIND(luminary.cult, status_holder))
		luminary.cult -= status_holder

/datum/status_effect/starcultist/tick()
	. = ..()
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjustSanityLoss(1.5 + (0.5 * cult_level))
	if(!praying && status_holder.sanity_lost)
		StartInsanity()
		return

/datum/status_effect/starcultist/proc/update()
	var/mob/living/carbon/human/status_holder = owner
	if(!ishuman(owner))
		return
	status_holder.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -(10 * cache))
	status_holder.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, (10 * cult_level))
	cache = cult_level

/datum/status_effect/starcultist/proc/CultistDeath()
	SIGNAL_HANDLER
	var/mob/living/carbon/human/status_holder = owner
	if(status_holder.stat == DEAD || !status_holder) // Just making sure.
		luminary.CultistDeathRage()
		qdel(src)

/datum/status_effect/starcultist/proc/StartInsanity()
	SIGNAL_HANDLER
	var/mob/living/carbon/human/cultist = owner
	UnregisterSignal(cultist, COMSIG_HUMAN_INSANE)
	praying = TRUE
	addtimer(CALLBACK(src, PROC_REF(CultistInsane)), 1) // Sanity signal gets send before the whole SanityLoss proc is completed, so we need to give it time.

/datum/status_effect/starcultist/proc/CultistInsane()
	var/mob/living/carbon/human/cultist = owner
	QDEL_NULL(cultist.ai_controller)
	cultist.ai_controller = /datum/ai_controller/insane/luminary_trance
	cultist.apply_status_effect(/datum/status_effect/panicked_type/luminary)
	cultist.visible_message(span_bolddanger("[cultist]'s eyes glaze over and they suddenly kneel down, lost in fervent prayer!"))
	cultist.InitializeAIController()

/datum/ai_controller/insane/luminary_trance
	lines_type = /datum/ai_behavior/say_line/insanity_wander/luminary //We use the wander subtype so that it drains sanity
	var/mob/living/simple_animal/hostile/abnormality/star_luminary/luminary

/datum/ai_controller/insane/luminary_trance/PossessPawn(atom/new_pawn)
	. = ..()
	if(!ishuman(new_pawn))
		return
	var/mob/living/carbon/human/cultist = new_pawn
	var/datum/status_effect/starcultist/obsession = cultist.has_status_effect(/datum/status_effect/starcultist)
	if(obsession)
		luminary = obsession.luminary


/datum/ai_controller/insane/luminary_trance/PerformIdleBehavior(delta_time)
	var/mob/living/carbon/human/cultist = pawn
	if(DT_PROB(25, delta_time))
		current_behaviors += GET_AI_BEHAVIOR(lines_type)
		if(!luminary)
			return
		for(var/mob/living/carbon/human/H in oview(9, cultist))
			if(HAS_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE))
				continue
			if(prob(33) || H.sanity_lost)
				H.apply_status_effect(STATUS_EFFECT_STARCULTIST, luminary, luminary.datum_reference.qliphoth_meter)
		cultist.jitteriness += 10
		cultist.do_jitter_animation(cultist.jitteriness)

/datum/status_effect/panicked_type/luminary
	icon = "orangetree"

/datum/ai_behavior/say_line/insanity_wander/luminary //this subtype should make the lines cause white damage.
	lines = list(
		"PLACEHOLDER 1",
		"PLACEHOLDER 2",
		"PLACEHOLDER 3",
		"PLACEHOLDER 4",
	)
