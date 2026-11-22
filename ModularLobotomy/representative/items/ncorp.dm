//Ncorp levelers
/obj/item/attribute_increase
	name = "training accelerator"
	desc = "A fluid used to increase the user's stats. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"
	var/amount = 1

/obj/item/attribute_increase/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.adjust_all_attribute_levels(amount)
	qdel(src)


/obj/item/attribute_increase/small
	name = "ncorp small training accelerator"
	icon_state = "ncorp_syringe1"
	amount = 3

/obj/item/attribute_increase/medium
	name = "ncorp medium training accelerator"
	icon_state = "ncorp_syringe2"
	amount = 5

/obj/item/attribute_increase/large
	name = "ncorp large training accelerator"
	icon_state = "ncorp_syringe3"
	amount = 10

/obj/item/attribute_increase/xtralarge
	name = "ncorp extra large training accelerator"
	icon_state = "ncorp_syringe4"
	amount = 20

//Limit increaser
/obj/item/limit_increase
	name = "ncorp limit breaker"
	desc = "A fluid used to increase an agent's maximum potential. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "ncorp_syringe5"
	var/amount = 140
	var/list/allowed_roles = list()

/obj/item/limit_increase/Initialize()
	..()
	if(!LAZYLEN(allowed_roles))
		allowed_roles = GLOB.security_positions // defaults to agents.

/obj/item/limit_increase/attack_self(mob/living/carbon/human/user)
	if(user?.mind?.assigned_role in allowed_roles)
		to_chat(user, span_nicegreen("You feel like you can become even more powerful."))
		user.set_attribute_limit(amount)
		qdel(src)
		return
	to_chat(user, span_notice("This is not for you."))
	return

//Officer limit increase.
/obj/item/limit_increase/officer
	name = "officer limit breaker"
	desc = "A fluid used to increase the limit of L-Corp officer's potential. Use in hand to activate."
	icon_state = "oddity7_gween"
	amount = 80
	allowed_roles = list("Records Officer", "Extraction Officer")

//Temporary attributes
#define STATUS_EFFECT_FORTITUDE /datum/status_effect/ncorp/fortitude
#define STATUS_EFFECT_PRUDENCE /datum/status_effect/ncorp/prudence
#define STATUS_EFFECT_TEMPERANCE /datum/status_effect/ncorp/temperance
#define STATUS_EFFECT_JUSTICE /datum/status_effect/ncorp/justice

/atom/movable/screen/alert/status_effect/ncorp
	name = "N-Corp Fading Ampules"
	desc = "Your attributes are temporarily buffed."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "bg_template"

/datum/status_effect/ncorp
	id = "ncorptemp"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 3000		//Lasts 5 minutes
	alert_type = /atom/movable/screen/alert/status_effect/ncorp
	var/attribute_buff = FORTITUDE_ATTRIBUTE

/datum/status_effect/ncorp/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		L.adjust_attribute_buff(attribute_buff, 15)

/datum/status_effect/ncorp/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		L.adjust_attribute_buff(attribute_buff, -15)

/datum/status_effect/ncorp/fortitude

/datum/status_effect/ncorp/prudence
	attribute_buff = PRUDENCE_ATTRIBUTE

/datum/status_effect/ncorp/temperance
	attribute_buff = TEMPERANCE_ATTRIBUTE

/datum/status_effect/ncorp/justice
	attribute_buff = JUSTICE_ATTRIBUTE

/obj/item/attribute_temporary/justicesmall
	name = "ncorp small fading justice accelerator"
	desc = "A fluid used to increase the user's justice temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"

/obj/item/attribute_temporary/justicesmall/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_JUSTICE)
	qdel(src)

/obj/item/attribute_temporary/temperancesmall
	name = "ncorp small fading temperance  accelerator"
	desc = "A fluid used to increase the user's temperance temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"

/obj/item/attribute_temporary/temperancesmall/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_TEMPERANCE)
	qdel(src)

/obj/item/attribute_temporary/fortitudesmall
	name = "ncorp small fading fortitude accelerator"
	desc = "A fluid used to increase the user's fortitude temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"

/obj/item/attribute_temporary/fortitudesmall/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_FORTITUDE)
	qdel(src)

/obj/item/attribute_temporary/prudencesmall
	name = "ncorp small fading prudence accelerator"
	desc = "A fluid used to increase the user's prudence temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "tcorp_syringe"

/obj/item/attribute_temporary/prudencesmall/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_PRUDENCE)
	qdel(src)

//Generalized temporary ampules
/obj/item/attribute_temporary/stattemporary
	name = "ncorp medium fading accelerator"
	desc = "A fluid used to increase the user's stats temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "ncorp_syringe2"

/obj/item/attribute_temporary/stattemporary/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(/datum/status_effect/nstats)
	qdel(src)

/datum/status_effect/nstats
	id = "nstats"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/ncorp
	duration = 1200

/datum/status_effect/nstats/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, 15)
	H.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, 15)
	H.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, 15)
	H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, 15)

/datum/status_effect/nstats/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -15)
	H.adjust_attribute_buff(TEMPERANCE_ATTRIBUTE, -15)
	H.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, -15)
	H.adjust_attribute_buff(PRUDENCE_ATTRIBUTE, -15)

//Focused Ncorp ampules
#define STATUS_EFFECT_FORTITUDE_FOCUS /datum/status_effect/nfocus/fortitude
#define STATUS_EFFECT_PRUDENCE_FOCUS /datum/status_effect/nfocus/prudence
#define STATUS_EFFECT_TEMPERANCE_FOCUS /datum/status_effect/nfocus/temperance
#define STATUS_EFFECT_JUSTICE_FOCUS /datum/status_effect/nfocus/justice

/datum/status_effect/nfocus
	id = "nfocus"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 3000		//Lasts 5 minutes
	alert_type = /atom/movable/screen/alert/status_effect/ncorp
	var/attribute_buff = FORTITUDE_ATTRIBUTE

/datum/status_effect/ncorp/on_apply()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		L.adjust_attribute_buff(attribute_buff, 20)

/datum/status_effect/ncorp/on_remove()
	. = ..()
	if(ishuman(owner))
		var/mob/living/carbon/human/L = owner
		L.adjust_attribute_buff(attribute_buff, -20)

/datum/status_effect/nfocus/fortitude

/datum/status_effect/nfocus/prudence
	attribute_buff = PRUDENCE_ATTRIBUTE

/datum/status_effect/nfocus/temperance
	attribute_buff = TEMPERANCE_ATTRIBUTE

/datum/status_effect/nfocus/justice
	attribute_buff = JUSTICE_ATTRIBUTE

/obj/item/attribute_temporary/justicebig
	name = "ncorp large fading justice accelerator"
	desc = "A fluid used to increase the user's justice temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "ncorp_syringe3"

/obj/item/attribute_temporary/justicebig/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_JUSTICE_FOCUS)
	qdel(src)

/obj/item/attribute_temporary/temperancebig
	name = "ncorp large fading temperance  accelerator"
	desc = "A fluid used to increase the user's temperance temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "ncorp_syringe3"

/obj/item/attribute_temporary/temperancebig/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_TEMPERANCE_FOCUS)
	qdel(src)

/obj/item/attribute_temporary/fortitudebig
	name = "ncorp large fading fortitude accelerator"
	desc = "A fluid used to increase the user's fortitude temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "ncorp_syringe3"

/obj/item/attribute_temporary/fortitudebig/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_FORTITUDE_FOCUS)
	qdel(src)

/obj/item/attribute_temporary/prudencebig
	name = "ncorp large fading prudence accelerator"
	desc = "A fluid used to increase the user's prudence temporarily. Use in hand to activate."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "ncorp_syringe3"

/obj/item/attribute_temporary/prudencebig/attack_self(mob/living/carbon/human/user)
	to_chat(user, span_nicegreen("You suddenly feel different."))
	user.apply_status_effect(STATUS_EFFECT_PRUDENCE_FOCUS)
	qdel(src)




//Scrolls
/obj/item/ncorp_scroll
	name = "Blank N-Corp Scroll"
	desc = "A blank N-Corporation Scroll."
	icon = 'ModularLobotomy/_Lobotomyicons/ncorp_scrolls.dmi'
	var/special = "Nothing. It's a blank Scroll."
	icon_state = "ncorp_blank"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_BULKY
	var/in_use
	var/ticks_left = 5
	var/tick_speed = 2 SECONDS
	var/infinite_use = FALSE	//You can make stronger scrolls
	var/list/say_lines = list("AAAAAAAAAAAAAAAA")
	var/say_chance = 10			//Some offensive scrolls, you REALLY want to know when someone is saying it.

/obj/item/ncorp_scroll/examine(mob/living/carbon/human/user)
	. = ..()
	if(infinite_use)
		. += span_notice("This scroll has infinite use, and takes [ticks_left] to finish.")
	else
		. += span_notice("Charges left: [ticks_left]/[initial(ticks_left)].")

	. += span_notice("[special]")
	. += span_notice("Bulky, but fits in your pocket!")


/obj/item/ncorp_scroll/attack_self(mob/living/carbon/human/user)
	..()
	if(in_use)
		return
	in_use = TRUE
	UseLoop(user)

/obj/item/ncorp_scroll/proc/UseLoop(mob/living/carbon/human/user)
	if(ticks_left <= 0)
		if(say_chance == 100)
			user.say(pick(say_lines))		//So you can't just game it

		in_use = FALSE
		EndLoop(user)
		if(!infinite_use)
			qdel(src)
		return

	if(prob(say_chance))
		user.say(pick(say_lines))

	//Okay, the charges don't regenerate unless it's infinite.
	if(!do_after(user, tick_speed, src))
		in_use = FALSE
		if(infinite_use)
			ticks_left = initial(ticks_left)
		return

	ticks_left--
	TickAbility(user)
	UseLoop(user)

//Some Scrolls activate every tick.
/obj/item/ncorp_scroll/proc/TickAbility(mob/living/carbon/human/user)
	return

//Some scrolls have a stronger effect if they are used infinitely.
/obj/item/ncorp_scroll/proc/EndLoop(mob/living/carbon/human/user)
	return

//Only really here for IFF in City
/obj/item/ncorp_scroll/proc/ArmorCheck(mob/living/carbon/ally)
	var/obj/item/clothing/suit/armor/ego_gear/city/ncorp/klein = ally.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	var/obj/item/clothing/suit/armor/ego_gear/city/ncorp/vet/mittle = ally.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	var/obj/item/clothing/suit/armor/ego_gear/city/grosshammmer/gross = ally.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	var/obj/item/clothing/suit/armor/ego_gear/city/ncorpcommander/kromer = ally.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(klein) || istype(mittle) || istype(gross) || istype(kromer))
		return TRUE
	return FALSE

/obj/item/ncorp_scroll/sp
	name = "N-Corp Sanity Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll heals your SP when read."
	icon_state = "ncorp_sp"
	ticks_left = 10
	custom_price = 100
	say_lines = list("A prayer... for better days...", "A moment of peace...", "I wish to be better...")

/obj/item/ncorp_scroll/sp/TickAbility(mob/living/carbon/human/user)
	user.adjustSanityLoss(-5)

/obj/item/ncorp_scroll/sp/EndLoop(mob/living/carbon/human/user)
	user.adjustSanityLoss(-20)	//Little bonus. As a treat


/obj/item/ncorp_scroll/spwide
	name = "N-Corp Sermon Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll heals the SP of allies when read."
	icon_state = "ncorp_spaoe"
	ticks_left = 3
	tick_speed = 5 SECONDS
	custom_price = 250
	say_lines = list("Let us pray....","A prayer... for better days...", "A moment of peace...", "I wish to be better...")

/obj/item/ncorp_scroll/spwide/TickAbility(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		H.adjustSanityLoss(-10)

/obj/item/ncorp_scroll/spwide/EndLoop(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		H.adjustSanityLoss(-20)


/obj/item/ncorp_scroll/strength
	name = "N-Corp Strength Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll gives Strength when read. when finishing, gives a stronger strength bonus."
	icon_state = "ncorp_strength"
	ticks_left = 5
	custom_price = 225
	say_lines = list("Grant me fury...", "Death to my enemies...")

/obj/item/ncorp_scroll/strength/TickAbility(mob/living/carbon/human/user)
	user.apply_lc_strength(1)

/obj/item/ncorp_scroll/strength/EndLoop(mob/living/carbon/human/user)
	user.apply_lc_strength(3)

/obj/item/ncorp_scroll/strengthwide
	name = "N-Corp Area Strength Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll gives Strength to all allies when read. when finishing, gives a stronger strength bonus."
	icon_state = "ncorp_strengthaoe"
	tick_speed = 5 SECONDS
	ticks_left = 3
	custom_price = 300
	say_lines = list("Grant us fury...", "Death to our enemies...")

/obj/item/ncorp_scroll/strengthwide/TickAbility(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		H.apply_lc_strength(1)

/obj/item/ncorp_scroll/strengthwide/EndLoop(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		H.apply_lc_strength(3)


/obj/item/ncorp_scroll/protection
	name = "N-Corp Protection Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll gives Protection when read. when finishing, gives a stronger protection bonus."
	icon_state = "ncorp_protection"
	ticks_left = 5
	custom_price = 225
	say_lines = list("Protect my body.....", "Keep me safe...")

/obj/item/ncorp_scroll/protection/TickAbility(mob/living/carbon/human/user)
	user.apply_lc_protection(1)

/obj/item/ncorp_scroll/protection/EndLoop(mob/living/carbon/human/user)
	user.apply_lc_protection(3)


/obj/item/ncorp_scroll/combat
	name = "N-Corp Combat Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll gives Protection and Strength when read."
	icon_state = "ncorp_combat"
	ticks_left = 5
	tick_speed = 5 SECONDS
	custom_price = 250
	say_lines = list("DEATH TO MY ENEMIES!!")

/obj/item/ncorp_scroll/combat/TickAbility(mob/living/carbon/human/user)
	user.apply_lc_protection(1)
	user.apply_lc_strength(1)


/obj/item/ncorp_scroll/cleanse
	name = "N-Corp Cleansing Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This scroll cleansess burn and toxins when read."
	icon_state = "ncorp_cleanse"
	ticks_left = 5
	custom_price = 100
	say_lines = list("My body please....", "Cleanse my soul...")

/obj/item/ncorp_scroll/cleanse/TickAbility(mob/living/carbon/human/user)
	user.adjustFireLoss(-5)
	user.adjustToxLoss(-5)

/obj/item/ncorp_scroll/cleanse/EndLoop(mob/living/carbon/human/user)
	user.adjustFireLoss(-10)
	user.adjustToxLoss(-10)


/obj/item/ncorp_scroll/randomstr
	name = "N-Corp Volatile Strength Scroll"
	desc = "A scroll sold by N-Corp."
	special = "This scroll gives the user a random strength type."
	icon_state = "ncorp_randomstr"
	ticks_left = 5
	custom_price = 200
	say_lines = list("Grant us fury...", "Death to our enemies...")

/obj/item/ncorp_scroll/randomstr/TickAbility(mob/living/carbon/human/user)
	var/str = pick("red", "white", "black", "pale")
	switch(str)
		if("red")
			user.apply_lc_red_strength(3)
		if("white")
			user.apply_lc_white_strength(3)
		if("black")
			user.apply_lc_black_strength(3)
		if("pale")
			user.apply_lc_pale_strength(3)

/obj/item/ncorp_scroll/randomprot
	name = "N-Corp Volatile Protection Scroll"
	desc = "A scroll sold by N-Corp."
	special = "This scroll gives the user a random protection type."
	icon_state = "ncorp_randomprot"
	ticks_left = 5
	custom_price = 200
	say_lines = list("Protect my body.....", "Keep me safe...")

/obj/item/ncorp_scroll/randomprot/TickAbility(mob/living/carbon/human/user)
	var/str = pick("red", "white", "black", "pale")
	switch(str)
		if("red")
			user.apply_lc_red_protection(3)
		if("white")
			user.apply_lc_white_protection(3)
		if("black")
			user.apply_lc_black_protection(3)
		if("pale")
			user.apply_lc_pale_protection(3)


/obj/item/ncorp_scroll/nailup
	name = "N-Corp Unladen Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll removes certain slowdown when read. when finishing, gives a boost to speed."
	icon_state = "ncorp_nailup"
	ticks_left = 5
	custom_price = 300
	say_lines = list("Savor the pain...", "Drive the flesh...", "Seize the heretic...")

//for NCorpers this means moving much faster
/obj/item/ncorp_scroll/nailup/TickAbility(mob/living/carbon/human/user)
	user.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	user.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/equipment_speedmod)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, remove_movespeed_mod_immunities), /datum/movespeed_modifier/damage_slowdown), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob/living, remove_movespeed_mod_immunities), /datum/movespeed_modifier/equipment_speedmod), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/item/ncorp_scroll/nailup/EndLoop(mob/living/carbon/human/user)
	user.add_movespeed_modifier(/datum/movespeed_modifier/unladen)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/unladen), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)


/obj/item/ncorp_scroll/nailupwide
	name = "N-Corp Area Unladen Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This Scroll removes certain slowdown from all allies when read. when finishing, gives a boost to speed."
	icon_state = "ncorp_nailupaoe"
	ticks_left = 3
	tick_speed = 5 SECONDS
	custom_price = 450
	say_lines = list("Pursue them to the end...", "Savor the pain...", "Drive the flesh...", "Seize the heretic...")

//for NCorpers this means moving much faster
/obj/item/ncorp_scroll/nailupwide/TickAbility(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		H.add_movespeed_mod_immunities(H, /datum/movespeed_modifier/damage_slowdown)
		H.add_movespeed_mod_immunities(H, /datum/movespeed_modifier/equipment_speedmod)
		addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living, remove_movespeed_mod_immunities), /datum/movespeed_modifier/damage_slowdown), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living, remove_movespeed_mod_immunities), /datum/movespeed_modifier/equipment_speedmod), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/item/ncorp_scroll/nailupwide/EndLoop(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		H.add_movespeed_modifier(/datum/movespeed_modifier/unladen)
		addtimer(CALLBACK(H, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/unladen), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/movespeed_modifier/unladen
	multiplicative_slowdown = -0.3


//PVP Scrolls below
/obj/item/ncorp_scroll/flame
	name = "N-Corp Flame Scroll"
	desc = "A scroll sold by N-Corp"
	special = "This scroll lights all nearby humans on fire when read."
	icon_state = "ncorp_fire"
	ticks_left = 1
	tick_speed = 4 SECONDS
	say_lines = list("BURN HERETIC!", "FIRE AND BRIMSTONE!")
	say_chance = 100
	custom_price = 200 //Im making this cheap because its a single stack of NORMAL fire and everyone has extinguishers

/obj/item/ncorp_scroll/flame/TickAbility(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(!ArmorCheck(H))
			H.adjust_fire_stacks(1)
			H.IgniteMob()
	//Light the user on fire too. Fuck 'em
	user.adjust_fire_stacks(1)
	user.IgniteMob()


/obj/item/ncorp_scroll/death
	name = "N-Corp Death Scroll"
	desc = "A scroll sold by N-Corp"
	special = "When this scroll is fully read, the user explodes"
	icon_state = "ncorp_explode"
	ticks_left = 3
	tick_speed = 4 SECONDS
	say_lines = list("My body is sacrifice...")
	say_chance = 100
	custom_price = 0
	var/boom_damage = 100

//No tick ability.
/obj/item/ncorp_scroll/death/EndLoop(mob/living/carbon/human/user)
	user.gib()
	for(var/mob/living/carbon/human/H in view(3, user))
		if(!ArmorCheck(H))
			H.deal_damage(boom_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
			H.deal_damage(boom_damage * 0.5, FIRE, src, attack_type = (ATTACK_TYPE_SPECIAL))
			if(H.health < 0)
				H.gib()
	new /obj/effect/temp_visual/explosion(get_turf(src))
	var/datum/effect_system/smoke_spread/S = new
	S.set_up(3, get_turf(src))
	S.start()


/obj/item/ncorp_scroll/naildown
	name = "N-Corp Nailing Scroll"
	desc = "A scroll sold by N-Corp"
	special = "When this scroll is fully read all nearby humans are slowed by nails"
	icon_state = "ncorp_naildown"
	ticks_left = 1
	tick_speed = 4 SECONDS
	say_lines = list("HAMMERS SHALL NAIL YOU DOWN!!", "SIN WEIGHS UPON YOU!!")
	say_chance = 100
	custom_price = 600 //Costliest scroll so far because slowdown is absurdly strong

/obj/item/ncorp_scroll/flame/TickAbility(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(!ArmorCheck(H))
			H.add_movespeed_modifier(/datum/movespeed_modifier/naileddown)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/naileddown), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
			new /obj/effect/temp_visual/remorse(get_turf(H))
	//You also get hit by the slowdown
	user.add_movespeed_modifier(/datum/movespeed_modifier/naileddown)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/naileddown), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
	new /obj/effect/temp_visual/remorse(get_turf(user))
	playsound(user, 'sound/weapons/fixer/generic/nail2.ogg', 100, FALSE, 5)

/datum/movespeed_modifier/naileddown
	multiplicative_slowdown = 0.5


//Scrolls below are just copypasted versions of existing buff scrolls but for COL specifically, just defining the subtype in a proc should be enough
/obj/item/ncorp_scroll/strengthwide/col/TickAbility(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		if(ArmorCheck(H))
			H.apply_lc_strength(1)

/obj/item/ncorp_scroll/strengthwide/col/EndLoop(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		if(ArmorCheck(H))
			H.apply_lc_strength(3)


/obj/item/ncorp_scroll/nailupwide/col/TickAbility(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		if(ArmorCheck(H))
			H.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
			H.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/equipment_speedmod)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living, remove_movespeed_mod_immunities), /datum/movespeed_modifier/damage_slowdown), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living, remove_movespeed_mod_immunities), /datum/movespeed_modifier/equipment_speedmod), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/item/ncorp_scroll/nailupwide/col/EndLoop(mob/living/carbon/human/user)
	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue
		if(ArmorCheck(H))
			H.add_movespeed_modifier(/datum/movespeed_modifier/unladen)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/unladen), 10 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

