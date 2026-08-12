//As an ALEPH, mountain should be really demanding. The goal is to stuff as much food in its cell as possible to keep it satiated, or use corpses to slow down its hunger.
/mob/living/simple_animal/hostile/limbus_abno/mountain
	true_name = "Mountain of Smiling Bodies"
	egg_icon_state = "mountain_egg"
	maxHealth = 2000
	health = 2000
	pixel_x = -16
	base_pixel_x = -16
	melee_damage_lower = 5
	melee_damage_upper = 10
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 0.5)
	attack_sound = 'sound/abnormalities/mountain/bite.ogg'
	ranged = FALSE
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/scream,
	/datum/action/cooldown/limbus_abno_action/slam,
	/datum/action/cooldown/limbus_abno_action/mountain_spit,
	/datum/action/cooldown/limbus_abno_action/rot_gas,
	/datum/action/cooldown/limbus_abno_action/mosb_garble)

	original_abno = /mob/living/simple_animal/hostile/abnormality/mountain
	abno_additional_instructions = "You like repression and instinct. You are hungry, always hungry, never satisfied. \
	Seeing blood in your cell makes you even hungrier. Eating humanoid corpses can sate you for longer, but it won't last. \
	If left starving, you'll breach, growing bigger with each corpse consumed, but you'll need even more food than usual. Only overwhelming force will calm you down once you're in this state. \
	Your words come apart as you speak them, worse the larger you get - use Flesh-Voice to hold them together when you need to be understood."
	max_counter = 3
	kickstart_timer = 20 MINUTES //More generous timer due to it being a handful once it starts going off.
	//Gets hungry REALLY fast, but will eat nearly anything edible, even if it doesn't give a lot of hunger.
	hunger_cooldown_time =  20 SECONDS
	hunger_bar = 80
	diet_value = 10
	diet_list = list(/obj/item/organ, /obj/item/food, /obj/item/bodypart)
	desire_on_eat = 5
	desire_on_eat_threshold = 70
	desire_on_pet = -30
	rep_desire_gain = 0.1
	rep_desire_loss_at_threshold = 300
	rep_threshold = 100
	rep_min_damage = 30
	insight_cooldown_time = 5 MINUTES
	hated_objects_list = list(/obj/effect/decal/cleanable/blood) //It's not that mountain hates it, but it makes it  thirst for blood even more if it lingers around.
	hated_objects_value = 0.1
	ego_desire_gained = 2
	attunement_family = "smile"
	ego_list = list(/datum/ego_datum/armor/lce/smile)
	var/phase_one_health = 2000
	var/phase_two_health = 3000
	var/phase_three_health = 4000
	var/phase = 1
	var/satiated = FALSE //If they ate a carbon recently or not.
	var/max_starving_patience = 4
	var/starving_patience = 4
	var/body_count = 0 //Only starts to add body counts on breach. Contributes to phase changes.
	var/breached = FALSE
	var/spit_ready = FALSE //If the next open_fire attack will be a spit.
	var/spitting = FALSE
	var/scream_damage = 40
	var/slam_damage = 30
	var/spit_amount = 16
	///Whether speech is being mangled into its own broken voice. On by default - the
	///instructions tell the player it can be switched off, so it is a choice rather than a trap.
	var/garbling = TRUE
	var/list/protected_words = list("clean", "cook", "fight")
	var/list/growls_low = list("Grgh", "Ghhrg", "Krrgh")
	var/list/growls_high = list("Krrrrh", "Grr… Ghrrrgh", "Ghrrr", "KHAAA")

/mob/living/simple_animal/hostile/limbus_abno/mountain/funpet(mob/living/petter)
	. = ..()
	AdjustCounter(-1)
	petter.adjustBlackLoss(40)
	playsound(src, 'sound/abnormalities/mountain/bite.ogg', 70, TRUE)
	to_chat(petter, span_warning("[src] bites your hand!")) //What did you expect.

//Adds Mountain's unique phase/breach/body-count state to the player's numeric readout.
/mob/living/simple_animal/hostile/limbus_abno/mountain/SelfStatusReadout()
	. = ..()
	. += "Phase: [phase] of 3"
	. += "Breached: [breached ? "YES" : "no"]"
	if(breached && phase < 3)
		. += "Bodies until you grow: [max(0, 4 - body_count)]"

/mob/living/simple_animal/hostile/limbus_abno/mountain/Login()
	. = ..()
	icon_living = "mosb_breach"
	icon_state = icon_living
	new /mob/living/carbon/human/species/monkey(get_turf(src))

//We don't really swap phases when mountain dies like the original, instead we make it change phases depending on its HP after updating health.
/mob/living/simple_animal/hostile/limbus_abno/mountain/updatehealth()
	if(!breached)
		return ..()
	var/phase_threshold = maxHealth * 0.3

	if(health < phase_threshold)
		if(phase <= 1)
			Unbreach()
		else
			ChangePhase(FALSE)
	..()

/mob/living/simple_animal/hostile/limbus_abno/mountain/OpenFire(atom/A)
	..()
	if(phase <= 2)
		spit_ready = FALSE
		return FALSE
	if(spitting || !spit_ready)
		return FALSE
	Spit(target)

///If increase is TRUE, we move up a phase, if FALSE, go down.
/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/ChangePhase(increase = TRUE)
	if(increase)
		phase++
		playsound(get_turf(src), 'sound/abnormalities/mountain/level_up.ogg', 75, 1)
		icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
		pixel_x = -32
		base_pixel_x = -32
	else
		phase--
		playsound(get_turf(src), 'sound/abnormalities/mountain/level_down.ogg', 75, 1)
		if(phase <= 1)
			icon = 'ModularLobotomy/_Lobotomyicons/64x64.dmi'
			pixel_x = -16
			base_pixel_x = -16
			maxHealth = phase_one_health

	switch(phase)
		if(2)
			maxHealth = phase_two_health
			icon_living = "mosb_breach"
			melee_damage_lower = 35
			melee_damage_upper = 45
		if(3)
			maxHealth = phase_three_health
			icon_living = "mosb_breach2"
			melee_damage_lower = 55
			melee_damage_upper = 65
	adjustHealth(-maxHealth, FALSE)
	body_count = 0
	icon_state = icon_living
	UpdateBars()

///Whenever mountain gets hungrier during starvation, it loses patience, until it severely loses out on desire.
/mob/living/simple_animal/hostile/limbus_abno/mountain/AdjustHunger(feeding_amount)
	..()
	if(starving && !IsPositive(feeding_amount))
		starving_patience--
		AdjustDesire(-5)
		if(starving_patience == 2)
			to_chat(src, span_warning("Your patience frays. Feed soon, or you'll lash out."))
		else if(starving_patience == 1)
			to_chat(src, span_boldwarning("You are on the verge of a frenzy. FEED."))

	if(starving_patience <= 0)
		starving_patience = max_starving_patience
		to_chat(src, span_warning("YOU NEED TO EAT."))
		Scream(TRUE) //FEED ME.
		AdjustDesire(-40)
		if(breached)
			adjustBruteLoss(maxHealth * 0.1) //Loses 10% health if breached. Better get eating.
			if(phase >= 2)
				Slam(TRUE)

/mob/living/simple_animal/hostile/limbus_abno/mountain/AdjustDesire(desire_amount)
	..()
	if(desire_bar <= 10 && !IsPositive(desire_amount))
		AdjustCounter(-1)

/mob/living/simple_animal/hostile/limbus_abno/mountain/AdjustCounter()
	..()
	if(breached)
		return
	if(counter <= 0)
		Breach()

/mob/living/simple_animal/hostile/limbus_abno/mountain/AbnoEat(atom/food)
	if(istype(food, /obj/item/bodypart/head))
		to_chat(src, span_warning("For some reason, the head looks unappetizing to you."))
		return FALSE
	. = ..()
	if(.) //They already ate whatever was there.
		return .

	var/mob/living/mob_target
	if(isliving(food))
		mob_target = food
	else
		return FALSE

	if(mob_target.stat <= HARD_CRIT)
		return FALSE

	if(istype(mob_target, /mob/living/simple_animal/hostile/limbus_abno))
		to_chat(src, span_warning("You bite down and something bites back. Another specimen is not food."))
		return FALSE

	if(iscarbon(mob_target))
		starving_patience = max_starving_patience
		if(breached)
			adjustBruteLoss(-maxHealth * 0.3)
			body_count++
			if(phase < 3 && body_count < 4)
				var/remaining = 4 - body_count
				to_chat(src, span_notice("Flesh knits over your frame. [remaining] more [remaining == 1 ? "body" : "bodies"] until you swell to your next form."))
		else
			satiated = TRUE
			addtimer(CALLBACK(src, PROC_REF(RegularHunger)), 20 MINUTES)
			hunger_cooldown_time =  1.5 MINUTES //Will now lose a full hunger bar in 15 minutes instead of 2.5
			to_chat(src, span_notice("The corpse fills you deeply. Your hunger will crawl slowly for a while."))
		AdjustHunger(100)
	else
		AdjustHunger(50)
		AdjustDesire(20)

	mob_target.gib()
	if(body_count >= 4)
		ChangePhase(TRUE)

/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/RegularHunger()
	if(satiated)
		to_chat(src, span_notice("The fullness from your last meal fades. Your hunger quickens again."))
	hunger_cooldown_time =  15 SECONDS
	satiated = FALSE

//When breached, become incapable of being satiated. Gets hungry even faster, and will start losing health when starving for too long.
/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/Breach()
	melee_damage_lower = 30
	melee_damage_upper = 25
	hunger_cooldown_time = 5 SECONDS
	max_starving_patience = max_starving_patience * 6 //Severely increase the patience so they don't spam scream every five second.
	breached = TRUE
	satiated = FALSE
	unstable = TRUE
	AddBreachEffect()
	to_chat(src, span_userdanger("You breach! You can no longer be sated the usual way. Devour humanoid corpses to grow larger and mend your wounds, but starving now tears at your health. Only overwhelming force will calm you."))

/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/Unbreach()
	melee_damage_lower = 5
	melee_damage_upper = 10
	breached = FALSE
	max_starving_patience = initial(max_starving_patience)
	unstable = FALSE
	icon_state = icon_living
	AdjustCounter(max_counter)
	AdjustDesire(max_desire)
	AdjustHunger(max_hunger)
	RegularHunger()
	manual_emote("calms down.")
	to_chat(src, span_notice("The frenzy drains away. You settle back down, whole and sated once more."))
	RemoveBreachEffect()

//Speech mangling. treat_message() is the engine's own hook for this - it is where stuttering,
//slurring and derpspeech are applied - so it catches player speech and nothing else. Emotes,
//system messages and the forced "YOU NEED TO EAT" line all bypass it, which is what we want.
//Garbling runs on the parent's OUTPUT, not before it. Reassigning the argument and then calling
//a bare ..() sent the untouched line to the parent, so the mangling was thrown away and she
//spoke normally. Doing it in this order also puts the garbling last, so capitalize() cannot
//re-case a growl.
/mob/living/simple_animal/hostile/limbus_abno/mountain/treat_message(message)
	. = ..(message)
	if(garbling)
		. = GarbleFlesh(.)

///TRUE if this word contains something another specimen is listening for, and so must not be
///broken up. Matched case-insensitively, because findtext is.
/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/IsProtectedWord(word)
	var/lower = lowertext(word)
	for(var/protected in protected_words)
		if(findtext(lower, protected))
			return TRUE
	return FALSE

///Mangles a line into its own voice: words split mid-syllable, punctuation turned into
///ellipses, a guttural thrown in front, and everything trailing off.

///Strength scales with how far gone it is, so the toggle doubles as a status readout - the
///facility can hear what phase it is in. Phase 2 is garbled HARDER than phase 3 on purpose:
///it is the one stage with no coherent line to its name.
/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/GarbleFlesh(message)
	if(!message)
		return message
	var/split_chance = 15
	var/growl_chance = 20
	var/list/growls = growls_low
	if(breached)
		growls = growls_high
		switch(phase)
			if(3)
				split_chance = 50
				growl_chance = 80
			if(2)
				split_chance = 60
				growl_chance = 90
			else
				split_chance = 30
				growl_chance = 50
	var/list/out = list()
	for(var/word in splittext(message, " "))
		var/word_len = length_char(word)
		if(word_len > 3 && prob(split_chance) && !IsProtectedWord(word))
			var/at = rand(2, word_len - 1)
			word = copytext_char(word, 1, at) + "…" + copytext_char(word, at)
		out += word
	message = jointext(out, " ")
	message = replacetext(message, ".", "…")
	message = replacetext(message, ",", "…")
	message = replacetext(message, "!", "…!")
	message = replacetext(message, "?", "…?")
	if(prob(growl_chance))
		message = "[pick(growls)]… [message]"
	//Every line trails off. Skipped only where one is already sitting at the end, so a
	//sentence never comes out with a doubled ellipsis.
	var/last = copytext_char(message, -1)
	if(last != "…" && last != "!" && last != "?")
		message += "…"
	return message

///An ability that makes everyone in area feel disgusted and puke. Cannot be used during a breach since the puke stun is kind of busted in combat.
/datum/action/cooldown/limbus_abno_action/rot_gas
	name = "Rot Gas"
	desc = "Makes everyone puke in a wide area. Useful to show your discontent without screaming. Cannot be used during a breach."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_mosb"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "mustard"
	transparent_when_unavailable = TRUE
	cooldown_time = 1 MINUTES

/datum/action/cooldown/limbus_abno_action/rot_gas/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	if(mosb.breached)
		return FALSE

	return TRUE

/datum/action/cooldown/limbus_abno_action/rot_gas/Trigger()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	StartCooldown()
	mosb.RotGas()

///The gas makes everyone puke, and goes through glass because I don't want to check if every turf has a path towards this for a meme ability.
/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/RotGas()
	playsound(get_turf(src), 'sound/abnormalities/mountain/spit.ogg', 50, 1, 3)
	for(var/turf/T in oview(5, src))
		SLEEP_CHECK_DEATH(0.01)
		new /obj/effect/temp_visual/bee_gas(T) //The bee gas is only visual and does not infect anything by itself, so we can use it freely for this.
		for(var/mob/living/carbon/C in T)
			C.vomit()

///Unfortunately, we're going to need to copy paste most of the original code for convenience when it comes to abilities, with only a few tweaks.
///If a skill is FORCED, it'll ignore friend checks entirely. These are usually triggered during uncontrollable starvation freakouts.
/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/Scream(forced = FALSE)
	visible_message(span_danger("[src] screams wildly!"))
	new /obj/effect/temp_visual/voidout(get_turf(src))
	playsound(get_turf(src), 'sound/abnormalities/mountain/scream.ogg', 75, 1, 5)
	for(var/turf/T in view(7, src))
		for(var/mob/living/L in T)
			if(IsFriend(L) && !forced)
				continue
			if(L != src)
				L.adjustBlackLoss(scream_damage)

/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/Slam(forced = FALSE)
	visible_message(span_danger("[src] slams on the ground!"))
	playsound(get_turf(src), 'sound/abnormalities/mountain/slam.ogg', 75, 1)
	for(var/turf/open/T in view(2, src))
		new /obj/effect/temp_visual/small_smoke/halfsecond(T)
		for(var/mob/living/L in T)
			if(IsFriend(L) && !forced)
				continue
			if(L != src)
				L.adjustBlackLoss(slam_damage)

/mob/living/simple_animal/hostile/limbus_abno/mountain/proc/Spit(atom/target)
	if(IsFriend(target))
		return
	spitting = TRUE
	ranged = FALSE
	visible_message(span_danger("[src] prepares to spit an acidic substance at [target]!"))
	SLEEP_CHECK_DEATH(4)
	playsound(get_turf(src), 'sound/abnormalities/mountain/spit.ogg', 75, 1, 3)
	for(var/k = 1 to 3)
		var/turf/startloc = get_turf(targets_from)
		for(var/i = 1 to spit_amount)
			var/obj/projectile/mountain_spit/limbus/P = new(get_turf(src))
			P.mountain_user = src
			P.starting = startloc
			P.firer = src
			P.fired_from = src
			P.yo = target.y - startloc.y
			P.xo = target.x - startloc.x
			P.original = target
			P.preparePixelProjectile(target, src)
			P.fire()
		SLEEP_CHECK_DEATH(2)
	spit_ready = FALSE
	spitting = FALSE

/datum/action/cooldown/limbus_abno_action/scream
	name = "Scream"
	desc = "Scream your heart right out. Only available when starving and your counter is below 3."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_mosb"
	icon_icon = 'icons/mob/actions/actions_ability.dmi'
	button_icon_state = "screach0"
	transparent_when_unavailable = TRUE
	cooldown_time = 30 SECONDS
	counter_req = 2
	//Deliberately NOT starving_req. The base reads that flag as "unavailable WHILE starving"
	//(lcl_abno.dm: `if(starving_req && abno_user.starving) return FALSE`), which is the exact
	//opposite of this ability's own description and of what it is for - the hunger loop fires
	//Scream by itself when patience runs out. The requirement is enforced below instead.

/datum/action/cooldown/limbus_abno_action/scream/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(!abno_user.starving)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/scream/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	mosb.Scream(FALSE)
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/slam
	name = "Slam"
	desc = "Deal damage in an area around you. Can only be used when breached in your second phase."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_mosb"
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "repulse"
	transparent_when_unavailable = TRUE
	counter_req = 1
	cooldown_time = 45 SECONDS

/datum/action/cooldown/limbus_abno_action/slam/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	if(mosb.phase < 2)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/slam/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	mosb.Slam()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/mountain_spit
	name = "Puke"
	desc = "Puke out a vile bile. Only available on breach on your third phase."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_mosb"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "greenglow"
	transparent_when_unavailable = TRUE
	cooldown_time = 1.5 MINUTES
	counter_req = 1

/datum/action/cooldown/limbus_abno_action/mountain_spit/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	if(mosb.phase < 3)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/mountain_spit/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	mosb.spit_ready = TRUE
	to_chat(mosb, span_warning("You feel bile rising up your throat."))
	mosb.ranged = TRUE
	StartCooldown()
	return TRUE

///Toggles the speech mangling. This is the first LCL action to actually use a `_on` border -
///every other abno sets background_icon_state once and never swaps it - so the frame itself
///tells the player at a glance whether they are currently intelligible.
/datum/action/cooldown/limbus_abno_action/mosb_garble
	name = "Flesh-Voice"
	desc = "Toggle whether your words come apart as you speak them. On by default. Turn it off when you actually need to be understood - asking for food, mostly."
	button_icon = 'ModularLobotomy/_Lobotomyicons/lcl_abno_actions.dmi'
	background_icon_state = "bg_mosb_on" //Matches garbling defaulting to TRUE.
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "mimic_voice"
	transparent_when_unavailable = TRUE
	cooldown_time = 2 SECONDS

/datum/action/cooldown/limbus_abno_action/mosb_garble/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/mountain/mosb = abno_user
	mosb.garbling = !mosb.garbling
	background_icon_state = mosb.garbling ? "bg_mosb_on" : "bg_mosb"
	UpdateButtonIcon()
	to_chat(mosb, mosb.garbling \
		? span_warning("Your jaw slackens. The words come apart on the way out.") \
		: span_notice("You gather the mouths together. You can make yourself understood, for now."))
	StartCooldown()
