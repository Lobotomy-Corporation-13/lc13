// EGO Communion - an LCL abno action that reaches into anyone bearing its EGO gear.
// The abno can see through a wearer (or through the gear itself if it isn't worn), hear
// what the wearer hears (as floating runechat AND a tagged to_chat feed of everything
// around them, emotes included), whisper into their mind, and - at 50%+ attunement -
// briefly seize control of their voice or body.

// Prefix that marks the abno's relayed remote feed apart from its own local chatter.
#define COMMUNE_TAG "<font color='#b066e6'>\[COMMUNE\]:</font>"

// ---- Communion state on the abno ----
/mob/living/simple_animal/hostile/limbus_abno
	var/obj/item/clothing/suit/armor/ego_gear/lce/communion_armor
	var/mob/living/communion_target
	var/atom/communion_view
	var/list/communion_subactions

// ---- Opening the menu + choosing a target ----
/mob/living/simple_animal/hostile/limbus_abno/proc/CommuneMenu()
	if(!attunement_family)
		to_chat(src, span_warning("You have no EGO to commune through."))
		return
	var/list/wearers = GLOB.lce_armors[attunement_family]
	if(!LAZYLEN(wearers))
		to_chat(src, span_warning("None of your EGO is out in the world right now."))
		return
	var/list/choices = list()
	var/i = 0
	for(var/obj/item/clothing/suit/armor/ego_gear/lce/A in wearers)
		i++
		var/mob/living/wearer = GetArmorWearer(A)
		var/label = wearer ? "[i]. [wearer.real_name] (worn)" : "[i]. [A.name] (unworn - [get_area(A)])"
		choices[label] = A
	if(communion_view)
		EndCommunion() // Only one communion at a time.
	var/picked = input(src, "Whose EGO will you reach into?", "EGO Communion") as null|anything in choices
	if(!picked)
		return
	var/obj/item/clothing/suit/armor/ego_gear/lce/chosen = choices[picked]
	if(!chosen)
		return
	BeginCommunion(chosen)

/mob/living/simple_animal/hostile/limbus_abno/proc/GetArmorWearer(obj/item/clothing/suit/armor/ego_gear/lce/A)
	if(isliving(A.loc))
		var/mob/living/L = A.loc
		if(L.get_item_by_slot(ITEM_SLOT_OCLOTHING) == A)
			return L
	return null

// ---- Begin / end ----
/mob/living/simple_animal/hostile/limbus_abno/proc/BeginCommunion(obj/item/clothing/suit/armor/ego_gear/lce/armor)
	if(!client || !armor)
		return
	communion_armor = armor
	communion_target = GetArmorWearer(armor)
	communion_view = communion_target ? communion_target : armor
	reset_perspective(communion_view) // See through them (or the gear itself).
	if(communion_target)
		RegisterSignal(communion_target, COMSIG_MOVABLE_HEAR, PROC_REF(RelayHeard))
		RegisterSignal(communion_target, COMSIG_MOB_SHOW_MESSAGE, PROC_REF(RelayShown))
		RegisterSignal(communion_target, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(OnCommunionGone))
	RegisterSignal(communion_armor, COMSIG_PARENT_QDELETING, PROC_REF(OnCommunionGone))
	RegisterSignal(src, COMSIG_LIVING_DEATH, PROC_REF(OnCommunionGone))
	GrantCommunionActions()
	if(communion_target)
		to_chat(src, "<span class='revenboldnotice'><i>You slip behind [communion_target]'s eyes...</i></span>")
	else
		to_chat(src, "<span class='revenboldnotice'><i>You gaze out through your discarded EGO...</i></span>")

/mob/living/simple_animal/hostile/limbus_abno/proc/EndCommunion()
	if(isnull(communion_view))
		return
	reset_perspective(null)
	if(communion_target)
		UnregisterSignal(communion_target, list(COMSIG_MOVABLE_HEAR, COMSIG_MOB_SHOW_MESSAGE, COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	if(communion_armor)
		UnregisterSignal(communion_armor, COMSIG_PARENT_QDELETING)
	UnregisterSignal(src, COMSIG_LIVING_DEATH)
	communion_target = null
	communion_armor = null
	communion_view = null
	RemoveCommunionActions()
	to_chat(src, span_notice("You withdraw back into yourself."))

/mob/living/simple_animal/hostile/limbus_abno/proc/OnCommunionGone(datum/source)
	SIGNAL_HANDLER
	EndCommunion()

// ---- Relaying what the wearer perceives ----
// Speech: a floating runechat bubble AND a tagged to_chat line. Handled here (not in
// RelayShown) because COMSIG_MOVABLE_HEAR fires even when the wearer has no client of their
// own, and doing all speech here keeps RelayShown from double-relaying it.
/mob/living/simple_animal/hostile/limbus_abno/proc/RelayHeard(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	var/atom/movable/speaker = hearing_args[HEARING_SPEAKER]
	to_chat(src, "[COMMUNE_TAG] [compose_message(speaker, hearing_args[HEARING_LANGUAGE], hearing_args[HEARING_RAW_MESSAGE], hearing_args[5], hearing_args[6], hearing_args[7])]")
	if(client?.prefs?.chat_on_map)
		create_chat_message(speaker, hearing_args[HEARING_LANGUAGE], hearing_args[HEARING_RAW_MESSAGE], hearing_args[6])

// Everything else the wearer sees/perceives (emotes, visible actions) as a tagged to_chat.
// Skip MSG_AUDIBLE so speech (which also reaches show_message) isn't relayed twice - speech
// is handled by RelayHeard above.
/mob/living/simple_animal/hostile/limbus_abno/proc/RelayShown(datum/source, msg, type)
	SIGNAL_HANDLER
	if(!msg || (type & MSG_AUDIBLE))
		return
	to_chat(src, "[COMMUNE_TAG] [msg]")

// ---- Sub-action lifecycle ----
/mob/living/simple_animal/hostile/limbus_abno/proc/GrantCommunionActions()
	if(communion_subactions)
		return
	communion_subactions = list()
	for(var/path in list(
			/datum/action/cooldown/limbus_abno_action/communion_whisper,
			/datum/action/cooldown/limbus_abno_action/communion_compel,
			/datum/action/cooldown/limbus_abno_action/communion_end))
		var/datum/action/cooldown/limbus_abno_action/A = new path()
		A.Grant(src)
		// Grant runs its first UpdateButtonIcon before abno_user/reqs are set, leaving the
		// button greyed; refresh now that Grant has finished setting them.
		A.UpdateButtonIcon()
		communion_subactions += A

/mob/living/simple_animal/hostile/limbus_abno/proc/RemoveCommunionActions()
	if(!communion_subactions)
		return
	for(var/datum/action/A in communion_subactions)
		A.Remove(src)
		qdel(A)
	communion_subactions = null

// ---- Telepathy ----
/mob/living/simple_animal/hostile/limbus_abno/proc/CommunionWhisper()
	if(!communion_target)
		to_chat(src, span_warning("There is no mind to whisper to."))
		return
	var/msg = input(src, "Whisper into their mind:", "EGO Communion") as null|text
	if(!msg || !communion_target)
		return
	msg = trim(msg)
	if(!msg)
		return
	log_directed_talk(src, communion_target, msg, LOG_SAY, "EGO communion")
	to_chat(communion_target, "<span class='revenboldnotice'>A voice speaks through your EGO...</span> <span class='revennotice'>[msg]</span>")
	to_chat(src, "<span class='revenboldnotice'>You whisper to [communion_target]:</span> <span class='revennotice'>[msg]</span>")
	for(var/ded in GLOB.dead_mob_list)
		if(!isobserver(ded))
			continue
		var/follow_abno = FOLLOW_LINK(ded, src)
		var/follow_target = FOLLOW_LINK(ded, communion_target)
		to_chat(ded, "[follow_abno] <span class='revenboldnotice'>[src] EGO Communion:</span> <span class='revennotice'>\"[msg]\" to</span> [follow_target] [span_name("[communion_target]")]")

// ---- Compulsion (50%+ attunement) ----
// Returns TRUE if a compulsion actually happened (so the caller starts the cooldown).
/mob/living/simple_animal/hostile/limbus_abno/proc/CommunionCompel()
	if(!communion_target || !communion_armor || communion_armor.attunement < 50)
		to_chat(src, span_warning("Your bond is not strong enough to compel them."))
		return FALSE
	var/mode = input(src, "How will you seize them?", "EGO Communion") as null|anything in list("Force Speech", "Force Emote")
	if(!mode || !communion_target)
		return FALSE
	var/prompt = (mode == "Force Speech") ? "What words will you put in their mouth?" : "What will you make them do? (e.g. laughs, twitches violently)"
	var/text = input(src, prompt, "EGO Communion") as null|text
	if(!text || !communion_target)
		return FALSE
	text = trim(text)
	if(!text)
		return FALSE
	if(mode == "Force Speech")
		communion_target.say(text, forced = "EGO compulsion")
	else
		communion_target.manual_emote(text)
	to_chat(src, span_notice("You seize control of [communion_target]."))
	return TRUE

// ==================================================================================
// Actions
// ==================================================================================
/datum/action/cooldown/limbus_abno_action/ego_communion
	name = "Commune with EGO"
	desc = "Reach into anyone bearing your EGO: see through them, hear what they hear, and whisper into their mind."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "commune"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/limbus_abno_action/ego_communion/Trigger()
	. = ..()
	if(!.)
		return FALSE
	abno_user.CommuneMenu()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/communion_whisper
	name = "Whisper"
	desc = "Speak privately into the mind of the one you commune with."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "whisper"
	cooldown_time = 3 SECONDS

/datum/action/cooldown/limbus_abno_action/communion_whisper/Trigger()
	. = ..()
	if(!.)
		return FALSE
	abno_user.CommunionWhisper()
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/communion_compel
	name = "Compel"
	desc = "At 50%+ attunement, force the one you commune with to speak or act against their will. Cools down faster the higher your attunement."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "compel"
	transparent_when_unavailable = TRUE

/datum/action/cooldown/limbus_abno_action/communion_compel/IsAvailable()
	. = ..()
	if(!.)
		return FALSE
	if(!abno_user.communion_target)
		return FALSE
	if(!abno_user.communion_armor || abno_user.communion_armor.attunement < 50)
		return FALSE
	return TRUE

/datum/action/cooldown/limbus_abno_action/communion_compel/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.CommunionCompel())
		var/obj/item/clothing/suit/armor/ego_gear/lce/A = abno_user.communion_armor
		var/att = A ? A.attunement : 50
		// 40s at 50% attunement, shrinking to 10s at 100%.
		cooldown_time = 40 SECONDS - (clamp(att, 50, 100) - 50) * 0.6 SECONDS
		StartCooldown()

/datum/action/cooldown/limbus_abno_action/communion_end
	name = "End Communion"
	desc = "Return to your own senses."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "end_communion"

/datum/action/cooldown/limbus_abno_action/communion_end/Trigger()
	. = ..()
	if(!.)
		return FALSE
	abno_user.EndCommunion()

#undef COMMUNE_TAG
