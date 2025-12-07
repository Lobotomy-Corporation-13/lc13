/datum/antagonist/wizard/arbiter
	name = "Incomplete Arbiter"
	roundend_category = "arbiters"
	antagpanel_category = "The Head"
	give_objectives = FALSE
	move_to_lair = FALSE
	outfit_type = /datum/outfit/arbiter
	antag_attributes = list(
		FORTITUDE_ATTRIBUTE = 130,
		PRUDENCE_ATTRIBUTE = 130,
		TEMPERANCE_ATTRIBUTE = 130,
		JUSTICE_ATTRIBUTE = 130
		)

	var/list/spell_types = list(
		/obj/effect/proc_holder/spell/aimed/fairy,
		/obj/effect/proc_holder/spell/aimed/pillar,
		/obj/effect/proc_holder/spell/aoe_turf/repulse/arbiter,
		/obj/effect/proc_holder/spell/aoe_turf/knock/arbiter,
		/obj/effect/proc_holder/spell/targeted/touch/arbiterpunch,
		)

/datum/antagonist/wizard/arbiter/greet()
	to_chat(owner, span_boldannounce("You are the Arbiter!"))

/datum/antagonist/wizard/arbiter/farewell()
	to_chat(owner, span_boldannounce("You have been fired from The Head. Your services are no longer needed."))

/datum/antagonist/wizard/arbiter/apply_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/human/M = mob_override || owner.current
	add_antag_hud(antag_hud_type, antag_hud_name, M)
	M.faction |= "Head"
	M.faction |= "hostile"
	M.faction -= "neutral"
	ADD_TRAIT(M, TRAIT_BOMBIMMUNE, "Arbiter") // We truly are the elite agent of the Head
	ADD_TRAIT(M, TRAIT_STUNIMMUNE, "Arbiter")
	ADD_TRAIT(M, TRAIT_SLEEPIMMUNE, "Arbiter")
	ADD_TRAIT(M, TRAIT_PUSHIMMUNE, "Arbiter")
	ADD_TRAIT(M, TRAIT_IGNOREDAMAGESLOWDOWN, "Arbiter")
	ADD_TRAIT(M, TRAIT_NOFIRE, "Arbiter")
	ADD_TRAIT(M, TRAIT_NODISMEMBER, "Arbiter")
	ADD_TRAIT(M, TRAIT_SANITYIMMUNE, "Arbiter")
	ADD_TRAIT(M, TRAIT_BRUTEPALE, "Arbiter")
	ADD_TRAIT(M, TRAIT_BRUTESANITY, "Arbiter")
	ADD_TRAIT(M, TRAIT_TRUE_NIGHT_VISION, "Arbiter")
	M.update_sight() //Nightvision trait wont matter without it
	M.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, 500) // Obviously they are very tough
	for(var/spell_type in spell_types)
		var/obj/effect/proc_holder/spell/S = new spell_type
		M.mind?.AddSpell(S)

/datum/antagonist/wizard/arbiter/remove_innate_effects(mob/living/mob_override)
	var/mob/living/carbon/human/M = mob_override || owner.current
	remove_antag_hud(antag_hud_type, M)
	M.faction -= "Head"
	M.faction -= "hostile"
	M.faction += "neutral"
	REMOVE_TRAIT(M, TRAIT_BOMBIMMUNE, "Arbiter") // We truly are the elite agent of the Head
	REMOVE_TRAIT(M, TRAIT_STUNIMMUNE, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_SLEEPIMMUNE, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_PUSHIMMUNE, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_IGNOREDAMAGESLOWDOWN, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_NOFIRE, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_NODISMEMBER, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_SANITYIMMUNE, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_BRUTEPALE, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_BRUTESANITY, "Arbiter")
	REMOVE_TRAIT(M, TRAIT_TRUE_NIGHT_VISION, "Arbiter")
	M.update_sight() //Removing nightvision wont matter without it
	M.adjust_attribute_buff(FORTITUDE_ATTRIBUTE, -500)

/datum/outfit/arbiter
	name = "Arbiter"

	uniform = /obj/item/clothing/under/suit/lobotomy/extraction/arbiter
	suit = /obj/item/clothing/suit/armor/extraction/arbiter
	neck = /obj/item/clothing/neck/cloak/arbiter
	shoes = /obj/item/clothing/shoes/combat
	ears = /obj/item/radio/headset/headset_head/alt
	id = /obj/item/card/id

/datum/outfit/arbiter/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	if(visualsOnly)
		return

	var/obj/item/card/id/W = H.wear_id
	W.assignment = "Arbiter"
	W.registered_name = H.real_name
	W.update_label()
	..()

//Spawner
/obj/effect/mob_spawn/human/arbiter
	name = "The Arbiter"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_s"
	short_desc = "You are The Arbiter."
	important_info = "You are hostile to L-Corp. Assist abnormalities in killing them all."
	outfit = /datum/outfit/arbiter
	max_integrity = 9999999
	density = TRUE
	roundstart = FALSE
	death = FALSE

/obj/effect/mob_spawn/human/arbiter/special(mob/living/new_spawn)
	new_spawn.mind.add_antag_datum(/datum/antagonist/wizard/arbiter)

/obj/effect/mob_spawn/human/arbiter/complete

/obj/effect/mob_spawn/human/arbiter/complete/special(mob/living/new_spawn)
	new_spawn.mind.add_antag_datum(/datum/antagonist/wizard/arbiter/complete)

/datum/antagonist/wizard/arbiter/complete
	name = "Arbiter"
	spell_types = list(
		/obj/effect/proc_holder/spell/aimed/fairy,
		/obj/effect/proc_holder/spell/aimed/pillar,
		/obj/effect/proc_holder/spell/aoe_turf/repulse/arbiter,
		/obj/effect/proc_holder/spell/pointed/lock,
		/obj/effect/proc_holder/spell/aoe_turf/knock/arbiter,
		/obj/effect/proc_holder/spell/targeted/touch/arbiterpunch,
		/obj/effect/proc_holder/spell/aoe_turf/singularity,
	)

/obj/effect/proc_holder/spell/aoe_turf/singularity
	name = "Singularity Swap"
	desc = "Utilize a different singularity to deal a different damage type."
	school = SCHOOL_EVOCATION
	charge_max = 150
	range = 15
	clothes_req = FALSE
	antimagic_allowed = TRUE
	invocation_type = "none"
	base_icon_state = "singularity"
	action_icon_state = "singularity"
	sound = 'sound/magic/castsummon.ogg'
	var/damage_type = BLACK_DAMAGE
	var/queued_damage_type = PALE_DAMAGE
	var/list/damage_type_list = list(RED_DAMAGE, WHITE_DAMAGE, BLACK_DAMAGE, PALE_DAMAGE)
	var/filter

/obj/effect/proc_holder/spell/aoe_turf/singularity/Click()
	var/list/damagetype_icons = list(
		RED_DAMAGE = image(icon = 'icons/mob/actions/actions_spells.dmi', icon_state = "RED_DAMAGE"),
		WHITE_DAMAGE = image(icon = 'icons/mob/actions/actions_spells.dmi', icon_state = "WHITE_DAMAGE"),
		BLACK_DAMAGE = image(icon = 'icons/mob/actions/actions_spells.dmi', icon_state = "BLACK_DAMAGE"),
		PALE_DAMAGE = image(icon = 'icons/mob/actions/actions_spells.dmi', icon_state = "PALE_DAMAGE"),
	)
	var/choice = show_radial_menu(usr, usr, damagetype_icons, radius = 42)
	if(!choice)
		return
	queued_damage_type = choice
	. = ..()

/obj/effect/proc_holder/spell/aoe_turf/singularity/cast(list/targets,mob/user = usr)
	damage_type = queued_damage_type
	playMagSound()

	to_chat(usr, span_nicegreen("You are now dealing [damage_type] damage with your Singularities!"))
	for(var/thespell in usr.mind.spell_list)
		if(istype(thespell, /obj/effect/proc_holder/spell/aimed/fairy))
			var/obj/effect/proc_holder/spell/aimed/fairy/fairyspell = thespell
			fairyspell.damage_type = damage_type
		if(istype(thespell, /obj/effect/proc_holder/spell/aimed/pillar))
			var/obj/effect/proc_holder/spell/aimed/fairy/pillarspell = thespell
			pillarspell.damage_type = damage_type
		if(istype(thespell, /obj/effect/proc_holder/spell/pointed/thin_line))
			var/obj/effect/proc_holder/spell/pointed/thin_line/linespell = thespell
			linespell.damage_type = damage_type
		if(istype(thespell, /obj/effect/proc_holder/spell/aimed/thick_line))
			var/obj/effect/proc_holder/spell/aimed/thick_line/thicklinespell = thespell
			thicklinespell.damage_type = damage_type

	var/appropiate_color = rgb(128, 128, 128)
	switch(damage_type)
		if(RED_DAMAGE)
			appropiate_color = rgb(255, 0, 0)
		if(WHITE_DAMAGE)
			appropiate_color = rgb(255,255,255)
		if(BLACK_DAMAGE)
			appropiate_color = rgb(48, 25, 52)
		if(PALE_DAMAGE)
			appropiate_color = rgb(128, 128, 128)
	if(!filter)
		filter = TRUE
		usr.filters += filter(type="drop_shadow", x=0, y=0, size=5, offset=2, color=rgb(128, 128, 128))
		return
	var/f1 = usr.filters[usr.filters.len]
	animate(f1, color = appropiate_color, time = 5)


/obj/effect/temp_visual/target_field/yellow
	name = "arbiter target field"
	desc = "Well shit."
	icon_state = "target_field_blue"
	color = COLOR_YELLOW
	duration = 4 SECONDS

// Different version of the Complete Arbiter that probably should only show up in adminbus.
// Replaces Fairy with Thin Line, Pillar with Thick Line. Also gets Birdcage.
/datum/antagonist/wizard/arbiter/complete/line_variant
	name = "Arbiter (Line Variant)"
	outfit_type = /datum/outfit/arbiter/line
	spell_types = list(
		/obj/effect/proc_holder/spell/pointed/thin_line,
		/obj/effect/proc_holder/spell/aimed/thick_line,
		/obj/effect/proc_holder/spell/aoe_turf/repulse/arbiter,
		/obj/effect/proc_holder/spell/pointed/lock,
		/obj/effect/proc_holder/spell/pointed/chain,
		/obj/effect/proc_holder/spell/aoe_turf/knock/arbiter,
		/obj/effect/proc_holder/spell/targeted/touch/arbiterpunch,
		/obj/effect/proc_holder/spell/aoe_turf/singularity,
	)

/datum/outfit/arbiter/line
	name = "Arbiter (Line Variant)"
	neck = /obj/item/clothing/neck/cloak/arbiter/zena


// Below code is for Power Null status effect. It's a stacking debuff that subtracts an amount of Power Modifier from the victim, which must be a human.

// Status effect
/datum/status_effect/stacking/arbiter_powernull
	id = "arbiter_powernull"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = 15 SECONDS
	max_stacks = 10
	stacks = 0
	consumed_on_threshold = FALSE
	alert_type = /atom/movable/screen/alert/status_effect/arbiter_powernull
	var/powermod_loss_per_stack = 20 // AAAAAAAAAAAAAH GIVE ME BACK MY POWERMOD NOOOOOOOOOOO (Power Modifier is the stat affected by Justice, which increases attack damage and movespeed)

/datum/status_effect/stacking/arbiter_powernull/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(owner))
		return
	var/power_penalty = (powermod_loss_per_stack * stacks) * -1
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, power_penalty)

/datum/status_effect/stacking/arbiter_powernull/add_stacks(stacks_added)
	var/mob/living/carbon/human/H = owner
	if(!istype(owner))
		return

	var/old_penalty = (stacks * powermod_loss_per_stack) * -1 // Calculate what our previous penalty was before adding the stacks.

	. = ..() // Add the stacks

	var/power_penalty = (powermod_loss_per_stack * stacks) * -1 // Calculate the new penalty.

	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -old_penalty) // Revert our old penalty.
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, power_penalty) // Add our new penalty.

	linked_alert.desc = initial(linked_alert.desc)+"[stacks*powermod_loss_per_stack]."

// We need to revert the powermod malus when removing the debuff.
/datum/status_effect/stacking/arbiter_powernull/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(owner))
		return

	var/power_penalty = (powermod_loss_per_stack * stacks) * -1
	H.adjust_attribute_buff(JUSTICE_ATTRIBUTE, -power_penalty)

// Doesn't decay.
/datum/status_effect/stacking/arbiter_powernull/tick()
	if(!can_have_status())
		qdel(src)

/datum/status_effect/stacking/arbiter_powernull/can_have_status()
	return ((owner.stat < DEAD) && (ishuman(owner)))

// Mob proc which handles applying the debuff and stacking/refreshing it.
/mob/living/proc/apply_arbiter_powernull(stacks)
	if(!ishuman(src))
		return
	var/datum/status_effect/stacking/arbiter_powernull/P = src.has_status_effect(/datum/status_effect/stacking/arbiter_powernull)
	if(!P)
		src.apply_status_effect(/datum/status_effect/stacking/arbiter_powernull, stacks)
		return
	else
		P.add_stacks(stacks)
		P.refresh()

// Alert
/atom/movable/screen/alert/status_effect/arbiter_powernull
	name = "Faltering Justice"
	desc = "Your sense of Justice is fading as you confront the true rulers of the City. Power Modifier is reduced by "
	icon = 'icons/effects/effects.dmi'
	icon_state = "judge"
