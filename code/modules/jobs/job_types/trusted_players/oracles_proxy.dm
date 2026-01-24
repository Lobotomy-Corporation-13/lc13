//The Oracle's Proxy
/datum/job/oracles_proxy
	title = "Oracle Proxy"
	outfit = /datum/outfit/job/oracles_proxy
	department_head = list("the will of the prescript")
	faction = "Station"
	supervisors = "the will of the prescript"
	selection_color = "#cccccc"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a wandering proxy of the Index, carrying out prescripts delivered to you by the Oracle. \
		You are not inherently hostile, but you must follow the prescripts you receive. \
		Use your index pager to receive and view your prescripts. \
		You have buffed stats. You automatically dodge the first attack every 30 seconds, and have a 50% chance to dodge attacks when not holding a weapon. \
		However, all damage you take also inflicts 5% unhealable damage."
	job_notice = "Avoid killing other players without a reason. Killing a player for stopping your prescripts is a valid reason."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 300,
		PRUDENCE_ATTRIBUTE = 300,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/oracles_proxy/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	H.AddComponent(/datum/component/oracle_proxy_passive)
	. = ..()

/datum/outfit/job/oracles_proxy
	name = "Oracle Proxy"
	jobtype = /datum/job/oracles_proxy

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/pda/security
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/laceup
	l_hand = /obj/item/ego_weapon/index_vial
	r_hand = /obj/item/clothing/suit/armor/ego_gear/city/index_proxy_wanderer
	accessory = /obj/item/clothing/accessory/index_pager
	l_pocket = /obj/item/index_proxy_recruitment

// Index Proxy Apprentice Recruitment Scroll
/obj/item/index_proxy_recruitment
	name = "proxy apprenticeship scroll"
	desc = "A scroll that allows you to recruit an apprentice to follow the prescripts."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "scroll"
	w_class = WEIGHT_CLASS_TINY
	/// Whether this scroll has been used
	var/used = FALSE

/obj/item/index_proxy_recruitment/attack(mob/living/target, mob/living/user)
	if(used)
		to_chat(user, span_warning("This scroll has already been used."))
		return
	if(!ishuman(target))
		to_chat(user, span_warning("You can only recruit humans."))
		return
	if(target == user)
		to_chat(user, span_warning("You cannot recruit yourself."))
		return

	var/mob/living/carbon/human/H = target

	// Ask target if they accept
	var/response = alert(H, "[user] is offering to make you their Index Proxy Apprentice. Do you accept?", "Apprenticeship Offer", "Accept", "Decline")

	if(response != "Accept")
		to_chat(user, span_warning("[H] declined your offer."))
		return

	// Check if user still has the scroll and is nearby
	if(QDELETED(src) || used || !user.is_holding(src))
		return
	if(get_dist(user, H) > 2)
		to_chat(user, span_warning("[H] is too far away now."))
		return

	// Mark as used
	used = TRUE

	// Set attributes
	// First raise the limit, then set the levels
	H.set_attribute_limit(200)

	// Set FORTITUDE and PRUDENCE to 200
	var/datum/attribute/fort = H.attributes[FORTITUDE_ATTRIBUTE]
	var/datum/attribute/prud = H.attributes[PRUDENCE_ATTRIBUTE]
	var/datum/attribute/temp = H.attributes[TEMPERANCE_ATTRIBUTE]
	var/datum/attribute/just = H.attributes[JUSTICE_ATTRIBUTE]

	if(fort)
		fort.level = 200
		fort.on_update(H)
	if(prud)
		prud.level = 200
		prud.on_update(H)
	if(temp)
		temp.level = 100
		temp.on_update(H)
	if(just)
		just.level = 100
		just.on_update(H)

	// Give armor
	var/obj/item/clothing/suit/armor/ego_gear/index_proxy/apprentice/armor = new(H.loc)
	H.put_in_hands(armor)

	// Update ID card assignment
	// Check for ID in hand or worn
	var/obj/item/card/id/id_card = H.get_idcard(TRUE)

	// If no ID found directly, check PDA
	if(!id_card)
		// Check all items for a PDA with an ID
		for(var/obj/item/pda/P in H.GetAllContents())
			if(P.id)
				id_card = P.id
				break

	if(id_card)
		id_card.assignment = "Index Proxy Apprentice"
		id_card.update_label()
		id_card.update_icon()

	// Update mind role
	if(H.mind)
		H.mind.assigned_role = "Index Proxy Apprentice"

	// Give the index pager
	var/obj/item/clothing/accessory/index_pager/pager = new(H.loc)
	H.put_in_hands(pager)

	// Add the oracle proxy passive component and traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, "index_apprentice")
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, "index_apprentice")
	H.AddComponent(/datum/component/oracle_proxy_passive)

	// Visual/audio feedback
	to_chat(user, span_notice("You have recruited [H] as your apprentice."))
	playsound(get_turf(H), 'sound/items/index_beeper_prescript.ogg', 50, 0, 4)

	// Show role explanation to the new apprentice
	to_chat(H, span_userdanger("You have become an Index Proxy Apprentice!"))
	to_chat(H, span_boldnotice("You are now an apprentice of [user], a proxy of the Index. \
		You must follow the prescripts delivered to you and assist your mentor in carrying them out. \
		Use your index pager to receive and view your prescripts."))
	to_chat(H, span_boldnotice("You have buffed stats. You automatically dodge the first attack every 30 seconds, \
		and have a 50% chance to dodge attacks when not holding a weapon. \
		However, all damage you take also inflicts 5% unhealable damage."))
	to_chat(H, span_boldwarning("Avoid killing other players without a reason. \
		Killing a player for stopping your prescripts is a valid reason."))

	// Consume the scroll
	qdel(src)

// Oracle Proxy passive abilities component
/datum/component/oracle_proxy_passive
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Whether the guaranteed evade is available
	var/guaranteed_evade_ready = TRUE

/datum/component/oracle_proxy_passive/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/oracle_proxy_passive/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage_taken))

/datum/component/oracle_proxy_passive/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)

/datum/component/oracle_proxy_passive/proc/on_damage_taken(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return

	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return

	// Check if this is a MELEE or RANGED attack (for evasion mechanics)
	var/is_evadable_attack = (attack_type & ATTACK_TYPE_MELEE) || (attack_type & ATTACK_TYPE_RANGED)

	// Guaranteed Evade: 100% dodge for first MELEE/RANGED hit, 30 second cooldown
	if(is_evadable_attack && guaranteed_evade_ready)
		var/turf/T = get_step(H, pick(GLOB.cardinals))
		if(T && !T.density)
			H.forceMove(T)
			playsound(H, 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)
			guaranteed_evade_ready = FALSE
			addtimer(CALLBACK(src, PROC_REF(recharge_guaranteed_evade)), 30 SECONDS)
			return COMPONENT_MOB_DENY_DAMAGE

	// Check if holding an ego_weapon
	var/obj/item/held = H.get_active_held_item()
	var/holding_ego_weapon = istype(held, /obj/item/ego_weapon)

	// Random Evasion: 50% chance to dodge if NOT holding ego weapon (only for MELEE or RANGED attacks)
	if(!holding_ego_weapon && is_evadable_attack && prob(50))
		var/turf/T = get_step(H, pick(GLOB.cardinals))
		if(T && !T.density)
			H.forceMove(T)
			playsound(H, 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)
			return COMPONENT_MOB_DENY_DAMAGE

	// Clone Decay: Take 5% of damage as unhealable damage (not from simple mobs)
	if(!istype(attack_source, /mob/living/simple_animal))
		var/clone_damage = damage * 0.05
		if(clone_damage > 0)
			INVOKE_ASYNC(src, PROC_REF(apply_clone_damage), clone_damage)

/datum/component/oracle_proxy_passive/proc/recharge_guaranteed_evade()
	guaranteed_evade_ready = TRUE

/datum/component/oracle_proxy_passive/proc/apply_clone_damage(damage)
	var/mob/living/L = parent
	if(QDELETED(L) || L.stat == DEAD)
		return
	L.adjustCloneLoss(damage)
