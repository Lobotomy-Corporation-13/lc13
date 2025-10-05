/obj/item/clothing/suit/armor/ego_gear/city/insurgence_transport
	name = "grade 1 transport armor"
	desc = "Armor worn by insurgence clan transport agents."
	icon_state = "transport"
	flags_inv = 0
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 50, BLACK_DAMAGE = 50, PALE_DAMAGE = 0)
	hat = /obj/item/clothing/head/ego_hat/helmet/insurgence_transport
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	actions_types = list(/datum/action/item_action/insurgence_disguise/transport)
	var/disguised = FALSE
	var/original_icon_state = "transport"
	var/original_name = "grade 1 transport armor"
	var/original_desc = "Armor worn by insurgence clan transport agents."
	var/disguise_icon_state = "syndievest"
	var/disguise_name = "syndicate captain's vest"
	var/disguise_desc = "A sinister looking vest of advanced armor worn over a black and red fireproof jacket."

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_transport/proc/ToggleDisguise(mob/living/user)
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user

	// Check if wearing helmet and remove it if disguising
	if(!disguised)
		var/obj/item/clothing/head/headgear = H.get_item_by_slot(ITEM_SLOT_HEAD)
		if(istype(headgear, /obj/item/clothing/head/ego_hat/helmet/insurgence_transport))
			H.dropItemToGround(headgear, TRUE)
			to_chat(user, span_notice("You remove your helmet as you activate the disguise."))
			qdel(headgear)

		// Apply disguise
		disguised = TRUE
		name = disguise_name
		desc = disguise_desc
		icon_state = disguise_icon_state
		icon = 'icons/obj/clothing/suits.dmi'
		worn_icon = 'icons/mob/clothing/suit.dmi'
		to_chat(user, span_notice("You activate your armor's disguise system."))
	else
		// Remove disguise
		disguised = FALSE
		name = original_name
		desc = original_desc
		icon_state = original_icon_state
		icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
		worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
		to_chat(user, span_notice("You deactivate your armor's disguise system."))

	update_slot_icon()

/obj/item/clothing/head/ego_hat/helmet/insurgence_transport
	name = "grade 1 transport helmet"
	desc = "A helmet worn by insurgence clan transport agents."
	icon_state = "transport"

/obj/item/clothing/head/ego_hat/helmet/insurgence_transport/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(!ishuman(M))
		return ..()
	var/mob/living/carbon/human/H = M
	var/obj/item/clothing/suit/armor/ego_gear/city/insurgence_transport/armor = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(armor) && armor.disguised)
		to_chat(H, span_warning("You cannot wear your helmet while your armor is disguised!"))
		return FALSE
	return ..()

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch
	name = "grade 1 nightwatch armor"
	desc = "Armor worn by insurgence clan nightwatch agents."
	icon_state = "nightwatch"
	flags_inv = 0
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 70, BLACK_DAMAGE = 70, PALE_DAMAGE = 30)
	hat = /obj/item/clothing/head/ego_hat/helmet/insurgence_nightwatch
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)
	var/cloak_active = FALSE
	var/cloak_alpha = 255
	var/damage_modifier = 1
	var/cloak_cooldown = 0
	var/cloak_cooldown_time = 30 SECONDS
	actions_types = list(/datum/action/item_action/nightwatch_cloak, /datum/action/item_action/corrupted_whisper, /datum/action/item_action/insurgence_disguise/nightwatch)
	var/disguised = FALSE
	var/original_icon_state = "nightwatch"
	var/original_name = "grade 1 nightwatch armor"
	var/original_desc = "Armor worn by insurgence clan nightwatch agents."
	var/disguise_icon_state = "gothcoat"
	var/disguise_name = "gothic coat"
	var/disguise_desc = "Perfect for those who want to stalk around a corner of a bar."

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/ToggleDisguise(mob/living/user)
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user

	// Cannot disguise while cloaked
	if(cloak_active)
		to_chat(user, span_warning("You cannot change your disguise while cloaked!"))
		return

	// Check if wearing helmet and remove it if disguising
	if(!disguised)
		var/obj/item/clothing/head/headgear = H.get_item_by_slot(ITEM_SLOT_HEAD)
		if(istype(headgear, /obj/item/clothing/head/ego_hat/helmet/insurgence_nightwatch))
			H.dropItemToGround(headgear, TRUE)
			to_chat(user, span_notice("You remove your helmet as you activate the disguise."))
			qdel(headgear)

		// Apply disguise
		disguised = TRUE
		name = disguise_name
		desc = disguise_desc
		icon_state = disguise_icon_state
		icon = 'icons/obj/clothing/suits.dmi'
		worn_icon = 'icons/mob/clothing/suit.dmi'
		to_chat(user, span_notice("You activate your armor's disguise system."))
	else
		// Remove disguise
		disguised = FALSE
		name = original_name
		desc = original_desc
		icon_state = original_icon_state
		icon = 'icons/obj/clothing/ego_gear/lc13_armor.dmi'
		worn_icon = 'icons/mob/clothing/ego_gear/lc13_armor.dmi'
		to_chat(user, span_notice("You deactivate your armor's disguise system."))

	update_slot_icon()

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/ToggleCloak(mob/living/user)
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user
	if(!H.mind || H.mind.assigned_role != "Insurgence Nightwatch Agent")
		to_chat(user, span_warning("This armor's systems do not recognize you."))
		return

	if(!cloak_active)
		if(world.time < cloak_cooldown)
			var/remaining = round((cloak_cooldown - world.time) / 10)
			to_chat(user, span_warning("Cloaking systems recharging. Ready in [remaining] seconds."))
			return
		ActivateCloak(user)
	else
		DeactivateCloak(user)

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/ActivateCloak(mob/living/user)
	cloak_active = TRUE
	to_chat(user, span_notice("You activate the cloaking field."))
	playsound(user, 'sound/effects/stealthoff.ogg', 30, TRUE)
	damage_modifier = 0.5
	animate(user, alpha = 0, time = 5 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(FullCloak), user), 5 SECONDS)

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/FullCloak(mob/living/user)
	if(!cloak_active)
		return
	user.density = FALSE
	user.invisibility = 0
	to_chat(user, span_notice("You are now fully cloaked."))

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/DeactivateCloak(mob/living/user)
	cloak_active = FALSE
	cloak_cooldown = world.time + cloak_cooldown_time
	to_chat(user, span_warning("Your cloaking field deactivates!"))
	playsound(user, 'sound/effects/stealthoff.ogg', 30, TRUE)
	damage_modifier = 1
	user.density = TRUE
	user.invisibility = initial(user.invisibility)
	animate(user, alpha = 255, time = 2 SECONDS)

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/equipped(mob/living/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		return
	RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnAttack))
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnDamage))

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/dropped(mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_MOB_ITEM_ATTACK)
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)
	if(cloak_active)
		DeactivateCloak(user)

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/OnAttack(mob/living/user)
	SIGNAL_HANDLER
	if(cloak_active)
		DeactivateCloak(user)

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/OnDamage(mob/living/user, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	if(cloak_active && damage > 0)
		to_chat(user, span_warning("Your cloak flickers and fails as you take damage!"))
		DeactivateCloak(user)

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/GetDamageModifier()
	return damage_modifier

/datum/action/item_action/nightwatch_cloak
	name = "Toggle Cloak"
	desc = "Activate or deactivate your cloaking field."
	button_icon_state = "sniper_zoom"
	icon_icon = 'icons/mob/actions/actions_items.dmi'

/datum/action/item_action/nightwatch_cloak/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch))
		return
	var/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/N = target
	N.ToggleCloak(owner)

/obj/item/clothing/head/ego_hat/helmet/insurgence_nightwatch
	name = "grade 1 nightwatch helmet"
	desc = "A helmet worn by insurgence clan nightwatch agents."
	icon_state = "nightwatch"

/obj/item/clothing/head/ego_hat/helmet/insurgence_nightwatch/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(!ishuman(M))
		return ..()
	var/mob/living/carbon/human/H = M
	var/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/armor = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(armor) && armor.disguised)
		to_chat(H, span_warning("You cannot wear your helmet while your armor is disguised!"))
		return FALSE
	return ..()

/datum/action/item_action/corrupted_whisper
	name = "Corrupted Whisper"
	desc = "Send a telepathic message to those touched by the Elder One's corruption."
	button_icon_state = "r_transmit"
	icon_icon = 'icons/mob/actions/actions_revenant.dmi'

/datum/action/item_action/corrupted_whisper/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch))
		return
	var/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/N = target
	N.CorruptedWhisper(owner)

/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/proc/CorruptedWhisper(mob/living/user)
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user
	if(!H.mind || H.mind.assigned_role != "Insurgence Nightwatch Agent")
		to_chat(user, span_warning("This armor's systems do not recognize you."))
		return

	// Find all humans with mental corrosion within range
	var/list/possible_targets = list()
	for(var/mob/living/carbon/human/target in view(7, user))
		if(target == user || target.stat == DEAD)
			continue

		// Check if they have mental corrosion
		var/has_corrosion = FALSE
		for(var/datum/component/augment/mental_corrosion/MC in target.GetComponents(/datum/component/augment/mental_corrosion))
			has_corrosion = TRUE
			break

		if(has_corrosion)
			possible_targets += target

	if(!length(possible_targets))
		to_chat(user, span_warning("There are no corrupted minds within range."))
		return

	// Select target
	var/mob/living/carbon/human/chosen_target = input(user, "Choose a corrupted mind to whisper to:", "Corrupted Whisper") as null|anything in possible_targets
	if(!chosen_target || get_dist(user, chosen_target) > 7)
		return

	// Get message
	var/msg = stripped_input(user, "What corruption do you wish to whisper to [chosen_target]?", "Corrupted Whisper", "")
	if(!msg)
		return

	// Log the communication
	log_directed_talk(user, chosen_target, msg, LOG_SAY, "Corrupted Whisper")

	// Send to user
	to_chat(user, span_boldnotice("You send a corrupted whisper to [chosen_target]:") + span_notice(" [msg]"))

	// Send to target using show_blurb like mental corrosion
	if(chosen_target.client)
		// Random position matching mental_corrosion style
		var/tile_x = rand(3, 11)
		var/tile_y = rand(3, 11)
		var/pixel_x = rand(-16, 16)
		var/pixel_y = rand(-16, 16)
		show_blurb(chosen_target.client, 50, msg, 10, "#ff4848", "black", "center", "[tile_x]:[pixel_x],[tile_y]:[pixel_y]")
		chosen_target.playsound_local(chosen_target, 'sound/abnormalities/whitenight/whisper.ogg', 25, TRUE)

	// Notify ghosts
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		var/follow_insurgent = FOLLOW_LINK(ghost, user)
		var/follow_target = FOLLOW_LINK(ghost, chosen_target)
		to_chat(ghost, "[follow_insurgent] <span class='boldnotice'>[user] Corrupted Whisper:</span> <span class='notice'>\"[msg]\" to</span> [follow_target] [span_name("[chosen_target]")]")

// Disguise action datums
/datum/action/item_action/insurgence_disguise
	name = "Toggle Disguise"
	desc = "Toggle your armor's disguise system."
	button_icon_state = "chameleon"
	icon_icon = 'icons/mob/actions/actions_items.dmi'

/datum/action/item_action/insurgence_disguise/transport
	name = "Toggle Transport Disguise"

/datum/action/item_action/insurgence_disguise/transport/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/city/insurgence_transport))
		return
	var/obj/item/clothing/suit/armor/ego_gear/city/insurgence_transport/T = target
	T.ToggleDisguise(owner)

/datum/action/item_action/insurgence_disguise/nightwatch
	name = "Toggle Nightwatch Disguise"

/datum/action/item_action/insurgence_disguise/nightwatch/Trigger()
	if(!istype(target, /obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch))
		return
	var/obj/item/clothing/suit/armor/ego_gear/city/insurgence_nightwatch/N = target
	N.ToggleDisguise(owner)

// Insurgence Forged ID Card
/obj/item/card/id/insurgence_forge
	var/forged = FALSE

/obj/item/card/id/insurgence_forge/attack_self(mob/user)
	if(!isliving(user))
		return ..()

	var/popup_input = alert(user, "Choose Action", "Forged ID", "Show", "Forge/Reset")
	if(user.incapacitated())
		return

	if(popup_input == "Forge/Reset" && !forged)
		var/input_name = stripped_input(user, "What name would you like to put on this card?", "Forged card name", registered_name ? registered_name : (ishuman(user) ? user.real_name : user.name), MAX_NAME_LEN)
		input_name = sanitize_name(input_name)
		if(!input_name)
			// Invalid/blank names give a randomly generated one.
			if(user.gender == MALE)
				input_name = "[pick(GLOB.first_names_male)] [pick(GLOB.last_names)]"
			else if(user.gender == FEMALE)
				input_name = "[pick(GLOB.first_names_female)] [pick(GLOB.last_names)]"
			else
				input_name = "[pick(GLOB.first_names)] [pick(GLOB.last_names)]"

		var/target_occupation = stripped_input(user, "What occupation would you like to put on this card?", "Forged card job assignment", assignment ? assignment : "Assistant", MAX_MESSAGE_LEN)
		if(!target_occupation)
			return

		registered_name = input_name
		assignment = target_occupation
		update_label()
		forged = TRUE
		to_chat(user, span_notice("You successfully forge the ID card."))
		log_game("[key_name(user)] has forged \the [initial(name)] with name \"[registered_name]\" and occupation \"[assignment]\".")
		return

	else if(popup_input == "Forge/Reset" && forged)
		registered_name = initial(registered_name)
		assignment = initial(assignment)
		log_game("[key_name(user)] has reset \the [initial(name)] named \"[src]\" to default.")
		update_label()
		forged = FALSE
		to_chat(user, span_notice("You successfully reset the ID card."))
		return

	return ..()
