// Musical Corruption Brain Trauma
/datum/brain_trauma/special/musical_corruption
	name = "Musical Corruption"
	desc = "Patient exhibits an obsessive need to create 'music' through violence."
	scan_desc = "severe auditory-motor dissociation"
	gain_text = span_warning("You hear a beautiful melody... it demands sacrifices.")
	lose_text = span_notice("The music finally stops.")
	resilience = TRAUMA_RESILIENCE_SURGERY

	var/corruption_points = 100
	var/last_decay_time = 0
	var/decay_interval = 30 SECONDS
	var/butcher_time = 5 SECONDS
	var/is_butchering = FALSE
	var/current_prudence_malus = 0

/datum/brain_trauma/special/musical_corruption/on_gain()
	. = ..()
	START_PROCESSING(SSobj, src)
	RegisterSignal(owner, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	to_chat(owner, span_boldwarning("You must feed the melody... butcher the dead to sustain yourself!"))

/datum/brain_trauma/special/musical_corruption/on_lose(silent)
	STOP_PROCESSING(SSobj, src)
	UnregisterSignal(owner, COMSIG_PARENT_EXAMINE)
	// Remove any remaining prudence debuff
	if(current_prudence_malus && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, current_prudence_malus)
		current_prudence_malus = 0
	return ..()

/datum/brain_trauma/special/musical_corruption/on_life()
	// Override to add butchering check
	. = ..()
	if(!owner.client)
		return
	var/mob/living/carbon/target = owner.pulling
	if(target && target.stat == DEAD && owner.a_intent == INTENT_HELP)
		attempt_butcher(target)

/datum/brain_trauma/special/musical_corruption/process()
	// Decay points over time
	if(world.time >= last_decay_time + decay_interval)
		last_decay_time = world.time
		adjust_points(-1)

	// Apply effects based on corruption level
	var/points_lost = 100 - corruption_points
	if(points_lost >= 20 && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/new_prudence_malus = round(points_lost / 20) * 10
		// Calculate the difference and apply it
		var/malus_diff = new_prudence_malus - current_prudence_malus
		if(malus_diff != 0)
			H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -malus_diff)
			current_prudence_malus = new_prudence_malus
	else if(current_prudence_malus && ishuman(owner))
		// Remove debuff if corruption is back to normal
		var/mob/living/carbon/human/H = owner
		H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, current_prudence_malus)
		current_prudence_malus = 0

	// Red vision and SP damage at low points
	if(corruption_points <= 20)
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.adjustSanityLoss(1)
		if(prob(5))
			to_chat(owner, span_warning("The melody grows faint... you need more!"))

/datum/brain_trauma/special/musical_corruption/proc/adjust_points(amount)
	corruption_points = clamp(corruption_points + amount, 0, 100)

	// Update HUD if human
	// if(ishuman(owner))
		// var/mob/living/carbon/human/H = owner
		// Visual feedback could go here

/datum/brain_trauma/special/musical_corruption/proc/attempt_butcher(mob/living/carbon/target)
	if(is_butchering || !ishuman(owner))
		return

	var/mob/living/carbon/human/source = owner

	// Check if target is valid for butchering
	if(target.stat != DEAD)
		return

	// Start butchering
	is_butchering = TRUE
	source.visible_message(span_danger("[source] begins carving into [target]!"), \
		span_warning("You begin to extract the melody from [target]..."))

	// Show progress to viewers
	var/list/viewers = list()
	for(var/mob/living/L in viewers(7, source))
		if(L != source && L.client)
			viewers |= L
			to_chat(L, span_userdanger("You can't look away from the horrific scene!"))

	// Use a single do_after with callback for SP damage
	if(do_after(source, butcher_time, target))
		complete_butchering(source, target, viewers)
	else
		is_butchering = FALSE
		to_chat(source, span_warning("Your performance is interrupted!"))

/datum/brain_trauma/special/musical_corruption/proc/complete_butchering(mob/living/carbon/human/butcher, mob/living/carbon/target, list/viewers)
	is_butchering = FALSE

	// Determine rewards based on target type
	var/point_reward = 5
	var/sp_reward = 10
	var/viewer_sp_damage = 20

	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.client) // Soulless
			point_reward = 50
			sp_reward = 80
			viewer_sp_damage = 40

	// Apply rewards
	adjust_points(point_reward)
	if(ishuman(butcher))
		butcher.adjustSanityLoss(-sp_reward)

	// Gib the target
	target.gib()
	playsound(target, 'sound/effects/splat.ogg', 70, TRUE)

	// Damage viewer sanity
	for(var/mob/living/L in viewers)
		if(!L.client)
			continue
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			H.adjustSanityLoss(viewer_sp_damage)
			to_chat(H, span_userdanger("The scene burns itself into your mind!"))

	// Feedback
	to_chat(butcher, span_greentext("The melody grows stronger!"))
	butcher.visible_message(span_danger("[butcher] finishes their grisly performance!"))

/datum/brain_trauma/special/musical_corruption/proc/on_examine(mob/living/carbon/human/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(corruption_points <= 50)
		examine_list += span_warning("Their eyes have a distant, haunted look.")
	if(corruption_points <= 20)
		examine_list += span_boldwarning("Blood drips from their fingers like musical notes.")

// Admin proc to check corruption level
/datum/brain_trauma/special/musical_corruption/proc/check_corruption()
	to_chat(usr, "Musical Corruption Points: [corruption_points]/100")
	to_chat(usr, "Prudence Malus: -[(100 - corruption_points) / 20 * 10]")
