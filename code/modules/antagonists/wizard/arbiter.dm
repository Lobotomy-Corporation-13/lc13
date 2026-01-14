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
		/obj/effect/proc_holder/spell/pointed/chain,
		/obj/effect/proc_holder/spell/aoe_turf/knock/arbiter,
		/obj/effect/proc_holder/spell/targeted/touch/arbiterpunch,
		/obj/effect/proc_holder/spell/aoe_turf/singularity,
		/obj/effect/proc_holder/spell/aoe_turf/summon_meltdown,
	)

// Allows you to freely swap between the available damage types through a radial menu.
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
	var/filter_enabled
	var/filter_size = 3
	var/filter_offset = 2

// When first clicking the spell. This will only cast the spell if we make a choice in the radial menu.
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

// Called after we choose a damage type from the radial menu.
/obj/effect/proc_holder/spell/aoe_turf/singularity/cast(list/targets,mob/user = usr)
	damage_type = queued_damage_type
	playMagSound()

	to_chat(usr, span_nicegreen("You are now dealing [damage_type] damage with your Singularities!"))
	for(var/thespell in usr.mind.spell_list) // Add any Arbiter spell that needs a damagetype change to this for loop please <3
		// Fairy: Incomplete & Complete Arbiter. Hitscan projectile.
		if(istype(thespell, /obj/effect/proc_holder/spell/aimed/fairy))
			var/obj/effect/proc_holder/spell/aimed/fairy/fairyspell = thespell
			fairyspell.damage_type = damage_type

		// Pillar: Incomplete & Complete Arbiter. AoE, phasing projectile that causes meltdowns when hitting consoles.
		if(istype(thespell, /obj/effect/proc_holder/spell/aimed/pillar))
			var/obj/effect/proc_holder/spell/aimed/fairy/pillarspell = thespell
			pillarspell.damage_type = damage_type

		// Thin Line: Line Arbiter. Point and click damage that applies Powernull.
		if(istype(thespell, /obj/effect/proc_holder/spell/pointed/thin_line))
			var/obj/effect/proc_holder/spell/pointed/thin_line/linespell = thespell
			linespell.damage_type = damage_type

		// Thick Line: Line Arbiter. Telegraphed 3-tile-thick hitscan beam that applies Powernull.
		if(istype(thespell, /obj/effect/proc_holder/spell/aimed/thick_line))
			var/obj/effect/proc_holder/spell/aimed/thick_line/thicklinespell = thespell
			thicklinespell.damage_type = damage_type

		// Birdcage: Line Arbiter. Point and click 2 instances of damage, applies Chain.
		if(istype(thespell, /obj/effect/proc_holder/spell/pointed/birdcage))
			var/obj/effect/proc_holder/spell/pointed/birdcage/birdcagespell = thespell
			birdcagespell.damage_type = damage_type

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
	if(!filter_enabled)
		filter_enabled = TRUE
		user.add_filter("arbiter_singularity_swap", 3, list("type"="drop_shadow", "x"=0, "y"=0, "size" = filter_size, "offset" = filter_offset, "color"=appropiate_color, "name" = "arbiter_singularity_swap"))
		return
	var/f1 = user.filters["arbiter_singularity_swap"]
	if(f1)
		animate(f1, color = appropiate_color, size = filter_size, offset = filter_offset, time = 5)


/obj/effect/temp_visual/target_field/yellow
	name = "arbiter target field"
	desc = "Well shit."
	icon_state = "target_field_blue"
	color = COLOR_YELLOW
	duration = 4 SECONDS

/// Spell that causes Meltdowns in containment cells when used on the same Z Level as the Facility. Long cooldown. Doesn't do the special melts that Megafauna-Arbiter does.
/obj/effect/proc_holder/spell/aoe_turf/summon_meltdown
	name = "Meltdown"
	desc = "Use Singularity F to create failures in Abnormality containment cells, causing Qliphoth Meltdowns. Has no effect outside of a Lobotomy Corporation facility."
	school = SCHOOL_EVOCATION
	charge_max = 1200
	clothes_req = FALSE
	antimagic_allowed = TRUE
	invocation_type = "none"
	base_icon_state = "meltdown"
	action_icon_state = "meltdown"
	sound = 'sound/magic/castsummon.ogg'

/obj/effect/proc_holder/spell/aoe_turf/summon_meltdown/cast(list/targets, mob/user)
	. = ..()
	playsound(get_turf(user), 'sound/magic/arbiter/repulse.ogg', 50, TRUE, 7)
	for(var/turf/T in orange(2, user))
		new /obj/effect/temp_visual/revenant(T)
	user.visible_message(span_danger("[user] emits an energized pulse!"), span_nicegreen("You send out your Fairies to break open some Abnormality containment cells."))
	addtimer(CALLBACK(src, PROC_REF(CauseMeltdowns), user), 2 SECONDS) // Slight delay.

/obj/effect/proc_holder/spell/aoe_turf/summon_meltdown/proc/CauseMeltdowns(mob/user)
	// If we're not on a LobCorp mode map, cancel and refund the spell.
	if(!((SSmaptype.maptype in SSmaptype.lc_maps) || SSmaptype.maptype == "mini"))
		to_chat(user, span_danger("There are no Abnormality containment cells with a functioning Qliphoth Deterrence to overload nearby. Your Fairies return to you, having found nothing to break open."))
		revert_cast()
		return
	// If we're not on the Facility Z Level, cancel and refund the spell.
	var/turf/sample_dept_center = pick(GLOB.department_centers)
	if(!(sample_dept_center && sample_dept_center.z == user.z))
		to_chat(user, span_danger("You're too far from any Abnormality containment cells to cause meltdowns. Your Fairies return to you."))
		revert_cast()
		return

	var/meltdown_type = MELTDOWN_NORMAL
	var/meltdown_text = "Qliphoth meltdown occured in containment zones of the following abnormalities:"
	var/meltdown_min_time = 60
	var/meltdown_max_time = 90

	// Factors only working agents into meltdown amount calculations.
	var/active_threats = max(1, length(AllLivingAgents(FALSE))) // Working Agents only.
	SSlobotomy_corp.InitiateMeltdown(clamp(rand(floor(active_threats*0.75), active_threats), 1, 10), TRUE, meltdown_type, meltdown_min_time, meltdown_max_time, meltdown_text, 'sound/magic/arbiter/meltdown.ogg')

// Different version of the Complete Arbiter that probably should only show up in adminbus.
// Replaces Fairy -> Thin Line, Pillar -> Thick Line. Also gets Birdcage.
/datum/antagonist/wizard/arbiter/complete/line_variant
	name = "Arbiter (Line Variant)"
	outfit_type = /datum/outfit/arbiter/line
	spell_types = list(
		/obj/effect/proc_holder/spell/pointed/thin_line,
		/obj/effect/proc_holder/spell/aimed/thick_line,
		/obj/effect/proc_holder/spell/pointed/birdcage,
		/obj/effect/proc_holder/spell/aoe_turf/repulse/arbiter,
		/obj/effect/proc_holder/spell/pointed/lock,
		/obj/effect/proc_holder/spell/pointed/chain,
		/obj/effect/proc_holder/spell/aoe_turf/knock/arbiter,
		/obj/effect/proc_holder/spell/targeted/touch/arbiterpunch,
		/obj/effect/proc_holder/spell/aoe_turf/singularity,
		/obj/effect/proc_holder/spell/aoe_turf/summon_meltdown,
	)

/datum/outfit/arbiter/line
	name = "Arbiter (Line Variant)"
	neck = /obj/item/clothing/neck/cloak/arbiter/zena


// Below code is for Power Null status effect. It's a stacking debuff that subtracts an amount of Power Modifier from the victim, which must be a human.

// This has an added status effect it applies that does nothing but display a little icon. Why? Because for some reason /status_effect/display is a subtype instead of optional functionality for
// every status effect, and I can't just kidnap the functionality I want from that subtype because that subtype specifically checks for other status effects of the /display subtype and...
// Look just trust me on this one. If you have a problem with it please refactor /status_effect/display's stuff to be on every status effect as an option

// Status effect
/datum/status_effect/stacking/arbiter_powernull
	id = "arbiter_powernull"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = 15 SECONDS
	max_stacks = 10
	stacks = 0
	consumed_on_threshold = FALSE
	alert_type = /atom/movable/screen/alert/status_effect/arbiter_powernull
	var/applied_vfx
	var/powermod_loss_per_stack = 20 // AAAAAAAAAAAAAH GIVE ME BACK MY POWERMOD NOOOOOOOOOOO (Power Modifier is the stat affected by Justice, which increases attack damage and movespeed)
	var/datum/status_effect/display/arbiter_powernull_visual/attached_visual_status

/datum/status_effect/stacking/arbiter_powernull/on_apply()
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(owner))
		return
	if(!attached_visual_status)
		attached_visual_status = H.apply_status_effect(/datum/status_effect/display/arbiter_powernull_visual)

	var/power_penalty = (powermod_loss_per_stack * stacks) * -1
	H.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, power_penalty)

/datum/status_effect/stacking/arbiter_powernull/add_stacks(stacks_added)
	var/mob/living/carbon/human/H = owner
	if(!istype(owner))
		return

	var/old_penalty = (stacks * powermod_loss_per_stack) * -1 // Calculate what our previous penalty was before adding the stacks.

	. = ..() // Add the stacks

	var/power_penalty = (powermod_loss_per_stack * stacks) * -1 // Calculate the new penalty.

	H.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -old_penalty) // Revert our old penalty.
	H.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, power_penalty) // Add our new penalty.

	linked_alert.desc = initial(linked_alert.desc)+"[stacks*powermod_loss_per_stack]."

// We need to revert the powermod malus when removing the debuff.
/datum/status_effect/stacking/arbiter_powernull/on_remove()
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(owner))
		return

	var/power_penalty = (powermod_loss_per_stack * stacks) * -1
	H.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -power_penalty)

	if(attached_visual_status)
		H.remove_status_effect(attached_visual_status)

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
		// Show the VFX as an overlay on the human
		var/image/cool_overlay = image('icons/effects/effects.dmi', loc = src, icon_state = "powernull", layer = src.layer + 1)
		cool_overlay.pixel_y += 26
		cool_overlay.alpha = 220
		cool_overlay.transform *= 0.85
		flick_overlay_view(cool_overlay, src, 1.5 SECONDS)
		return
	else
		P.add_stacks(stacks)
		P.refresh()

// Alert
/atom/movable/screen/alert/status_effect/arbiter_powernull
	name = "Faltering Justice"
	desc = "Your sense of Justice is fading as you confront the true rulers of the City. Power Modifier is reduced by "
	icon_state = "powernull"

// Silly status effect only meant to borrow functionality from /display/ subtype. Does nothing else.
/datum/status_effect/display/arbiter_powernull_visual
	id = "arbiter_powernull_visual"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = null
	display_name = "powernull"
