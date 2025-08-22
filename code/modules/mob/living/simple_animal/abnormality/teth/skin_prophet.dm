/mob/living/simple_animal/hostile/abnormality/skin_prophet
	name = "Skin Prophet"
	desc = "A little fleshy being reading a tiny book."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "skin_prophet"
	core_icon = "prophet_egg"
	portrait = "skin_prophet"
	maxHealth = 600
	health = 600
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0.2)
	threat_level = TETH_LEVEL
	can_breach = TRUE
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(70, 60, 50, 50, 40),
		ABNORMALITY_WORK_INSIGHT = list(70, 60, 50, 50, 40),
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = 0,
	)
	work_damage_amount = 6	//Gets more later
	work_damage_type = WHITE_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/visions,
		/datum/ego_datum/armor/visions,
	)
	gift_type = /datum/ego_gifts/visions
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS
	chem_type = /datum/reagent/abnormality/sin/wrath

	observation_prompt = "Candles quietly burn away. <br>\
		Scribbling sounds are all that fill the air. <br>\
		A trio of eyes takes turns glaring into a grand tome, bound in skin. <br>\
		You can’t tell what it’s referencing, <br>\
		or if there is any deliberation in its writing; <br>\
		hands are busy nonetheless. <br>\
		Yearning for destruction and doom, it writes and writes and writes. <br>\
		You feel the passages it’s writing may be prophecies for someplace and sometime."
	observation_choices = list(
		"Snuff out the candles" = list(TRUE, "You hushed the candles, one by one. <br>\
			The space grew darker, but its hands won’t stop. <br>\
			The only light left was on the quill it held. <br>\
			Even that was snuffed by our breaths. <br>\
			Then, the whole place went dark. <br>\
			All that’s left is the pen in its hand."),
		"Peek at the book" = list(FALSE, "!@)(!@&)&*%(%@!@#*(#)*(%&!@#$ <br>\
			@$*@)$ ? <br> @#$!!@#* ! <br> @*()!%&$(^!!!!@&(@)"),
	)

	var/list/speak_list = list(
		"!@)(!@&)&*%(%@!@#*(#)*(%&!@#$",
		"@$*@)$?",
		"@#$!!@#*!",
		"@*()!%&$(^!!!!@&(@)",
	)
	var/candles = 0
	var/list/breach_candles = list()
	var/breaching = FALSE

/mob/living/simple_animal/hostile/abnormality/skin_prophet/WorkChance(mob/living/carbon/human/user, chance)
	//work damage starts at 7, + candles stuffed
	work_damage_amount = initial(work_damage_amount) + candles

	//If you're doing rep or temeprance then your work chance is your total buffs combined, and damage is increased too
	if(chance == 0)
		var/totalbuff = get_level_buff(user, FORTITUDE_ATTRIBUTE) + get_level_buff(user, PRUDENCE_ATTRIBUTE) + get_level_buff(user, TEMPERANCE_ATTRIBUTE) + get_level_buff(user, JUSTICE_ATTRIBUTE)
		chance = totalbuff
		work_damage_amount += totalbuff/10
	return chance

/mob/living/simple_animal/hostile/abnormality/skin_prophet/WorktickFailure(mob/living/carbon/human/user)
	if(prob(30))
		say(pick(speak_list))
	..()

//If you success on temperance or repression, clear all your temperance/justice buffs and then add to your max stats.
//You're on the hook for any changes in your attribute
/mob/living/simple_animal/hostile/abnormality/skin_prophet/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(work_type == ABNORMALITY_WORK_ATTACHMENT)
		say(pick(speak_list))

		//Don't try it without any buffs.
		if(get_level_buff(user, TEMPERANCE_ATTRIBUTE) <=0)
			user.dust()
			return
		user.adjust_attribute_limit(get_level_buff(user, TEMPERANCE_ATTRIBUTE))
		user.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -get_level_buff(user, TEMPERANCE_ATTRIBUTE))

	if(work_type == ABNORMALITY_WORK_REPRESSION)
		say(pick(speak_list))

		if(get_level_buff(user, JUSTICE_ATTRIBUTE) <=0)
			user.dust()
			return

		user.adjust_attribute_limit(get_level_buff(user, JUSTICE_ATTRIBUTE))
		user.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -get_level_buff(user, JUSTICE_ATTRIBUTE))
	return

/mob/living/simple_animal/hostile/abnormality/skin_prophet/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	say(pick(speak_list))
	//He has 10 candles. Each snuffed candle deals more work damage
	if(candles != 10)
		candles += 1
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/skin_prophet/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	if(breaching)
		return
	breaching = TRUE
	// Teleport to a random department center
	var/turf/breach_location = pick(GLOB.department_centers)
	if(breach_location)
		forceMove(breach_location)
	// Start setting fires
	addtimer(CALLBACK(src, PROC_REF(SpreadFire)), 1 SECONDS)
	// Spawn 7 candles at xeno spawn points
	SpawnCandles()
	say("!@#$%^&*()!@#$%^&*()!@#$%^&*()!")

/mob/living/simple_animal/hostile/abnormality/skin_prophet/Move()
	if(breaching)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/skin_prophet/proc/SpreadFire()
	if(!breaching || QDELETED(src))
		return
	for(var/turf/open/T in shuffle(view(7, src)))
		// Check if there's already fire on this exact tile to prevent overlap
		if(!locate(/obj/effect/prophet_fire) in T)
			if(prob(80))
				new /obj/effect/prophet_fire(T)
	addtimer(CALLBACK(src, PROC_REF(SpreadFire)), 4 SECONDS)

/mob/living/simple_animal/hostile/abnormality/skin_prophet/proc/SpawnCandles()
	if(!LAZYLEN(GLOB.xeno_spawn))
		return
	for(var/i = 1 to 7)
		var/obj/structure/prophet_candle/C = new()
		C.forceMove(pick(GLOB.xeno_spawn))
		C.transform = matrix(3, MATRIX_SCALE)
		C.prophet_reference = src
		breach_candles += C

/mob/living/simple_animal/hostile/abnormality/skin_prophet/proc/CandleDestroyed(obj/structure/prophet_candle/C)
	breach_candles -= C
	if(!LAZYLEN(breach_candles) && breaching)
		// All candles destroyed, kill the prophet
		say("@#$!!@#*!")
		// Clean up remaining fires
		for(var/obj/effect/prophet_fire/F in range(20, src))
			qdel(F)
		breaching = FALSE
		death()

// Prophet's special fire effect
/obj/effect/prophet_fire
	gender = PLURAL
	name = "prophetic flames"
	desc = "Otherworldly fire that burns with an eerie glow."
	icon = 'icons/effects/effects.dmi'
	icon_state = "turf_fire"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	color = "#FF6600"
	var/damaging = FALSE

/obj/effect/prophet_fire/Initialize()
	. = ..()
	QDEL_IN(src, 30 SECONDS)

/obj/effect/prophet_fire/Crossed(atom/movable/AM)
	. = ..()
	if(!damaging)
		damaging = TRUE
		DoDamage()

/obj/effect/prophet_fire/proc/DoDamage()
	var/dealt_damage = FALSE
	for(var/mob/living/L in get_turf(src))
		if(ishuman(L))
			var/mob/living/carbon/human/H = L
			H.deal_damage(3, WHITE_DAMAGE)
			H.apply_lc_burn(1)
			dealt_damage = TRUE
	if(!dealt_damage)
		damaging = FALSE
		return
	addtimer(CALLBACK(src, PROC_REF(DoDamage)), 5)

// Candle structure for containment
/obj/structure/prophet_candle
	name = "prophetic candle"
	desc = "A strange candle that seems to burn with otherworldly energy. It must be destroyed."
	icon = 'icons/obj/candle.dmi'
	icon_state = "candle1_lit"
	density = FALSE
	anchored = TRUE
	max_integrity = 50
	integrity_failure = 0
	var/mob/living/simple_animal/hostile/abnormality/skin_prophet/prophet_reference

/obj/structure/prophet_candle/Initialize()
	. = ..()
	set_light(2, 1, "#FF6600")
	// Add red glowing outline
	add_filter("prophet_glow", 2, list("type" = "outline", "color" = "#ff000060", "size" = 2))
	addtimer(CALLBACK(src, PROC_REF(glow_loop)), rand(1,19))

/obj/structure/prophet_candle/proc/glow_loop()
	var/filter = get_filter("prophet_glow")
	if(filter)
		animate(filter, alpha = 110, time = 15, loop = -1)
		animate(alpha = 40, time = 25)

/obj/structure/prophet_candle/examine(mob/user)
	. = ..()
	. += span_warning("It must be destroyed to contain the Skin Prophet!")

/obj/structure/prophet_candle/Destroy()
	remove_filter("prophet_glow")
	if(prophet_reference)
		prophet_reference.CandleDestroyed(src)
	return ..()

