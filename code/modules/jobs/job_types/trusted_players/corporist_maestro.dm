// The Corporist Maestro - A high-ranking member of The Ring's Corporist school
/datum/job/corporist_maestro
	title = "Corporist Maestro"
	outfit = /datum/outfit/job/corporist_maestro
	department_head = list("the Ring")
	faction = "Station"
	supervisors = "the Ring's artistic vision"
	selection_color = "#f5f5dc"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a Maestro of the Corporist school, a high-ranking member of the Ring. \
		The Ring is a Syndicate devoted to creating art that reflects the human condition through causing and exhibiting human suffering. \
		As a Corporist, you specialize in utilizing the interaction between human bones and muscles, the contraction and elongation thereof. \
		You have buffed stats. You automatically dodge the first attack every 30 seconds, and have a 50% chance to dodge attacks when not holding a weapon. \
		However, all damage you take also inflicts 5% unhealable damage."
	job_notice = "Avoid killing other players without artistic purpose. Your art is your justification."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 300,
		PRUDENCE_ATTRIBUTE = 300,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/corporist_maestro/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_RING_ARTIST, JOB_TRAIT)
	H.AddComponent(/datum/component/oracle_proxy_passive)
	H.set_species(/datum/species/corporist_maestro)

	// Re-equip hand items after species change (set_species can drop held items)
	var/obj/item/ego_weapon/city/ring/tibia/weapon = new(H)
	H.put_in_l_hand(weapon)
	var/obj/item/clothing/suit/armor/ego_gear/city/ring_maestro/armor = new(H)
	H.put_in_r_hand(armor)

	// Add artistic EXP component with starting bonus
	var/datum/component/artistic_exp/exp_comp = H.AddComponent(/datum/component/artistic_exp)
	exp_comp.grant_starting_points("maestro")

	// Grant Maestro actions
	var/datum/action/cooldown/sculpt_corpse/sculpt = new(H)
	sculpt.Grant(H)
	var/datum/action/cooldown/demonstrate_artistry/demo = new(H)
	demo.Grant(H)
	var/datum/action/cooldown/judge_artwork/judge = new(H)
	judge.Grant(H)
	var/datum/action/cooldown/describe_artwork/describe = new(H)
	describe.Grant(H)
	var/datum/action/cooldown/reset_artistry/reset = new(H)
	reset.Grant(H)
	var/datum/action/innate/ring_skill_tree/tree = new(H)
	tree.Grant(H)

	// Add antagonist datum for rules/round end tracking
	if(H.mind)
		H.mind.add_antag_datum(/datum/antagonist/ring_artist/maestro)

	. = ..()

/datum/outfit/job/corporist_maestro
	name = "Corporist Maestro"
	jobtype = /datum/job/corporist_maestro

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/pda/security
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/laceup
	// l_hand and r_hand are equipped in after_spawn() after set_species()
	l_pocket = /obj/item/ring_apprentice_recruitment

// Ring Corporist Apprentice Recruitment Scroll
/obj/item/ring_apprentice_recruitment
	name = "corporist apprenticeship contract"
	desc = "An ornate contract that allows you to recruit an apprentice into the Corporist school of the Ring."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "scroll"
	w_class = WEIGHT_CLASS_TINY
	/// Whether this contract has been used
	var/used = FALSE

/obj/item/ring_apprentice_recruitment/attack(mob/living/target, mob/living/user)
	if(used)
		to_chat(user, span_warning("This contract has already been used."))
		return
	if(!ishuman(target))
		to_chat(user, span_warning("You can only recruit humans."))
		return
	if(target == user)
		to_chat(user, span_warning("You cannot recruit yourself."))
		return

	var/mob/living/carbon/human/H = target

	// Ask target if they accept
	var/response = alert(H, "[user] is offering to make you their Corporist Apprentice. Do you accept?", "Apprenticeship Offer", "Accept", "Decline")

	if(response != "Accept")
		to_chat(user, span_warning("[H] declined your offer."))
		return

	// Check if user still has the contract and is nearby
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

	// Give armor (mask auto-equips when worn, weapon is summoned from armor via ability)
	var/obj/item/clothing/suit/armor/ego_gear/city/ring_apprentice/armor = new(H.loc)
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
		id_card.assignment = "Corporist Apprentice"
		id_card.update_label()
		id_card.update_icon()

	// Update mind role and add antagonist datum
	if(H.mind)
		H.mind.assigned_role = "Corporist Apprentice"
		// Remove any existing ring_artist datum (if they were a student)
		var/datum/antagonist/ring_artist/old_antag = H.mind.has_antag_datum(/datum/antagonist/ring_artist)
		if(old_antag)
			H.mind.remove_antag_datum(old_antag.type)
		// Add apprentice antagonist datum
		H.mind.add_antag_datum(/datum/antagonist/ring_artist/apprentice)

	// Set the apprentice species (full prosthetic body)
	H.set_species(/datum/species/corporist_apprentice)

	// Remove underwear/undershirt/socks for full prosthetic body
	H.underwear = "Nude"
	H.undershirt = "Nude"
	H.socks = "Nude"
	H.updateappearance()

	// Add the oracle proxy passive component and traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, "corporist_apprentice")
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, "corporist_apprentice")
	ADD_TRAIT(H, TRAIT_RING_ARTIST, "corporist_apprentice")
	H.AddComponent(/datum/component/oracle_proxy_passive)

	// Check if they already have artistic EXP (e.g., they were a student)
	var/datum/component/artistic_exp/exp_comp = H.GetComponent(/datum/component/artistic_exp)
	if(exp_comp)
		// They were already a student - preserve their EXP and add 4 skill points
		exp_comp.grant_starting_points("apprentice")
		// Remove student component if they had one
		var/datum/component/corporist_student/student_comp = H.GetComponent(/datum/component/corporist_student)
		if(student_comp)
			qdel(student_comp)
	else
		// New to the arts - create fresh component
		exp_comp = H.AddComponent(/datum/component/artistic_exp)
		exp_comp.grant_starting_points("apprentice")

	// Grant Apprentice actions
	var/datum/action/cooldown/sculpt_corpse/sculpt = new(H)
	sculpt.Grant(H)
	var/datum/action/cooldown/describe_artwork/describe = new(H)
	describe.Grant(H)
	var/datum/action/innate/ring_skill_tree/tree = new(H)
	tree.Grant(H)

	// Visual/audio feedback
	to_chat(user, span_notice("You have recruited [H] as your apprentice."))
	playsound(get_turf(H), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)

	// Show role explanation to the new apprentice
	to_chat(H, span_userdanger("You have become a Corporist Apprentice!"))
	to_chat(H, span_boldnotice("You are now an apprentice of [user], a Maestro of the Corporist school. \
		The Ring is a Syndicate devoted to creating art that reflects the human condition. \
		As a Corporist, you will learn to sculpt flesh and bone into masterpieces."))
	to_chat(H, span_boldnotice("You have buffed stats. You automatically dodge the first attack every 30 seconds, \
		and have a 50% chance to dodge attacks when not holding a weapon. \
		However, all damage you take also inflicts 5% unhealable damage."))
	to_chat(H, span_boldwarning("Avoid killing other players without artistic purpose. \
		Your art is your justification."))

	// Consume the contract
	qdel(src)
